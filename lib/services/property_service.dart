import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/property.dart';
import '../services/firebase_service.dart';
import '../services/persistence_service.dart';

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
  final Map<String, Property> _localModifications = {}; // Track local modifications
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<List<Property>>? _propertiesSubscription;

  List<Property> get properties => List.unmodifiable(_properties);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setErrorMessage(String? message) {
    if (_errorMessage != message) {
      _errorMessage = message;
      notifyListeners();
    }
  }

  /// Helper method to check if two property lists are equal
  bool _arePropertiesEqual(List<Property> list1, List<Property> list2) {
    if (list1.length != list2.length) return false;
    
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id || 
          list1[i].isBoosted != list2[i].isBoosted ||
          list1[i].isFeatured != list2[i].isFeatured) {
        return false;
      }
    }
    return true;
  }

  /// Initialize the property service
  Future<void> initialize({PersistenceService? persistenceService, String? userId}) async {
    try {
      // Get persistence service from parameter or create default
      final persistence = persistenceService ?? PersistenceService();
      
      // Start listening to Firestore changes
      _startPropertiesStream(persistence, userId: userId);
    } catch (e) {
      _setErrorMessage('Failed to initialize PropertyService: $e');
      if (kDebugMode) {
        debugPrint('❌ PropertyService initialization error: $e');
      }
    }
  }
  
  /// Clean up expired boosts in Firestore
  Future<void> _cleanupExpiredBoosts() async {
    try {
      final now = Timestamp.now();
      
      // Find properties with expired boosts
      final expiredBoostsSnapshot = await _firestore
          .collection('properties')
          .where('isBoosted', isEqualTo: true)
          .where('boostExpiresAt', isLessThan: now)
          .get();
      
      if (expiredBoostsSnapshot.docs.isEmpty) return;
      
      if (kDebugMode) {
        debugPrint('🧹 Found ${expiredBoostsSnapshot.docs.length} expired boosts to clean up');
      }
      
      // Update each expired boost
      final batch = _firestore.batch();
      for (final doc in expiredBoostsSnapshot.docs) {
        batch.update(doc.reference, {
          'isBoosted': false,
          'boostExpired': true,
        });
      }
      
      await batch.commit();
      
      if (kDebugMode) {
        debugPrint('✅ Cleaned up ${expiredBoostsSnapshot.docs.length} expired boosts');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error cleaning up expired boosts: $e');
      }
    }
  }

  /// Enforces limits on user slots
  Future<void> enforceSlotLimits(String userId) async {
    // This is now a placeholder as we moved to a credit system
    // but we keep the method signature to avoid breaking references
    if (kDebugMode) {
      debugPrint('ℹ️ enforceSlotLimits called for $userId (Legacy - Credits system active)');
    }
  }

  /// Renew an expired property
  Future<bool> renewProperty(String propertyId) async {
    _setLoading(true);
    _setErrorMessage(null);

    try {
      final propertyDoc = await _firestore.collection('properties').doc(propertyId).get();
      final propertyData = propertyDoc.data();
      if (propertyData == null) return false;

      final userId = propertyData['userId'] as String?;
      if (userId == null) return false;

      // Check credit balance
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      if (userData == null) return false;

      final credits = (userData['postingCredits'] ?? 0) as int;
      if (credits <= 0) {
        _setErrorMessage('No posting credits remaining. Please buy more credits.');
        return false;
      }

      final batch = _firestore.batch();
      
      // Update property
      batch.update(_firestore.collection('properties').doc(propertyId), {
        'isPublished': true,
        'isExpired': false,
        'slotConsumed': true,
        'createdAt': FieldValue.serverTimestamp(), // Reset timer
        'updatedAt': FieldValue.serverTimestamp(),
        'slotConsumedAt': FieldValue.serverTimestamp(),
      });

      // Deduct credit
      batch.update(_firestore.collection('users').doc(userId), {
        'postingCredits': FieldValue.increment(-1),
        'totalListings': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      
      if (kDebugMode) {
        debugPrint('✅ Property renewed and credit deducted: $propertyId');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to renew property $propertyId: $e');
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Start listening to properties stream from Firestore
  void _startPropertiesStream(PersistenceService persistence, {String? userId, bool showUnpublished = false}) {
    _propertiesSubscription?.cancel();
    
    Query query = _firestore.collection('properties');
    
    // Filter by userId if provided (user's own properties - show all including unpublished)
    if (userId != null) {
      query = query.where('userId', isEqualTo: userId);
    }
    // Note: For public view, we filter by isPublished in memory since Firestore
    // doesn't allow multiple where clauses on different fields
    
    _propertiesSubscription = query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      var properties = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Property.fromFirestore(doc.id, data);
      }).toList();
      
      // Filter by isPublished, not isEffectivelyExpired, and not isDeleted for public view
      if (userId == null && !showUnpublished) {
        properties = properties.where((p) => p.isPublished && !p.isEffectivelyExpired && !p.isDeleted).toList();
      } else if (userId != null) {
        // Even for the owner, don't show deleted properties in the main list
        properties = properties.where((p) => !p.isDeleted).toList();
      }
      
      return properties;
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

      final docRef = _firestore.collection('properties').doc();
      final batch = _firestore.batch();
      
      batch.set(docRef, {
        'userId': property.userId,
        'title': property.title,
        'description': property.description,
        'price': property.price,
        'monthlyRent': property.monthlyRent,
        'dailyRent': property.dailyRent,
        'sizeSqm': property.sizeSqm,
        'city': property.city,
        'neighborhood': property.neighborhood,
        'address': property.address,
        'bedrooms': property.bedrooms,
        'bathrooms': property.bathrooms,
        'kitchens': property.kitchens,
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
        'hasWaterWell': property.hasWaterWell,
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
        'boostPrice': property.boostPrice,
        'isPublished': property.isPublished,
        'slotConsumed': property.isPublished,
        'slotConsumedAt': property.isPublished ? FieldValue.serverTimestamp() : null,
        'createdAt': Timestamp.fromDate(property.createdAt),
        'updatedAt': Timestamp.fromDate(property.updatedAt),
        'phone_clicks': 0,
        'whatsapp_clicks': 0,
        'save_count': 0,
      });

      if (property.isPublished) {
        batch.update(_firestore.collection('users').doc(property.userId), {
          'postingCredits': FieldValue.increment(-1),
          'totalListings': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      if (kDebugMode) {
        debugPrint('✅ Property created and point deducted with ID: ${docRef.id}');
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
      // Fetch current property to check if it has consumed a slot
      final currentDoc = await _firestore.collection('properties').doc(propertyId).get();
      if (!currentDoc.exists) return false;
      
      final currentData = currentDoc.data()!;
      final bool slotAlreadyConsumed = currentData['slotConsumed'] ?? false;
      
      if (slotAlreadyConsumed) {
        // Check if any identifying "Hard Fields" are being changed
        final currentType = currentData['type'] as String?;
        final currentStatus = currentData['status'] as String?;
        final currentCity = currentData['city'] as String?;
        final currentNeighborhood = currentData['neighborhood'] as String?;
        final currentSizeSqm = (currentData['sizeSqm'] ?? 0) as int;
        
        // Log changes if detected (for debugging)
        if (kDebugMode) {
          if (currentType != property.type.name) debugPrint('⚠️ Attempt to change Type: $currentType -> ${property.type.name}');
          if (currentStatus != property.status.name) debugPrint('⚠️ Attempt to change Status: $currentStatus -> ${property.status.name}');
          if (currentCity != property.city) debugPrint('⚠️ Attempt to change City: $currentCity -> ${property.city}');
          if (currentNeighborhood != property.neighborhood) debugPrint('⚠️ Attempt to change Neighborhood: $currentNeighborhood -> ${property.neighborhood}');
          if (currentSizeSqm != property.sizeSqm) debugPrint('⚠️ Attempt to change Size: $currentSizeSqm -> ${property.sizeSqm}');
        }

        // Prevent modification of these fields once a slot is consumed
        if (currentType != property.type.name ||
            currentStatus != property.status.name ||
            currentCity != property.city ||
            currentNeighborhood != property.neighborhood ||
            currentSizeSqm != property.sizeSqm) {
          
          _setErrorMessage('Cannot change property type, status, location, or size once it is listed.');
          return false;
        }
      }

      await _firestore.collection('properties').doc(propertyId).update({
        'title': property.title,
        'description': property.description,
        'price': property.price,
        'monthlyRent': property.monthlyRent,
        'dailyRent': property.dailyRent,
        'sizeSqm': property.sizeSqm,
        'city': property.city,
        'neighborhood': property.neighborhood,
        'address': property.address,
        'bedrooms': property.bedrooms,
        'bathrooms': property.bathrooms,
        'kitchens': property.kitchens,
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
        'boostPrice': property.boostPrice,
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
      // Get property first to get userId
      final propertyDoc = await _firestore.collection('properties').doc(propertyId).get();
      
      if (!propertyDoc.exists) {
        throw Exception('Property not found');
      }

      final userId = propertyDoc.data()?['userId'] as String?;
      
      // Soft delete the property instead of hard delete
      await _firestore.collection('properties').doc(propertyId).update({
        'isDeleted': true,
        'isPublished': false,
        'slotConsumed': false,
        'unpublishReason': 'deleted_by_user',
        'status': 'deleted', 
        'unpublishedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Slots are permanently burned when used, so we do not decrement totalListings here.

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

  /// Get a single property by ID
  Future<Property?> getPropertyById(String propertyId) async {
    try {
      // First check in local cache
      final cachedIndex = _properties.indexWhere((p) => p.id == propertyId);
      if (cachedIndex != -1) {
        return _properties[cachedIndex];
      }

      // Fetch from Firestore
      final propertyDoc = await _firestore.collection('properties').doc(propertyId).get();
      
      if (!propertyDoc.exists) {
        if (kDebugMode) {
          debugPrint('⚠️ Property not found: $propertyId');
        }
        return null;
      }

      final data = propertyDoc.data() as Map<String, dynamic>;
      final property = Property.fromFirestore(propertyDoc.id, data);
      
      if (kDebugMode) {
        debugPrint('✅ Property fetched: $propertyId');
      }
      
      return property;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching property: $e');
      }
      return null;
    }
  }

  /// Unpublish a property (hide it from public view and free slot)
  Future<bool> unpublishProperty(String propertyId) async {
    _setLoading(true);
    _setErrorMessage(null);

    try {
      final doc = await _firestore.collection('properties').doc(propertyId).get();
      final userId = doc.data()?['userId'] as String?;

      await _firestore.collection('properties').doc(propertyId).update({
        'isPublished': false,
        'slotConsumed': true, // Keep consumed because unpublishing doesn't refund the slot
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Slots are permanently burned; unpublishing hides the property but does not refund the slot.

      if (kDebugMode) {
        debugPrint('✅ Property unpublished (slot remains consumed): $propertyId');
      }

      return true;
    } catch (e) {
      _setErrorMessage('Failed to unpublish property: $e');
      if (kDebugMode) {
        debugPrint('❌ Error unpublishing property: $e');
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Publish a property (Deduct 1 credit)
  Future<bool> publishProperty(String propertyId) async {
    _setLoading(true);
    _setErrorMessage(null);

    try {
      final propertyDoc = await _firestore.collection('properties').doc(propertyId).get();
      final propertyData = propertyDoc.data();
      if (propertyData == null) return false;
      
      // If already published, just return success
      if (propertyData['isPublished'] == true) {
        if (kDebugMode) debugPrint('ℹ️ Property already published: $propertyId');
        return true;
      }

      final userId = propertyData['userId'] as String?;
      if (userId == null) return false;

      // Check credit balance
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      if (userData == null) return false;

      final credits = (userData['postingCredits'] ?? 0) as int;
      if (credits <= 0) {
        _setErrorMessage('No posting credits remaining. Please buy more credits.');
        return false;
      }

      final batch = _firestore.batch();
      
      // Update property
      batch.update(_firestore.collection('properties').doc(propertyId), {
        'isPublished': true,
        'slotConsumed': true,
        'updatedAt': FieldValue.serverTimestamp(),
        'slotConsumedAt': FieldValue.serverTimestamp(),
      });

      // Deduct credit
      batch.update(_firestore.collection('users').doc(userId), {
        'postingCredits': FieldValue.increment(-1),
        'totalListings': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      if (kDebugMode) {
        debugPrint('✅ Property published and credit deducted: $propertyId');
      }

      return true;
    } catch (e) {
      _setErrorMessage('Failed to publish property: $e');
      if (kDebugMode) {
        debugPrint('❌ Error publishing property: $e');
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

      // Filter out unpublished, deleted, and expired properties
      properties = properties.where((p) => 
        p.isPublished && 
        !p.isDeleted && 
        !p.isEffectivelyExpired
      ).toList();

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
        final data = doc.data();
        return Property.fromFirestore(doc.id, data);
      }).where((p) => !p.isDeleted && p.isPublished && !p.isEffectivelyExpired).toList();
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
        final data = doc.data();
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
      if (kDebugMode) {
        debugPrint('👁️ View tracked for property: $propertyId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error incrementing views: $e');
      }
    }
  }

  /// Track contact clicks for analytics
  Future<void> trackContactClick(String propertyId) async {
    try {
      // Store contact click in analytics collection
      await _firestore.collection('analytics').doc('contact_clicks').collection('clicks').add({
        'propertyId': propertyId,
        'timestamp': FieldValue.serverTimestamp(),
        'date': DateTime.now().toIso8601String().split('T')[0], // YYYY-MM-DD format
      });
      
      if (kDebugMode) {
        debugPrint('📞 Contact click tracked for property: $propertyId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error tracking contact click: $e');
      }
    }
  }

  /// Get view statistics for a property
  Future<Map<String, dynamic>> getPropertyViewStats(String propertyId) async {
    try {
      // Get the property document to get current view count
      final propertyDoc = await _firestore.collection('properties').doc(propertyId).get();
      
      if (!propertyDoc.exists) {
        return {'views': 0, 'contactClicks': 0};
      }
      
      final propertyData = propertyDoc.data()!;
      final views = (propertyData['views'] as num? ?? 0).toInt();
      
      // Get contact clicks count from analytics collection
      final contactClicksQuery = await _firestore
          .collection('analytics')
          .doc('contact_clicks')
          .collection('clicks')
          .where('propertyId', isEqualTo: propertyId)
          .get();
      
      final contactClicks = contactClicksQuery.docs.length;
      
      return {
        'views': views,
        'contactClicks': contactClicks,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting property view stats: $e');
      }
      return {'views': 0, 'contactClicks': 0, 'error': e.toString()};
    }
  }

  /// Get view statistics for all properties of a user
  Future<Map<String, dynamic>> getUserPropertyViewStats(String userId) async {
    try {
      // Get all properties for the user
      final propertiesQuery = await _firestore
          .collection('properties')
          .where('userId', isEqualTo: userId)
          .get();
      
      int totalViews = 0;
      int totalContactClicks = 0;
      List<Map<String, dynamic>> propertyStats = [];
      
      for (final doc in propertiesQuery.docs) {
        final propertyData = doc.data();
        final propertyId = doc.id;
        final views = (propertyData['views'] as num? ?? 0).toInt();
        final title = propertyData['title'] ?? 'Untitled Property';
        
        // Get contact clicks for this property
        final contactClicksQuery = await _firestore
            .collection('analytics')
            .doc('contact_clicks')
            .collection('clicks')
            .where('propertyId', isEqualTo: propertyId)
            .get();
        
        final contactClicks = contactClicksQuery.docs.length;
        
        totalViews += views;
        totalContactClicks += contactClicks;
        
        propertyStats.add({
          'propertyId': propertyId,
          'title': title,
          'views': views,
          'contactClicks': contactClicks,
        });
      }
      
      // Sort by views (highest first)
      propertyStats.sort((a, b) => (b['views'] as int).compareTo(a['views'] as int));
      
      return {
        'totalViews': totalViews,
        'totalContactClicks': totalContactClicks,
        'totalProperties': propertiesQuery.docs.length,
        'propertyStats': propertyStats,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting user property view stats: $e');
      }
      return {
        'totalViews': 0,
        'totalContactClicks': 0,
        'totalProperties': 0,
        'propertyStats': <Map<String, dynamic>>[],
        'error': e.toString(),
      };
    }
  }

  /// Boost a property
  Future<bool> boostProperty(String propertyId, String packageName, double packagePrice, int durationDays, {PersistenceService? persistenceService}) async {
    try {
      final boostExpiresAt = DateTime.now().add(Duration(days: durationDays));
      
      // Find the property to boost - check local list first
      int propertyIndex = _properties.indexWhere((p) => p.id == propertyId);
      Property? property;

      if (propertyIndex != -1) {
        property = _properties[propertyIndex];
      } else {
        // Not in local list (maybe it was filtered out because it's expired)
        // Fetch from Firestore directly
        final doc = await _firestore.collection('properties').doc(propertyId).get();
        if (doc.exists) {
          property = Property.fromFirestore(doc.id, doc.data()!);
        }
      }

      if (property == null) {
        if (kDebugMode) {
          debugPrint('❌ Property not found for boosting: $propertyId');
        }
        return false;
      }
      
      // If the property was expired or unpublished, boosting will renew it
      final now = DateTime.now();
      final boostedProperty = property.copyWith(
        isBoosted: true,
        boostPackageName: packageName,
        boostPrice: packagePrice,
        boostExpiresAt: boostExpiresAt,
        isPublished: true, // Re-publish if it was unpublished
        isExpired: false, // Reset expired flag
        createdAt: property.isEffectivelyExpired ? now : property.createdAt, // Reset timer if it was expired
        updatedAt: now,
      );
      
      // Store local modification
      _localModifications[propertyId] = boostedProperty;
      
      if (propertyIndex != -1) {
        _properties[propertyIndex] = boostedProperty;
      }
      
      // Update Firebase - CRITICAL: Always update by property ID, never by title
      Map<String, dynamic> updateData = {
        'isBoosted': true,
        'boostPackageName': packageName,
        'boostPrice': packagePrice,
        'boostExpiresAt': Timestamp.fromDate(boostExpiresAt),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // If boosting an expired/unpublished property, renew it
      if (!property.isPublished || property.isEffectivelyExpired) {
        updateData['isPublished'] = true;
        updateData['isExpired'] = false;
        updateData['createdAt'] = FieldValue.serverTimestamp();
      }

      await _firestore.collection('properties').doc(propertyId).update(updateData);
      
      if (kDebugMode) {
        debugPrint('✅ Boost updated for property ID: $propertyId (title: ${property.title})');
      }

      // Cache boosted property info locally for persistence
      // CRITICAL: Use property ID as key, never title
      final persistence = persistenceService ?? PersistenceService();
      final boostedProperties = await persistence.loadBoostedProperties();
      
      // Remove any expired boosts from cache
      _cleanExpiredBoosts(boostedProperties);
      
      // Add new boost using property ID as key
      boostedProperties[propertyId] = {
        'packageName': packageName,
        'expiresAt': boostExpiresAt.toIso8601String(),
        'boostedAt': DateTime.now().toIso8601String(),
        'propertyId': propertyId, // Store ID to ensure correct matching
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

  /// Clean expired boosts from cache
  /// This prevents expired boost data from being applied to properties
  /// Removes any boosts where expiresAt is in the past
  void _cleanExpiredBoosts(Map<String, Map<String, dynamic>> boostedProperties) {
    final now = DateTime.now();
    final expiredKeys = <String>[];
    
    for (final entry in boostedProperties.entries) {
      final boostData = entry.value;
      final expiresAtStr = boostData['expiresAt'] as String?;
      
      if (expiresAtStr != null) {
        try {
          final expiresAt = DateTime.parse(expiresAtStr);
          if (expiresAt.isBefore(now)) {
            expiredKeys.add(entry.key);
          }
        } catch (e) {
          // Invalid date format, remove it
          expiredKeys.add(entry.key);
        }
      }
    }
    
    // Remove expired entries
    for (final key in expiredKeys) {
      boostedProperties.remove(key);
    }
    
    if (kDebugMode && expiredKeys.isNotEmpty) {
      debugPrint('🧹 Cleaned ${expiredKeys.length} expired boosts from cache');
    }
  }

  /// Increment user's property count in Firestore
  Future<void> _incrementUserPropertyCount(String userId) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      await userRef.update({
        'totalListings': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        debugPrint('✅ Updated user property count for: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error incrementing user property count: $e');
      }
      // Don't throw - property creation still succeeded
    }
  }

  /// Decrement user's property count in Firestore
  Future<void> _decrementUserPropertyCount(String userId) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      await userRef.update({
        'totalListings': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        debugPrint('✅ Decremented user property count for: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error decrementing user property count: $e');
      }
      // Don't throw - property deletion still succeeded
    }
  }

  /// Get the actual number of properties for a user from Firestore
  Future<int> getUserPropertyCount(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    return (userDoc.data()?['totalListings'] ?? 0) as int;
  }

  /// Get the current property limit for a user (synced with active package status)
  Future<int> getPropertyLimit(String userId) async {
    // Proactively prune expired packages and adjust propertyLimit/totalListings
    await enforceSlotLimits(userId);
    
    final userDoc = await _firestore.collection('users').doc(userId).get();
    return (userDoc.data()?['propertyLimit'] ?? 3) as int;
  }

  /// Resets the 3 free slots for a user (costs 30 LYD)
  /// This clearing up to 3 "burned" slots from the lifetime count
  Future<bool> resetFreeTierSlots(String userId) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final userDoc = await userRef.get();
      
      if (!userDoc.exists) return false;
      
      final data = userDoc.data()!;
      final currentTotal = (data['totalListings'] ?? 0) as int;
      
      // We deduct 3 from totalListings to "unburn" the slots
      // But we don't want to go below the active listings count
      final activeSnapshot = await _firestore
          .collection('properties')
          .where('userId', isEqualTo: userId)
          .where('isPublished', isEqualTo: true)
          .get();
      final currentActiveCount = activeSnapshot.docs.length;
      
      int finalTotal = (currentTotal - 3);
      if (finalTotal < currentActiveCount) {
        finalTotal = currentActiveCount;
      }

      final now = Timestamp.now();
      await userRef.update({
        'totalListings': finalTotal,
        'freeTierResetDate': now,
        'updatedAt': now,
      });

      // RE-STAMP currently active properties for this new cycle
      // This ensures they are not "orphaned" by the anchor reset and can be republished
      for (final doc in activeSnapshot.docs) {
        await doc.reference.update({
          'slotConsumedAt': now,
          'updatedAt': now,
        });
      }

      if (kDebugMode) {
        debugPrint('♻️ Free tier slots reset for user $userId. Deducted up to 3 slots and re-stamped properties.');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error resetting free tier slots: $e');
      }
      return false;
    }
  }
}
