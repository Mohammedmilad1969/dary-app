import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import '../models/property.dart';
import '../models/wallet.dart' as wallet_models;
import '../models/premium_package.dart';
import '../models/saved_search.dart';

/// Comprehensive Persistence Service
/// 
/// Handles all data persistence using Firebase Firestore with local caching
/// for offline support and web compatibility
class PersistenceService {
  static final PersistenceService _instance = PersistenceService._internal();
  factory PersistenceService() => _instance;
  PersistenceService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Storage keys
  static const String _propertiesKey = 'cached_properties';
  static const String _propertiesTimestampKey = 'properties_timestamp';
  static const String _boostedPropertiesKey = 'boosted_properties';
  static const String _walletBalanceKey = 'wallet_balance';
  static const String _walletTransactionsKey = 'wallet_transactions';
  static const String _savedSearchesKey = 'saved_searches';
  static const String _userPreferencesKey = 'user_preferences';
  static const String _appSettingsKey = 'app_settings';

  /// Cache properties locally and in Firebase
  Future<void> cacheProperties(List<Property> properties) async {
    try {
      // Store in Firebase Firestore
      final batch = _firestore.batch();
      
      for (final property in properties) {
        final docRef = _firestore.collection('cached_properties').doc(property.id);
        batch.set(docRef, {
          'property': property.toJson(),
          'cachedAt': Timestamp.now(),
          'lastUpdated': Timestamp.now(),
        });
      }
      
      await batch.commit();

      // Also cache locally for offline access
      final prefs = await SharedPreferences.getInstance();
      final String propertiesJson = jsonEncode(properties.map((p) => p.toJson()).toList());
      await prefs.setString(_propertiesKey, propertiesJson);
      await prefs.setString(_propertiesTimestampKey, DateTime.now().toIso8601String());

      if (kDebugMode) {
        debugPrint('📦 PersistenceService: Cached ${properties.length} properties to Firebase and locally');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ PersistenceService: Error caching properties: $e');
      }
    }
  }

  /// Load cached properties from Firebase first, then local fallback
  Future<List<Property>> loadCachedProperties() async {
    try {
      // Try to load from Firebase first
      final snapshot = await _firestore
          .collection('cached_properties')
          .orderBy('cachedAt', descending: true)
          .limit(100) // Limit to prevent large queries
          .get();

      if (snapshot.docs.isNotEmpty) {
        final properties = snapshot.docs.map((doc) {
          final data = doc.data();
          return Property.fromJson(data['property']);
        }).toList();

        if (kDebugMode) {
          debugPrint('📦 PersistenceService: Loaded ${properties.length} properties from Firebase');
        }
        return properties;
      }

      // Fallback to local cache
      final prefs = await SharedPreferences.getInstance();
      final String? propertiesJson = prefs.getString(_propertiesKey);

      if (propertiesJson != null) {
        final List<dynamic> propertiesData = jsonDecode(propertiesJson);
        final List<Property> cachedProperties = propertiesData.map((data) => Property.fromJson(data)).toList();
        
        if (kDebugMode) {
          debugPrint('📦 PersistenceService: Loaded ${cachedProperties.length} properties from local cache');
        }
        return cachedProperties;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ PersistenceService: Error loading cached properties: $e');
      }
    }
    return [];
  }

