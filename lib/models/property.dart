import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import '../services/api_client.dart';
import '../services/property_cache_service.dart';
import '../config/env_config.dart';

enum PropertyType { apartment, house, villa, vacationHome, townhouse, studio, penthouse, commercial, land }
enum PropertyStatus { forSale, forRent, sold, rented }
enum PropertyCondition { newConstruction, excellent, good, fair, needsRenovation }

extension PropertyTypeExtension on PropertyType {
  String getLocalizedName(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return typeDisplayName;
    switch (this) {
      case PropertyType.apartment:
        return l10n.typeApartment;
      case PropertyType.house:
        return l10n.typeHouse;
      case PropertyType.villa:
        return l10n.typeVilla;
      case PropertyType.vacationHome:
        return l10n.typeVacationHome;
      case PropertyType.townhouse:
        return l10n.typeTownhouse;
      case PropertyType.studio:
        return l10n.typeStudio;
      case PropertyType.penthouse:
        return l10n.typePenthouse;
      case PropertyType.commercial:
        return l10n.typeCommercial;
      case PropertyType.land:
        return l10n.typeLand;
    }
  }

  // Deprecated: use getLocalizedName(context) instead
  String get typeDisplayName {
    switch (this) {
      case PropertyType.apartment:
        return 'Apartment';
      case PropertyType.house:
        return 'House';
      case PropertyType.villa:
        return 'Villa';
      case PropertyType.vacationHome:
        return 'Vacation Home';
      case PropertyType.townhouse:
        return 'Townhouse';
      case PropertyType.studio:
        return 'Studio';
      case PropertyType.penthouse:
        return 'Penthouse';
      case PropertyType.commercial:
        return 'Commercial';
      case PropertyType.land:
        return 'Land';
    }
  }
}

extension PropertyStatusExtension on PropertyStatus {
  String getLocalizedName(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return statusDisplayName;
    switch (this) {
      case PropertyStatus.forSale:
        return l10n.statusForSale;
      case PropertyStatus.forRent:
        return l10n.statusForRent;
      case PropertyStatus.sold:
        return l10n.statusSold;
      case PropertyStatus.rented:
        return l10n.statusRented;
    }
  }

  // Deprecated: use getLocalizedName(context) instead
  String get statusDisplayName {
    switch (this) {
      case PropertyStatus.forSale:
        return 'For Sale';
      case PropertyStatus.forRent:
        return 'For Rent';
      case PropertyStatus.sold:
        return 'Sold';
      case PropertyStatus.rented:
        return 'Rented';
    }
  }
}

extension PropertyConditionExtension on PropertyCondition {
  String getLocalizedName(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return conditionDisplayName;
    switch (this) {
      case PropertyCondition.newConstruction:
        return l10n.condNewConstruction;
      case PropertyCondition.excellent:
        return l10n.condExcellent;
      case PropertyCondition.good:
        return l10n.condGood;
      case PropertyCondition.fair:
        return l10n.condFair;
      case PropertyCondition.needsRenovation:
        return l10n.condNeedsRenovation;
    }
  }

  // Deprecated: use getLocalizedName(context) instead
  String get conditionDisplayName {
    switch (this) {
      case PropertyCondition.newConstruction:
        return 'New Construction';
      case PropertyCondition.excellent:
        return 'Excellent';
      case PropertyCondition.good:
        return 'Good';
      case PropertyCondition.fair:
        return 'Fair';
      case PropertyCondition.needsRenovation:
        return 'Needs Renovation';
    }
  }
}

class Property {
  final String id;
  final String userId; // Added userId field
  final String title;
  final String description;
  final double price;
  final int sizeSqm;
  final String city;
  final String neighborhood;
  final String address;
  final int bedrooms;
  final int bathrooms;
  final int kitchens;
  final int floors;
  final int yearBuilt;
  final PropertyType type;
  final PropertyStatus status;
  final PropertyCondition condition;
  
  // Features
  final bool hasBalcony;
  final bool hasGarden;
  final bool hasParking;
  final bool hasPool;
  final bool hasGym;
  final bool hasSecurity;
  final bool hasElevator;
  final bool hasAC;
  final bool hasHeating;
  final bool hasFurnished;
  final bool hasPetFriendly;
  final bool hasWaterWell;
  final bool hasNearbySchools;
  final bool hasNearbyHospitals;
  final bool hasNearbyShopping;
  final bool hasPublicTransport;
  
  // Additional details
  final double monthlyRent; // For rent properties
  final double dailyRent; // For daily rent properties
  final double deposit; // Security deposit
  final String contactPhone;
  final String contactEmail;
  final String agentName;
  final List<String> imageUrls;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int views;
  final int phoneClicks;
  final int whatsappClicks;
  final int saveCount;
  final bool isFeatured;
  final bool isVerified;
  final bool isBoosted;
  final String? boostPackageName;
  final double? boostPrice;
  final DateTime? boostExpiresAt;
  final bool isPublished; // Published status (visible to public)
  final bool isExpired; // Whether the 30-day listing has expired
  final bool isDeleted; // Whether the property has been deleted by user
  final DateTime? expiredAt; // When it expired
  final bool slotConsumed; // Whether this property currently occupies a listing slot
  final DateTime? slotConsumedAt; // When this property last consumed a slot

