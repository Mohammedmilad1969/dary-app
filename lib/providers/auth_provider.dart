import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';

/// AuthProvider manages authentication state using ChangeNotifier
/// This provides a clean interface for widgets to listen to auth changes
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  UserProfile? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  /// Getter for current user
  UserProfile? get currentUser => _currentUser;

  /// Getter for loading state
  bool get isLoading => _isLoading;

  /// Getter for error message
  String? get errorMessage => _errorMessage;

  /// Getter for authentication status
  bool get isAuthenticated => _currentUser != null;

  /// Getter for user ID
  String? get userId => _currentUser?.id;

  /// Getter for user email
  String? get userEmail => _currentUser?.email;

  /// Getter for user name
  String? get userName => _currentUser?.name;

  /// Initialize authentication state
  Future<void> initialize() async {
    _setLoading(true);
    try {
      // Check for existing session
      _currentUser = await _authService.getCurrentUser();
      
      if (_currentUser != null) {
        // Valid session found
        _clearError();
        if (kDebugMode) {
          debugPrint('✅ AuthProvider: Valid session found for user: ${_currentUser!.email}');
        }
      } else {
        // No valid session
        _clearError();
        if (kDebugMode) {
          debugPrint('ℹ️ AuthProvider: No valid session found');
        }
      }
    } catch (e) {
      _setError('Failed to initialize authentication: $e');
      if (kDebugMode) {
        debugPrint('❌ AuthProvider: Session check failed: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Check if there's a valid session without loading state
  Future<bool> hasValidSession() async {
    try {
      final user = await _authService.getCurrentUser();
      return user != null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ AuthProvider: Session validation failed: $e');
      }
      return false;
    }
  }

  /// Login with identifier (email/phone/username) and password
  Future<bool> login(String identifier, String password) async {
    _setLoading(true);
    _clearError();
    
    try {
      final user = await _authService.loginWithIdentifier(identifier, password);
      if (user != null) {
        _currentUser = user;
        notifyListeners();
        return true;
      } else {
        _setError('Login failed. Please check your credentials.');
        return false;
      }
    } catch (e) {
      _setError('Login error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();
    
    try {
      final success = await _authService.signInWithGoogle();
      if (success) {
        _currentUser = await _authService.getCurrentUser();
        notifyListeners();
        return true;
      } else {
        _setError('Google Sign-In failed. Please try again.');
        return false;
      }
    } catch (e) {
      _setError('Google Sign-In error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Register new user
  Future<bool> register(String name, String email, String phone, String password) async {
    _setLoading(true);
    _clearError();
    
    try {
      final user = await _authService.register(name, email, phone, password);
      if (user != null) {
        _currentUser = user;
        notifyListeners();
        return true;
      } else {
        _setError('Registration failed. Please try again.');
        return false;
      }
    } catch (e) {
      _setError('Registration error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Logout current user
  Future<void> logout() async {
    _setLoading(true);
    _clearError();
    
    try {
      await _authService.logout();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      _setError('Logout error: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh current user data
  Future<void> refreshUser() async {
    if (_currentUser == null) return;
    
    _setLoading(true);
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        _currentUser = user;
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to refresh user data: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Verify user (update verification status)
  Future<void> verifyUser() async {
    if (_currentUser == null) return;
    
    _setLoading(true);
    try {
      // Update user verification status in AuthService
      await _authService.verifyUser(_currentUser!.email);
      
      // Refresh user data to get updated verification status
      final user = await _authService.getCurrentUser();
      if (user != null) {
        _currentUser = user;
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to verify user: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Clear error message
  void clearError() {
    _clearError();
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error message
  void _setError(String error) {
    _errorMessage = error;
    if (kDebugMode) {
      debugPrint('AuthProvider Error: $error');
    }
    notifyListeners();
  }

  /// Clear error message
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Update user profile
  Future<bool> updateProfile({
    required String name,
    String? phone,
    String? profileImageUrl,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      final success = await _authService.updateProfile(
        name: name,
        phone: phone,
        profileImageUrl: profileImageUrl,
      );
      
      if (success) {
        // Refresh user data to get updated profile
        _currentUser = await _authService.getCurrentUser();
        notifyListeners();
        return true;
      } else {
        _setError('Failed to update profile.');
        return false;
      }
    } catch (e) {
      _setError('Update profile error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Check if user has specific permission (placeholder for future use)
  bool hasPermission(String permission) {
    // Placeholder for future permission system
    return isAuthenticated;
  }

  /// Get user's display name
  String getDisplayName() {
    if (_currentUser != null) {
      return _currentUser!.name;
    }
    return 'Guest';
  }

  /// Get user's initials for avatar
  String getInitials() {
    if (_currentUser != null) {
      final names = _currentUser!.name.split(' ');
      if (names.length >= 2) {
        return '${names[0][0]}${names[1][0]}'.toUpperCase();
      } else if (names.isNotEmpty) {
        return names[0][0].toUpperCase();
      }
    }
    return 'G';
  }

  @override
  void dispose() {
    // AuthService doesn't need disposal as it's static
    super.dispose();
  }
}
