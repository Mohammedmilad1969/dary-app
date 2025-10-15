import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_structure.dart';
import 'firestore_setup.dart';

/// Firestore Database Manager
/// 
/// This class provides easy access to Firestore operations
/// and handles initialization of the database structure.
class FirestoreManager {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static bool _isInitialized = false;

  /// Initialize Firestore with default structure and sample data
  static Future<void> initialize({
    bool createSampleData = false,
    bool clearExistingData = false,
  }) async {
    try {
      if (clearExistingData) {
        await FirestoreSetup.clearAllCollections();
      }

      if (createSampleData) {
        await FirestoreSetup.completeSetup();
      } else {
        await FirestoreStructure.initializeDefaultPackages();
      }

      _isInitialized = true;
      print('✅ Firestore Manager initialized successfully');
    } catch (e) {
      print('❌ Error initializing Firestore Manager: $e');
      rethrow;
    }
  }

  /// Check if Firestore is initialized
  static bool get isInitialized => _isInitialized;

  /// Get Firestore instance
  static FirebaseFirestore get instance => _firestore;

  /// Quick access to collections
  static CollectionReference get users => _firestore.collection('users');
  static CollectionReference get properties => _firestore.collection('properties');
  static CollectionReference get wallet => _firestore.collection('wallet');
  static CollectionReference get savedSearches => _firestore.collection('saved_searches');
  static CollectionReference get packages => _firestore.collection('packages');

  /// Create a new user with wallet
  static Future<void> createUserWithWallet({
    required String uid,
    required String name,
    required String email,
    required String phone,
    double initialBalance = 0.0,
    bool isVerified = false,
    bool isAdmin = false,
  }) async {
    try {
      // Create user document
      await FirestoreStructure.createUserDocument(
        uid: uid,
        name: name,
        email: email,
        phone: phone,
        isVerified: isVerified,
        isAdmin: isAdmin,
      );

      // Create wallet document
      await FirestoreStructure.createWalletDocument(
        uid: uid,
        initialBalance: initialBalance,
      );

      print('✅ User and wallet created for $uid');
    } catch (e) {
      print('❌ Error creating user with wallet: $e');
      rethrow;
    }
  }

  /// Boost a property
  static Future<void> boostProperty({
    required String propertyId,
    required String packageId,
    required int durationDays,
  }) async {
    try {
      final boostExpiresAt = DateTime.now().add(Duration(days: durationDays));
      
      await _firestore.collection('properties').doc(propertyId).update({
        'isBoosted': true,
        'boostPackageName': packageId,
        'boostExpiresAt': Timestamp.fromDate(boostExpiresAt),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Property $propertyId boosted until $boostExpiresAt');
    } catch (e) {
      print('❌ Error boosting property: $e');
      rethrow;
    }
  }

  /// Get user's wallet balance
  static Future<double> getUserWalletBalance(String uid) async {
    try {
      final doc = await _firestore.collection('wallet').doc(uid).get();
      if (doc.exists) {
        return (doc.data()?['balance'] ?? 0.0).toDouble();
      }
      return 0.0;
    } catch (e) {
      print('❌ Error getting wallet balance: $e');
      return 0.0;
    }
  }

  /// Get user's properties
  static Future<List<DocumentSnapshot>> getUserProperties(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('properties')
          .where('userId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs;
    } catch (e) {
      print('❌ Error getting user properties: $e');
      return [];
    }
  }

  /// Get featured properties
  static Future<List<DocumentSnapshot>> getFeaturedProperties() async {
    try {
      final snapshot = await _firestore
          .collection('properties')
          .where('isFeatured', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();
      
      return snapshot.docs;
    } catch (e) {
      print('❌ Error getting featured properties: $e');
      return [];
    }
  }

  /// Get boosted properties
  static Future<List<DocumentSnapshot>> getBoostedProperties() async {
    try {
      final now = Timestamp.now();
      final snapshot = await _firestore
          .collection('properties')
          .where('isBoosted', isEqualTo: true)
          .where('boostExpiresAt', isGreaterThan: now)
          .orderBy('boostExpiresAt', descending: true)
          .limit(10)
          .get();
      
      return snapshot.docs;
    } catch (e) {
      print('❌ Error getting boosted properties: $e');
      return [];
    }
  }

  /// Search properties with filters
  static Future<List<DocumentSnapshot>> searchProperties({
    String? city,
    String? type,
    String? status,
    double? minPrice,
    double? maxPrice,
    int? minBedrooms,
    int? maxBedrooms,
    List<String>? features,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore.collection('properties');

      // Apply filters
      if (city != null) query = query.where('city', isEqualTo: city);
      if (type != null) query = query.where('type', isEqualTo: type);
      if (status != null) query = query.where('status', isEqualTo: status);
      if (minPrice != null) query = query.where('price', isGreaterThanOrEqualTo: minPrice);
      if (maxPrice != null) query = query.where('price', isLessThanOrEqualTo: maxPrice);
      if (minBedrooms != null) query = query.where('bedrooms', isGreaterThanOrEqualTo: minBedrooms);
      if (maxBedrooms != null) query = query.where('bedrooms', isLessThanOrEqualTo: maxBedrooms);

      // Order by creation date
      query = query.orderBy('createdAt', descending: true).limit(limit);

      final snapshot = await query.get();
      return snapshot.docs;
    } catch (e) {
      print('❌ Error searching properties: $e');
      return [];
    }
  }

  /// Get available packages
  static Future<List<DocumentSnapshot>> getAvailablePackages() async {
    try {
      final snapshot = await _firestore
          .collection('packages')
          .where('isActive', isEqualTo: true)
          .orderBy('priority', descending: false)
          .get();
      
      return snapshot.docs;
    } catch (e) {
      print('❌ Error getting packages: $e');
      return [];
    }
  }

  /// Increment property views
  static Future<void> incrementPropertyViews(String propertyId) async {
    try {
      await _firestore.collection('properties').doc(propertyId).update({
        'views': FieldValue.increment(1),
        'analytics.totalViews': FieldValue.increment(1),
      });
    } catch (e) {
      print('❌ Error incrementing property views: $e');
    }
  }

  /// Update user profile
  static Future<void> updateUserProfile({
    required String uid,
    String? name,
    String? phone,
    String? profileImageUrl,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;
      if (profileImageUrl != null) updates['profileImageUrl'] = profileImageUrl;

      await _firestore.collection('users').doc(uid).update(updates);
      print('✅ User profile updated for $uid');
    } catch (e) {
      print('❌ Error updating user profile: $e');
      rethrow;
    }
  }

  /// Verify user
  static Future<void> verifyUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'isVerified': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ User $uid verified');
    } catch (e) {
      print('❌ Error verifying user: $e');
      rethrow;
    }
  }

  /// Delete user and all related data
  static Future<void> deleteUser(String uid) async {
    try {
      final batch = _firestore.batch();

      // Delete user document
      batch.delete(_firestore.collection('users').doc(uid));

      // Delete wallet document
      batch.delete(_firestore.collection('wallet').doc(uid));

      // Delete user's properties
      final propertiesSnapshot = await _firestore
          .collection('properties')
          .where('userId', isEqualTo: uid)
          .get();
      
      for (final doc in propertiesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete user's saved searches
      final searchesSnapshot = await _firestore
          .collection('saved_searches')
          .where('userId', isEqualTo: uid)
          .get();
      
      for (final doc in searchesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('✅ User $uid and all related data deleted');
    } catch (e) {
      print('❌ Error deleting user: $e');
      rethrow;
    }
  }
}
