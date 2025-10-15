import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/property.dart';
import '../services/firebase_service.dart';
import '../services/persistence_service.dart';
import 'package:provider/provider.dart';

/// Firebase-based Property Service
/// 
/// Handles property CRUD operations with Firestore and Firebase Storage.
/// Includes offline caching and real-time updates.
class PropertyService extends ChangeNotifier {
  static final PropertyService _instance = PropertyService._internal();
  factory PropertyService() => _instance;
  PropertyService._internal();

  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseFirestore _firestore = FirebaseService().firestore;

  List<Property> _properties = [];
  Map<String, Property> _localModifications = {}; // Track local modifications
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<List<Property>>? _propertiesSubscription;

  List<Property> get properties => List.unmodifiable(_properties);
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

  /// Initialize the property service
  Future<void> initialize({PersistenceService? persistenceService, String? userId}) async {
    try {
      // Get persistence service from parameter or create default
      final persistence = persistenceService ?? PersistenceService();
      
      // Load cached properties first (filter by userId if provided)
      final cachedProperties = await persistence.loadCachedProperties();
      if (cachedProperties.isNotEmpty) {
        if (userId != null) {
          _properties = cachedProperties.where((p) => p.userId == userId).toList();
        } else {
          _properties = cachedProperties;
        }
        notifyListeners();
      }

      // Start listening to Firestore changes
      _startPropertiesStream(persistence, userId: userId);
      
      if (kDebugMode) {
        debugPrint('🏠 PropertyService initialized with ${_properties.length} cached properties${userId != null ? ' for user: $userId' : ''}');
      }
    } catch (e) {
      _setErrorMessage('Failed to initialize PropertyService: $e');
      if (kDebugMode) {
        debugPrint('❌ PropertyService initialization error: $e');
      }
    }
  }

