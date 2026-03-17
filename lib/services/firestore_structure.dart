import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore Collection Structure and Helper Functions
/// 
/// This file defines the structure for all Firestore collections
/// and provides helper functions to create and manage documents.
/// 
/// Collections:
/// - users/{uid}
/// - properties/{propertyId}
/// - wallet/{uid}
/// - saved_searches/{searchId}
/// - packages/{packageId}

class FirestoreStructure {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection names
  static const String usersCollection = 'users';
  static const String propertiesCollection = 'properties';
  static const String walletCollection = 'wallet';
  static const String savedSearchesCollection = 'saved_searches';
  static const String packagesCollection = 'packages';

  /// Create user document in users/{uid} collection
  static Future<void> createUserDocument({
    required String uid,
    required String name,
    required String email,
    required String phone,
    String? profileImageUrl,
    bool isVerified = false,
    bool isAdmin = false,
  }) async {
    try {
      await _firestore.collection(usersCollection).doc(uid).set({
        'name': name,
        'email': email,
        'phone': phone,
        'profileImageUrl': profileImageUrl ?? 'https://via.placeholder.com/150/4F46E5/FFFFFF?text=${name.substring(0, 1).toUpperCase()}',
        'totalListings': 0,
        'activeListings': 0,
        'propertyLimit': 3, // Default free tier: 3 properties for all users
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isVerified': isVerified,
        'isAdmin': isAdmin,
        'isRealEstateOffice': false,
        'lastLoginAt': FieldValue.serverTimestamp(),
        'preferences': {
          'notifications': true,
          'emailUpdates': true,
          'language': 'en',
          'theme': 'light',
        },
        'stats': {
          'propertiesViewed': 0,
          'searchesPerformed': 0,
          'favoritesCount': 0,
        },
      });
      
      print('✅ User document created for $uid');
    } catch (e) {
      print('❌ Error creating user document: $e');
      rethrow;
    }
  }

  /// Create property document in properties/{propertyId} collection
  static Future<void> createPropertyDocument({
    required String propertyId,
    required String userId,
    required String title,
    required String description,
    required double price,
    double? monthlyRent,
    required int sizeSqm,
    required String city,
    required String neighborhood,
    required String address,
    required int bedrooms,
    required int bathrooms,
    required int floors,
    int? yearBuilt,
    required String type, // 'apartment', 'house', 'villa', 'commercial'
    required String status, // 'for_sale', 'for_rent', 'sold', 'rented'
    required String condition, // 'excellent', 'good', 'fair', 'needs_renovation'
    double? deposit,
    required String contactPhone,
    required String contactEmail,
    String? agentName,
    required List<String> imageUrls,
    Map<String, bool> features = const {},
    bool isFeatured = false,
    bool isVerified = false,
    bool isBoosted = false,
    String? boostPackageName,
    DateTime? boostExpiresAt,
  }) async {
    try {
      await _firestore.collection(propertiesCollection).doc(propertyId).set({
        'userId': userId,
        'title': title,
        'description': description,
        'price': price,
        'monthlyRent': monthlyRent,
        'sizeSqm': sizeSqm,
        'city': city,
        'neighborhood': neighborhood,
        'address': address,
        'bedrooms': bedrooms,
        'bathrooms': bathrooms,
        'floors': floors,
        'yearBuilt': yearBuilt,
        'type': type,
        'status': status,
        'condition': condition,
        'deposit': deposit,
        'contactPhone': contactPhone,
        'contactEmail': contactEmail,
        'agentName': agentName,
        'imageUrls': imageUrls,
        'features': {
          'hasBalcony': features['hasBalcony'] ?? false,
          'hasGarden': features['hasGarden'] ?? false,
          'hasParking': features['hasParking'] ?? false,
          'hasPool': features['hasPool'] ?? false,
          'hasGym': features['hasGym'] ?? false,
          'hasSecurity': features['hasSecurity'] ?? false,
          'hasElevator': features['hasElevator'] ?? false,
          'hasAC': features['hasAC'] ?? false,
          'hasHeating': features['hasHeating'] ?? false,
          'hasFurnished': features['hasFurnished'] ?? false,
          'hasPetFriendly': features['hasPetFriendly'] ?? false,
          'hasWaterWell': features['hasWaterWell'] ?? false,
          'hasNearbySchools': features['hasNearbySchools'] ?? false,
          'hasNearbyHospitals': features['hasNearbyHospitals'] ?? false,
          'hasNearbyShopping': features['hasNearbyShopping'] ?? false,
          'hasPublicTransport': features['hasPublicTransport'] ?? false,
        },
        'views': 0,
        'isFeatured': isFeatured,
        'isVerified': isVerified,
        'isBoosted': isBoosted,
        'boostPackageName': boostPackageName,
        'boostExpiresAt': boostExpiresAt != null ? Timestamp.fromDate(boostExpiresAt) : null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'publishedAt': FieldValue.serverTimestamp(),
        'expiresAt': FieldValue.serverTimestamp(),
        'location': {
          'latitude': 0.0, // Will be set when location is available
          'longitude': 0.0,
          'address': address,
        },
        'analytics': {
          'totalViews': 0,
          'uniqueViews': 0,
          'contactClicks': 0,
          'favorites': 0,
          'shares': 0,
        },
      });
      
      print('✅ Property document created for $propertyId');
    } catch (e) {
      print('❌ Error creating property document: $e');
      rethrow;
    }
  }