  bool get isEffectivelyExpired => isExpired || DateTime.now().difference(createdAt).inDays >= 60;

  Property({
    required this.id,
    required this.userId, // Added userId parameter
    required this.title,
    required this.description,
    required this.price,
    required this.sizeSqm,
    required this.city,
    required this.neighborhood,
    required this.address,
    required this.bedrooms,
    required this.bathrooms,
    required this.kitchens,
    required this.floors,
    required this.yearBuilt,
    required this.type,
    required this.status,
    required this.condition,
    this.hasBalcony = false,
    this.hasGarden = false,
    this.hasParking = false,
    this.hasPool = false,
    this.hasGym = false,
    this.hasSecurity = false,
    this.hasElevator = false,
    this.hasAC = false,
    this.hasHeating = false,
    this.hasFurnished = false,
    this.hasPetFriendly = false,
    this.hasWaterWell = false,
    this.hasNearbySchools = false,
    this.hasNearbyHospitals = false,
    this.hasNearbyShopping = false,
    this.hasPublicTransport = false,
    this.monthlyRent = 0.0,
    this.dailyRent = 0.0,
    this.deposit = 0.0,
    required this.contactPhone,
    required this.contactEmail,
    required this.agentName,
    this.imageUrls = const [],
    required this.createdAt,
    required this.updatedAt,
    this.views = 0,
    this.phoneClicks = 0,
    this.whatsappClicks = 0,
    this.saveCount = 0,
    this.isFeatured = false,
    this.isVerified = false,
    this.isBoosted = false,
    this.boostPackageName,
    this.boostPrice,
    this.boostExpiresAt,
    this.isPublished = true, // Default to published
    this.isExpired = false,
    this.isDeleted = false,
    this.expiredAt,
    this.slotConsumed = false,
    this.slotConsumedAt,
  });

  String get displayPrice {
    final formatter = NumberFormat('#,###');
    if (status == PropertyStatus.forRent) {
      if (dailyRent > 0) {
        return '${formatter.format(dailyRent)} LYD/day';
      } else if (monthlyRent > 0) {
        return '${formatter.format(monthlyRent)} LYD/month';
      }
    }
    return '${formatter.format(price)} LYD';
  }

