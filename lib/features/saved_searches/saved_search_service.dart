import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/saved_search.dart';
import '../../models/property.dart';
import '../../config/env_config.dart';
import '../../services/api_client.dart';

class SavedSearchService extends ChangeNotifier {
  static final SavedSearchService _instance = SavedSearchService._internal();
  factory SavedSearchService() => _instance;
  SavedSearchService._internal();

  final ApiClient _apiClient = ApiClient();
  List<SavedSearch> _savedSearches = [];
  static const String _storageKey = 'saved_searches';

  List<SavedSearch> get savedSearches => List.unmodifiable(_savedSearches);

  // Initialize service and load saved searches
  Future<void> initialize() async {
    if (EnvConfig.useMockData) {
      await _loadMockData();
    } else {
      await _loadFromStorage();
    }
  }

  // Load mock data for development
  Future<void> _loadMockData() async {
    _savedSearches = [
      SavedSearch(
        id: 'search_001',
        userId: 'user_001',
        name: 'Apartments in Tripoli',
        filters: {
          'searchQuery': 'apartment',
          'city': 'Tripoli',
          'type': 'apartment',
          'status': 'forRent',
          'priceRange': {'min': 500, 'max': 1500},
          'features': ['hasBalcony', 'hasParking'],
        },
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        lastCheckedAt: DateTime.now().subtract(const Duration(days: 1)),
        newMatchesCount: 3,
      ),
      SavedSearch(
        id: 'search_002',
        userId: 'user_001',
        name: 'Luxury Villas for Sale',
        filters: {
          'searchQuery': 'villa',
          'type': 'villa',
          'status': 'forSale',
          'priceRange': {'min': 200000, 'max': 500000},
          'features': ['hasPool', 'hasGarden', 'hasSecurity'],
        },
        createdAt: DateTime.now().subtract(const Duration(days: 14)),
        lastCheckedAt: DateTime.now().subtract(const Duration(days: 3)),
        newMatchesCount: 1,
      ),
      SavedSearch(
        id: 'search_003',
        userId: 'user_002',
        name: 'Budget Rentals',
        filters: {
          'searchQuery': '',
          'status': 'forRent',
          'priceRange': {'min': 200, 'max': 800},
          'features': ['hasAC'],
        },
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        lastCheckedAt: DateTime.now().subtract(const Duration(hours: 6)),
        newMatchesCount: 0,
      ),
    ];
    notifyListeners();
  }

  // Load saved searches from local storage
  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? searchesJson = prefs.getString(_storageKey);
      
