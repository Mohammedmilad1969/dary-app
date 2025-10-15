import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/property_service.dart';
import '../models/property.dart';

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? profileImageUrl;
  final DateTime joinDate;
  final int totalListings;
  final int activeListings;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isVerified;
  final bool isAdmin;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.profileImageUrl,
    required this.joinDate,
    required this.totalListings,
    required this.activeListings,
    required this.createdAt,
    required this.updatedAt,
    this.isVerified = false,
    this.isAdmin = false,
  });

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? profileImageUrl,
    DateTime? joinDate,
    int? totalListings,
    int? activeListings,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isVerified,
    bool? isAdmin,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      joinDate: joinDate ?? this.joinDate,
      totalListings: totalListings ?? this.totalListings,
      activeListings: activeListings ?? this.activeListings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isVerified: isVerified ?? this.isVerified,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
}

class UserListing {
  final String id;
  final String title;
  final double price;
  final String city;
  final String imageUrl;
  final DateTime createdAt;
  final bool isActive;
  final int views;
  final bool isBoosted;
  final String? boostPackageName;
  final DateTime? boostExpiresAt;

  const UserListing({
    required this.id,
    required this.title,
    required this.price,
    required this.city,
    required this.imageUrl,
    required this.createdAt,
    required this.isActive,
    required this.views,
    this.isBoosted = false,
    this.boostPackageName,
    this.boostExpiresAt,
  });

  UserListing copyWith({
    String? id,
    String? title,
    double? price,
    String? city,
    String? imageUrl,
    DateTime? createdAt,
    bool? isActive,
    int? views,
    bool? isBoosted,
    String? boostPackageName,
    DateTime? boostExpiresAt,
  }) {
    return UserListing(
      id: id ?? this.id,
      title: title ?? this.title,
      price: price ?? this.price,
      city: city ?? this.city,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      views: views ?? this.views,
      isBoosted: isBoosted ?? this.isBoosted,
      boostPackageName: boostPackageName ?? this.boostPackageName,
      boostExpiresAt: boostExpiresAt ?? this.boostExpiresAt,
    );
  }

  bool get isBoostActive {
    if (!isBoosted || boostExpiresAt == null) return false;
    return DateTime.now().isBefore(boostExpiresAt!);
  }

  String? get boostStatusText {
    if (!isBoosted) return null;
    if (isBoostActive) {
      final remaining = boostExpiresAt!.difference(DateTime.now());
      if (remaining.inHours > 0) {
        return 'Boosted (${remaining.inHours}h left)';
      } else {
        return 'Boosted (${remaining.inMinutes}m left)';
      }
    } else {
      return 'Boost expired';
    }
  }
}

class ProfileService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Remove static mock data - we'll use real Firebase data
  static UserProfile? _currentUser;
  static List<UserListing> _userListings = [];

  static UserProfile? get currentUser => _currentUser;
  
  static List<UserListing> get userListings => _userListings;
  
  static List<UserListing> get activeListings => 
      _userListings.where((listing) => listing.isActive).toList();
  
  static List<UserListing> get allUserListings => _userListings;

  /// Load user properties from Firebase and convert to UserListing format
  static Future<void> loadUserProperties(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('properties')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      _userListings = snapshot.docs.map((doc) {
        final data = doc.data();
        final property = Property.fromFirestore(doc.id, data);
        
        return UserListing(
          id: property.id,
          title: property.title,
          price: property.price,
          city: property.city,
          imageUrl: property.imageUrls.isNotEmpty ? property.imageUrls.first : '',
          createdAt: property.createdAt,
          isActive: property.status == PropertyStatus.forSale || property.status == PropertyStatus.forRent,
          views: property.views,
          isBoosted: property.isBoosted,
          boostPackageName: property.boostPackageName,
          boostExpiresAt: property.boostExpiresAt,
        );
      }).toList();

      if (kDebugMode) {
        debugPrint('👤 ProfileService: Loaded ${_userListings.length} properties for user: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ProfileService: Error loading user properties: $e');
      }
      _userListings = [];
    }
  }

  /// Update user profile with real property counts
  static Future<UserProfile?> updateUserProfileWithCounts(UserProfile user) async {
    await loadUserProperties(user.id);
    
    final totalListings = _userListings.length;
    final activeListings = _userListings.where((l) => l.isActive).length;
    
    _currentUser = user.copyWith(
      totalListings: totalListings,
      activeListings: activeListings,
    );
    
    return _currentUser;
  }

  static void boostListing(String listingId, String packageName, int durationDays) {
    final index = _userListings.indexWhere((listing) => listing.id == listingId);
    if (index != -1) {
      final listing = _userListings[index];
      final boostExpiresAt = DateTime.now().add(Duration(days: durationDays));
      
      _userListings[index] = listing.copyWith(
        isBoosted: true,
        boostPackageName: packageName,
        boostExpiresAt: boostExpiresAt,
      );
    }
  }

  static bool canBoostListing(String listingId) {
    final listing = _userListings.firstWhere(
      (l) => l.id == listingId,
      orElse: () => UserListing(
        id: '',
        title: '',
        price: 0,
        city: '',
        imageUrl: '',
        createdAt: DateTime.now(),
        isActive: false,
        views: 0,
      ),
    );
    
    if (listing.id.isEmpty) return false;
    return !listing.isBoostActive;
  }

  static Future<UserProfile?> fetchProfile() async {
    // TODO: Implement actual API call
    await Future.delayed(const Duration(seconds: 1));
    return _currentUser;
  }

  static Future<List<UserListing>> fetchUserListings() async {
    // TODO: Implement actual API call
    await Future.delayed(const Duration(seconds: 1));
    return _userListings;
  }
}