  String getLocalizedPrice(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final formatter = NumberFormat('#,###');
    final currency = l10n?.currencyLYD ?? 'LYD';
    
    if (status == PropertyStatus.forRent) {
      if (dailyRent > 0) {
        return '${formatter.format(dailyRent)} $currency${l10n?.perDay ?? "/day"}';
      } else if (monthlyRent > 0) {
        return '${formatter.format(monthlyRent)} $currency${l10n?.perMonth ?? "/month"}';
      }
    }
    return '${formatter.format(price)} $currency';
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

  /// Get the boost amount in LYD based on the package name
  double? get boostAmount {
    if (!isBoosted) return null;
    
    // First try to use the stored boost price
    if (boostPrice != null) {
      return boostPrice;
    }
    
    // Fallback to package name parsing
    if (boostPackageName == null) return null;
    
    // Map package names to their LYD amounts
    final packageName = boostPackageName!.toLowerCase();
    
    if (packageName.contains('bronze')) {
      return 20.0;
    } else if (packageName.contains('emerald') || 
               packageName.contains('green') || 
               packageName.contains('50')) {
      return 50.0;
    } else if (packageName.contains('silver')) {
      return 100.0;
    } else if (packageName.contains('gold')) {
      return 300.0;
    } else if (packageName.contains('20')) {
      return 20.0;
    } else if (packageName.contains('100')) {
      return 100.0;
    } else if (packageName.contains('300')) {
      return 300.0;
    }
    
    // For "Top Listing" packages, try to determine from boostExpiresAt duration
    if (packageName.contains('top listing')) {
      if (boostExpiresAt != null) {
        final now = DateTime.now();
        final duration = boostExpiresAt!.difference(now);
        final days = duration.inDays;
        
        // Determine package based on duration
        if (days >= 25) { // 30-day package
          return 300.0;
        } else if (days >= 5) { // 7-day package
          return 100.0;
        } else { // 1-day package
          return 20.0;
        }
      }
      // If no expiration date, default to cheapest
      return 20.0;
    }
    
    // Try to extract amount from package name using regex, but exclude "Top Listing"
    if (!packageName.contains('top listing')) {
      final regex = RegExp(r'(\d+(?:\.\d+)?)');
      final match = regex.firstMatch(boostPackageName!);
      if (match != null) {
        return double.tryParse(match.group(1)!);
      }
    }
    
    return null;
  }

  Property copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    double? price,
    int? sizeSqm,
    String? city,
    String? neighborhood,
    String? address,
    int? bedrooms,
    int? bathrooms,
    int? kitchens,
    int? floors,
    int? yearBuilt,
    PropertyType? type,
    PropertyStatus? status,
    PropertyCondition? condition,
    bool? hasBalcony,
    bool? hasGarden,
    bool? hasParking,
    bool? hasPool,
    bool? hasGym,
    bool? hasSecurity,
    bool? hasElevator,
    bool? hasAC,
    bool? hasHeating,
    bool? hasFurnished,
    bool? hasPetFriendly,
    bool? hasWaterWell,
    bool? hasNearbySchools,
    bool? hasNearbyHospitals,
    bool? hasNearbyShopping,
    bool? hasPublicTransport,
    double? monthlyRent,
    double? dailyRent,
    double? deposit,
    String? contactPhone,
    String? contactEmail,
    String? agentName,
    List<String>? imageUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? views,
    int? phoneClicks,
    int? whatsappClicks,
    int? saveCount,
    bool? isFeatured,
    bool? isVerified,
    bool? isBoosted,
    String? boostPackageName,
    double? boostPrice,
    DateTime? boostExpiresAt,
    bool? isPublished,
    bool? isExpired,
    bool? isDeleted,
    DateTime? expiredAt,
    bool? slotConsumed,
    DateTime? slotConsumedAt,
  }) {
    return Property(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      sizeSqm: sizeSqm ?? this.sizeSqm,
      city: city ?? this.city,
      neighborhood: neighborhood ?? this.neighborhood,
      address: address ?? this.address,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      kitchens: kitchens ?? this.kitchens,
      floors: floors ?? this.floors,
      yearBuilt: yearBuilt ?? this.yearBuilt,
      type: type ?? this.type,
      status: status ?? this.status,
      condition: condition ?? this.condition,
      hasBalcony: hasBalcony ?? this.hasBalcony,
      hasGarden: hasGarden ?? this.hasGarden,
      hasParking: hasParking ?? this.hasParking,
      hasPool: hasPool ?? this.hasPool,
      hasGym: hasGym ?? this.hasGym,
      hasSecurity: hasSecurity ?? this.hasSecurity,
      hasElevator: hasElevator ?? this.hasElevator,
      hasAC: hasAC ?? this.hasAC,
      hasHeating: hasHeating ?? this.hasHeating,
      hasFurnished: hasFurnished ?? this.hasFurnished,
      hasPetFriendly: hasPetFriendly ?? this.hasPetFriendly,
      hasWaterWell: hasWaterWell ?? this.hasWaterWell,
      hasNearbySchools: hasNearbySchools ?? this.hasNearbySchools,
      hasNearbyHospitals: hasNearbyHospitals ?? this.hasNearbyHospitals,
      hasNearbyShopping: hasNearbyShopping ?? this.hasNearbyShopping,
      hasPublicTransport: hasPublicTransport ?? this.hasPublicTransport,
      monthlyRent: monthlyRent ?? this.monthlyRent,
      dailyRent: dailyRent ?? this.dailyRent,
      deposit: deposit ?? this.deposit,
      contactPhone: contactPhone ?? this.contactPhone,
      contactEmail: contactEmail ?? this.contactEmail,
      agentName: agentName ?? this.agentName,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      views: views ?? this.views,
      phoneClicks: phoneClicks ?? this.phoneClicks,
      whatsappClicks: whatsappClicks ?? this.whatsappClicks,
      saveCount: saveCount ?? this.saveCount,
      isFeatured: isFeatured ?? this.isFeatured,
      isVerified: isVerified ?? this.isVerified,
      isBoosted: isBoosted ?? this.isBoosted,
      boostPackageName: boostPackageName ?? this.boostPackageName,
      boostPrice: boostPrice ?? this.boostPrice,
      boostExpiresAt: boostExpiresAt ?? this.boostExpiresAt,
      isPublished: isPublished ?? this.isPublished,
      isExpired: isExpired ?? this.isExpired,
      isDeleted: isDeleted ?? this.isDeleted,
      expiredAt: expiredAt ?? this.expiredAt,
      slotConsumed: slotConsumed ?? this.slotConsumed,
      slotConsumedAt: slotConsumedAt ?? this.slotConsumedAt,
    );
  }

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id']?.toString() ?? '',
      userId: json['userId'] ?? json['user_id'] ?? '', // Added userId parsing
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      sizeSqm: json['size_sqm'] ?? json['sizeSqm'] ?? 0,
      city: json['city'] ?? '',
      neighborhood: json['neighborhood'] ?? '',
      address: json['address'] ?? '',
      bedrooms: json['bedrooms'] ?? 0,
      bathrooms: json['bathrooms'] ?? 0,
      kitchens: json['kitchens'] ?? 1,
      floors: json['floors'] ?? 1,
      yearBuilt: json['year_built'] ?? json['yearBuilt'] ?? 0,
      type: _parsePropertyType(json['type']),
      status: _parsePropertyStatus(json['status']),
      condition: _parsePropertyCondition(json['condition']),
      hasBalcony: json['has_balcony'] ?? json['hasBalcony'] ?? false,
      hasGarden: json['has_garden'] ?? json['hasGarden'] ?? false,
      hasParking: json['has_parking'] ?? json['hasParking'] ?? false,
      hasPool: json['has_pool'] ?? json['hasPool'] ?? false,
      hasGym: json['has_gym'] ?? json['hasGym'] ?? false,
      hasSecurity: json['has_security'] ?? json['hasSecurity'] ?? false,
      hasElevator: json['has_elevator'] ?? json['hasElevator'] ?? false,
      hasAC: json['has_ac'] ?? json['hasAC'] ?? false,
      hasHeating: json['has_heating'] ?? json['hasHeating'] ?? false,
      hasFurnished: json['has_furnished'] ?? json['hasFurnished'] ?? false,
      hasPetFriendly: json['has_pet_friendly'] ?? json['hasPetFriendly'] ?? false,
      hasWaterWell: json['has_water_well'] ?? json['hasWaterWell'] ?? false,
      hasNearbySchools: json['has_nearby_schools'] ?? json['hasNearbySchools'] ?? false,
      hasNearbyHospitals: json['has_nearby_hospitals'] ?? json['hasNearbyHospitals'] ?? false,
      hasNearbyShopping: json['has_nearby_shopping'] ?? json['hasNearbyShopping'] ?? false,
      hasPublicTransport: json['has_public_transport'] ?? json['hasPublicTransport'] ?? false,
      monthlyRent: (json['monthly_rent'] ?? json['monthlyRent'] ?? 0).toDouble(),
      dailyRent: (json['daily_rent'] ?? json['dailyRent'] ?? 0).toDouble(),
      deposit: (json['deposit'] ?? 0).toDouble(),
      contactPhone: json['contact_phone'] ?? json['contactPhone'] ?? '',
      contactEmail: json['contact_email'] ?? json['contactEmail'] ?? '',
      agentName: json['agent_name'] ?? json['agentName'] ?? '',
      imageUrls: (json['image_urls'] ?? json['imageUrls'] ?? []).cast<String>(),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : json['createdAt'] != null 
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'])
          : json['updatedAt'] != null 
              ? DateTime.parse(json['updatedAt'])
              : DateTime.now(),
      views: json['views'] ?? 0,
      isFeatured: json['is_featured'] ?? json['isFeatured'] ?? false,
      isVerified: json['is_verified'] ?? json['isVerified'] ?? false,
      isBoosted: json['is_boosted'] ?? json['isBoosted'] ?? false,
      boostPackageName: json['boost_package_name'] ?? json['boostPackageName'],
      boostPrice: json['boost_price'] != null 
          ? (json['boost_price'] as num).toDouble()
          : json['boostPrice'] != null 
              ? (json['boostPrice'] as num).toDouble()
              : null,
      boostExpiresAt: json['boost_expires_at'] != null
          ? DateTime.parse(json['boost_expires_at'])
          : json['boostExpiresAt'] != null
              ? DateTime.parse(json['boostExpiresAt'])
              : null,
      slotConsumed: json['slotConsumed'] ?? json['slot_consumed'] ?? false,
      slotConsumedAt: json['slotConsumedAt'] != null 
          ? DateTime.parse(json['slotConsumedAt'])
          : json['slot_consumed_at'] != null
              ? DateTime.parse(json['slot_consumed_at'])
              : null,
    );
  }

  factory Property.fromFirestore(String id, Map<String, dynamic> data) {
    // Helper to safely extract bool from nested features or root level
    bool safeBool(Map<String, dynamic> map, String key) {
      // First try nested features object
      if (map['features'] is Map) {
        final features = map['features'] as Map<String, dynamic>;
        final value = features[key];
        if (value != null && value is bool) return value;
      }
      // Then try root level
      final value = map[key];
      if (value == null) return false;
      if (value is bool) return value;
      // Handle explicit null or other types
      return false;
    }

    return Property(
      id: id,
      userId: data['userId'] ?? '', // Added userId parsing
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      sizeSqm: data['sizeSqm'] ?? 0,
      city: data['city'] ?? '',
      neighborhood: data['neighborhood'] ?? '',
      address: data['address'] ?? '',
      bedrooms: data['bedrooms'] ?? 0,
      bathrooms: data['bathrooms'] ?? 0,
      kitchens: data['kitchens'] ?? 1,
      floors: data['floors'] ?? 1,
      yearBuilt: data['yearBuilt'] ?? 0,
      type: _parsePropertyType(data['type']),
      status: _parsePropertyStatus(data['status']),
      condition: _parsePropertyCondition(data['condition']),
      hasBalcony: safeBool(data, 'hasBalcony'),
      hasGarden: safeBool(data, 'hasGarden'),
      hasParking: safeBool(data, 'hasParking'),
      hasPool: safeBool(data, 'hasPool'),
      hasGym: safeBool(data, 'hasGym'),
      hasSecurity: safeBool(data, 'hasSecurity'),
      hasElevator: safeBool(data, 'hasElevator'),
      hasAC: safeBool(data, 'hasAC'),
      hasHeating: safeBool(data, 'hasHeating'),
      hasFurnished: safeBool(data, 'hasFurnished'),
      hasPetFriendly: safeBool(data, 'hasPetFriendly'),
      hasWaterWell: safeBool(data, 'hasWaterWell'),
      hasNearbySchools: safeBool(data, 'hasNearbySchools'),
      hasNearbyHospitals: safeBool(data, 'hasNearbyHospitals'),
      hasNearbyShopping: safeBool(data, 'hasNearbyShopping'),
      hasPublicTransport: safeBool(data, 'hasPublicTransport'),
      monthlyRent: (data['monthlyRent'] ?? 0).toDouble(),
      dailyRent: (data['dailyRent'] ?? 0).toDouble(),
      deposit: (data['deposit'] ?? 0).toDouble(),
      contactPhone: data['contactPhone'] ?? '',
      contactEmail: data['contactEmail'] ?? '',
      agentName: data['agentName'] ?? '',
      imageUrls: (data['imageUrls'] ?? []).cast<String>(),
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] is Timestamp 
              ? (data['createdAt'] as Timestamp).toDate() 
              : DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] is Timestamp 
              ? (data['updatedAt'] as Timestamp).toDate() 
              : DateTime.tryParse(data['updatedAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      views: data['views'] ?? 0,
      phoneClicks: data['phone_clicks'] ?? data['phoneClicks'] ?? 0,
      whatsappClicks: data['whatsapp_clicks'] ?? data['whatsappClicks'] ?? 0,
      saveCount: data['save_count'] ?? data['saveCount'] ?? 0,
      isFeatured: data['isFeatured'] ?? false,
      isVerified: data['isVerified'] ?? false,
      // Check if boost is expired - if so, treat as not boosted
      // This ensures each property ID has independent boost status
      isBoosted: _parseBoostData(data)['isBoosted'] as bool,
      boostPackageName: _parseBoostData(data)['boostPackageName'] as String?,
      boostPrice: _parseBoostData(data)['boostPrice'] as double?,
      boostExpiresAt: _parseBoostData(data)['boostExpiresAt'] as DateTime?,
      isPublished: data['isPublished'] ?? true, // Default to true for backward compatibility
      isExpired: data['isExpired'] ?? false,
      isDeleted: data['isDeleted'] ?? false,
      expiredAt: data['expiredAt'] != null 
          ? (data['expiredAt'] is Timestamp 
              ? (data['expiredAt'] as Timestamp).toDate() 
              : DateTime.tryParse(data['expiredAt'].toString()))
          : null,
      slotConsumed: data['slotConsumed'] ?? false,
      slotConsumedAt: data['slotConsumedAt'] != null 
          ? (data['slotConsumedAt'] is Timestamp 
              ? (data['slotConsumedAt'] as Timestamp).toDate() 
              : DateTime.tryParse(data['slotConsumedAt'].toString()))
          : null,
    );
  }

  /// Parse boost data from Firestore, ensuring expired boosts are treated as inactive
  /// This prevents properties with the same name from affecting each other's boost status
  /// Each property ID has independent boost state - matching by ID, never by title
  static Map<String, dynamic> _parseBoostData(Map<String, dynamic> data) {
    final boostExpiresAt = data['boostExpiresAt'] != null
        ? (data['boostExpiresAt'] is Timestamp 
            ? (data['boostExpiresAt'] as Timestamp).toDate() 
            : DateTime.tryParse(data['boostExpiresAt'].toString()))
        : null;
    final isBoostedFlag = data['isBoosted'] ?? false;
    
    // Only consider boosted if flag is true AND boost hasn't expired
    // This ensures expired boosts don't show as active
    final isBoosted = isBoostedFlag && 
        (boostExpiresAt == null || DateTime.now().isBefore(boostExpiresAt));
    
    return {
      'isBoosted': isBoosted,
      'boostPackageName': isBoosted ? data['boostPackageName'] : null,
      'boostPrice': isBoosted && data['boostPrice'] != null
          ? (data['boostPrice'] as num).toDouble()
          : null,
      'boostExpiresAt': boostExpiresAt,
    };
  }

  static PropertyType _parsePropertyType(dynamic type) {
    if (type == null) return PropertyType.apartment;
    final typeString = type.toString().toLowerCase();
    switch (typeString) {
      case 'apartment': return PropertyType.apartment;
      case 'house': return PropertyType.house;
      case 'villa': return PropertyType.villa;
      case 'vacation_home':
      case 'vacationhome': return PropertyType.vacationHome;
      case 'townhouse': return PropertyType.townhouse;
      case 'studio': return PropertyType.studio;
      case 'penthouse': return PropertyType.penthouse;
      case 'commercial': return PropertyType.commercial;
      case 'land': return PropertyType.land;
      default: return PropertyType.apartment;
    }
  }

  static PropertyStatus _parsePropertyStatus(dynamic status) {
    if (status == null) return PropertyStatus.forSale;
    final statusString = status.toString().toLowerCase();
    switch (statusString) {
      case 'for_sale': case 'forsale': return PropertyStatus.forSale;
      case 'for_rent': case 'forrent': return PropertyStatus.forRent;
      case 'sold': return PropertyStatus.sold;
      case 'rented': return PropertyStatus.rented;
      default: return PropertyStatus.forSale;
    }
  }

  static PropertyCondition _parsePropertyCondition(dynamic condition) {
    if (condition == null) return PropertyCondition.good;
    final conditionString = condition.toString().toLowerCase();
    switch (conditionString) {
      case 'new_construction': case 'newconstruction': return PropertyCondition.newConstruction;
      case 'excellent': return PropertyCondition.excellent;
      case 'good': return PropertyCondition.good;
      case 'fair': return PropertyCondition.fair;
      case 'needs_renovation': case 'needsrenovation': return PropertyCondition.needsRenovation;
      default: return PropertyCondition.good;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId, // Added userId to JSON
      'title': title,
      'description': description,
      'price': price,
      'monthlyRent': monthlyRent,
      'dailyRent': dailyRent,
      'sizeSqm': sizeSqm,
      'city': city,
      'neighborhood': neighborhood,
      'address': address,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'kitchens': kitchens,
      'floors': floors,
      'yearBuilt': yearBuilt,
      'type': type.name,
      'status': status.name,
      'condition': condition.name,
      'deposit': deposit,
      'contactPhone': contactPhone,
      'contactEmail': contactEmail,
      'agentName': agentName,
      'imageUrls': imageUrls,
      'hasBalcony': hasBalcony,
      'hasGarden': hasGarden,
      'hasParking': hasParking,
      'hasPool': hasPool,
      'hasGym': hasGym,
      'hasSecurity': hasSecurity,
      'hasElevator': hasElevator,
      'hasAC': hasAC,
      'hasHeating': hasHeating,
      'hasFurnished': hasFurnished,
      'hasPetFriendly': hasPetFriendly,
      'hasWaterWell': hasWaterWell,
      'hasNearbySchools': hasNearbySchools,
      'hasNearbyHospitals': hasNearbyHospitals,
      'hasNearbyShopping': hasNearbyShopping,
      'hasPublicTransport': hasPublicTransport,
      'views': views,
      'phoneClicks': phoneClicks,
      'whatsappClicks': whatsappClicks,
      'saveCount': saveCount,
      'isFeatured': isFeatured,
      'isVerified': isVerified,
      'isBoosted': isBoosted,
      'boostPackageName': boostPackageName,
      'boostPrice': boostPrice,
      'isPublished': isPublished,
      'isExpired': isExpired,
      'isDeleted': isDeleted,
      'expiredAt': expiredAt?.toIso8601String(),
      'boostExpiresAt': boostExpiresAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'slotConsumed': slotConsumed,
      'slotConsumedAt': slotConsumedAt?.toIso8601String(),
    };
  }
}

