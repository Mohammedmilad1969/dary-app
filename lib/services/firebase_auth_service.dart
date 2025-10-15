import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../app/app_router.dart';

class FirebaseAuthService extends ChangeNotifier {
  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Secure storage for sensitive data (tokens, user IDs)
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Storage keys
  static const String _sessionTokenKey = 'firebase_session_token';
  static const String _userEmailKey = 'firebase_user_email';
  static const String _userNameKey = 'firebase_user_name';
  static const String _userPhoneKey = 'firebase_user_phone';
  static const String _userIdKey = 'firebase_user_id';
  static const String _isLoggedInKey = 'firebase_is_logged_in';

  UserProfile? _currentUser;
  String? _sessionToken;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  UserProfile? get currentUser => _currentUser;
  String? get sessionToken => _sessionToken;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  FirebaseAuthService() {
    _initializeAuth();
    _setupAuthStateListener();
  }

  /// Initialize authentication state from stored data
  Future<void> _initializeAuth() async {
    _setLoading(true);
    
    try {
      // Check if user is already signed in with Firebase
      final firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        await _loadUserFromFirestore(firebaseUser.uid);
        return;
      }

      // Try to restore session from storage
      await _restoreSessionFromStorage();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error initializing Firebase auth: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Set up Firebase Auth state listener
  void _setupAuthStateListener() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _loadUserFromFirestore(user.uid);
      } else {
        _clearUserSession();
      }
    });
  }

  /// Load user data from Firestore
  Future<void> _loadUserFromFirestore(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      
      if (doc.exists) {
        final data = doc.data()!;
        _currentUser = UserProfile(
          id: uid,
          name: data['name'] ?? '',
          email: data['email'] ?? '',
          phone: data['phone'],
          profileImageUrl: data['profileImageUrl'],
          totalListings: data['totalListings'] ?? 0,
          activeListings: data['activeListings'] ?? 0,
          joinDate: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          isVerified: data['isVerified'] ?? false,
          isAdmin: data['isAdmin'] ?? false,
        );
        
        _sessionToken = await _auth.currentUser?.getIdToken();
        _isLoggedIn = true;
        
        await _saveUserSession(_currentUser!, _sessionToken!);
        
        if (kDebugMode) {
          debugPrint('✅ FirebaseAuthService: User loaded from Firestore');
        }
        
        notifyListeners();
        AppRouter.refresh();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ FirebaseAuthService: Error loading user from Firestore: $e');
      }
    }
  }

  /// Restore session from local storage
  Future<void> _restoreSessionFromStorage() async {
    try {
      // Try secure storage first (mobile platforms)
      if (!kIsWeb) {
        try {
          final email = await _secureStorage.read(key: _userEmailKey);
          final name = await _secureStorage.read(key: _userNameKey);
          final phone = await _secureStorage.read(key: _userPhoneKey);
          final userId = await _secureStorage.read(key: _userIdKey);
          final token = await _secureStorage.read(key: _sessionTokenKey);
          
          if (email != null && name != null && userId != null && token != null) {
            _currentUser = UserProfile(
              id: userId,
              name: name,
              email: email,
              phone: phone,
              profileImageUrl: 'https://via.placeholder.com/150/4F46E5/FFFFFF?text=${name.substring(0, 1).toUpperCase()}',
              totalListings: 0,
              activeListings: 0,
              joinDate: DateTime.now().subtract(const Duration(days: 30)),
              createdAt: DateTime.now().subtract(const Duration(days: 30)),
              updatedAt: DateTime.now(),
              isVerified: false,
              isAdmin: false,
            );
            _sessionToken = token;
            _isLoggedIn = true;
            
            if (kDebugMode) {
              debugPrint('✅ FirebaseAuthService: Session restored from secure storage');
            }
            notifyListeners();
            return;
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ FirebaseAuthService: Secure storage failed, falling back to SharedPreferences: $e');
          }
        }
      }
      
      // Fallback to SharedPreferences (web or if secure storage fails)
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
      
      if (isLoggedIn) {
        final email = prefs.getString(_userEmailKey);
        final name = prefs.getString(_userNameKey);
        final phone = prefs.getString(_userPhoneKey);
        final userId = prefs.getString(_userIdKey);
        final token = prefs.getString(_sessionTokenKey);
        
        if (email != null && name != null && userId != null && token != null) {
          _currentUser = UserProfile(
            id: userId,
            name: name,
            email: email,
            phone: phone,
            profileImageUrl: 'https://via.placeholder.com/150/4F46E5/FFFFFF?text=${name.substring(0, 1).toUpperCase()}',
            totalListings: 0,
            activeListings: 0,
            joinDate: DateTime.now().subtract(const Duration(days: 30)),
            createdAt: DateTime.now().subtract(const Duration(days: 30)),
            updatedAt: DateTime.now(),
            isVerified: false,
            isAdmin: false,
          );
          _sessionToken = token;
          _isLoggedIn = true;
          
          if (kDebugMode) {
            debugPrint('✅ FirebaseAuthService: Session restored from SharedPreferences');
          }
          notifyListeners();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ FirebaseAuthService: Error restoring session: $e');
      }
    }
  }

  /// Login with email and password using Firebase Auth
  Future<UserProfile?> login(String email, String password) async {
    _setLoading(true);
    _clearError();
    
    try {
      // Sign in with Firebase Auth
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (userCredential.user != null) {
        // Load user data from Firestore
        await _loadUserFromFirestore(userCredential.user!.uid);
        
        if (kDebugMode) {
          debugPrint('✅ FirebaseAuthService: Login successful for ${userCredential.user!.email}');
        }
        
        return _currentUser;
      } else {
        throw FirebaseAuthException(
          code: 'login-failed',
          message: 'Login failed. Please try again.',
        );
      }
    } on FirebaseAuthException catch (e) {
      _setError(_getFirebaseErrorMessage(e));
      if (kDebugMode) {
        debugPrint('❌ FirebaseAuthService: Login failed: ${e.message}');
      }
      rethrow;
    } catch (e) {
      _setError('An unexpected error occurred. Please try again.');
      if (kDebugMode) {
        debugPrint('❌ FirebaseAuthService: Unexpected login error: $e');
      }
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Register new user with Firebase Auth and Firestore
  Future<UserProfile?> register(String name, String email, String phone, String password) async {
    _setLoading(true);
    _clearError();
    
    try {
      // Validate input
      if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
        throw FirebaseAuthException(
          code: 'invalid-input',
          message: 'All fields are required',
        );
      }
      
      if (!_isValidEmail(email)) {
        throw FirebaseAuthException(
          code: 'invalid-email',
          message: 'Invalid email format',
        );
      }
      
      if (password.length < 6) {
        throw FirebaseAuthException(
          code: 'weak-password',
          message: 'Password must be at least 6 characters',
        );
      }

      // Create user with Firebase Auth
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (userCredential.user != null) {
        final user = userCredential.user!;
        
        // Create user document in Firestore
        await _createUserDocument(user.uid, name, email, phone);
        
        // Load user data from Firestore
        await _loadUserFromFirestore(user.uid);
        
        if (kDebugMode) {
          debugPrint('✅ FirebaseAuthService: Registration successful for $email');
        }
        
        return _currentUser;
      } else {
        throw FirebaseAuthException(
          code: 'registration-failed',
          message: 'Registration failed. Please try again.',
        );
      }
    } on FirebaseAuthException catch (e) {
      _setError(_getFirebaseErrorMessage(e));
      if (kDebugMode) {
        debugPrint('❌ FirebaseAuthService: Registration failed: ${e.message}');
      }
      rethrow;
    } catch (e) {
      _setError('An unexpected error occurred. Please try again.');
      if (kDebugMode) {
        debugPrint('❌ FirebaseAuthService: Unexpected registration error: $e');
      }
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Create user document in Firestore
  Future<void> _createUserDocument(String uid, String name, String email, String phone) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'name': name,
        'email': email.trim(),
        'phone': phone,
        'profileImageUrl': 'https://via.placeholder.com/150/4F46E5/FFFFFF?text=${name.substring(0, 1).toUpperCase()}',
        'totalListings': 0,
        'activeListings': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isVerified': false, // New users are not verified by default
        'isAdmin': false, // New users are not admin by default
      });
      
      if (kDebugMode) {
        debugPrint('✅ FirebaseAuthService: User document created in Firestore');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ FirebaseAuthService: Error creating user document: $e');
      }
      throw Exception('Failed to create user profile');
    }
  }

  /// Logout current user
  Future<void> logout() async {
    _setLoading(true);
    
    try {
      // Sign out from Firebase Auth
      await _auth.signOut();
      
      // Clear local session
      await _clearUserSession();
      
      if (kDebugMode) {
        debugPrint('✅ FirebaseAuthService: Logout successful');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ FirebaseAuthService: Logout error: $e');
      }
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Clear user session from local storage
  Future<void> _clearUserSession() async {
    try {
      // Clear secure storage (mobile platforms)
      if (!kIsWeb) {
        try {
          await _secureStorage.delete(key: _sessionTokenKey);
          await _secureStorage.delete(key: _userEmailKey);
          await _secureStorage.delete(key: _userNameKey);
          await _secureStorage.delete(key: _userPhoneKey);
          await _secureStorage.delete(key: _userIdKey);
          
          if (kDebugMode) {
            debugPrint('✅ FirebaseAuthService: Secure storage cleared');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ FirebaseAuthService: Failed to clear secure storage: $e');
          }
        }
      }
      
      // Clear SharedPreferences (web or fallback)
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionTokenKey);
      await prefs.remove(_userEmailKey);
      await prefs.remove(_userNameKey);
      await prefs.remove(_userPhoneKey);
      await prefs.remove(_userIdKey);
      await prefs.remove(_isLoggedInKey);
      
      if (kDebugMode) {
        debugPrint('✅ FirebaseAuthService: SharedPreferences cleared');
      }
      
      // Update state
      _currentUser = null;
      _sessionToken = null;
      _isLoggedIn = false;
      
      notifyListeners();
      AppRouter.refresh();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ FirebaseAuthService: Error clearing session: $e');
      }
    }
  }

  /// Get current user
  Future<UserProfile?> getCurrentUser() async {
    if (_currentUser != null) {
      return _currentUser;
    }
    
    // Try to load from Firebase Auth
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      await _loadUserFromFirestore(firebaseUser.uid);
      return _currentUser;
    }
    
    return null;
  }

  /// Save user session to local storage
  Future<void> _saveUserSession(UserProfile user, String token) async {
    try {
      // Try secure storage first (mobile platforms)
      if (!kIsWeb) {
        try {
          await _secureStorage.write(key: _sessionTokenKey, value: token);
          await _secureStorage.write(key: _userEmailKey, value: user.email);
          await _secureStorage.write(key: _userNameKey, value: user.name);
          if (user.phone != null) {
            await _secureStorage.write(key: _userPhoneKey, value: user.phone!);
          }
          await _secureStorage.write(key: _userIdKey, value: user.id);
          
          if (kDebugMode) {
            debugPrint('✅ FirebaseAuthService: Session saved to secure storage');
          }
          return;
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ FirebaseAuthService: Secure storage failed, falling back to SharedPreferences: $e');
          }
        }
      }
      
      // Fallback to SharedPreferences (web or if secure storage fails)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionTokenKey, token);
      await prefs.setString(_userEmailKey, user.email);
      await prefs.setString(_userNameKey, user.name);
      if (user.phone != null) {
        await prefs.setString(_userPhoneKey, user.phone!);
      }
      await prefs.setString(_userIdKey, user.id);
      await prefs.setBool(_isLoggedInKey, true);
      
      if (kDebugMode) {
        debugPrint('✅ FirebaseAuthService: Session saved to SharedPreferences');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ FirebaseAuthService: Failed to save session: $e');
      }
      rethrow;
    }
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }

  /// Get user-friendly error message from Firebase Auth exception
  String _getFirebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      case 'invalid-credential':
        return 'Invalid credentials. Please check your email and password.';
      default:
        return e.message ?? 'An error occurred. Please try again.';
    }
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error message
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// Clear error message
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Check if user is authenticated
  bool isAuthenticated() {
    return _isLoggedIn && _currentUser != null && _sessionToken != null;
  }

  /// Refresh user data from Firestore
  Future<void> refreshUser() async {
    if (_currentUser == null) return;
    
    _setLoading(true);
    
    try {
      await _loadUserFromFirestore(_currentUser!.id);
      
      if (kDebugMode) {
        debugPrint('✅ FirebaseAuthService: User data refreshed');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ FirebaseAuthService: Error refreshing user: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Verify user (update verification status in Firestore)
  Future<void> verifyUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'isVerified': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      if (kDebugMode) {
        debugPrint('✅ FirebaseAuthService: User $uid has been verified');
      }
      
      // If this is the current user, update their profile
      if (_currentUser != null && _currentUser!.id == uid) {
        _currentUser = _currentUser!.copyWith(isVerified: true);
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ FirebaseAuthService: Failed to verify user $uid: $e');
      }
      throw Exception('Failed to verify user: $e');
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      
      if (kDebugMode) {
        debugPrint('✅ FirebaseAuthService: Password reset email sent to $email');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ FirebaseAuthService: Failed to send password reset email: $e');
      }
      rethrow;
    }
  }

  /// Update user profile in Firestore
  Future<void> updateUserProfile({
    String? name,
    String? phone,
    String? profileImageUrl,
  }) async {
    if (_currentUser == null) return;
    
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;
      if (profileImageUrl != null) updates['profileImageUrl'] = profileImageUrl;
      
      await _firestore.collection('users').doc(_currentUser!.id).update(updates);
      
      // Update local user profile
      _currentUser = _currentUser!.copyWith(
        name: name ?? _currentUser!.name,
        phone: phone ?? _currentUser!.phone,
        profileImageUrl: profileImageUrl ?? _currentUser!.profileImageUrl,
        updatedAt: DateTime.now(),
      );
      
      notifyListeners();
      
      if (kDebugMode) {
        debugPrint('✅ FirebaseAuthService: User profile updated');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ FirebaseAuthService: Failed to update user profile: $e');
      }
      rethrow;
    }
  }
}

/// Custom exception for Firebase authentication errors
class FirebaseAuthException implements Exception {
  final String code;
  final String message;
  
  FirebaseAuthException({required this.code, required this.message});
  
  @override
  String toString() => 'FirebaseAuthException: $message';
}