  /// Create wallet document in wallet/{uid} collection
  static Future<void> createWalletDocument({
    required String uid,
    double initialBalance = 0.0,
  }) async {
    try {
      await _firestore.collection(walletCollection).doc(uid).set({
        'balance': initialBalance,
        'currency': 'LYD',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'transactions': [],
        'settings': {
          'autoRecharge': false,
          'rechargeThreshold': 50.0,
          'notifications': true,
        },
        'stats': {
          'totalDeposited': 0.0,
          'totalSpent': 0.0,
          'totalTransactions': 0,
        },
      });
      
      print('✅ Wallet document created for $uid');
    } catch (e) {
      print('❌ Error creating wallet document: $e');
      rethrow;
    }
  }

  /// Add transaction to wallet
  static Future<void> addWalletTransaction({
    required String uid,
    required String type, // 'deposit', 'withdrawal', 'purchase', 'refund'
    required double amount,
    required String description,
    String? referenceId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final transaction = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'type': type,
        'amount': amount,
        'description': description,
        'referenceId': referenceId,
        'metadata': metadata ?? {},
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'completed',
      };

      await _firestore.collection(walletCollection).doc(uid).update({
        'transactions': FieldValue.arrayUnion([transaction]),
        'balance': FieldValue.increment(amount),
        'updatedAt': FieldValue.serverTimestamp(),
        'stats.totalTransactions': FieldValue.increment(1),
        'stats.totalDeposited': FieldValue.increment(amount > 0 ? amount : 0),
        'stats.totalSpent': FieldValue.increment(amount < 0 ? amount.abs() : 0),
      });
      
      print('✅ Transaction added to wallet for $uid');
    } catch (e) {
      print('❌ Error adding wallet transaction: $e');
      rethrow;
    }
  }

  /// Create saved search document in saved_searches/{searchId} collection
  static Future<void> createSavedSearchDocument({
    required String searchId,
    required String userId,
    required String name,
    required Map<String, dynamic> filters,
    String? description,
  }) async {
    try {
      await _firestore.collection(savedSearchesCollection).doc(searchId).set({
        'userId': userId,
        'name': name,
        'description': description,
        'filters': filters,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastRunAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'notifications': {
          'enabled': true,
          'email': true,
          'push': true,
        },
        'stats': {
          'runCount': 0,
          'resultsFound': 0,
          'lastResultsCount': 0,
        },
        'schedule': {
          'frequency': 'daily', // 'daily', 'weekly', 'monthly', 'manual'
          'nextRun': FieldValue.serverTimestamp(),
        },
      });
      
      print('✅ Saved search document created for $searchId');
    } catch (e) {
      print('❌ Error creating saved search document: $e');
      rethrow;
    }
  }

  /// Create package document in packages/{packageId} collection
  static Future<void> createPackageDocument({
    required String packageId,
    required String name,
    required String description,
    required double price,
    required String currency,
    required int durationDays,
    required List<String> features,
    bool isActive = true,
    int priority = 0,
  }) async {
    try {
      await _firestore.collection(packagesCollection).doc(packageId).set({
        'name': name,
        'description': description,
        'price': price,
        'currency': currency,
        'durationDays': durationDays,
        'features': features,
        'isActive': isActive,
        'priority': priority,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'stats': {
          'totalPurchases': 0,
          'totalRevenue': 0.0,
          'activeSubscriptions': 0,
        },
        'settings': {
          'maxProperties': durationDays == 1 ? 1 : durationDays == 7 ? 3 : 10,
          'boostPriority': priority,
          'featuredPlacement': priority > 0,
        },
      });
      
      print('✅ Package document created for $packageId');
    } catch (e) {
      print('❌ Error creating package document: $e');
      rethrow;
    }
  }

  /// Initialize default packages
  static Future<void> initializeDefaultPackages() async {
    try {
      // Top Listing - 1 Day
      await createPackageDocument(
        packageId: 'top_listing_1day',
        name: 'Top Listing - 1 Day',
        description: 'Boost your property for 1 day',
        price: 20.0,
        currency: 'LYD',
        durationDays: 1,
        features: [
          'Featured placement',
          'Priority in search results',
          'Highlighted listing',
          'Increased visibility',
        ],
        priority: 3,
      );

      // Top Listing - 1 Week
      await createPackageDocument(
        packageId: 'top_listing_1week',
        name: 'Top Listing - 1 Week',
        description: 'Boost your property for 1 week',
        price: 100.0,
        currency: 'LYD',
        durationDays: 7,
        features: [
          'Featured placement',
          'Priority in search results',
          'Highlighted listing',
          'Increased visibility',
          'Multiple property boost',
        ],
        priority: 2,
      );

      // Top Listing - 1 Month
      await createPackageDocument(
        packageId: 'top_listing_1month',
        name: 'Top Listing - 1 Month',
        description: 'Boost your property for 1 month',
        price: 300.0,
        currency: 'LYD',
        durationDays: 30,
        features: [
          'Featured placement',
          'Priority in search results',
          'Highlighted listing',
          'Increased visibility',
          'Multiple property boost',
          'Premium support',
        ],
        priority: 1,
      );

      print('✅ Default packages initialized');
    } catch (e) {
      print('❌ Error initializing default packages: $e');
      rethrow;
    }
  }

  /// Get collection reference helpers
  static CollectionReference get users => _firestore.collection(usersCollection);
  static CollectionReference get properties => _firestore.collection(propertiesCollection);
  static CollectionReference get wallet => _firestore.collection(walletCollection);
  static CollectionReference get savedSearches => _firestore.collection(savedSearchesCollection);
  static CollectionReference get packages => _firestore.collection(packagesCollection);

  /// Batch operations helper
  static WriteBatch batch() => _firestore.batch();

  /// Transaction helper
  static Future<T> runTransaction<T>(TransactionHandler<T> transactionHandler) {
    return _firestore.runTransaction(transactionHandler);
  }
}

