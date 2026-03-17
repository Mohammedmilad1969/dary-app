import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/api_client.dart';
import '../services/wallet_service.dart' as wallet_service;
import '../config/env_config.dart';
import 'wallet.dart' as wallet_models;
import '../l10n/app_localizations.dart';

enum PackageDuration {
  day,
  week,
  month,
}

class PremiumPackage {
  final String id;
  final String name;
  final String description;
  final PackageDuration duration;
  final int durationDays;
  final double price;
  final int? credits; // Number of posting credits provided by this package
  final String currency;
  final List<String> features;
  final bool isPopular;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PremiumPackage({
    required this.id,
    required this.name,
    required this.description,
    required this.duration,
    required this.durationDays,
    required this.price,
    this.credits,
    required this.currency,
    required this.features,
    this.isPopular = false,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PremiumPackage.fromJson(Map<String, dynamic> json) {
    return PremiumPackage(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      duration: _parseDuration(json['duration']),
      durationDays: json['duration_days'] ?? json['durationDays'] ?? 1,
      price: (json['price'] ?? 0).toDouble(),
      credits: json['credits'],
      currency: json['currency'] ?? 'LYD',
      features: (json['features'] ?? []).cast<String>(),
      isPopular: json['is_popular'] ?? json['isPopular'] ?? false,
      isActive: json['is_active'] ?? json['isActive'] ?? true,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  factory PremiumPackage.fromFirestore(String id, Map<String, dynamic> data) {
    return PremiumPackage(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      duration: _parseDuration(data['duration']),
      durationDays: data['durationDays'] ?? 1,
      price: (data['price'] ?? 0).toDouble(),
      credits: data['credits'],
      currency: data['currency'] ?? 'LYD',
      features: (data['features'] ?? []).cast<String>(),
      isPopular: data['isPopular'] ?? false,
      isActive: data['isActive'] ?? true,
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  static PackageDuration _parseDuration(dynamic duration) {
    if (duration == null) return PackageDuration.day;
    final durationString = duration.toString().toLowerCase();
    switch (durationString) {
      case 'day': case 'daily': return PackageDuration.day;
      case 'week': case 'weekly': return PackageDuration.week;
      case 'month': case 'monthly': return PackageDuration.month;
      default: return PackageDuration.day;
    }
  }
}

class PaywallService {
  static const String _currency = 'LYD';

  static final List<PremiumPackage> _packages = [
    PremiumPackage(
      id: 'plus',
      name: 'Plus',
      description: 'Boost your property for 1 day',
      duration: PackageDuration.day,
      durationDays: 1,
      price: 20.0,
      currency: _currency,
      features: const [
        'Priority placement in search results',
        'Featured badge on your listing',
        'Increased visibility',
        '24-hour boost',
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    PremiumPackage(
      id: 'emerald',
      name: 'Emerald',
      description: 'Boost your property for 3 days',
      duration: PackageDuration.day,
      durationDays: 3,
      price: 50.0,
      currency: _currency,
      features: const [
        'Priority placement in search results',
        'Featured badge on your listing',
        'Increased visibility',
        '3-day boost',
        'Enhanced analytics',
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    PremiumPackage(
      id: 'premium',
      name: 'Premium',
      description: 'Boost your property for 1 week',
      duration: PackageDuration.week,
      durationDays: 7,
      price: 100.0,
      currency: _currency,
      features: const [
        'Priority placement in search results',
        'Featured badge on your listing',
        'Increased visibility',
        '7-day boost',
        'Analytics dashboard',
        'Premium support',
      ],
      isPopular: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    PremiumPackage(
      id: 'elite',
      name: 'Elite',
      description: 'Boost your property for 1 month',
      duration: PackageDuration.month,
      durationDays: 30,
      price: 300.0,
      currency: _currency,
      features: const [
        'Priority placement in search results',
        'Featured badge on your listing',
        'Increased visibility',
        '30-day boost',
        'Analytics dashboard',
        'Premium support',
        'Multiple listing promotion',
        'Custom listing design',
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  static final List<PremiumPackage> _creditPackages = [
    PremiumPackage(
      id: 'credits_15',
      name: 'Starter Package',
      description: 'Get 15 posting credits',
      duration: PackageDuration.month,
      durationDays: 30,
      price: 100.0,
      credits: 15,
      currency: _currency,
      features: const [
        '15 Property Posting Credits',
        'Persistent credits (no monthly loss)',
        'Basic search visibility',
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    PremiumPackage(
      id: 'credits_50',
      name: 'Standard Package',
      description: 'Get 50 posting credits',
      duration: PackageDuration.month,
      durationDays: 30,
      price: 300.0,
      credits: 50,
      currency: _currency,
      features: const [
        '50 Property Posting Credits',
        'Persistent credits',
        'Standard search visibility',
        'Email support',
      ],
      isPopular: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    PremiumPackage(
      id: 'credits_100',
      name: 'Professional Package',
      description: 'Get 100 posting credits',
      duration: PackageDuration.month,
      durationDays: 30,
      price: 600.0,
      credits: 100,
      currency: _currency,
      features: const [
        '100 Property Posting Credits',
        'Persistent credits',
        'Enhanced search visibility',
        'Priority support',
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    PremiumPackage(
      id: 'credits_200',
      name: 'Business Package',
      description: 'Get 200 posting credits',
      duration: PackageDuration.month,
      durationDays: 30,
      price: 1000.0,
      credits: 200,
      currency: _currency,
      features: const [
        '200 Property Posting Credits',
        'Persistent credits',
        'Maximum search visibility',
        'Dedicated account manager',
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  static List<PremiumPackage> get packages => _creditPackages;
  static List<PremiumPackage> get boostPackages => _packages;
  static String get currency => _currency;

  static Future<List<PremiumPackage>> getPackages({String? token}) async {
    // Check if mock data mode is enabled
    if (EnvConfig.useMockData) {
      if (kDebugMode) {
        debugPrint('🎭 Using mock data for packages (useMockData: true)');
      }
      return _creditPackages;
    }
    
    try {
      // Try to fetch from API
      if (kDebugMode) {
        debugPrint('🌐 Fetching packages from API (useMockData: false)');
      }
      final response = await apiClient.get('/paywall/packages', token: token);
      
      if (response['data'] != null && response['data'] is List) {
        final List<dynamic> packagesData = response['data'];
        return packagesData.map((data) => PremiumPackage.fromJson(data)).toList();
      } else if (response['packages'] != null && response['packages'] is List) {
        final List<dynamic> packagesData = response['packages'];
        return packagesData.map((data) => PremiumPackage.fromJson(data)).toList();
      } else {
        // If response format is unexpected, fall back to mock data
        if (kDebugMode) {
          debugPrint('⚠️ Unexpected packages API response format, using mock data');
        }
        return _creditPackages;
      }
    } catch (e) {
      // If API call fails, fall back to mock data
      if (kDebugMode) {
        debugPrint('⚠️ Packages API call failed, using mock data: $e');
      }
      return _creditPackages;
    }
  }

  static Future<bool> purchasePackage(String packageId, {String? token}) async {
    // Check if mock data mode is enabled
    if (EnvConfig.useMockData) {
      if (kDebugMode) {
        debugPrint('🎭 Using mock data for package purchase (useMockData: true)');
      }
      return await _mockPurchasePackage(packageId);
    }
    
    try {
      // Try to purchase via API
      if (kDebugMode) {
        debugPrint('🌐 Purchasing package via API (useMockData: false)');
      }
      final response = await apiClient.post('/paywall/purchase', 
        token: token,
        body: {'package_id': packageId}
      );
      
      if (response['success'] == true || response['status'] == 'success') {
        // If API purchase succeeds, deduct from wallet
        final package = getPackageById(packageId);
        if (package != null) {
          return await _processWalletDeduction(package);
        }
        return true;
      } else {
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Purchase package API call failed: $e');
      }
      
      // Fall back to mock purchase with wallet integration
      return await _mockPurchasePackage(packageId);
    }
  }

  static Future<bool> _mockPurchasePackage(String packageId) async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 2));
    
    // Get the package details
    final package = getPackageById(packageId);
    if (package == null) {
      if (kDebugMode) {
        debugPrint('❌ Package not found: $packageId');
      }
      return false;
    }
    
    // Process wallet deduction
    return await _processWalletDeduction(package);
  }

  static Future<bool> _processWalletDeduction(PremiumPackage package) async {
    // Check if user has sufficient balance
    final currentBalance = wallet_service.WalletService().currentWallet?.balance ?? 0.0;
    if (currentBalance < package.price) {
      if (kDebugMode) {
        debugPrint('❌ Insufficient balance: $currentBalance < ${package.price}');
      }
      return false;
    }
    
    // Deduct the package cost from wallet
    final success = await wallet_service.WalletService().deductAmount(
      userId: wallet_service.WalletService().currentWallet?.userId ?? '',
      amount: package.price,
      description: 'Top Listing Purchase - ${package.name}',
    );
    if (!success) {
      if (kDebugMode) {
        debugPrint('❌ Failed to deduct funds from wallet');
      }
      return false;
    }
    
    // Add purchase transaction
    _addPurchaseTransaction(package);
    
    if (kDebugMode) {
      debugPrint('✅ Package purchased successfully: ${package.name} for ${package.price} ${package.currency}');
    }
    
    return true;
  }

  static void _addPurchaseTransaction(PremiumPackage package) {
    final currentWallet = wallet_service.WalletService().currentWallet;
    if (currentWallet != null) {
      final newTransaction = wallet_models.Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: -package.price, // Negative amount for deduction
        type: wallet_models.TransactionType.purchase,
        description: 'Top Listing Purchase - ${package.name} (${package.durationDays} day${package.durationDays > 1 ? 's' : ''})',
        createdAt: DateTime.now(),
        status: wallet_models.TransactionStatus.completed,
        referenceId: 'PKG${package.id}_${DateTime.now().millisecondsSinceEpoch}',
      );
      
      final updatedTransactions = List<wallet_models.Transaction>.from(currentWallet.transactions)
        ..insert(0, newTransaction); // Add to beginning of list
      
      // Update the wallet with new transaction
      // Transaction is already added via deductAmount method
    }
  }

  static PremiumPackage? getPackageById(String packageId) {
    try {
      // Search in both credits and boost packages
      final allPackages = [..._creditPackages, ..._packages];
      return allPackages.firstWhere((package) => package.id == packageId);
    } catch (e) {
      return null;
    }
  }

  static String getDurationText(PremiumPackage package, AppLocalizations? l10n) {
    if (package.credits != null && package.credits! > 0) {
      return l10n?.oneTimePurchase ?? 'One-time purchase';
    }
    if (package.duration == PackageDuration.week) return l10n?.oneWeek ?? '1 Week';
    if (package.duration == PackageDuration.month) return l10n?.oneMonth ?? '1 Month';
    
    // Default to days
    if (package.durationDays == 1) return l10n?.oneDay ?? '1 Day';
    return l10n?.durationDays('${package.durationDays}') ?? '${package.durationDays} Days';
  }

  static String getDurationDescription(PremiumPackage package, AppLocalizations? l10n) {
    if (package.durationDays == 3) return l10n?.shortTermPromo ?? 'Perfect for short-term promotion';
    switch (package.duration) {
      case PackageDuration.day:
        return l10n?.quickPromo ?? 'Perfect for quick promotion';
      case PackageDuration.week:
        return l10n?.testingWaters ?? 'Great for testing the waters';
      case PackageDuration.month:
        return l10n?.bestValueSerious ?? 'Best value for serious sellers';
    }
  }
}