  /// Cache boosted properties in Firebase and locally
  Future<void> cacheBoostedProperties(Map<String, Map<String, dynamic>> boostedProperties) async {
    try {
      // Store in Firebase Firestore
      final batch = _firestore.batch();
      
      for (final entry in boostedProperties.entries) {
        final docRef = _firestore.collection('boosted_properties').doc(entry.key);
        batch.set(docRef, {
          'propertyId': entry.key,
          'boostData': entry.value,
          'cachedAt': Timestamp.now(),
          'lastUpdated': Timestamp.now(),
        });
      }
      
      await batch.commit();

      // Also cache locally for offline access
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_boostedPropertiesKey, jsonEncode(boostedProperties));

      if (kDebugMode) {
        debugPrint('🚀 PersistenceService: Cached ${boostedProperties.length} boosted properties to Firebase and locally');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ PersistenceService: Error caching boosted properties: $e');
      }
    }
  }

  /// Load cached boosted properties from Firebase first, then local fallback
  Future<Map<String, Map<String, dynamic>>> loadBoostedProperties() async {
    try {
      // Try to load from Firebase first
      final snapshot = await _firestore
          .collection('boosted_properties')
          .get();

      if (snapshot.docs.isNotEmpty) {
        final Map<String, Map<String, dynamic>> boostedProperties = {};
        
        for (final doc in snapshot.docs) {
          final data = doc.data();
          boostedProperties[data['propertyId']] = Map<String, dynamic>.from(data['boostData']);
        }

        if (kDebugMode) {
          debugPrint('🚀 PersistenceService: Loaded ${boostedProperties.length} boosted properties from Firebase');
        }
        return boostedProperties;
      }

      // Fallback to local cache
      final prefs = await SharedPreferences.getInstance();
      final String? boostedJson = prefs.getString(_boostedPropertiesKey);

      if (boostedJson != null) {
        final Map<String, dynamic> boostedData = jsonDecode(boostedJson);
        final Map<String, Map<String, dynamic>> boostedProperties = {};
        
        boostedData.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            boostedProperties[key] = value;
          }
        });

        if (kDebugMode) {
          debugPrint('🚀 PersistenceService: Loaded ${boostedProperties.length} boosted properties from local cache');
        }
        return boostedProperties;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ PersistenceService: Error loading boosted properties: $e');
      }
    }
    return {};
  }

  /// Cache wallet balance in Firebase and locally
  Future<void> cacheWalletBalance(String userId, double balance) async {
    try {
      // Store in Firebase Firestore
      await _firestore.collection('user_wallet_cache').doc(userId).set({
        'userId': userId,
        'balance': balance,
        'cachedAt': Timestamp.now(),
        'lastUpdated': Timestamp.now(),
      }, SetOptions(merge: true));

      // Also cache locally for offline access
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('${_walletBalanceKey}_$userId', balance);

      if (kDebugMode) {
        debugPrint('💰 PersistenceService: Cached wallet balance for user $userId: $balance LYD to Firebase and locally');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ PersistenceService: Error caching wallet balance: $e');
      }
    }
  }

  /// Load cached wallet balance from Firebase first, then local fallback
  Future<double> loadWalletBalance(String userId) async {
    try {
      // Try to load from Firebase first
      final doc = await _firestore.collection('user_wallet_cache').doc(userId).get();
      
      if (doc.exists) {
        final data = doc.data()!;
        final balance = (data['balance'] ?? 0.0).toDouble();

        if (kDebugMode) {
          debugPrint('💰 PersistenceService: Loaded wallet balance for user $userId: $balance LYD from Firebase');
        }
        return balance;
      }

      // Fallback to local cache
      final prefs = await SharedPreferences.getInstance();
      final balance = prefs.getDouble('${_walletBalanceKey}_$userId') ?? 0.0;

      if (kDebugMode) {
        debugPrint('💰 PersistenceService: Loaded wallet balance for user $userId: $balance LYD from local cache');
      }
      return balance;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ PersistenceService: Error loading wallet balance: $e');
      }
      return 0.0;
    }
  }

  /// Cache wallet transactions in Firebase and locally
  Future<void> cacheWalletTransactions(String userId, List<wallet_models.Transaction> transactions) async {
    try {
      // Store in Firebase Firestore
      final batch = _firestore.batch();
      
      for (final transaction in transactions) {
        final docRef = _firestore
            .collection('user_wallet_cache')
            .doc(userId)
            .collection('cached_transactions')
            .doc(transaction.id);
        batch.set(docRef, {
          'transaction': transaction.toJson(),
          'cachedAt': Timestamp.now(),
          'lastUpdated': Timestamp.now(),
        });
      }
      
      await batch.commit();

      // Also cache locally for offline access
      final prefs = await SharedPreferences.getInstance();
      final String transactionsJson = jsonEncode(transactions.map((t) => t.toJson()).toList());
      await prefs.setString('${_walletTransactionsKey}_$userId', transactionsJson);

      if (kDebugMode) {
        debugPrint('📊 PersistenceService: Cached ${transactions.length} transactions for user $userId to Firebase and locally');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ PersistenceService: Error caching transactions: $e');
      }
    }
  }

  /// Load cached wallet transactions from Firebase first, then local fallback
  Future<List<wallet_models.Transaction>> loadWalletTransactions(String userId) async {
    try {
      // Try to load from Firebase first
      final snapshot = await _firestore
          .collection('user_wallet_cache')
          .doc(userId)
          .collection('cached_transactions')
          .orderBy('cachedAt', descending: true)
          .limit(50) // Limit to prevent large queries
          .get();

      if (snapshot.docs.isNotEmpty) {
        final transactions = snapshot.docs.map((doc) {
          final data = doc.data();
          return wallet_models.Transaction.fromJson(data['transaction']);
        }).toList();

        if (kDebugMode) {
          debugPrint('📊 PersistenceService: Loaded ${transactions.length} transactions for user $userId from Firebase');
        }
        return transactions;
      }

      // Fallback to local cache
      final prefs = await SharedPreferences.getInstance();
      final String? transactionsJson = prefs.getString('${_walletTransactionsKey}_$userId');

      if (transactionsJson != null) {
        final List<dynamic> transactionsData = jsonDecode(transactionsJson);
        final List<wallet_models.Transaction> transactions = transactionsData.map((data) => wallet_models.Transaction.fromJson(data)).toList();

        if (kDebugMode) {
          debugPrint('📊 PersistenceService: Loaded ${transactions.length} transactions for user $userId from local cache');
        }
        return transactions;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ PersistenceService: Error loading transactions: $e');
      }
    }
    return [];
  }

  /// Cache saved searches in Firebase and locally
  Future<void> cacheSavedSearches(String userId, List<SavedSearch> searches) async {
    try {
      // Store in Firebase Firestore
      final batch = _firestore.batch();
      
      for (final search in searches) {
        final docRef = _firestore
            .collection('user_saved_searches')
            .doc(userId)
            .collection('searches')
            .doc(search.id);
        batch.set(docRef, {
          'search': search.toJson(),
          'cachedAt': Timestamp.now(),
          'lastUpdated': Timestamp.now(),
        });
      }
      
      await batch.commit();

      // Also cache locally for offline access
      final prefs = await SharedPreferences.getInstance();
      final String searchesJson = jsonEncode(searches.map((s) => s.toJson()).toList());
      await prefs.setString('${_savedSearchesKey}_$userId', searchesJson);

      if (kDebugMode) {
        debugPrint('🔍 PersistenceService: Cached ${searches.length} saved searches for user $userId to Firebase and locally');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ PersistenceService: Error caching saved searches: $e');
      }
    }
  }

  /// Load cached saved searches from Firebase first, then local fallback
  Future<List<SavedSearch>> loadSavedSearches(String userId) async {
    try {
      // Try to load from Firebase first
      final snapshot = await _firestore
          .collection('user_saved_searches')
          .doc(userId)
          .collection('searches')
          .orderBy('cachedAt', descending: true)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final searches = snapshot.docs.map((doc) {
          final data = doc.data();
          return SavedSearch.fromJson(data['search']);
        }).toList();

        if (kDebugMode) {
          debugPrint('🔍 PersistenceService: Loaded ${searches.length} saved searches for user $userId from Firebase');
        }
        return searches;
      }

      // Fallback to local cache
      final prefs = await SharedPreferences.getInstance();
      final String? searchesJson = prefs.getString('${_savedSearchesKey}_$userId');

      if (searchesJson != null) {
        final List<dynamic> searchesData = jsonDecode(searchesJson);
        final List<SavedSearch> searches = searchesData.map((data) => SavedSearch.fromJson(data)).toList();

        if (kDebugMode) {
          debugPrint('🔍 PersistenceService: Loaded ${searches.length} saved searches for user $userId from local cache');
        }
        return searches;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ PersistenceService: Error loading saved searches: $e');
      }
    }
    return [];
  }

  /// Cache user preferences in Firebase and locally
  Future<void> cacheUserPreferences(String userId, Map<String, dynamic> preferences) async {
    try {
      // Store in Firebase Firestore
      await _firestore.collection('user_preferences').doc(userId).set({
        'userId': userId,
        'preferences': preferences,
        'cachedAt': Timestamp.now(),
        'lastUpdated': Timestamp.now(),
      }, SetOptions(merge: true));

      // Also cache locally for offline access
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('${_userPreferencesKey}_$userId', jsonEncode(preferences));

      if (kDebugMode) {
        debugPrint('⚙️ PersistenceService: Cached user preferences for user $userId to Firebase and locally');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ PersistenceService: Error caching user preferences: $e');
      }
    }
  }

  /// Load cached user preferences from Firebase first, then local fallback
  Future<Map<String, dynamic>> loadUserPreferences(String userId) async {
    try {
      // Try to load from Firebase first
      final doc = await _firestore.collection('user_preferences').doc(userId).get();
      
      if (doc.exists) {
        final data = doc.data()!;
        final preferences = Map<String, dynamic>.from(data['preferences'] ?? {});

        if (kDebugMode) {
          debugPrint('⚙️ PersistenceService: Loaded user preferences for user $userId from Firebase');
        }
        return preferences;
      }

      // Fallback to local cache
      final prefs = await SharedPreferences.getInstance();
      final String? preferencesJson = prefs.getString('${_userPreferencesKey}_$userId');

      if (preferencesJson != null) {
        final Map<String, dynamic> preferences = jsonDecode(preferencesJson);

        if (kDebugMode) {
          debugPrint('⚙️ PersistenceService: Loaded user preferences for user $userId from local cache');
        }
        return preferences;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ PersistenceService: Error loading user preferences: $e');
      }
    }
    return {};
  }

  /// Cache app settings
  Future<void> cacheAppSettings(Map<String, dynamic> settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_appSettingsKey, jsonEncode(settings));

      if (kDebugMode) {
        debugPrint('⚙️ PersistenceService: Cached app settings');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ PersistenceService: Error caching app settings: $e');
      }
    }
  }

  /// Load cached app settings
  Future<Map<String, dynamic>> loadAppSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? settingsJson = prefs.getString(_appSettingsKey);

      if (settingsJson != null) {
        final Map<String, dynamic> settings = jsonDecode(settingsJson);

        if (kDebugMode) {
          debugPrint('⚙️ PersistenceService: Loaded app settings');
        }
        return settings;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ PersistenceService: Error loading app settings: $e');
      }
    }
    return {};
  }

  /// Clear all cached data for a specific user from Firebase and locally
  Future<void> clearUserData(String userId) async {
    try {
      // Clear Firebase data
      final batch = _firestore.batch();
      
      // Clear wallet cache
      batch.delete(_firestore.collection('user_wallet_cache').doc(userId));
      
      // Clear cached transactions
      final transactionsSnapshot = await _firestore
          .collection('user_wallet_cache')
          .doc(userId)
          .collection('cached_transactions')
          .get();
      for (final doc in transactionsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Clear saved searches
      final searchesSnapshot = await _firestore
          .collection('user_saved_searches')
          .doc(userId)
          .collection('searches')
          .get();
      for (final doc in searchesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Clear user preferences
      batch.delete(_firestore.collection('user_preferences').doc(userId));
      
      await batch.commit();

      // Clear local data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${_walletBalanceKey}_$userId');
      await prefs.remove('${_walletTransactionsKey}_$userId');
      await prefs.remove('${_savedSearchesKey}_$userId');
      await prefs.remove('${_userPreferencesKey}_$userId');

      if (kDebugMode) {
        debugPrint('🧹 PersistenceService: Cleared all data for user $userId from Firebase and locally');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ PersistenceService: Error clearing user data: $e');
      }
    }
  }

  /// Clear all cached data
  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_propertiesKey);
      await prefs.remove(_propertiesTimestampKey);
      await prefs.remove(_boostedPropertiesKey);
      await prefs.remove(_savedSearchesKey);
      await prefs.remove(_userPreferencesKey);
      await prefs.remove(_appSettingsKey);

      // Clear all wallet-related keys
      final keys = prefs.getKeys();
      for (String key in keys) {
        if (key.startsWith(_walletBalanceKey) || 
            key.startsWith(_walletTransactionsKey) ||
            key.startsWith(_savedSearchesKey) ||
            key.startsWith(_userPreferencesKey)) {
          await prefs.remove(key);
        }
      }

      if (kDebugMode) {
        debugPrint('🧹 PersistenceService: Cleared all cached data');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ PersistenceService: Error clearing all data: $e');
      }
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? propertiesJson = prefs.getString(_propertiesKey);
      final String? timestampString = prefs.getString(_propertiesTimestampKey);
      final String? boostedJson = prefs.getString(_boostedPropertiesKey);

      return {
        'propertiesCount': propertiesJson != null ? (jsonDecode(propertiesJson) as List).length : 0,
        'boostedPropertiesCount': boostedJson != null ? (jsonDecode(boostedJson) as Map).length : 0,
        'lastUpdated': timestampString != null ? DateTime.parse(timestampString) : null,
        'totalKeys': prefs.getKeys().length,
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ PersistenceService: Error getting cache stats: $e');
      }
      return {'propertiesCount': 0, 'boostedPropertiesCount': 0, 'lastUpdated': null, 'totalKeys': 0};
    }
  }
}
