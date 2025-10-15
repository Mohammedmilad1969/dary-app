import 'package:flutter/foundation.dart';
import '../services/persistence_service.dart';

/// User Preferences Service
/// 
/// Manages user-specific preferences and settings with persistence
class UserPreferencesService extends ChangeNotifier {
  static final UserPreferencesService _instance = UserPreferencesService._internal();
  factory UserPreferencesService() => _instance;
  UserPreferencesService._internal();

  final PersistenceService _persistenceService = PersistenceService();

  Map<String, dynamic> _preferences = {};
  bool _isLoading = false;
  String? _errorMessage;

  Map<String, dynamic> get preferences => Map.unmodifiable(_preferences);
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

  /// Initialize preferences for a user
  Future<void> initialize(String userId) async {
    try {
      _setLoading(true);
      _setErrorMessage(null);

      // Load cached preferences
      final cachedPreferences = await _persistenceService.loadUserPreferences(userId);
      _preferences = cachedPreferences;

      if (kDebugMode) {
        debugPrint('⚙️ UserPreferencesService: Loaded preferences for user $userId');
      }
    } catch (e) {
      _setErrorMessage('Failed to load user preferences: $e');
      if (kDebugMode) {
        debugPrint('❌ UserPreferencesService: Error loading preferences: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Set a preference value
  Future<void> setPreference(String userId, String key, dynamic value) async {
    try {
      _preferences[key] = value;
      
      // Cache the updated preferences
      await _persistenceService.cacheUserPreferences(userId, _preferences);
      
      notifyListeners();

      if (kDebugMode) {
        debugPrint('⚙️ UserPreferencesService: Set preference $key = $value');
      }
    } catch (e) {
      _setErrorMessage('Failed to set preference: $e');
      if (kDebugMode) {
        debugPrint('❌ UserPreferencesService: Error setting preference: $e');
      }
    }
  }

  /// Get a preference value
  T? getPreference<T>(String key, {T? defaultValue}) {
    final value = _preferences[key];
    if (value is T) {
      return value;
    }
    return defaultValue;
  }

  /// Set language preference
  Future<void> setLanguage(String userId, String languageCode) async {
    await setPreference(userId, 'language', languageCode);
  }

  /// Get language preference
  String getLanguage({String defaultValue = 'en'}) {
    return getPreference<String>('language', defaultValue: defaultValue) ?? defaultValue;
  }

  /// Set theme preference
  Future<void> setTheme(String userId, String theme) async {
    await setPreference(userId, 'theme', theme);
  }

  /// Get theme preference
  String getTheme({String defaultValue = 'system'}) {
    return getPreference<String>('theme', defaultValue: defaultValue) ?? defaultValue;
  }

  /// Set notification preferences
  Future<void> setNotificationPreference(String userId, String type, bool enabled) async {
    final notifications = getPreference<Map<String, dynamic>>('notifications', defaultValue: {}) ?? {};
    notifications[type] = enabled;
    await setPreference(userId, 'notifications', notifications);
  }

  /// Get notification preference
  bool getNotificationPreference(String type, {bool defaultValue = true}) {
    final notifications = getPreference<Map<String, dynamic>>('notifications', defaultValue: {});
    return notifications?[type] ?? defaultValue;
  }

  /// Set search preferences
  Future<void> setSearchPreference(String userId, String key, dynamic value) async {
    final searchPrefs = getPreference<Map<String, dynamic>>('search', defaultValue: {}) ?? {};
    searchPrefs[key] = value;
    await setPreference(userId, 'search', searchPrefs);
  }

  /// Get search preference
  T? getSearchPreference<T>(String key, {T? defaultValue}) {
    final searchPrefs = getPreference<Map<String, dynamic>>('search', defaultValue: {});
    final value = searchPrefs?[key];
    if (value is T) {
      return value;
    }
    return defaultValue;
  }

  /// Set favorite cities
  Future<void> setFavoriteCities(String userId, List<String> cities) async {
    await setPreference(userId, 'favoriteCities', cities);
  }

  /// Get favorite cities
  List<String> getFavoriteCities() {
    final cities = getPreference<List<dynamic>>('favoriteCities', defaultValue: []);
    return cities?.cast<String>() ?? [];
  }

  /// Add favorite city
  Future<void> addFavoriteCity(String userId, String city) async {
    final cities = getFavoriteCities();
    if (!cities.contains(city)) {
      cities.add(city);
      await setFavoriteCities(userId, cities);
    }
  }

  /// Remove favorite city
  Future<void> removeFavoriteCity(String userId, String city) async {
    final cities = getFavoriteCities();
    cities.remove(city);
    await setFavoriteCities(userId, cities);
  }

  /// Set property view preferences
  Future<void> setPropertyViewPreference(String userId, String viewType) async {
    await setPreference(userId, 'propertyView', viewType);
  }

  /// Get property view preference
  String getPropertyViewPreference({String defaultValue = 'grid'}) {
    return getPreference<String>('propertyView', defaultValue: defaultValue) ?? defaultValue;
  }

  /// Set price range preferences
  Future<void> setPriceRangePreference(String userId, double minPrice, double maxPrice) async {
    await setPreference(userId, 'priceRange', {
      'min': minPrice,
      'max': maxPrice,
    });
  }

  /// Get price range preference
  Map<String, double> getPriceRangePreference({double defaultMin = 0, double defaultMax = 1000000}) {
    final range = getPreference<Map<String, dynamic>>('priceRange', defaultValue: {});
    return {
      'min': (range?['min'] ?? defaultMin).toDouble(),
      'max': (range?['max'] ?? defaultMax).toDouble(),
    };
  }

  /// Set bedroom preferences
  Future<void> setBedroomPreference(String userId, int minBedrooms, int maxBedrooms) async {
    await setPreference(userId, 'bedrooms', {
      'min': minBedrooms,
      'max': maxBedrooms,
    });
  }

  /// Get bedroom preference
  Map<String, int> getBedroomPreference({int defaultMin = 0, int defaultMax = 10}) {
    final bedrooms = getPreference<Map<String, dynamic>>('bedrooms', defaultValue: {});
    return {
      'min': bedrooms?['min'] ?? defaultMin,
      'max': bedrooms?['max'] ?? defaultMax,
    };
  }

  /// Set feature preferences
  Future<void> setFeaturePreference(String userId, String feature, bool enabled) async {
    final features = getPreference<Map<String, dynamic>>('features', defaultValue: {}) ?? {};
    features[feature] = enabled;
    await setPreference(userId, 'features', features);
  }

  /// Get feature preference
  bool getFeaturePreference(String feature, {bool defaultValue = false}) {
    final features = getPreference<Map<String, dynamic>>('features', defaultValue: {});
    return features?[feature] ?? defaultValue;
  }

  /// Clear all preferences for a user
  Future<void> clearPreferences(String userId) async {
    try {
      _preferences.clear();
      await _persistenceService.cacheUserPreferences(userId, _preferences);
      notifyListeners();

      if (kDebugMode) {
        debugPrint('⚙️ UserPreferencesService: Cleared all preferences for user $userId');
      }
    } catch (e) {
      _setErrorMessage('Failed to clear preferences: $e');
      if (kDebugMode) {
        debugPrint('❌ UserPreferencesService: Error clearing preferences: $e');
      }
    }
  }

  /// Export preferences as JSON
  Map<String, dynamic> exportPreferences() {
    return Map.from(_preferences);
  }

  /// Import preferences from JSON
  Future<void> importPreferences(String userId, Map<String, dynamic> preferences) async {
    try {
      _preferences = Map.from(preferences);
      await _persistenceService.cacheUserPreferences(userId, _preferences);
      notifyListeners();

      if (kDebugMode) {
        debugPrint('⚙️ UserPreferencesService: Imported preferences for user $userId');
      }
    } catch (e) {
      _setErrorMessage('Failed to import preferences: $e');
      if (kDebugMode) {
        debugPrint('❌ UserPreferencesService: Error importing preferences: $e');
      }
    }
  }
}
