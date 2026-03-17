import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/env_config.dart';
import '../config/firebase_config.dart';
import '../services/api_client.dart';

/// Admin data models
class AdminUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final DateTime joinDate;
  final bool isVerified;
  final bool isActive;
  final bool isRealEstateOffice;
  final bool isAdmin;
  final int totalListings;
  final int activeListings;
  final int postingCredits;

  AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.joinDate,
    required this.isVerified,
    required this.isActive,
    this.isRealEstateOffice = false,
    this.isAdmin = false,
    required this.totalListings,
    required this.activeListings,
    this.postingCredits = 0,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      joinDate: DateTime.parse(json['joinDate']),
      isVerified: json['isVerified'],
      isActive: json['isActive'],
      isRealEstateOffice: json['isRealEstateOffice'] ?? false,
      isAdmin: json['isAdmin'] ?? false,
      totalListings: json['totalListings'],
      activeListings: json['activeListings'],
      postingCredits: json['postingCredits'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'joinDate': joinDate.toIso8601String(),
      'isVerified': isVerified,
      'isActive': isActive,
      'isRealEstateOffice': isRealEstateOffice,
      'isAdmin': isAdmin,
      'totalListings': totalListings,
      'activeListings': activeListings,
      'postingCredits': postingCredits,
    };
  }

  AdminUser copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    DateTime? joinDate,
    bool? isVerified,
    bool? isActive,
    bool? isRealEstateOffice,
    bool? isAdmin,
    int? totalListings,
    int? activeListings,
    int? postingCredits,
  }) {
    return AdminUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      joinDate: joinDate ?? this.joinDate,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      isRealEstateOffice: isRealEstateOffice ?? this.isRealEstateOffice,
      isAdmin: isAdmin ?? this.isAdmin,
      totalListings: totalListings ?? this.totalListings,
      activeListings: activeListings ?? this.activeListings,
      postingCredits: postingCredits ?? this.postingCredits,
    );
  }
}

class AdminProperty {
  final String id;
  final String title;
  final String ownerName;
  final String ownerEmail;
  final double price;
  final String city;
  final String status;
  final DateTime createdAt;
  final bool isActive;
  final int views;
  final bool isBoosted;
  final bool isPublished;
  final bool isExpired;

  AdminProperty({
    required this.id,
    required this.title,
    required this.ownerName,
    required this.ownerEmail,
    required this.price,
    required this.city,
    required this.status,
    required this.createdAt,
    required this.isActive,
    required this.views,
    required this.isBoosted,
    required this.isPublished,
    required this.isExpired,
  });

  factory AdminProperty.fromJson(Map<String, dynamic> json) {
    return AdminProperty(
      id: json['id'],
      title: json['title'],
      ownerName: json['ownerName'],
      ownerEmail: json['ownerEmail'],
      price: json['price'].toDouble(),
      city: json['city'],
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
      isActive: json['isActive'],
      views: json['views'],
      isBoosted: json['isBoosted'],
      isPublished: json['isPublished'] ?? true,
      isExpired: json['isExpired'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'ownerName': ownerName,
      'ownerEmail': ownerEmail,
      'price': price,
      'city': city,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
      'views': views,
      'isBoosted': isBoosted,
      'isPublished': isPublished,
      'isExpired': isExpired,
    };
  }

  AdminProperty copyWith({
    String? id,
    String? title,
    String? ownerName,
    String? ownerEmail,
    double? price,
    String? city,
    String? status,
    DateTime? createdAt,
    bool? isActive,
    int? views,
    bool? isBoosted,
    bool? isPublished,
    bool? isExpired,
  }) {
    return AdminProperty(
      id: id ?? this.id,
      title: title ?? this.title,
      ownerName: ownerName ?? this.ownerName,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      price: price ?? this.price,
      city: city ?? this.city,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      views: views ?? this.views,
      isBoosted: isBoosted ?? this.isBoosted,
      isPublished: isPublished ?? this.isPublished,
      isExpired: isExpired ?? this.isExpired,
    );
  }
}

class AdminPayment {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String type;
  final double amount;
  final String currency;
  final String status;
  final DateTime createdAt;
  final String? description;

  AdminPayment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.type,
    required this.amount,
    required this.currency,
    required this.status,
    required this.createdAt,
    this.description,
  });

  factory AdminPayment.fromJson(Map<String, dynamic> json) {
    return AdminPayment(
      id: json['id'],
      userId: json['userId'],
      userName: json['userName'],
      userEmail: json['userEmail'],
      type: json['type'],
      amount: json['amount'].toDouble(),
      currency: json['currency'],
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'type': type,
      'amount': amount,
      'currency': currency,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'description': description,
    };
  }
}

class AdminPremiumListing {
  final String id;
  final String propertyId;
  final String propertyTitle;
  final String ownerName;
  final String ownerEmail;
  final String packageName;
  final double packagePrice;
  final DateTime purchaseDate;
  final DateTime expiryDate;
  final bool isActive;
  final int views;
  final String status;

  AdminPremiumListing({
    required this.id,
    required this.propertyId,
    required this.propertyTitle,
    required this.ownerName,
    required this.ownerEmail,
    required this.packageName,
    required this.packagePrice,
    required this.purchaseDate,
    required this.expiryDate,
    required this.isActive,
    required this.views,
    required this.status,
  });