/// Firestore Security Rules Template
/// 
/// Copy these rules to your Firebase Console > Firestore > Rules:
const String firestoreSecurityRules = '''
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection - users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      allow read: if request.auth != null; // Allow reading other users for public profiles
    }
    
    // Properties collection - authenticated users can read, owners can write
    match /properties/{propertyId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && request.auth.uid == resource.data.userId;
      allow update, delete: if request.auth != null && request.auth.uid == resource.data.userId;
    }
    
    // Wallet collection - users can only access their own wallet
    match /wallet/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Saved searches collection - users can only access their own searches
    match /saved_searches/{searchId} {
      allow read, write: if request.auth != null && request.auth.uid == resource.data.userId;
    }
    
    // Packages collection - authenticated users can read, admins can write
    match /packages/{packageId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        exists(/databases/\$(database)/documents/users/\$(request.auth.uid)) &&
        get(/databases/\$(database)/documents/users/\$(request.auth.uid)).data.isAdmin == true;
    }
  }
}
''';

/// Firestore Indexes Template
/// 
/// Add these indexes in Firebase Console > Firestore > Indexes:
const List<Map<String, dynamic>> firestoreIndexes = [
  {
    'collection': 'properties',
    'fields': [
      {'field': 'status', 'order': 'ASCENDING'},
      {'field': 'city', 'order': 'ASCENDING'},
      {'field': 'createdAt', 'order': 'DESCENDING'},
    ],
  },
  {
    'collection': 'properties',
    'fields': [
      {'field': 'type', 'order': 'ASCENDING'},
      {'field': 'price', 'order': 'ASCENDING'},
      {'field': 'createdAt', 'order': 'DESCENDING'},
    ],
  },
  {
    'collection': 'properties',
    'fields': [
      {'field': 'isBoosted', 'order': 'DESCENDING'},
      {'field': 'isFeatured', 'order': 'DESCENDING'},
      {'field': 'createdAt', 'order': 'DESCENDING'},
    ],
  },
  {
    'collection': 'saved_searches',
    'fields': [
      {'field': 'userId', 'order': 'ASCENDING'},
      {'field': 'createdAt', 'order': 'DESCENDING'},
    ],
  },
  {
    'collection': 'wallet',
    'fields': [
      {'field': 'updatedAt', 'order': 'DESCENDING'},
    ],
  },
];
