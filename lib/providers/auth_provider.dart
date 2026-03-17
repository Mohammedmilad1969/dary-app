import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/wallet_service.dart';
import 'package:dary/services/notification_service.dart';
import '../app/app_router.dart';

/// AuthProvider manages authentication state using ChangeNotifier
/// This provides a clean interface for widgets to listen to auth changes
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final WalletService _walletService = WalletService();
  
  UserProfile? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider() {
    _authService.addListener(_handleAuthServiceUpdate);
    initialize();
  }

  @override
  void dispose() {
    _authService.removeListener(_handleAuthServiceUpdate);
    super.dispose();
  }

  void _handleAuthServiceUpdate() {
    if (_currentUser != _authService.currentUser) {
      _currentUser = _authService.currentUser;
      notifyListeners();
    }
  }

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

  /// Getter for session token
  String? get sessionToken => _authService.sessionToken;

  /// Check if email is verified
  bool get isEmailVerified => _currentUser?.isVerified ?? false;


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
        // Initialize wallet for the authenticated user
        await _initializeWallet();
        // Update FCM token for push notifications
        await NotificationService().updateFCMToken(_currentUser!.id);
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
        _notifySafely();
        AppRouter.refresh();
        // Initialize wallet for the authenticated user
        await _initializeWallet();
        // Update FCM token for push notifications
        await NotificationService().updateFCMToken(_currentUser!.id);
        return true;
      } else {
        _setError('LOGIN_FAILED');
        return false;
      }
    } catch (e) {
      // Pass the raw error so the UI can translate the specific Firebase error code
      _setError(e.toString());
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
        _notifySafely();
        AppRouter.refresh();
        // Initialize wallet for the authenticated user
        await _initializeWallet();
        // Update FCM token for push notifications
        await NotificationService().updateFCMToken(_currentUser!.id);
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
        _notifySafely();
        AppRouter.refresh();
        // Initialize wallet for the authenticated user
        await _initializeWallet();
        // Update FCM token for push notifications
        await NotificationService().updateFCMToken(_currentUser!.id);
        return true;
      } else {
        _setError('REGISTRATION_FAILED');
        return false;
      }
    } catch (e) {
      // Pass the raw error so the UI can translate the specific Firebase error code
      _setError(e.toString());
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
      _notifySafely();
    } catch (e) {
      _setError('Logout error: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Delete current user account fully
  Future<bool> deleteAccount({String? password}) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _authService.deleteAccount(password: password);
      _currentUser = null;
      _notifySafely();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }


  /// Refresh current user data
  Future<void> refreshUser() async {
    if (_currentUser == null) return;
    
    _setLoading(true);
    try {
      // Call refreshUser which fetches from Firestore
      await _authService.refreshUser();
      final user = await _authService.getCurrentUser();
      if (user != null) {
        _currentUser = user;
        _notifySafely();
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
    _clearError();
    try {
      await _authService.verifyUser(_currentUser!.email);
      _currentUser = await _authService.getCurrentUser();
      _notifySafely();
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
    if (_isLoading == loading) return;
    _isLoading = loading;
    _notifySafely();
  }

  void _notifySafely() {
    if (WidgetsBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
    } else {
      notifyListeners();
    }
  }

  /// Set error message
  void _setError(String error) {
    _errorMessage = error;
    if (kDebugMode) {
      debugPrint('AuthProvider Error: $error');
    }
    _notifySafely();
  }

  /// Clear error message
  void _clearError() {
    _errorMessage = null;
    _notifySafely();
  }

  /// Initialize wallet for the current user
  Future<void> _initializeWallet() async {
    if (_currentUser != null) {
      try {
        await _walletService.initialize(_currentUser!.id);
        if (kDebugMode) {
          debugPrint('💰 AuthProvider: Wallet initialized for user: ${_currentUser!.id}');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ AuthProvider: Failed to initialize wallet: $e');
        }
      }
    }
  }

  /// Update user profile
  Future<bool> updateProfile({
    required String name,
    String? phone,
    String? profileImageUrl,
    String? coverImageUrl,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      final success = await _authService.updateProfile(
        name: name,
        phone: phone,
        profileImageUrl: profileImageUrl,
        coverImageUrl: coverImageUrl,
      );
      
      if (success) {
        // Refresh user data to get updated profile
        _currentUser = await _authService.getCurrentUser();
        _notifySafely();
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

  /// Send password reset email
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _authService.resetPassword(email);
      return true;
    } catch (e) {
      _setError('Reset password error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Check email verification status
  Future<bool> checkEmailVerification(String token) async {
    return await _authService.checkEmailVerification(token);
  }

  /// Send email verification
  Future<void> sendEmailVerification([String? token]) async {
    await _authService.sendEmailVerification(token);
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
}