class PropertyService {
  static final List<Property> _properties = [
    Property(
      id: '7',
      userId: 'user_007',
      title: 'Luxury Mediterranean Villa',
      description: 'Stunning Mediterranean villa with panoramic ocean views. Features private pool, spacious terraces, and premium finishes throughout.',
      price: 850000,
      sizeSqm: 400,
      city: 'Malibu',
      neighborhood: 'Malibu Colony',
      address: '200 Ocean Drive, Malibu, CA 90265',
      bedrooms: 5,
      bathrooms: 4,
      kitchens: 1,
      floors: 2,
      yearBuilt: 2019,
      type: PropertyType.villa,
      status: PropertyStatus.forSale,
      condition: PropertyCondition.excellent,
      hasBalcony: true,
      hasGarden: true,
      hasParking: true,
      hasPool: true,
      hasGym: true,
      hasSecurity: true,
      hasElevator: false,
      hasAC: true,
      hasHeating: true,
      hasFurnished: true,
      hasPetFriendly: true,
      hasNearbySchools: true,
      hasNearbyHospitals: true,
      hasNearbyShopping: true,
      hasPublicTransport: false,
      monthlyRent: 0.0,
      dailyRent: 0.0,
      deposit: 0.0,
      contactPhone: '+1-310-555-1234',
      contactEmail: 'agent7@dary.com',
      agentName: 'Luxury Coastal Properties',
      imageUrls: ['https://via.placeholder.com/400x300/FF6B6B/FFFFFF?text=Luxury+Villa'],
      createdAt: DateTime(2024, 3, 15),
      updatedAt: DateTime(2024, 3, 25),
      views: 156,
      isFeatured: true,
      isVerified: true,
    ),
    Property(
      id: '10',
      userId: 'user_010',
      title: 'new villa',
      description: 'Brand new modern villa with contemporary design and premium amenities.',
      price: 600000,
      sizeSqm: 350,
      city: 'Tripoli',
      neighborhood: 'Al-Andalus',
      address: '123 New Villa Street, Tripoli',
      bedrooms: 4,
      bathrooms: 3,
      kitchens: 1,
      floors: 2,
      yearBuilt: 2024,
      type: PropertyType.villa,
      status: PropertyStatus.forSale,
      condition: PropertyCondition.excellent,
      hasBalcony: true,
      hasGarden: true,
      hasParking: true,
      hasPool: true,
      hasGym: false,
      hasSecurity: true,
      hasElevator: false,
      hasAC: true,
      hasHeating: true,
      hasFurnished: false,
      hasPetFriendly: true,
      hasNearbySchools: true,
      hasNearbyHospitals: true,
      hasNearbyShopping: true,
      hasPublicTransport: true,
      monthlyRent: 0.0,
      dailyRent: 0.0,
      deposit: 0.0,
      contactPhone: '+218-21-555-0100',
      contactEmail: 'newvilla@dary.com',
      agentName: 'New Villa Properties',
      imageUrls: ['https://via.placeholder.com/400x300/10B981/FFFFFF?text=New+Villa'],
      createdAt: DateTime(2024, 12, 1),
      updatedAt: DateTime(2024, 12, 1),
      views: 25,
      isFeatured: false,
      isVerified: true,
      isBoosted: true,
      boostPackageName: 'Premium Boost - 1 Week',
      boostExpiresAt: DateTime.now().add(const Duration(days: 7)),
    ),
    Property(
      id: '8',
      userId: 'user_008',
      title: 'Modern Studio Apartment',
      description: 'Contemporary studio apartment in downtown area. Perfect for young professionals with modern amenities and city views.',
      price: 180000,
      sizeSqm: 45,
      city: 'San Francisco',
      neighborhood: 'SOMA',
      address: '300 Market Street, San Francisco, CA 94105',
      bedrooms: 0,
      bathrooms: 1,
      kitchens: 1,
      floors: 1,
      yearBuilt: 2020,
      type: PropertyType.studio,
      status: PropertyStatus.forSale,
      condition: PropertyCondition.excellent,
      hasBalcony: true,
      hasGarden: false,
      hasParking: false,
      hasPool: false,
      hasGym: true,
      hasSecurity: true,
      hasElevator: true,
      hasAC: true,
      hasHeating: true,
      hasFurnished: true,
      hasPetFriendly: false,
      hasNearbySchools: false,
      hasNearbyHospitals: true,
      hasNearbyShopping: true,
      hasPublicTransport: true,
      monthlyRent: 0.0,
      dailyRent: 0.0,
      deposit: 0.0,
      contactPhone: '+1-415-555-1234',
      contactEmail: 'agent8@dary.com',
      agentName: 'Urban Living Realty',
      imageUrls: ['https://via.placeholder.com/400x300/4ECDC4/FFFFFF?text=Modern+Studio'],
      createdAt: DateTime(2024, 3, 20),
      updatedAt: DateTime(2024, 3, 30),
      views: 89,
      isFeatured: false,
      isVerified: true,
    ),
    Property(
      id: '9',
      userId: 'user_009',
      title: 'Historic Townhouse',
      description: 'Beautiful historic townhouse with modern updates. Features original architectural details, updated kitchen, and private garden.',
      price: 420000,
      sizeSqm: 180,
      city: 'Boston',
      neighborhood: 'Beacon Hill',
      address: '101 Charles Street, Boston, MA 02114',
      bedrooms: 3,
      bathrooms: 2,
      kitchens: 1,
      floors: 3,
      yearBuilt: 1890,
      type: PropertyType.townhouse,
      status: PropertyStatus.forRent,
      condition: PropertyCondition.good,
      hasBalcony: true,
      hasGarden: true,
      hasParking: false,
      hasPool: false,
      hasGym: false,
      hasSecurity: false,
      hasElevator: false,
      hasAC: true,
      hasHeating: true,
      hasFurnished: false,
      hasPetFriendly: true,
      hasNearbySchools: true,
      hasNearbyHospitals: true,
      hasNearbyShopping: true,
      hasPublicTransport: true,
      monthlyRent: 2800.0,
      deposit: 5600.0,
      contactPhone: '+1-617-555-1234',
      contactEmail: 'agent9@dary.com',
      agentName: 'Historic Homes Co.',
      imageUrls: ['https://via.placeholder.com/400x300/95A5A6/FFFFFF?text=Historic+Townhouse'],
      createdAt: DateTime(2024, 2, 10),
      updatedAt: DateTime(2024, 3, 12),
      views: 134,
      isVerified: true,
    ),
  ];