  factory AdminPremiumListing.fromJson(Map<String, dynamic> json) {
    return AdminPremiumListing(
      id: json['id'],
      propertyId: json['propertyId'],
      propertyTitle: json['propertyTitle'],
      ownerName: json['ownerName'],
      ownerEmail: json['ownerEmail'],
      packageName: json['packageName'],
      packagePrice: json['packagePrice'].toDouble(),
      purchaseDate: DateTime.parse(json['purchaseDate']),
      expiryDate: DateTime.parse(json['expiryDate']),
      isActive: json['isActive'],
      views: json['views'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'propertyId': propertyId,
      'propertyTitle': propertyTitle,
      'ownerName': ownerName,
      'ownerEmail': ownerEmail,
      'packageName': packageName,
      'packagePrice': packagePrice,
      'purchaseDate': purchaseDate.toIso8601String(),
      'expiryDate': expiryDate.toIso8601String(),
      'isActive': isActive,
      'views': views,
      'status': status,
    };
  }

  AdminPremiumListing copyWith({
    String? id,
    String? propertyId,
    String? propertyTitle,
    String? ownerName,
    String? ownerEmail,
    String? packageName,
    double? packagePrice,
    DateTime? purchaseDate,
    DateTime? expiryDate,
    bool? isActive,
    int? views,
    String? status,
  }) {
    return AdminPremiumListing(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      propertyTitle: propertyTitle ?? this.propertyTitle,
      ownerName: ownerName ?? this.ownerName,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      packageName: packageName ?? this.packageName,
      packagePrice: packagePrice ?? this.packagePrice,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      expiryDate: expiryDate ?? this.expiryDate,
      isActive: isActive ?? this.isActive,
      views: views ?? this.views,
      status: status ?? this.status,
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiryDate);
  bool get isExpiringSoon => DateTime.now().add(const Duration(days: 1)).isAfter(expiryDate);
  int get daysUntilExpiry => expiryDate.difference(DateTime.now()).inDays;
}

/// Admin service for managing users, properties, and payments
class AdminService {
  static final AdminService _instance = AdminService._internal();
  factory AdminService() => _instance;
  AdminService._internal();

  final ApiClient _apiClient = ApiClient();

  // Mock data for admin dashboard
  static final List<AdminUser> _mockUsers = [
    AdminUser(
      id: 'user_001',
      name: 'John Doe',
      email: 'john.doe@example.com',
      phone: '+1234567890',
      joinDate: DateTime(2024, 1, 15),
      isVerified: true,
      isActive: true,
      totalListings: 5,
      activeListings: 3,
    ),
    AdminUser(
      id: 'user_002',
      name: 'Jane Smith',
      email: 'jane.smith@example.com',
      phone: '+1987654321',
      joinDate: DateTime(2024, 2, 20),
      isVerified: true,
      isActive: true,
      totalListings: 8,
      activeListings: 6,
    ),
    AdminUser(
      id: 'user_003',
      name: 'Mike Wilson',
      email: 'mike.wilson@example.com',
      phone: '+1122334455',
      joinDate: DateTime(2024, 3, 10),
      isVerified: false,
      isActive: true,
      totalListings: 12,
      activeListings: 9,
    ),
    AdminUser(
      id: 'user_004',
      name: 'Small User',
      email: 'small@test.com',
      phone: '+5555555555',
      joinDate: DateTime(2024, 4, 1),
      isVerified: true,
      isActive: true,
      totalListings: 2,
      activeListings: 1,
    ),
    AdminUser(
      id: 'user_005',
      name: 'Test User',
      email: 't',
      phone: '+1111111111',
      joinDate: DateTime(2024, 5, 1),
      isVerified: false,
      isActive: true,
      totalListings: 1,
      activeListings: 1,
    ),
    AdminUser(
      id: 'user_006',
      name: 'Sarah Johnson',
      email: 'sarah.johnson@example.com',
      phone: '+1222333444',
      joinDate: DateTime(2024, 6, 15),
      isVerified: false,
      isActive: false,
      totalListings: 3,
      activeListings: 0,
    ),
  ];

  static final List<AdminProperty> _mockProperties = [
    AdminProperty(
      id: 'prop_007',
      title: 'Luxury Mediterranean Villa',
      ownerName: 'Luxury Coastal Properties',
      ownerEmail: 'agent7@dary.com',
      price: 850000,
      city: 'Malibu',
      status: 'For Sale',
      createdAt: DateTime(2024, 3, 15),
      isActive: true,
      views: 156,
      isBoosted: true,
      isPublished: true,
      isExpired: false,
    ),
    AdminProperty(
      id: 'prop_008',
      title: 'Modern Studio Apartment',
      ownerName: 'Urban Living Realty',
      ownerEmail: 'agent8@dary.com',
      price: 180000,
      city: 'San Francisco',
      status: 'For Sale',
      createdAt: DateTime(2024, 3, 20),
      isActive: true,
      views: 89,
      isBoosted: false,
      isPublished: true,
      isExpired: false,
    ),
    AdminProperty(
      id: 'prop_009',
      title: 'Historic Townhouse',
      ownerName: 'Historic Homes Co.',
      ownerEmail: 'agent9@dary.com',
      price: 420000,
      city: 'Boston',
      status: 'For Rent',
      createdAt: DateTime(2024, 2, 10),
      isActive: true,
      views: 134,
      isBoosted: false,
      isPublished: true,
      isExpired: false,
    ),
  ];

  static final List<AdminPayment> _mockPayments = [
    AdminPayment(
      id: 'pay_001',
      userId: 'user_001',
      userName: 'John Doe',
      userEmail: 'john.doe@example.com',
      type: 'Wallet Recharge',
      amount: 100,
      currency: 'LYD',
      status: 'Completed',
      createdAt: DateTime(2024, 7, 1),
      description: 'Wallet recharge via bank transfer',
    ),
    AdminPayment(
      id: 'pay_002',
      userId: 'user_002',
      userName: 'Jane Smith',
      userEmail: 'jane.smith@example.com',
      type: 'Top Listing Purchase',
      amount: 20,
      currency: 'LYD',
      status: 'Completed',
      createdAt: DateTime(2024, 7, 2),
      description: '1 Day Top Listing package',
    ),
    AdminPayment(
      id: 'pay_003',
      userId: 'user_003',
      userName: 'Mike Wilson',
      userEmail: 'mike.wilson@example.com',
      type: 'Top Listing Purchase',
      amount: 100,
      currency: 'LYD',
      status: 'Completed',
      createdAt: DateTime(2024, 7, 3),
      description: '1 Week Top Listing package',
    ),
    AdminPayment(
      id: 'pay_004',
      userId: 'user_004',
      userName: 'Small User',
      userEmail: 'small@test.com',
      type: 'Wallet Recharge',
      amount: 50,
      currency: 'LYD',
      status: 'Pending',
      createdAt: DateTime(2024, 7, 4),
      description: 'Wallet recharge via credit card',
    ),
    AdminPayment(
      id: 'pay_005',
      userId: 'user_005',
      userName: 'Test User',
      userEmail: 't',
      type: 'Top Listing Purchase',
      amount: 300,
      currency: 'LYD',
      status: 'Completed',
      createdAt: DateTime(2024, 7, 5),
      description: '1 Month Top Listing package',
    ),
    AdminPayment(
      id: 'pay_006',
      userId: 'user_001',
      userName: 'John Doe',
      userEmail: 'john.doe@example.com',
      type: 'Top Listing Purchase',
      amount: 20,
      currency: 'LYD',
      status: 'Failed',
      createdAt: DateTime(2024, 7, 6),
      description: '1 Day Top Listing package - Insufficient funds',
    ),
  ];

  static final List<AdminPremiumListing> _mockPremiumListings = [
    AdminPremiumListing(
      id: 'premium_001',
      propertyId: 'prop_002',
      propertyTitle: 'Spacious Family House',
      ownerName: 'Jane Smith',
      ownerEmail: 'jane.smith@example.com',
      packageName: '1 Week',
      packagePrice: 100,
      purchaseDate: DateTime(2024, 7, 2),
      expiryDate: DateTime(2024, 7, 9),
      isActive: true,
      views: 45,
      status: 'Active',
    ),
    AdminPremiumListing(
      id: 'premium_002',
      propertyId: 'prop_001',
      propertyTitle: 'Modern Downtown Apartment',
      ownerName: 'John Doe',
      ownerEmail: 'john.doe@example.com',
      packageName: '1 Day',
      packagePrice: 20,
      purchaseDate: DateTime(2024, 7, 1),
      expiryDate: DateTime(2024, 7, 2),
      isActive: false,
      views: 12,
      status: 'Expired',
    ),
    AdminPremiumListing(
      id: 'premium_003',
      propertyId: 'prop_003',
      propertyTitle: 'Cozy Studio for Rent',
      ownerName: 'Mike Wilson',
      ownerEmail: 'mike.wilson@example.com',
      packageName: '1 Month',
      packagePrice: 300,
      purchaseDate: DateTime(2024, 7, 5),
      expiryDate: DateTime(2024, 8, 5),
      isActive: true,
      views: 28,
      status: 'Active',
    ),
    AdminPremiumListing(
      id: 'premium_004',
      propertyId: 'prop_004',
      propertyTitle: 'Luxury Villa',
      ownerName: 'Small User',
      ownerEmail: 'small@test.com',
      packageName: '1 Day',
      packagePrice: 20,
      purchaseDate: DateTime(2024, 7, 6),
      expiryDate: DateTime(2024, 7, 7),
      isActive: true,
      views: 8,
      status: 'Expiring Soon',
    ),
    AdminPremiumListing(
      id: 'premium_005',
      propertyId: 'prop_005',
      propertyTitle: 'Commercial Office Space',
      ownerName: 'Test User',
      ownerEmail: 't',
      packageName: '1 Week',
      packagePrice: 100,
      purchaseDate: DateTime(2024, 7, 3),
      expiryDate: DateTime(2024, 7, 10),
      isActive: true,
      views: 15,
      status: 'Active',
    ),
  ];

  /// Get all users for admin dashboard
  Future<List<AdminUser>> getUsers({String? token}) async {
    try {
      if (kDebugMode) {
        debugPrint('🔥 Fetching admin users from Firebase (useMockData: false)');
      }
      
      // Get users from Firebase Auth and Firestore
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();
      
      // Get all properties to count per user
      final propertiesSnapshot = await FirebaseFirestore.instance
          .collection('properties')
          .get();
      
      // Build a map of user ID -> property counts
      final Map<String, int> totalListingsMap = {};
      final Map<String, int> activeListingsMap = {};
      
      for (final propDoc in propertiesSnapshot.docs) {
        final propData = propDoc.data();
        final userId = propData['userId']?.toString() ?? '';
        if (userId.isNotEmpty) {
          totalListingsMap[userId] = (totalListingsMap[userId] ?? 0) + 1;
          
          // Check if property is active/published
          // Properties are considered active if:
          // - isPublished doesn't exist (default true) OR isPublished == true
          // - AND isActive doesn't exist (default true) OR isActive == true
          final isPublished = propData.containsKey('isPublished') ? propData['isPublished'] : true;
          final isActive = propData.containsKey('isActive') ? propData['isActive'] : true;
          
          // Only count as inactive if explicitly set to false
          if (isPublished != false && isActive != false) {
            activeListingsMap[userId] = (activeListingsMap[userId] ?? 0) + 1;
          }
        }
      }
      
      if (kDebugMode) {
        debugPrint('📊 Property counts calculated from ${propertiesSnapshot.docs.length} total properties:');
        totalListingsMap.forEach((userId, count) {
          debugPrint('   User $userId: ${activeListingsMap[userId] ?? 0}/$count properties');
        });
        // Count properties without userId
        final noUserIdCount = propertiesSnapshot.docs.where((doc) {
          final userId = doc.data()['userId']?.toString() ?? '';
          return userId.isEmpty;
        }).length;
        if (noUserIdCount > 0) {
          debugPrint('   ⚠️ $noUserIdCount properties have no userId');
        }
        // List all user IDs from users collection for comparison
        debugPrint('📋 Users in database: ${usersSnapshot.docs.map((d) => d.id).join(', ')}');
      }
      
      final List<AdminUser> users = [];
      
      for (final doc in usersSnapshot.docs) {
        try {
          final data = doc.data();
          final userId = doc.id;
          final user = AdminUser(
            id: userId,
            name: data['name']?.toString() ?? 'Unknown',
            email: data['email']?.toString() ?? '',
            phone: data['phone']?.toString() ?? 'N/A',
            joinDate: data['createdAt'] != null 
                ? (data['createdAt'] is Timestamp 
                    ? (data['createdAt'] as Timestamp).toDate() 
                    : DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now())
                : DateTime.now(),
            isVerified: data['isVerified'] ?? false,
            isActive: data['isActive'] ?? true,
            isRealEstateOffice: data['isRealEstateOffice'] ?? false,
            isAdmin: data['isAdmin'] ?? false,
            // Use actual counted values instead of stored values
            totalListings: totalListingsMap[userId] ?? 0,
            activeListings: activeListingsMap[userId] ?? 0,
            postingCredits: (data['postingCredits'] as num?)?.toInt() ?? 0,
          );
          users.add(user);
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ Error parsing user ${doc.id}: $e');
          }
        }
      }
      
      if (kDebugMode) {
        debugPrint('✅ Loaded ${users.length} users from Firestore');
        if (users.isEmpty) {
          debugPrint('⚠️ No users found in Firestore collection');
        } else {
          debugPrint('   First user: ${users.first.name} (${users.first.email})');
        }
      }
      
      return users;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ Failed to fetch admin users from Firebase: $e');
        debugPrint('   Stack trace: $stackTrace');
      }
      return [];
    }
  }

