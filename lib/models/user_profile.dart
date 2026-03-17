import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/property.dart';
import '../l10n/app_localizations.dart';

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? profileImageUrl;
  final String? coverImageUrl;
  final DateTime joinDate;
  final int totalListings;
  final int activeListings;
  final int propertyLimit; // Total property slots allowed
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isVerified;
  final bool isAdmin;
  final bool isRealEstateOffice; // Real estate office status
  final bool isGoogleUser; // Whether signed in with Google
  final DateTime? freeTierResetDate; // Last time free tier was reset
  final int postingCredits; // Replaces slot system: Credits needed to publish

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.profileImageUrl,
    this.coverImageUrl,
    required this.joinDate,
    required this.totalListings,
    required this.activeListings,
    this.propertyLimit = 3, // Default free tier: 3 properties for all users
    required this.createdAt,
    required this.updatedAt,
    this.isVerified = false,
    this.isAdmin = false,
    this.isRealEstateOffice = false,
    this.isGoogleUser = false,
    this.freeTierResetDate,
    this.postingCredits = 0,
  });

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? profileImageUrl,
    String? coverImageUrl,
    DateTime? joinDate,
    int? totalListings,
    int? activeListings,
    int? propertyLimit,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isVerified,
    bool? isAdmin,
    bool? isRealEstateOffice,
    bool? isGoogleUser,
    DateTime? freeTierResetDate,
    int? postingCredits,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      joinDate: joinDate ?? this.joinDate,
      totalListings: totalListings ?? this.totalListings,
      activeListings: activeListings ?? this.activeListings,
      propertyLimit: propertyLimit ?? this.propertyLimit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isVerified: isVerified ?? this.isVerified,
      isAdmin: isAdmin ?? this.isAdmin,
      isRealEstateOffice: isRealEstateOffice ?? this.isRealEstateOffice,
      isGoogleUser: isGoogleUser ?? this.isGoogleUser,
      freeTierResetDate: freeTierResetDate ?? this.freeTierResetDate,
      postingCredits: postingCredits ?? this.postingCredits,
    );
  }

  /// Check if user can add more properties
  bool get canAddProperty {
    // Debug logging
    if (kDebugMode) {
      debugPrint('🔍 Posting Credits Check:');
      debugPrint('   Current Credits: $postingCredits');
      debugPrint('   Can Add: ${postingCredits > 0}');
    }
    return postingCredits > 0;
  }
  
  /// Get effective property limit (Legacy - used for UI)
  int get effectivePropertyLimit => propertyLimit;
  
  /// Get remaining property slots
  int get remainingSlots => (propertyLimit - totalListings).clamp(0, propertyLimit);
  
  /// Get used property slots
  int get usedSlots => totalListings;
}

class UserListing {
  final String id;
  final String title;
  final double price;
  final String city;
  final String imageUrl;
  final DateTime createdAt;
  final bool isActive;
  final bool isPublished;
  final int views;
  final bool isBoosted;
  final String? boostPackageName;
  final DateTime? boostExpiresAt;
  final bool isExpired;
  final bool isDeleted;
  final DateTime? slotConsumedAt;

  const UserListing({
    required this.id,
    required this.title,
    required this.price,
    required this.city,
    required this.imageUrl,
    required this.createdAt,
    required this.isActive,
    this.isPublished = true,
    required this.views,
    this.isBoosted = false,
    this.boostPackageName,
    this.boostExpiresAt,
    this.isExpired = false,
    this.isDeleted = false,
    this.slotConsumedAt,
  });

  UserListing copyWith({
    String? id,
    String? title,
    double? price,
    String? city,
    String? imageUrl,
    DateTime? createdAt,
    bool? isActive,
    bool? isPublished,
    int? views,
    bool? isBoosted,
    String? boostPackageName,
    DateTime? boostExpiresAt,
    bool? isExpired,
    bool? isDeleted,
    DateTime? slotConsumedAt,
  }) {
    return UserListing(
      id: id ?? this.id,
      title: title ?? this.title,
      price: price ?? this.price,
      city: city ?? this.city,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      isPublished: isPublished ?? this.isPublished,
      views: views ?? this.views,
      isBoosted: isBoosted ?? this.isBoosted,
      boostPackageName: boostPackageName ?? this.boostPackageName,
      boostExpiresAt: boostExpiresAt ?? this.boostExpiresAt,
      isExpired: isExpired ?? this.isExpired,
      isDeleted: isDeleted ?? this.isDeleted,
      slotConsumedAt: slotConsumedAt ?? this.slotConsumedAt,
    );
  }

  bool get isEffectivelyExpired => isExpired || DateTime.now().difference(createdAt).inDays >= 60;

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

  String? getLocalizedBoostStatus(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (!isBoosted) return null;

    if (isBoostActive) {
      final remaining = boostExpiresAt!.difference(DateTime.now());
      String timeStr;
      if (remaining.inHours > 0) {
        timeStr = '${remaining.inHours}${l10n?.hoursShort ?? "h"}';
      } else {
        timeStr = '${remaining.inMinutes}${l10n?.minutesShort ?? "m"}';
      }
      return l10n?.boostedWithTime(timeStr) ?? 'Boosted ($timeStr left)';
    } else {
      return l10n?.boostExpired ?? 'Boost expired';
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
        
        // A listing is active if it's published AND is for sale/rent (not sold/rented)
        final isActiveStatus = property.status == PropertyStatus.forSale || property.status == PropertyStatus.forRent;
        final isActiveProperty = isActiveStatus && property.isPublished && !property.isDeleted;
        
        return UserListing(
          id: property.id,
          title: property.title,
          price: property.price,
          city: property.city,
          imageUrl: property.imageUrls.isNotEmpty ? property.imageUrls.first : '',
          createdAt: property.createdAt,
          isActive: isActiveProperty,
          isPublished: property.isPublished,
          views: property.views,
          isBoosted: property.isBoosted,
          boostPackageName: property.boostPackageName,
          boostExpiresAt: property.boostExpiresAt,
          isExpired: property.isExpired,
          isDeleted: property.isDeleted,
          slotConsumedAt: property.slotConsumedAt,
        );
      }).toList(); // Include deleted listings for burned slot visualization

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