import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/property.dart';

class PropertyCacheService {
  static final PropertyCacheService _instance = PropertyCacheService._internal();
  factory PropertyCacheService() => _instance;
  PropertyCacheService._internal();

  static const String _cacheKey = 'cached_properties';
  static const String _cacheTimestampKey = 'properties_cache_timestamp';
  static const Duration _cacheExpiry = Duration(hours: 1); // Cache expires after 1 hour

  List<Property> _cachedProperties = [];
  DateTime? _lastCacheTime;

  List<Property> get cachedProperties => List.unmodifiable(_cachedProperties);

  /// Initialize cache service and load cached data
  Future<void> initialize() async {
    await _loadCachedData();
  }

  /// Load cached properties from SharedPreferences
  Future<void> _loadCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load cached properties
      final String? cachedJson = prefs.getString(_cacheKey);
      if (cachedJson != null) {
        final List<dynamic> propertiesList = jsonDecode(cachedJson);
        _cachedProperties = propertiesList
            .map((json) => Property.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      // Load cache timestamp
      final String? timestampString = prefs.getString(_cacheTimestampKey);
      if (timestampString != null) {
        _lastCacheTime = DateTime.parse(timestampString);
      }

      if (kDebugMode) {
        debugPrint('📦 PropertyCacheService: Loaded ${_cachedProperties.length} cached properties');
        if (_lastCacheTime != null) {
          debugPrint('📦 PropertyCacheService: Cache timestamp: $_lastCacheTime');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ PropertyCacheService: Error loading cached data: $e');
      }
    }
  }

  /// Save properties to cache
  Future<void> _saveToCache(List<Property> properties) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save properties
      final String propertiesJson = jsonEncode(
        properties.map((property) => property.toJson()).toList(),
      );
      await prefs.setString(_cacheKey, propertiesJson);

      // Save timestamp
      final now = DateTime.now();
      await prefs.setString(_cacheTimestampKey, now.toIso8601String());
      
      _cachedProperties = List.from(properties);
      _lastCacheTime = now;

      if (kDebugMode) {
        debugPrint('💾 PropertyCacheService: Cached ${properties.length} properties');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ PropertyCacheService: Error saving to cache: $e');
      }
    }
  }

  /// Check if cache is valid (not expired)
  bool get isCacheValid {
    if (_lastCacheTime == null) return false;
    return DateTime.now().difference(_lastCacheTime!) < _cacheExpiry;
  }

  /// Get cached properties if available and valid
  List<Property> getCachedProperties() {
    if (_cachedProperties.isNotEmpty && isCacheValid) {
      if (kDebugMode) {
        debugPrint('📦 PropertyCacheService: Returning ${_cachedProperties.length} cached properties');
      }
      return _cachedProperties;
    }
    return [];
  }

  /// Update cache with new properties
  Future<void> updateCache(List<Property> properties) async {
    await _saveToCache(properties);
  }

  /// Clear cache
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_cacheTimestampKey);
      
      _cachedProperties.clear();
      _lastCacheTime = null;

      if (kDebugMode) {
        debugPrint('🗑️ PropertyCacheService: Cache cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ PropertyCacheService: Error clearing cache: $e');
      }
    }
  }

  /// Get cache info for debugging
  Map<String, dynamic> getCacheInfo() {
    return {
      'cachedCount': _cachedProperties.length,
      'lastCacheTime': _lastCacheTime?.toIso8601String(),
      'isValid': isCacheValid,
      'expiresIn': _lastCacheTime != null 
          ? _cacheExpiry - DateTime.now().difference(_lastCacheTime!)
          : null,
    };
  }
}