  /// Import vouchers from a list of codes
  Future<int> importVouchers({
    required int amount,
    required List<String> codes,
  }) async {
    try {
      int count = 0;
      // Process in chunks of 500 (Firestore batch limit)
      for (var i = 0; i < codes.length; i += 500) {
        final end = (i + 500 < codes.length) ? i + 500 : codes.length;
        final batch = FirebaseFirestore.instance.batch();
        final chunk = codes.sublist(i, end);
        
        for (final code in chunk) {
          final cleanCode = code.trim();
          if (cleanCode.isNotEmpty) {
            final docRef = FirebaseFirestore.instance.collection('vouchers').doc(cleanCode);
            batch.set(docRef, {
              'value': amount,
              'isUsed': false,
              'createdAt': FieldValue.serverTimestamp(),
              'importedBy': 'admin_manual',
            });
            count++;
          }
        }
        await batch.commit();
      }
      
      if (kDebugMode) {
        debugPrint('✅ Imported $count vouchers of $amount LYD');
      }
      
      return count;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to import vouchers: $e');
      }
      rethrow;
    }
  }

  /// Get all properties for admin dashboard
  Future<List<AdminProperty>> getProperties({String? token}) async {
    try {
      if (kDebugMode) {
        debugPrint('🔥 Fetching admin properties from Firebase (useMockData: false)');
      }
      
      // Get properties from Firestore
      final propertiesSnapshot = await FirebaseFirestore.instance
          .collection('properties')
          .get();
      
      final List<AdminProperty> properties = [];
      final now = DateTime.now();
      
      for (final doc in propertiesSnapshot.docs) {
        final data = doc.data();
        
        // Check if boost has expired
        bool isBoosted = data['isBoosted'] ?? false;
        if (isBoosted && data['boostExpiresAt'] != null) {
          final expiryDate = (data['boostExpiresAt'] as Timestamp).toDate();
          if (expiryDate.isBefore(now)) {
            // Boost has expired - update Firestore in background
            isBoosted = false;
            FirebaseFirestore.instance
                .collection('properties')
                .doc(doc.id)
                .update({
                  'isBoosted': false,
                  'boostExpired': true,
                }).catchError((e) {
                  if (kDebugMode) {
                    debugPrint('⚠️ Failed to update expired boost for ${doc.id}: $e');
                  }
                });
          }
        }
        
        // Calculate if property is effectively expired (60 days old)
        final createdAt = data['createdAt'] != null 
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.now();
        final isExpiredByAge = now.difference(createdAt).inDays >= 60;
        final isExpiredFlag = data['isExpired'] ?? false;
        final effectivelyExpired = isExpiredFlag || isExpiredByAge;
        
        final property = AdminProperty(
          id: doc.id,
          title: data['title'] ?? 'Untitled',
          ownerName: data['agentName'] ?? 'Unknown',
          ownerEmail: data['contactEmail'] ?? '',
          price: (data['price'] ?? 0).toDouble(),
          city: data['city'] ?? '',
          status: data['status'] == 'for_sale' ? 'For Sale' : 
                 data['status'] == 'for_rent' ? 'For Rent' : 'Unknown',
          createdAt: createdAt,
          isActive: data['isActive'] ?? true,
          views: data['views'] ?? 0,
          isBoosted: isBoosted,
          isPublished: data['isPublished'] ?? true,
          isExpired: effectivelyExpired, // Use calculated expiration
        );
        properties.add(property);
      }
      
      return properties;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to fetch admin properties from Firebase, using empty list: $e');
      }
      return [];
    }
  }

  /// Get all payments for admin dashboard
  Future<List<AdminPayment>> getPayments({String? token}) async {
    try {
      if (kDebugMode) {
        debugPrint('🔥 Fetching admin payments from Firebase (useMockData: false)');
      }
      
      // Get transactions from all user wallets
      final List<AdminPayment> payments = [];
      
      // Get all users first
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();
      
      // Process users in batches to avoid overwhelming the database
      const batchSize = 5;
      for (int i = 0; i < usersSnapshot.docs.length; i += batchSize) {
        final batch = usersSnapshot.docs.skip(i).take(batchSize);
        
        // Process batch concurrently
        final batchFutures = batch.map((userDoc) async {
          final userData = userDoc.data();
          final userId = userDoc.id;
          
          // Get wallet transactions for this user
          final walletDoc = await FirebaseFirestore.instance
              .collection('wallet')
              .doc(userId)
              .get();
          
          if (walletDoc.exists) {
            // Get transactions from subcollection
            final transactionsSnapshot = await FirebaseFirestore.instance
                .collection('wallet')
                .doc(userId)
                .collection('transactions')
                .get();
            
            return transactionsSnapshot.docs.map((transactionDoc) {
              final transactionData = transactionDoc.data();
              return AdminPayment(
                id: transactionDoc.id,
                userId: userId,
                userName: userData['name'] ?? 'Unknown',
                userEmail: userData['email'] ?? '',
                type: transactionData['type'] ?? 'Unknown',
                amount: (transactionData['amount'] ?? 0).toDouble(),
                currency: 'LYD', // Default currency
                status: 'Completed', // All transactions are completed
                createdAt: transactionData['createdAt'] != null 
                    ? (transactionData['createdAt'] as Timestamp).toDate()
                    : DateTime.now(),
                description: transactionData['description'] ?? '',
              );
            }).toList();
          }
          return <AdminPayment>[];
        });
        
        final batchResults = await Future.wait(batchFutures);
        for (final batchPayments in batchResults) {
          payments.addAll(batchPayments);
        }
      }
      
      // Sort by creation date (newest first)
      payments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      if (kDebugMode) {
        debugPrint('🔍 AdminService: Returning ${payments.length} payments');
      }
      
      return payments;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to fetch admin payments from Firebase, using empty list: $e');
      }
      return [];
    }
  }

  /// Toggle user verification status
  Future<bool> toggleUserVerification(String userId, {String? token}) async {
    try {
      if (kDebugMode) {
        debugPrint('🔥 Toggling user verification in Firebase (useMockData: false)');
      }
      
      // Get current user data
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      if (!userDoc.exists) {
        if (kDebugMode) {
          debugPrint('⚠️ User $userId not found in Firebase');
        }
        return false;
      }
      
      final currentData = userDoc.data()!;
      final currentVerification = currentData['isVerified'] ?? false;
      
      // Toggle verification status
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'isVerified': !currentVerification,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      if (kDebugMode) {
        debugPrint('✅ User $userId verification toggled to ${!currentVerification} in Firebase');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to toggle user verification in Firebase: $e');
      }
      return false;
    }
  }

  /// Toggle real estate office status
  Future<bool> toggleRealEstateOfficeStatus(String userId, {String? token}) async {
    try {
      if (kDebugMode) {
        debugPrint('🔥 Toggling real estate office status in Firebase');
      }
      
      // Get current user data
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      if (!userDoc.exists) {
        if (kDebugMode) {
          debugPrint('⚠️ User $userId not found in Firebase');
        }
        return false;
      }
      
      final currentData = userDoc.data()!;
      final currentOfficeStatus = currentData['isRealEstateOffice'] ?? false;
      final newOfficeStatus = !currentOfficeStatus;
      
      if (kDebugMode) {
        debugPrint('🔄 Toggling office status for user $userId:');
        debugPrint('   Current status: $currentOfficeStatus');
        debugPrint('   New status: $newOfficeStatus');
        debugPrint('   Field exists in Firestore: ${currentData.containsKey('isRealEstateOffice')}');
      }
      
      // Update office status - use set with merge to ensure field is created if it doesn't exist
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .set({
        'isRealEstateOffice': newOfficeStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      if (kDebugMode) {
        debugPrint('✅ User $userId real estate office status updated to $newOfficeStatus in Firebase');
        
        // Verify the update
        final verifyDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        final verifyData = verifyDoc.data();
        debugPrint('   Verification - isRealEstateOffice in Firestore: ${verifyData?['isRealEstateOffice']}');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to toggle real estate office status in Firebase: $e');
      }
      return false;
    }
  }

  /// Toggle admin status for a user
  Future<bool> toggleAdminStatus(String userId, {String? token}) async {
    try {
      if (kDebugMode) {
        debugPrint('🔥 Toggling admin status in Firebase');
      }
      
      // Get current user data
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      if (!userDoc.exists) {
        if (kDebugMode) {
          debugPrint('⚠️ User $userId not found in Firebase');
        }
        return false;
      }
      
      final currentData = userDoc.data()!;
      final currentAdminStatus = currentData['isAdmin'] ?? false;
      final newAdminStatus = !currentAdminStatus;
      
      if (kDebugMode) {
        debugPrint('🔄 Toggling admin status for user $userId:');
        debugPrint('   Current status: $currentAdminStatus');
        debugPrint('   New status: $newAdminStatus');
      }
      
      // Update admin status
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .set({
        'isAdmin': newAdminStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      if (kDebugMode) {
        debugPrint('✅ User $userId admin status updated to $newAdminStatus in Firebase');
        
        // Verify the update
        final verifyDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        final verifyData = verifyDoc.data();
        debugPrint('   Verification - isAdmin in Firestore: ${verifyData?['isAdmin']}');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to toggle admin status in Firebase: $e');
      }
      return false;
    }
  }

  /// Deactivate a property
  Future<bool> deactivateProperty(String propertyId, {String? token}) async {
    try {
      if (kDebugMode) {
        debugPrint('🔥 Deactivating property in Firebase (useMockData: false)');
      }
      
      // Deactivate the property in Firebase
      await FirebaseFirestore.instance
          .collection('properties')
          .doc(propertyId)
          .update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      if (kDebugMode) {
        debugPrint('✅ Property $propertyId deactivated in Firebase');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to deactivate property in Firebase: $e');
      }
      return false;
    }
  }

  /// Delete a property
  Future<bool> deleteProperty(String propertyId, {String? token}) async {
    try {
      if (kDebugMode) {
        debugPrint('🔥 Deleting property from Firebase (useMockData: false)');
      }
      
      // Get property first to get userId
      final doc = await FirebaseFirestore.instance.collection('properties').doc(propertyId).get();
      final userId = doc.data()?['userId'] as String?;

      // Delete from Firebase Firestore
      await FirebaseFirestore.instance
          .collection('properties')
          .doc(propertyId)
          .delete();
      
      // Decrement user's property count to free up the slot
      // COMMENTED OUT: We want burned slots behavior (deleted properties still occupy a slot)
      /*
      if (userId != null) {
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'totalListings': FieldValue.increment(-1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      */
      
      if (kDebugMode) {
        debugPrint('✅ Property $propertyId deleted successfully from Firebase');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to delete property from Firebase: $e');
      }
      return false;
    }
  }

  /// Get dashboard statistics
  Future<Map<String, int>> getDashboardStats({String? token}) async {
    try {
      if (kDebugMode) {
        debugPrint('🔥 Fetching admin dashboard stats from Firebase (useMockData: false)');
      }
      
      // Get users count
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();
      final users = usersSnapshot.docs;
      
      // Get properties count
      final propertiesSnapshot = await FirebaseFirestore.instance
          .collection('properties')
          .get();
      final properties = propertiesSnapshot.docs;
      
      // Calculate stats
      int verifiedUsers = 0;
      int activeUsers = 0;
      int activeProperties = 0;
      int boostedProperties = 0;
      num totalRevenue = 0;
      int completedPayments = 0;
      int totalPointsIssued = 0;
      
      for (final userDoc in users) {
        final userData = userDoc.data();
        if (userData['isVerified'] == true) verifiedUsers++;
        if (userData['isActive'] == true) activeUsers++;
        totalPointsIssued += (userData['postingCredits'] as num?)?.toInt() ?? 0;
      }
      
      for (final propertyDoc in properties) {
        final propertyData = propertyDoc.data();
        if (propertyData['isActive'] == true) activeProperties++;
        if (propertyData['isBoosted'] == true) boostedProperties++;
      }
      
      // Get transactions for revenue calculation
      for (final userDoc in users) {
        final userId = userDoc.id;
        final walletDoc = await FirebaseFirestore.instance
            .collection('wallet')
            .doc(userId)
            .get();
        
        if (walletDoc.exists) {
          final walletData = walletDoc.data()!;
          final transactions = walletData['transactions'] as List<dynamic>? ?? [];
          
          for (final transaction in transactions) {
            final amount = (transaction['amount'] ?? 0).toDouble();
            if (amount > 0) {
              totalRevenue += amount;
              completedPayments++;
            }
          }
        }
      }
      
      return {
        'totalUsers': users.length,
        'verifiedUsers': verifiedUsers,
        'activeUsers': activeUsers,
        'totalProperties': properties.length,
        'activeProperties': activeProperties,
        'boostedProperties': boostedProperties,
        'totalPayments': completedPayments,
        'completedPayments': completedPayments,
        'pendingPayments': 0,
        'totalRevenue': totalRevenue.toInt(),
        'totalPremiumListings': boostedProperties,
        'activePremiumListings': boostedProperties,
        'expiredPremiumListings': 0,
        'premiumRevenue': totalRevenue.toInt(),
        'totalPointsIssued': totalPointsIssued,
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to fetch admin dashboard stats from Firebase, using empty stats: $e');
      }
      return {};
    }
  }

  /// Adjust posting credits for a user (admin action)
  /// [delta] can be positive (add) or negative (deduct)
  Future<bool> adjustUserPostingCredits(String userId, int delta) async {
    try {
      // Prevent credits from going below 0 by clamping
      if (delta < 0) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
        final current = (userDoc.data()?['postingCredits'] as num?)?.toInt() ?? 0;
        if (current + delta < 0) {
          delta = -current; // Clamp to 0
        }
        if (delta == 0) return true; // Already at 0
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'postingCredits': FieldValue.increment(delta),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        debugPrint('✅ Admin adjusted postingCredits for $userId by $delta');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to adjust posting credits for $userId: $e');
      }
      return false;
    }
  }

  /// Get all premium listings for admin dashboard
  Future<List<AdminPremiumListing>> getPremiumListings({String? token, String? sortBy}) async {
    try {
      if (kDebugMode) {
        debugPrint('🔥 Fetching admin premium listings from Firebase (useMockData: false)');
      }
      
      // Get boosted properties from Firestore - include both active and recently expired
      final propertiesSnapshot = await FirebaseFirestore.instance
          .collection('properties')
          .where('isBoosted', isEqualTo: true)
          .get();
      
      // Also get recently expired boosts (properties that have boostExpiresAt but isBoosted might still be true)
      final expiredBoostsSnapshot = await FirebaseFirestore.instance
          .collection('properties')
          .where('boostExpiresAt', isGreaterThan: Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 30))))
          .get();
      
      final List<AdminPremiumListing> premiumListings = [];
      final Set<String> processedIds = {};
      final now = DateTime.now();
      
      // Process both snapshots
      final allDocs = [...propertiesSnapshot.docs, ...expiredBoostsSnapshot.docs];
      
      for (final doc in allDocs) {
        // Skip duplicates
        if (processedIds.contains(doc.id)) continue;
        processedIds.add(doc.id);
        
        final data = doc.data();
        
        // Skip if no boost data at all
        if (data['boostExpiresAt'] == null && data['isBoosted'] != true) continue;
        
        // Determine if boost is expired
        DateTime expiryDate;
        bool isExpired = false;
        
        if (data['boostExpiresAt'] != null) {
          // Handle both Timestamp and String formats
          if (data['boostExpiresAt'] is Timestamp) {
            expiryDate = (data['boostExpiresAt'] as Timestamp).toDate();
          } else if (data['boostExpiresAt'] is String) {
            expiryDate = DateTime.tryParse(data['boostExpiresAt'] as String) ?? now.add(const Duration(days: 7));
          } else {
            expiryDate = now.add(const Duration(days: 7));
          }
          isExpired = expiryDate.isBefore(now);
          
          if (kDebugMode) {
            final daysLeft = expiryDate.difference(now).inDays;
            final hoursLeft = expiryDate.difference(now).inHours;
            debugPrint('💎 Premium: ${data['title']} - Expires: $expiryDate, Days left: $daysLeft, Hours left: $hoursLeft, Expired: $isExpired');
          }
          
          // Auto-deactivate expired boosts in Firestore
          if (isExpired && data['isBoosted'] == true) {
            FirebaseFirestore.instance
                .collection('properties')
                .doc(doc.id)
                .update({
                  'isBoosted': false,
                  'boostExpired': true,
                }).catchError((e) {
                  if (kDebugMode) {
                    debugPrint('⚠️ Failed to update expired boost for ${doc.id}: $e');
                  }
                });
          }
        } else {
          expiryDate = DateTime.now().add(const Duration(days: 7));
          if (kDebugMode) {
            debugPrint('💎 Premium: ${data['title']} - No expiry date, defaulting to 7 days');
          }
        }
        
        // Get owner info
        final ownerId = data['userId'];
        String ownerName = 'Unknown';
        String ownerEmail = '';
        
        if (ownerId != null) {
          final ownerDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(ownerId)
              .get();
          if (ownerDoc.exists) {
            final ownerData = ownerDoc.data()!;
            ownerName = ownerData['name'] ?? 'Unknown';
            ownerEmail = ownerData['email'] ?? '';
          }
        }
        
        final premiumListing = AdminPremiumListing(
          id: doc.id,
          propertyId: doc.id,
          propertyTitle: data['title'] ?? 'Untitled',
          ownerName: ownerName,
          ownerEmail: ownerEmail,
          packageName: data['boostPackageName'] ?? 'Unknown Package',
          packagePrice: (data['boostPackagePrice'] ?? 0).toDouble(),
          purchaseDate: data['boostPurchasedAt'] != null 
              ? (data['boostPurchasedAt'] as Timestamp).toDate()
              : DateTime.now(),
          expiryDate: expiryDate,
          isActive: !isExpired,
          views: data['views'] ?? 0,
          status: isExpired ? 'Expired' : 'Active',
        );
        premiumListings.add(premiumListing);
      }
      
      // Sort by the specified field
      if (sortBy == 'expiryDate' || sortBy == null) {
        // Sort active listings first, then by expiry date
        premiumListings.sort((a, b) {
          if (a.isActive && !b.isActive) return -1;
          if (!a.isActive && b.isActive) return 1;
          return a.expiryDate.compareTo(b.expiryDate);
        });
      } else if (sortBy == 'purchaseDate') {
        premiumListings.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));
      } else if (sortBy == 'packageName') {
        premiumListings.sort((a, b) => a.packageName.compareTo(b.packageName));
      } else if (sortBy == 'views') {
        premiumListings.sort((a, b) => b.views.compareTo(a.views));
      }
      
      return premiumListings;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to fetch admin premium listings from Firebase, using empty list: $e');
      }
      return [];
    }
  }

  /// Extend premium listing
  Future<bool> extendPremiumListing(String premiumListingId, int daysToExtend, {String? token}) async {
    if (EnvConfig.useMockData) {
      if (kDebugMode) {
        debugPrint('🎭 Using mock data for extend premium listing (useMockData: true)');
      }
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Update mock data
      final listingIndex = _mockPremiumListings.indexWhere((listing) => listing.id == premiumListingId);
      if (listingIndex != -1) {
        final listing = _mockPremiumListings[listingIndex];
        _mockPremiumListings[listingIndex] = listing.copyWith(
          expiryDate: listing.expiryDate.add(Duration(days: daysToExtend)),
          isActive: true,
          status: 'Active',
        );
        return true;
      }
      return false;
    }

    try {
      if (kDebugMode) {
        debugPrint('🌐 Extending premium listing via API (useMockData: false)');
      }
      final response = await _apiClient.put('/admin/premium-listings/$premiumListingId/extend', 
        body: {'daysToExtend': daysToExtend}, token: token);
      return response['success'] == true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to extend premium listing via API: $e');
      }
      return false;
    }
  }

  /// Delete a user
  Future<bool> deleteUser(String userId, {String? token}) async {
    try {
      if (kDebugMode) {
        debugPrint('🔥 Deleting user from Firebase (useMockData: false)');
      }
      
      // Delete user from Firebase Authentication using REST API
      try {
        // Firebase Auth REST API endpoint for deleting a user
        const authUrl = 'https://identitytoolkit.googleapis.com/v1/accounts:delete?key=${FirebaseConfig.apiKey}';
        
        final authResponse = await http.post(
          Uri.parse(authUrl),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'localId': userId,
          }),
        );
        
        if (authResponse.statusCode == 200) {
          if (kDebugMode) {
            debugPrint('✅ User $userId deleted from Firebase Authentication');
          }
        } else {
          if (kDebugMode) {
            debugPrint('⚠️ Failed to delete user from Firebase Auth: ${authResponse.body}');
          }
          // Continue with Firestore deletion even if Auth deletion fails
        }
      } catch (authError) {
        if (kDebugMode) {
          debugPrint('⚠️ Failed to delete user from Firebase Auth (may not exist): $authError');
        }
        // Continue with Firestore deletion even if Auth deletion fails
      }
      
      // Delete user from Firebase Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .delete();
      
      // Also delete user's wallet data
      await FirebaseFirestore.instance
          .collection('wallet')
          .doc(userId)
          .delete();
      
      if (kDebugMode) {
        debugPrint('✅ User $userId deleted successfully from Firebase');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to delete user from Firebase: $e');
      }
      return false;
    }
  }

  /// Deactivate a user
  Future<bool> deactivateUser(String userId, {String? token}) async {
    try {
      if (kDebugMode) {
        debugPrint('🔥 Deactivating user in Firebase (useMockData: false)');
      }
      
      // Deactivate the user in Firebase
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      if (kDebugMode) {
        debugPrint('✅ User $userId deactivated in Firebase');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to deactivate user in Firebase: $e');
      }
      return false;
    }
  }

  /// Deactivate premium listing
  Future<bool> deactivatePremiumListing(String premiumListingId, {String? token}) async {
    try {
      if (kDebugMode) {
        debugPrint('🔥 Deactivating premium listing in Firebase (useMockData: false)');
      }
      
      // Deactivate the boosted property in Firebase
      await FirebaseFirestore.instance
          .collection('properties')
          .doc(premiumListingId)
          .update({
        'isBoosted': false,
        'boostExpiresAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      if (kDebugMode) {
        debugPrint('✅ Premium listing $premiumListingId deactivated in Firebase');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to deactivate premium listing in Firebase: $e');
      }
      return false;
    }
  }

  /// Renew a property (Admin)
  Future<bool> renewProperty(String propertyId) async {
    try {
      if (kDebugMode) debugPrint('🔥 Admin renewing property: $propertyId');
      
      await FirebaseFirestore.instance
          .collection('properties')
          .doc(propertyId)
          .update({
        'isPublished': true,
        'isExpired': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Failed to renew property as admin: $e');
      return false;
    }
  }
}
