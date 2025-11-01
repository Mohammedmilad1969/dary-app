import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/premium_package.dart' as premium_package;
import '../models/wallet.dart' as wallet_models;
import '../services/wallet_service.dart' as wallet_service;
import 'property_service.dart';

/// Firebase-based Paywall Service
/// 
/// Handles premium package management and purchases with Firestore.
/// Integrates with WalletService for payment processing.
class PaywallService extends ChangeNotifier {
  static final PaywallService _instance = PaywallService._internal();
  factory PaywallService() => _instance;
  PaywallService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final wallet_service.WalletService _walletService = wallet_service.WalletService();
  final PropertyService _propertyService = PropertyService();

  List<premium_package.PremiumPackage> _packages = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<QuerySnapshot>? _packagesSubscription;

  List<premium_package.PremiumPackage> get packages => List.unmodifiable(_packages);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setErrorMessage(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// Initialize the paywall service
  Future<void> initialize() async {
    try {
      _setLoading(true);
      _setErrorMessage(null);

      // Start listening to packages collection
      _packagesSubscription = _firestore
          .collection('packages')
          .orderBy('price')
          .snapshots()
          .listen(
        (snapshot) {
          _packages = snapshot.docs.map((doc) {
            final data = doc.data();
            return premium_package.PremiumPackage.fromFirestore(doc.id, data);
          }).toList();
          notifyListeners();
          
          if (kDebugMode) {
            debugPrint('💎 Packages updated: ${_packages.length} packages');
          }
        },
        onError: (error) {
          _setErrorMessage('Failed to load packages: $error');
          if (kDebugMode) {
            debugPrint('❌ Packages stream error: $error');
          }
        },
      );

      // Create default packages if they don't exist
      await _createDefaultPackages();

      if (kDebugMode) {
        debugPrint('💎 PaywallService initialized');
      }
    } catch (e) {
      _setErrorMessage('Failed to initialize PaywallService: $e');
      if (kDebugMode) {
        debugPrint('❌ PaywallService initialization error: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Create default packages if they don't exist
  Future<void> _createDefaultPackages() async {
    try {
      final packagesSnapshot = await _firestore.collection('packages').get();
      
      if (packagesSnapshot.docs.isEmpty) {
        // Create default packages
        final defaultPackages = [
          {
            'name': '1 Day Top Listing',
            'description': 'Boost your property for 1 day',
            'price': 20.0,
            'durationDays': 1,
            'features': [
              'Property appears at top of search results',
              'Highlighted with premium badge',
              'Increased visibility',
              'Priority in featured section',
            ],
            'isActive': true,
            'createdAt': Timestamp.now(),
            'updatedAt': Timestamp.now(),
          },
          {
            'name': '1 Week Top Listing',
            'description': 'Boost your property for 1 week',
            'price': 100.0,
            'durationDays': 7,
            'features': [
              'Property appears at top of search results',
              'Highlighted with premium badge',
              'Increased visibility',
              'Priority in featured section',
              'Extended exposure period',
            ],
            'isActive': true,
            'createdAt': Timestamp.now(),
            'updatedAt': Timestamp.now(),
          },
          {
            'name': '1 Month Top Listing',
            'description': 'Boost your property for 1 month',
            'price': 300.0,
            'durationDays': 30,
            'features': [
              'Property appears at top of search results',
              'Highlighted with premium badge',
              'Increased visibility',
              'Priority in featured section',
              'Maximum exposure period',
              'Best value for money',
            ],
            'isActive': true,
            'createdAt': Timestamp.now(),
            'updatedAt': Timestamp.now(),
          },
        ];

        // Add packages to Firestore
        for (final packageData in defaultPackages) {
          await _firestore.collection('packages').add(packageData);
        }

        if (kDebugMode) {
          debugPrint('💎 Created ${defaultPackages.length} default packages');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error creating default packages: $e');
      }
    }
  }

  /// Purchase a premium package
  Future<bool> purchasePackage({
    required String userId,
    required String packageId,
    required String propertyId,
  }) async {
    try {
      _setLoading(true);
      _setErrorMessage(null);

      // Get package details from static packages
      final package = premium_package.PaywallService.getPackageById(packageId);
      if (package == null) {
        _setErrorMessage('Package not found');
        return false;
      }

      // Check if package is active
      if (!package.isActive) {
        _setErrorMessage('Package is not available');
        return false;
      }

      // Check wallet balance
      final currentBalance = _walletService.getCurrentBalance();
      if (currentBalance < package.price) {
        _setErrorMessage('Insufficient balance');
        return false;
      }

      // Deduct amount from wallet
      final deductSuccess = await _walletService.deductAmount(
        userId: userId,
        amount: package.price,
        description: 'Top Listing Purchase - ${package.name}',
        metadata: {
          'packageId': packageId,
          'propertyId': propertyId,
          'durationDays': package.durationDays,
        },
      );

      if (!deductSuccess) {
        _setErrorMessage('Payment failed');
        return false;
      }

      // Boost the property directly using PropertyService
      final boostSuccess = await _propertyService.boostProperty(
        propertyId,
        package.name,
        package.price,
        package.durationDays,
      );

      if (!boostSuccess) {
        // Refund the amount if boosting fails
        await _walletService.addTransaction(
          userId: userId,
          amount: package.price,
          type: wallet_models.TransactionType.refund,
          description: 'Refund - Failed Top Listing Purchase',
          metadata: {
            'packageId': packageId,
            'propertyId': propertyId,
            'reason': 'boost_failed',
          },
        );
        
        _setErrorMessage('Failed to boost property');
        return false;
      }

      // Record the purchase
      await _recordPurchase(
        userId: userId,
        packageId: packageId,
        propertyId: propertyId,
        amount: package.price,
      );

      if (kDebugMode) {
        debugPrint('✅ Package purchased successfully: ${package.name} for ${package.price} LYD');
      }

      return true;
    } catch (e) {
      _setErrorMessage('Failed to purchase package: $e');
      if (kDebugMode) {
        debugPrint('❌ Error purchasing package: $e');
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Record a purchase in Firestore
  Future<void> _recordPurchase({
    required String userId,
    required String packageId,
    required String propertyId,
    required double amount,
  }) async {
    try {
      await _firestore.collection('purchases').add({
        'userId': userId,
        'packageId': packageId,
        'propertyId': propertyId,
        'amount': amount,
        'status': 'completed',
        'createdAt': Timestamp.now(),
      });

      if (kDebugMode) {
        debugPrint('📝 Purchase recorded: $packageId for $propertyId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error recording purchase: $e');
      }
    }
  }

  /// Get purchase history for a user
  Future<List<Map<String, dynamic>>> getPurchaseHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('purchases')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting purchase history: $e');
      }
      return [];
    }
  }

  /// Get active boosts for a user's properties
  Future<List<Map<String, dynamic>>> getActiveBoosts(String userId) async {
    try {
      final now = Timestamp.now();
      final snapshot = await _firestore
          .collection('properties')
          .where('userId', isEqualTo: userId)
          .where('isBoosted', isEqualTo: true)
          .where('boostExpiresAt', isGreaterThan: now)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'propertyId': doc.id,
          'title': data['title'],
          'boostPackageName': data['boostPackageName'],
          'boostExpiresAt': data['boostExpiresAt'],
        };
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting active boosts: $e');
      }
      return [];
    }
  }

  /// Check if a property is currently boosted
  Future<bool> isPropertyBoosted(String propertyId) async {
    try {
      final doc = await _firestore.collection('properties').doc(propertyId).get();
      if (!doc.exists) return false;

      final data = doc.data()!;
      final isBoosted = data['isBoosted'] ?? false;
      final boostExpiresAt = data['boostExpiresAt'] as Timestamp?;

      if (isBoosted && boostExpiresAt != null) {
        return boostExpiresAt.toDate().isAfter(DateTime.now());
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error checking boost status: $e');
      }
      return false;
    }
  }

  /// Extend a property's boost
  Future<bool> extendBoost({
    required String userId,
    required String propertyId,
    required String packageId,
  }) async {
    try {
      // Get package details
      final packageDoc = await _firestore.collection('packages').doc(packageId).get();
      if (!packageDoc.exists) {
        _setErrorMessage('Package not found');
        return false;
      }

      // Purchase the package to extend the boost
      return await purchasePackage(
        userId: userId,
        packageId: packageId,
        propertyId: propertyId,
      );
    } catch (e) {
      _setErrorMessage('Failed to extend boost: $e');
      if (kDebugMode) {
        debugPrint('❌ Error extending boost: $e');
      }
      return false;
    }
  }

  /// Dispose resources
  @override
  void dispose() {
    _packagesSubscription?.cancel();
    super.dispose();
  }
}
