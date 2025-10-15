import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/property.dart';

/// Firebase Service with Offline Persistence
/// 
/// Handles Firestore persistence and offline caching.
/// Firebase Storage integration can be added when web compatibility improves.
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache keys
  static const String _propertiesCacheKey = 'cached_properties';
  static const String _propertiesTimestampKey = 'properties_timestamp';

  /// Initialize Firebase with offline persistence
  Future<void> initialize() async {
    try {
      // Enable Firestore persistence
      _firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      if (kDebugMode) {
        debugPrint('🔥 Firebase Service initialized with offline persistence');
        debugPrint('🔥 Firestore persistence enabled');
        debugPrint('🔥 Cache size: unlimited');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Firebase Service initialization error: $e');
      }
    }
  }

  /// Cache properties to SharedPreferences for offline access
  Future<void> cacheProperties(List<Property> properties) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final propertiesJson = jsonEncode(
        properties.map((p) => p.toJson()).toList(),
      );
      
      await prefs.setString(_propertiesCacheKey, propertiesJson);
      await prefs.setString(_propertiesTimestampKey, DateTime.now().toIso8601String());
      
      if (kDebugMode) {
        debugPrint('💾 Cached ${properties.length} properties for offline access');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error caching properties: $e');
      }
    }
  }

  /// Load cached properties from SharedPreferences
  Future<List<Property>> loadCachedProperties() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_propertiesCacheKey);
      final timestampString = prefs.getString(_propertiesTimestampKey);
      
      if (cachedJson != null && timestampString != null) {
        final timestamp = DateTime.parse(timestampString);
        final cacheAge = DateTime.now().difference(timestamp);
        
        // Use cache if it's less than 1 hour old
        if (cacheAge.inHours < 1) {
          final List<dynamic> jsonList = jsonDecode(cachedJson);
          final properties = jsonList.map((json) => 
            Property.fromJson(json as Map<String, dynamic>)
          ).toList();
          
          if (kDebugMode) {
            debugPrint('📦 Loaded ${properties.length} cached properties (age: ${cacheAge.inMinutes}m)');
          }
          
          return properties;
        }
      }
      
      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error loading cached properties: $e');
      }
      return [];
    }
  }

  /// Get Firestore instance
  FirebaseFirestore get firestore => _firestore;

  /// Clear all cached data
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_propertiesCacheKey);
      await prefs.remove(_propertiesTimestampKey);
      
      if (kDebugMode) {
        debugPrint('🧹 Cache cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error clearing cache: $e');
      }
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_propertiesCacheKey);
      final timestampString = prefs.getString(_propertiesTimestampKey);
      
      if (cachedJson != null && timestampString != null) {
        final timestamp = DateTime.parse(timestampString);
        final cacheAge = DateTime.now().difference(timestamp);
        final propertiesCount = (jsonDecode(cachedJson) as List).length;
        
        return {
          'propertiesCount': propertiesCount,
          'cacheAge': cacheAge.inMinutes,
          'cacheSize': cachedJson.length,
          'lastUpdated': timestamp.toIso8601String(),
        };
      }
      
      return {
        'propertiesCount': 0,
        'cacheAge': 0,
        'cacheSize': 0,
        'lastUpdated': null,
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting cache stats: $e');
      }
      return {};
    }
  }
}