  /// Start listening to properties stream from Firestore
  void _startPropertiesStream(PersistenceService persistence, {String? userId}) {
    _propertiesSubscription?.cancel();
    
    Query query = _firestore.collection('properties');
    
    // Filter by userId if provided
    if (userId != null) {
      query = query.where('userId', isEqualTo: userId);
    }
    
    _propertiesSubscription = query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Property.fromFirestore(doc.id, data);
      }).toList();
    }).listen(
      (properties) {
        // Create a map of properties from Firestore for easy lookup
        final firestoreProperties = <String, Property>{};
        for (final property in properties) {
          firestoreProperties[property.id] = property;
        }
        
        // Merge local modifications with Firestore properties
        final mergedProperties = <Property>[];
        
        // First, add all Firestore properties with local modifications applied
        for (final property in properties) {
          if (_localModifications.containsKey(property.id)) {
            // Use local modification if it exists
            mergedProperties.add(_localModifications[property.id]!);
          } else {
            // Use Firestore property
            mergedProperties.add(property);
          }
        }
        
        // Then, add any local modifications that don't exist in Firestore yet
        for (final entry in _localModifications.entries) {
          if (!firestoreProperties.containsKey(entry.key)) {
            mergedProperties.add(entry.value);
          }
        }
        
        _properties = mergedProperties;
        persistence.cacheProperties(_properties);
        notifyListeners();
        
        if (kDebugMode) {
          debugPrint('🔄 Properties updated: ${_properties.length} properties${userId != null ? ' for user: $userId' : ''}');
        }
      },
      onError: (error) {
        _setErrorMessage('Failed to load properties: $error');
        if (kDebugMode) {
          debugPrint('❌ Properties stream error: $error');
        }
      },
    );
  }

  /// Create a new property
  Future<String?> createProperty(Property property) async {
    _setLoading(true);
    _setErrorMessage(null);

    try {
      final docRef = await _firestore.collection('properties').add({
        'userId': property.userId, // Added userId field
        'title': property.title,
        'description': property.description,
        'price': property.price,
        'monthlyRent': property.monthlyRent,
        'sizeSqm': property.sizeSqm,
        'city': property.city,
        'neighborhood': property.neighborhood,
        'address': property.address,
        'bedrooms': property.bedrooms,
        'bathrooms': property.bathrooms,
        'floors': property.floors,
        'yearBuilt': property.yearBuilt,
        'type': property.type.name,
        'status': property.status.name,
        'condition': property.condition.name,
        'deposit': property.deposit,
        'contactPhone': property.contactPhone,
        'contactEmail': property.contactEmail,
        'agentName': property.agentName,
        'imageUrls': property.imageUrls,
        'hasBalcony': property.hasBalcony,
        'hasGarden': property.hasGarden,
        'hasParking': property.hasParking,
        'hasPool': property.hasPool,
        'hasGym': property.hasGym,
        'hasSecurity': property.hasSecurity,
        'hasElevator': property.hasElevator,
        'hasAC': property.hasAC,
        'hasHeating': property.hasHeating,
        'hasFurnished': property.hasFurnished,
        'hasPetFriendly': property.hasPetFriendly,
        'hasNearbySchools': property.hasNearbySchools,
        'hasNearbyHospitals': property.hasNearbyHospitals,
        'hasNearbyShopping': property.hasNearbyShopping,
        'hasPublicTransport': property.hasPublicTransport,
        'views': property.views,
        'isFeatured': property.isFeatured,
        'isVerified': property.isVerified,
        'isBoosted': property.isBoosted,
        'boostPackageName': property.boostPackageName,
        'boostExpiresAt': property.boostExpiresAt != null 
            ? Timestamp.fromDate(property.boostExpiresAt!) 
            : null,
        'createdAt': Timestamp.fromDate(property.createdAt),
        'updatedAt': Timestamp.fromDate(property.updatedAt),
      });

      if (kDebugMode) {
        debugPrint('✅ Property created with ID: ${docRef.id}');
      }

      return docRef.id;
    } catch (e) {
      _setErrorMessage('Failed to create property: $e');
      if (kDebugMode) {
        debugPrint('❌ Error creating property: $e');
      }
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Update an existing property
  Future<bool> updateProperty(String propertyId, Property property) async {
    _setLoading(true);
    _setErrorMessage(null);

    try {
      await _firestore.collection('properties').doc(propertyId).update({
        'title': property.title,
        'description': property.description,
        'price': property.price,
        'monthlyRent': property.monthlyRent,
        'sizeSqm': property.sizeSqm,
        'city': property.city,
        'neighborhood': property.neighborhood,
        'address': property.address,
        'bedrooms': property.bedrooms,
        'bathrooms': property.bathrooms,
        'floors': property.floors,
        'yearBuilt': property.yearBuilt,
        'type': property.type.name,
        'status': property.status.name,
        'condition': property.condition.name,
        'deposit': property.deposit,
        'contactPhone': property.contactPhone,
        'contactEmail': property.contactEmail,
        'agentName': property.agentName,
        'imageUrls': property.imageUrls,
        'hasBalcony': property.hasBalcony,
        'hasGarden': property.hasGarden,
        'hasParking': property.hasParking,
        'hasPool': property.hasPool,
        'hasGym': property.hasGym,
        'hasSecurity': property.hasSecurity,
        'hasElevator': property.hasElevator,
        'hasAC': property.hasAC,
        'hasHeating': property.hasHeating,
        'hasFurnished': property.hasFurnished,
        'hasPetFriendly': property.hasPetFriendly,
        'hasNearbySchools': property.hasNearbySchools,
        'hasNearbyHospitals': property.hasNearbyHospitals,
        'hasNearbyShopping': property.hasNearbyShopping,
        'hasPublicTransport': property.hasPublicTransport,
        'views': property.views,
        'isFeatured': property.isFeatured,
        'isVerified': property.isVerified,
        'isBoosted': property.isBoosted,
        'boostPackageName': property.boostPackageName,
        'boostExpiresAt': property.boostExpiresAt != null 
            ? Timestamp.fromDate(property.boostExpiresAt!) 
            : null,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      if (kDebugMode) {
        debugPrint('✅ Property updated: $propertyId');
      }

      return true;
    } catch (e) {
      _setErrorMessage('Failed to update property: $e');
      if (kDebugMode) {
        debugPrint('❌ Error updating property: $e');
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete a property
  Future<bool> deleteProperty(String propertyId) async {
    _setLoading(true);
    _setErrorMessage(null);

    try {
      await _firestore.collection('properties').doc(propertyId).delete();

      if (kDebugMode) {
        debugPrint('✅ Property deleted: $propertyId');
      }

      return true;
    } catch (e) {
      _setErrorMessage('Failed to delete property: $e');
      if (kDebugMode) {
        debugPrint('❌ Error deleting property: $e');
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Search properties with filters
  Future<List<Property>> searchProperties({
    String? query,
    String? city,
    PropertyType? type,
    PropertyStatus? status,
    double? minPrice,
    double? maxPrice,
    int? minBedrooms,
    int? maxBedrooms,
    List<String>? features,
  }) async {
    try {
      Query queryRef = _firestore.collection('properties');

      // Apply filters
      if (city != null) {
        queryRef = queryRef.where('city', isEqualTo: city);
      }
      if (type != null) {
        queryRef = queryRef.where('type', isEqualTo: type.name);
      }
      if (status != null) {
        queryRef = queryRef.where('status', isEqualTo: status.name);
      }
      if (minPrice != null) {
        queryRef = queryRef.where('price', isGreaterThanOrEqualTo: minPrice);
      }
      if (maxPrice != null) {
        queryRef = queryRef.where('price', isLessThanOrEqualTo: maxPrice);
      }

      // Order by creation date
      queryRef = queryRef.orderBy('createdAt', descending: true);

      final snapshot = await queryRef.get();
      List<Property> properties = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Property.fromFirestore(doc.id, data);
      }).toList();

      // Apply text search filter
      if (query != null && query.isNotEmpty) {
        properties = properties.where((property) {
          return property.title.toLowerCase().contains(query.toLowerCase()) ||
                 property.description.toLowerCase().contains(query.toLowerCase()) ||
                 property.city.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }

      // Apply bedroom filter
      if (minBedrooms != null) {
        properties = properties.where((p) => p.bedrooms >= minBedrooms).toList();
      }
      if (maxBedrooms != null) {
        properties = properties.where((p) => p.bedrooms <= maxBedrooms).toList();
      }

      // Apply feature filters
      if (features != null && features.isNotEmpty) {
        for (final feature in features) {
          properties = properties.where((property) {
            switch (feature) {
              case 'hasBalcony': return property.hasBalcony;
              case 'hasGarden': return property.hasGarden;
              case 'hasParking': return property.hasParking;
              case 'hasPool': return property.hasPool;
              case 'hasGym': return property.hasGym;
              case 'hasSecurity': return property.hasSecurity;
              case 'hasElevator': return property.hasElevator;
              case 'hasAC': return property.hasAC;
              case 'hasHeating': return property.hasHeating;
              case 'hasFurnished': return property.hasFurnished;
              default: return true;
            }
          }).toList();
        }
      }

      return properties;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error searching properties: $e');
      }
      return [];
    }
  }

  /// Get properties by user ID
  Future<List<Property>> getPropertiesByUser(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('properties')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Property.fromFirestore(doc.id, data);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting user properties: $e');
      }
      return [];
    }
  }

  /// Get boosted properties
  Future<List<Property>> getBoostedProperties() async {
    try {
      final now = Timestamp.now();
      final snapshot = await _firestore
          .collection('properties')
          .where('isBoosted', isEqualTo: true)
          .where('boostExpiresAt', isGreaterThan: now)
          .orderBy('boostExpiresAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Property.fromFirestore(doc.id, data);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting boosted properties: $e');
      }
      return [];
    }
  }

  /// Increment property views
  Future<void> incrementViews(String propertyId) async {
    try {
      await _firestore.collection('properties').doc(propertyId).update({
        'views': FieldValue.increment(1),
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error incrementing views: $e');
      }
    }
  }

  /// Boost a property
  Future<bool> boostProperty(String propertyId, String packageName, int durationDays, {PersistenceService? persistenceService}) async {
    try {
      final boostExpiresAt = DateTime.now().add(Duration(days: durationDays));
      
      // Find the property to boost
      final propertyIndex = _properties.indexWhere((p) => p.id == propertyId);
      if (propertyIndex == -1) {
        if (kDebugMode) {
          debugPrint('❌ Property not found for boosting: $propertyId');
        }
        return false;
      }
      
      final property = _properties[propertyIndex];
      final boostedProperty = Property(
        id: property.id,
        userId: property.userId,
        title: property.title,
        description: property.description,
        price: property.price,
        sizeSqm: property.sizeSqm,
        city: property.city,
        neighborhood: property.neighborhood,
        address: property.address,
        bedrooms: property.bedrooms,
        bathrooms: property.bathrooms,
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
        hasNearbySchools: property.hasNearbySchools,
        hasNearbyHospitals: property.hasNearbyHospitals,
        hasNearbyShopping: property.hasNearbyShopping,
        hasPublicTransport: property.hasPublicTransport,
        monthlyRent: property.monthlyRent,
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
      
      // Store local modification
      _localModifications[propertyId] = boostedProperty;
      
      // Update the property in the list
      _properties[propertyIndex] = boostedProperty;
      
      // Update Firebase
      await _firestore.collection('properties').doc(propertyId).update({
        'isBoosted': true,
        'boostPackageName': packageName,
        'boostExpiresAt': Timestamp.fromDate(boostExpiresAt),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Cache boosted property info locally for persistence
      final persistence = persistenceService ?? PersistenceService();
      final boostedProperties = await persistence.loadBoostedProperties();
      boostedProperties[propertyId] = {
        'packageName': packageName,
        'expiresAt': boostExpiresAt.toIso8601String(),
        'boostedAt': DateTime.now().toIso8601String(),
      };
      await persistence.cacheBoostedProperties(boostedProperties);

      // Keep the local modification for a short time to ensure UI consistency
      // The stream will eventually update with the Firestore data
      notifyListeners();

      // Clear local modification after a delay to allow Firestore to propagate
      Timer(const Duration(seconds: 5), () {
        if (_localModifications.containsKey(propertyId)) {
          _localModifications.remove(propertyId);
          if (kDebugMode) {
            debugPrint('🧹 Cleared local modification for property: $propertyId');
          }
        }
      });

      if (kDebugMode) {
        debugPrint('✅ Property boosted: $propertyId until $boostExpiresAt');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error boosting property: $e');
      }
      return false;
    }
  }

  /// Dispose resources
  @override
  void dispose() {
    _propertiesSubscription?.cancel();
    super.dispose();
  }
}