  static List<Property> get properties => _properties;

  static void boostProperty(String propertyId, String packageName, int durationDays) {
    final index = _properties.indexWhere((property) => property.id == propertyId);
    if (index != -1) {
      final property = _properties[index];
      final boostExpiresAt = DateTime.now().add(Duration(days: durationDays));
      
      _properties[index] = Property(
        id: property.id,
        userId: property.userId, // Added userId
        title: property.title,
        description: property.description,
        price: property.price,
        sizeSqm: property.sizeSqm,
        city: property.city,
        neighborhood: property.neighborhood,
        address: property.address,
        bedrooms: property.bedrooms,
        bathrooms: property.bathrooms,
        kitchens: property.kitchens,
        floors: property.floors,
        yearBuilt: property.yearBuilt,
        type: property.type,
        status: property.status,
        condition: property.condition,
        hasBalcony: property.hasBalcony,
        hasGarden: property.hasGarden,
        hasParking: property.hasParking,
        hasPool: property.hasPool,
        hasGym: property.hasGym,
        hasSecurity: property.hasSecurity,
        hasElevator: property.hasElevator,
        hasAC: property.hasAC,
        hasHeating: property.hasHeating,
        hasFurnished: property.hasFurnished,
        hasPetFriendly: property.hasPetFriendly,
        hasWaterWell: property.hasWaterWell,
        hasNearbySchools: property.hasNearbySchools,
        hasNearbyHospitals: property.hasNearbyHospitals,
        hasNearbyShopping: property.hasNearbyShopping,
        hasPublicTransport: property.hasPublicTransport,
        monthlyRent: property.monthlyRent,
        dailyRent: property.dailyRent,
        deposit: property.deposit,
        contactPhone: property.contactPhone,
        contactEmail: property.contactEmail,
        agentName: property.agentName,
        imageUrls: property.imageUrls,
        createdAt: property.createdAt,
        updatedAt: DateTime.now(),
        views: property.views,
        isFeatured: property.isFeatured,
        isVerified: property.isVerified,
        isBoosted: true,
        boostPackageName: packageName,
        boostExpiresAt: boostExpiresAt,
      );
    }
  }