      if (searchesJson != null) {
        final List<dynamic> searchesList = jsonDecode(searchesJson);
        _savedSearches = searchesList
            .map((json) => SavedSearch.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading saved searches: $e');
      }
    }
  }

  // Save searches to local storage
  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String searchesJson = jsonEncode(
        _savedSearches.map((search) => search.toJson()).toList(),
      );
      await prefs.setString(_storageKey, searchesJson);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error saving saved searches: $e');
      }
    }
  }

  // Get saved searches for a specific user
  List<SavedSearch> getSavedSearchesForUser(String userId) {
    return _savedSearches.where((search) => search.userId == userId).toList();
  }

  // Save a new search
  Future<bool> saveSearch({
    required String userId,
    required String name,
    required Map<String, dynamic> filters,
  }) async {
    try {
      // Check if search with same name already exists for this user
      final existingSearch = _savedSearches.firstWhere(
        (search) => search.userId == userId && search.name == name,
        orElse: () => SavedSearch(
          id: '',
          userId: '',
          name: '',
          filters: {},
          createdAt: DateTime.now(),
        ),
      );

      if (existingSearch.id.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('Search with name "$name" already exists for user $userId');
        }
        return false;
      }

      final newSearch = SavedSearch(
        id: 'search_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        name: name,
        filters: filters,
        createdAt: DateTime.now(),
        lastCheckedAt: DateTime.now(),
        newMatchesCount: 0,
      );

      if (EnvConfig.useMockData) {
        _savedSearches.add(newSearch);
        notifyListeners();
        return true;
      } else {
        // API call to save search
        final response = await _apiClient.post('/saved-searches', body: newSearch.toJson());
        
        _savedSearches.add(newSearch);
        await _saveToStorage();
        notifyListeners();
        return true;
              return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error saving search: $e');
      }
      return false;
    }
  }

  // Delete a saved search
  Future<bool> deleteSearch(String searchId) async {
    try {
      if (EnvConfig.useMockData) {
        _savedSearches.removeWhere((search) => search.id == searchId);
        notifyListeners();
        return true;
      } else {
        // API call to delete search
        final response = await _apiClient.delete('/saved-searches/$searchId');
        
        _savedSearches.removeWhere((search) => search.id == searchId);
        await _saveToStorage();
        notifyListeners();
        return true;
              return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting search: $e');
      }
      return false;
    }
  }

  // Check for new matches in a saved search
  Future<int> checkNewMatches(String searchId) async {
    try {
      final search = _savedSearches.firstWhere(
        (s) => s.id == searchId,
        orElse: () => SavedSearch(
          id: '',
          userId: '',
          name: '',
          filters: {},
          createdAt: DateTime.now(),
        ),
      );

      if (search.id.isEmpty) return 0;

      // Apply filters to current properties
      final matchingProperties = _applyFiltersToProperties(search.filters);
      
      // Count new properties since last check
      int newMatches = 0;
      if (search.lastCheckedAt != null) {
        newMatches = matchingProperties
            .where((property) => property.createdAt.isAfter(search.lastCheckedAt!))
            .length;
      } else {
        newMatches = matchingProperties.length;
      }

      // Update the search with new match count and last checked time
      final updatedSearch = search.copyWith(
        lastCheckedAt: DateTime.now(),
        newMatchesCount: newMatches,
      );

      final index = _savedSearches.indexWhere((s) => s.id == searchId);
      if (index != -1) {
        _savedSearches[index] = updatedSearch;
        
        if (!EnvConfig.useMockData) {
          await _saveToStorage();
        }
        notifyListeners();
      }

      return newMatches;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error checking new matches: $e');
      }
      return 0;
    }
  }

  // Apply saved search filters to properties
  List<Property> _applyFiltersToProperties(Map<String, dynamic> filters) {
    List<Property> properties = PropertyService.getSortedProperties();

    // Apply search query
    if (filters['searchQuery'] != null && filters['searchQuery'].toString().isNotEmpty) {
      properties = PropertyService.searchProperties(filters['searchQuery'].toString());
    }

    // Apply type filter
    if (filters['type'] != null) {
      final typeString = filters['type'].toString();
      final type = PropertyType.values.firstWhere(
        (t) => t.typeDisplayName.toLowerCase() == typeString.toLowerCase(),
        orElse: () => PropertyType.apartment,
      );
      properties = properties.where((p) => p.type == type).toList();
    }

    // Apply status filter
    if (filters['status'] != null) {
      final statusString = filters['status'].toString();
      final status = PropertyStatus.values.firstWhere(
        (s) => s.toString().split('.').last == statusString,
        orElse: () => PropertyStatus.forSale,
      );
      properties = properties.where((p) => p.status == status).toList();
    }

    // Apply city filter
    if (filters['city'] != null && filters['city'].toString().isNotEmpty) {
      final city = filters['city'].toString();
      properties = properties.where((p) => p.city.toLowerCase() == city.toLowerCase()).toList();
    }

    // Apply price range filter
    if (filters['priceRange'] != null) {
      final priceRange = filters['priceRange'] as Map<String, dynamic>;
      final minPrice = (priceRange['min'] as num?)?.toDouble() ?? 0;
      final maxPrice = (priceRange['max'] as num?)?.toDouble() ?? double.infinity;
      
      properties = properties.where((p) {
        final price = p.status == PropertyStatus.forRent ? p.monthlyRent : p.price;
        return price >= minPrice && price <= maxPrice;
      }).toList();
    }

    // Apply feature filters
    if (filters['features'] != null) {
      final features = List<String>.from(filters['features'] as List);
      
      for (final feature in features) {
        switch (feature) {
          case 'hasBalcony':
            properties = properties.where((p) => p.hasBalcony).toList();
            break;
          case 'hasGarden':
            properties = properties.where((p) => p.hasGarden).toList();
            break;
          case 'hasParking':
            properties = properties.where((p) => p.hasParking).toList();
            break;
          case 'hasPool':
            properties = properties.where((p) => p.hasPool).toList();
            break;
          case 'hasGym':
            properties = properties.where((p) => p.hasGym).toList();
            break;
          case 'hasSecurity':
            properties = properties.where((p) => p.hasSecurity).toList();
            break;
          case 'hasElevator':
            properties = properties.where((p) => p.hasElevator).toList();
            break;
          case 'hasAC':
            properties = properties.where((p) => p.hasAC).toList();
            break;
          case 'hasHeating':
            properties = properties.where((p) => p.hasHeating).toList();
            break;
          case 'hasFurnished':
            properties = properties.where((p) => p.hasFurnished).toList();
            break;
        }
      }
    }

    return properties;
  }

  // Run a saved search and return matching properties
  List<Property> runSavedSearch(String searchId) {
    final search = _savedSearches.firstWhere(
      (s) => s.id == searchId,
      orElse: () => SavedSearch(
        id: '',
        userId: '',
        name: '',
        filters: {},
        createdAt: DateTime.now(),
      ),
    );

    if (search.id.isEmpty) return [];

    return _applyFiltersToProperties(search.filters);
  }

  // Get total new matches count for a user
  int getTotalNewMatchesCount(String userId) {
    return _savedSearches
        .where((search) => search.userId == userId)
        .fold(0, (sum, search) => sum + search.newMatchesCount);
  }

  // Clear all new matches count for a user
  Future<void> clearNewMatchesCount(String userId) async {
    for (int i = 0; i < _savedSearches.length; i++) {
      if (_savedSearches[i].userId == userId) {
        _savedSearches[i] = _savedSearches[i].copyWith(newMatchesCount: 0);
      }
    }
    
    if (!EnvConfig.useMockData) {
      await _saveToStorage();
    }
    notifyListeners();
  }
}
