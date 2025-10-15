import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/saved_search.dart';
import '../services/persistence_service.dart';

/// Firebase-compatible Saved Search Service
/// 
/// This service manages saved searches using local storage (SharedPreferences)
/// with a Firebase-compatible interface. When Firebase is properly configured,
/// this can be easily switched to use Firestore.
class SavedSearchService extends ChangeNotifier {
  static final SavedSearchService _instance = SavedSearchService._internal();
  factory SavedSearchService() => _instance;
  SavedSearchService._internal();

  List<SavedSearch> _savedSearches = [];
  bool _isLoading = false;
  String? _errorMessage;
  static const String _storageKey = 'saved_searches_firebase';
  final PersistenceService _persistenceService = PersistenceService();

  List<SavedSearch> get savedSearches => List.unmodifiable(_savedSearches);
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

  /// Initialize the service and load saved searches for the current user
  Future<void> initialize(String? userId) async {
    if (userId == null) return;
    
    _setLoading(true);
    _setErrorMessage(null);
    
    try {
      // Load cached saved searches first
      final cachedSearches = await _persistenceService.loadSavedSearches(userId);
      if (cachedSearches.isNotEmpty) {
        _savedSearches = cachedSearches;
        notifyListeners();
        
        if (kDebugMode) {
          debugPrint('🔍 SavedSearchService: Loaded ${cachedSearches.length} cached saved searches');
        }
      }
      
      await _loadSavedSearches(userId);
    } catch (e) {
      _setErrorMessage('Failed to load saved searches: $e');
      if (kDebugMode) debugPrint('Error loading saved searches: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load saved searches from local storage for a specific user
  Future<void> _loadSavedSearches(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? searchesJson = prefs.getString(_storageKey);
      
      if (searchesJson != null) {
        final List<dynamic> searchesList = jsonDecode(searchesJson);
        _savedSearches = searchesList
            .map((json) => SavedSearch.fromJson(json as Map<String, dynamic>))
            .where((search) => search.userId == userId)
            .toList();
      } else {
        _savedSearches = [];
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading saved searches from storage: $e');
      rethrow;
    }
  }

  /// Save searches to local storage
  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String searchesJson = jsonEncode(
        _savedSearches.map((search) => search.toJson()).toList(),
      );
      await prefs.setString(_storageKey, searchesJson);
    } catch (e) {
      if (kDebugMode) debugPrint('Error saving saved searches: $e');
    }
  }

  /// Save a new search to local storage
  Future<bool> saveSearch({
    required String userId,
    required String name,
    required Map<String, dynamic> filters,
    String? description,
  }) async {
    _setLoading(true);
    _setErrorMessage(null);

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
        _setErrorMessage('A search with this name already exists');
        return false;
      }

      // Create new saved search
      final searchId = DateTime.now().millisecondsSinceEpoch.toString();
      final newSearch = SavedSearch(
        id: searchId,
        userId: userId,
        name: name,
        filters: filters,
        createdAt: DateTime.now(),
        lastCheckedAt: DateTime.now(),
        newMatchesCount: 0,
      );

      // Add to local list
      _savedSearches.insert(0, newSearch);
      
      // Cache the updated searches
      await _persistenceService.cacheSavedSearches(userId, _savedSearches);
      
      // Save to storage
      await _saveToStorage();
      notifyListeners();

      if (kDebugMode) debugPrint('✅ Saved search "$name" created successfully');
      return true;
    } catch (e) {
      _setErrorMessage('Failed to save search: $e');
      if (kDebugMode) debugPrint('Error saving search: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Get list of saved searches for a user
  List<SavedSearch> list(String userId) {
    return _savedSearches.where((search) => search.userId == userId).toList();
  }

  /// Delete a saved search from local storage
  Future<bool> delete(String searchId) async {
    _setLoading(true);
    _setErrorMessage(null);

    try {
      // Remove from local list
      _savedSearches.removeWhere((search) => search.id == searchId);
      
      // Save to storage
      await _saveToStorage();
      notifyListeners();

      if (kDebugMode) debugPrint('✅ Saved search $searchId deleted successfully');
      return true;
    } catch (e) {
      _setErrorMessage('Failed to delete search: $e');
      if (kDebugMode) debugPrint('Error deleting search: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Run a saved search and update its stats
  Future<List<Map<String, dynamic>>> runSavedSearch(String searchId) async {
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

      if (search.id.isEmpty) return [];

      // Update last run time
      final updatedSearch = search.copyWith(lastCheckedAt: DateTime.now());
      final index = _savedSearches.indexWhere((s) => s.id == searchId);
      if (index != -1) {
        _savedSearches[index] = updatedSearch;
        await _saveToStorage();
        notifyListeners();
      }

      // Return the filters for the UI to apply
      return [search.filters];
    } catch (e) {
      if (kDebugMode) debugPrint('Error running saved search: $e');
      return [];
    }
  }

  /// Check for new matches in all saved searches
  Future<void> checkNewMatches(String userId) async {
    try {
      for (final search in _savedSearches.where((s) => s.userId == userId)) {
        // Update last checked time
        final updatedSearch = search.copyWith(lastCheckedAt: DateTime.now());
        final index = _savedSearches.indexWhere((s) => s.id == search.id);
        if (index != -1) {
          _savedSearches[index] = updatedSearch;
        }
      }
      
      await _saveToStorage();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('Error checking new matches: $e');
    }
  }

  /// Get total new matches count for a user
  int getTotalNewMatchesCount(String userId) {
    return _savedSearches
        .where((search) => search.userId == userId)
        .fold(0, (sum, search) => sum + search.newMatchesCount);
  }

  /// Clear all new matches count for a user
  Future<void> clearNewMatchesCount(String userId) async {
    try {
      // Update local data
      for (int i = 0; i < _savedSearches.length; i++) {
        if (_savedSearches[i].userId == userId) {
          _savedSearches[i] = _savedSearches[i].copyWith(newMatchesCount: 0);
        }
      }
      
      await _saveToStorage();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('Error clearing new matches count: $e');
    }
  }

  /// Update search notification settings
  Future<void> updateNotificationSettings({
    required String searchId,
    required bool enabled,
    required bool email,
    required bool push,
  }) async {
    try {
      // For now, just update local data
      // In Firebase version, this would update Firestore
      if (kDebugMode) debugPrint('Notification settings updated for search $searchId');
    } catch (e) {
      if (kDebugMode) debugPrint('Error updating notification settings: $e');
    }
  }

  /// Update search schedule
  Future<void> updateSearchSchedule({
    required String searchId,
    required String frequency, // 'daily', 'weekly', 'monthly', 'manual'
  }) async {
    try {
      // For now, just log the update
      // In Firebase version, this would update Firestore
      if (kDebugMode) debugPrint('Search schedule updated for search $searchId: $frequency');
    } catch (e) {
      if (kDebugMode) debugPrint('Error updating search schedule: $e');
    }
  }

  /// Listen to real-time updates for saved searches (mock implementation)
  Stream<List<SavedSearch>> listenToSavedSearches(String userId) {
    // For now, return a stream that emits the current list
    // In Firebase version, this would use Firestore snapshots
    return Stream.value(_savedSearches.where((s) => s.userId == userId).toList());
  }

  /// Clear all data (useful for logout)
  void clear() {
    _savedSearches.clear();
    _errorMessage = null;
    notifyListeners();
  }
}