  static List<Property> getSortedProperties() {
    final sortedProperties = List<Property>.from(_properties);
    
    // Sort by priority: Boosted > Featured > Verified > Regular
    sortedProperties.sort((a, b) {
      // First priority: Active boosts
      if (a.isBoostActive && !b.isBoostActive) return -1;
      if (!a.isBoostActive && b.isBoostActive) return 1;
      
      // Second priority: Featured
      if (a.isFeatured && !b.isFeatured) return -1;
      if (!a.isFeatured && b.isFeatured) return 1;
      
      // Third priority: Verified
      if (a.isVerified && !b.isVerified) return -1;
      if (!a.isVerified && b.isVerified) return 1;
      
      // Fourth priority: Views (higher views first)
      return b.views.compareTo(a.views);
    });
    
    return sortedProperties;
  }

  // Search and filter methods
  static List<Property> searchProperties(String query) {
    if (query.isEmpty) return _properties;
    
    return _properties.where((property) {
      return property.title.toLowerCase().contains(query.toLowerCase()) ||
             property.description.toLowerCase().contains(query.toLowerCase()) ||
             property.city.toLowerCase().contains(query.toLowerCase()) ||
             property.neighborhood.toLowerCase().contains(query.toLowerCase()) ||
             property.type.typeDisplayName.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  static List<Property> filterByType(PropertyType type) {
    return _properties.where((property) => property.type == type).toList();
  }

  static List<Property> filterByStatus(PropertyStatus status) {
    return _properties.where((property) => property.status == status).toList();
  }

  static List<Property> filterByCity(String city) {
    return _properties.where((property) => property.city.toLowerCase() == city.toLowerCase()).toList();
  }

  static List<Property> filterByPriceRange(double minPrice, double maxPrice) {
    return _properties.where((property) {
      double propertyPrice = property.status == PropertyStatus.forRent ? property.monthlyRent : property.price;
      return propertyPrice >= minPrice && propertyPrice <= maxPrice;
    }).toList();
  }

  static List<Property> getFeaturedProperties() {
    return _properties.where((property) => property.isFeatured).toList();
  }

  static List<Property> getVerifiedProperties() {
    return _properties.where((property) => property.isVerified).toList();
  }

  static Future<List<Property>> fetchProperties({String? token}) async {
    final cacheService = PropertyCacheService();
    
    // Check if mock data mode is enabled
    if (EnvConfig.useMockData) {
      if (kDebugMode) {
        debugPrint('🎭 Using mock data for properties (useMockData: true)');
      }
      // Update cache with mock data for offline use
      await cacheService.updateCache(_properties);
      return _properties;
    }
    
    // Try to get cached data first
    final cachedProperties = cacheService.getCachedProperties();
    if (cachedProperties.isNotEmpty) {
      if (kDebugMode) {
        debugPrint('📦 Using cached properties: ${cachedProperties.length} items');
      }
    }
    
    try {
      // Try to fetch from API
      if (kDebugMode) {
        debugPrint('🌐 Fetching properties from API (useMockData: false)');
      }
      final response = await apiClient.get('/properties', token: token);
      
      List<Property> apiProperties = [];
      
      if (response['data'] != null && response['data'] is List) {
        final List<dynamic> propertiesData = response['data'];
        apiProperties = propertiesData.map((data) => Property.fromJson(data)).toList();
      } else if (response['properties'] != null && response['properties'] is List) {
        final List<dynamic> propertiesData = response['properties'];
        apiProperties = propertiesData.map((data) => Property.fromJson(data)).toList();
      } else {
        // If response format is unexpected, fall back to cached or mock data
        if (kDebugMode) {
          debugPrint('⚠️ Unexpected API response format, using cached data');
        }
        return cachedProperties.isNotEmpty ? cachedProperties : _properties;
      }
      
      // Update cache with fresh API data
      await cacheService.updateCache(apiProperties);
      
      if (kDebugMode) {
        debugPrint('✅ Successfully fetched ${apiProperties.length} properties from API');
      }
      
      return apiProperties;
      
    } catch (e) {
      // If API call fails, return cached data or fall back to mock data
      if (kDebugMode) {
        debugPrint('⚠️ API call failed, using cached data: $e');
      }
      
      if (cachedProperties.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('📦 Returning ${cachedProperties.length} cached properties');
        }
        return cachedProperties;
      } else {
        if (kDebugMode) {
          debugPrint('📦 No cached data available, using mock data');
        }
        // Update cache with mock data for next time
        await cacheService.updateCache(_properties);
        return _properties;
      }
    }
  }
}