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
  final int totalListings;
  final int activeListings;

  AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.joinDate,
    required this.isVerified,
    required this.isActive,
    required this.totalListings,
    required this.activeListings,
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
      totalListings: json['totalListings'],
      activeListings: json['activeListings'],
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
      'totalListings': totalListings,
      'activeListings': activeListings,
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
    int? totalListings,
    int? activeListings,
  }) {
    return AdminUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      joinDate: joinDate ?? this.joinDate,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      totalListings: totalListings ?? this.totalListings,
      activeListings: activeListings ?? this.activeListings,
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
      
      final List<AdminUser> users = [];
      
      for (final doc in usersSnapshot.docs) {
        final data = doc.data();
        final user = AdminUser(
          id: doc.id,
          name: data['name'] ?? 'Unknown',
          email: data['email'] ?? '',
          phone: data['phone'] ?? '',
          joinDate: data['createdAt'] != null 
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
          isVerified: data['isVerified'] ?? false,
          isActive: data['isActive'] ?? true,
          totalListings: data['totalListings'] ?? 0,
          activeListings: data['activeListings'] ?? 0,
        );
        users.add(user);
      }
      
      return users;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to fetch admin users from Firebase, using empty list: $e');
      }
      return [];
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
      
      for (final doc in propertiesSnapshot.docs) {
        final data = doc.data();
        final property = AdminProperty(
          id: doc.id,
          title: data['title'] ?? 'Untitled',
          ownerName: data['agentName'] ?? 'Unknown',
          ownerEmail: data['contactEmail'] ?? '',
          price: (data['price'] ?? 0).toDouble(),
          city: data['city'] ?? '',
          status: data['status'] == 'for_sale' ? 'For Sale' : 
                 data['status'] == 'for_rent' ? 'For Rent' : 'Unknown',
          createdAt: data['createdAt'] != null 
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
          isActive: data['isActive'] ?? true,
          views: data['views'] ?? 0,
          isBoosted: data['isBoosted'] ?? false,
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
      
      // Delete from Firebase Firestore
      await FirebaseFirestore.instance
          .collection('properties')
          .doc(propertyId)
          .delete();
      
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
      
      for (final userDoc in users) {
        final userData = userDoc.data();
        if (userData['isVerified'] == true) verifiedUsers++;
        if (userData['isActive'] == true) activeUsers++;
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
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to fetch admin dashboard stats from Firebase, using empty stats: $e');
      }
      return {};
    }
  }

  /// Get all premium listings for admin dashboard
  Future<List<AdminPremiumListing>> getPremiumListings({String? token, String? sortBy}) async {
    try {
      if (kDebugMode) {
        debugPrint('🔥 Fetching admin premium listings from Firebase (useMockData: false)');
      }
      
      // Get boosted properties from Firestore
      final propertiesSnapshot = await FirebaseFirestore.instance
          .collection('properties')
          .where('isBoosted', isEqualTo: true)
          .get();
      
      final List<AdminPremiumListing> premiumListings = [];
      
      for (final doc in propertiesSnapshot.docs) {
        final data = doc.data();
        
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
          expiryDate: data['boostExpiresAt'] != null 
              ? (data['boostExpiresAt'] as Timestamp).toDate()
              : DateTime.now().add(const Duration(days: 7)),
          isActive: data['isBoosted'] ?? false,
          views: data['views'] ?? 0,
          status: data['isBoosted'] == true ? 'Active' : 'Expired',
        );
        premiumListings.add(premiumListing);
      }
      
      // Sort by the specified field
      if (sortBy == 'expiryDate' || sortBy == null) {
        premiumListings.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
      } else if (sortBy == 'purchaseDate') {
        premiumListings.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));
      } else if (sortBy == 'packagePrice') {
        premiumListings.sort((a, b) => b.packagePrice.compareTo(a.packagePrice));
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
        final authUrl = 'https://identitytoolkit.googleapis.com/v1/accounts:delete?key=${FirebaseConfig.apiKey}';
        
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
}
