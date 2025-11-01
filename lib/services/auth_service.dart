import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_profile.dart';
import '../app/app_router.dart';
import '../config/firebase_config.dart';

class AuthService extends ChangeNotifier {
  // Firestore instance for user data storage
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
  static const String _sessionTokenKey = 'session_token';
  static const String _userEmailKey = 'user_email';
  static const String _userNameKey = 'user_name';
  static const String _userPhoneKey = 'user_phone';
  static const String _userIdKey = 'user_id';
  static const String _isLoggedInKey = 'is_logged_in';

  UserProfile? _currentUser;
  String? _sessionToken;
  bool _isLoggedIn = false;
  bool _isLoading = false;

  // Getters
  UserProfile? get currentUser => _currentUser;
  String? get sessionToken => _sessionToken;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;

  // Mock user database for authentication (only for admin@dary.com)
  static final Map<String, Map<String, dynamic>> _mockUsers = {
    'admin@dary.com': {
      'id': 'admin_001',
      'name': 'Admin User',
      'email': 'admin@dary.com',
      'phone': '+9999999999',
      'password': 'admin123',
      'profileImageUrl': 'https://via.placeholder.com/150/DC2626/FFFFFF?text=AD',
      'totalListings': 0,
      'activeListings': 0,
      'joinDate': '2024-01-01',
      'isVerified': true,
      'isAdmin': true, // Admin user
    },
  };

  AuthService() {
    _initializeAuth();
  }

  /// Initialize authentication state from stored data
  Future<void> _initializeAuth() async {
    _setLoading(true);
    
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
              profileImageUrl: _mockUsers[email]?['profileImageUrl'],
              totalListings: _mockUsers[email]?['totalListings'] ?? 0,
              activeListings: _mockUsers[email]?['activeListings'] ?? 0,
              joinDate: DateTime.parse(_mockUsers[email]?['joinDate'] ?? '2024-01-01'),
              createdAt: DateTime.now().subtract(const Duration(days: 30)),
              updatedAt: DateTime.now(),
              isVerified: _mockUsers[email]?['isVerified'] ?? false,
              isAdmin: _mockUsers[email]?['isAdmin'] ?? false,
            );
            _sessionToken = token;
            _isLoggedIn = true;
            
            if (kDebugMode) {
              debugPrint('✅ AuthService: Session restored from secure storage');
            }
            return;
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ AuthService: Secure storage failed, falling back to SharedPreferences: $e');
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
            profileImageUrl: _mockUsers[email]?['profileImageUrl'],
            totalListings: _mockUsers[email]?['totalListings'] ?? 0,
            activeListings: _mockUsers[email]?['activeListings'] ?? 0,
            joinDate: DateTime.parse(_mockUsers[email]?['joinDate'] ?? '2024-01-01'),
            createdAt: DateTime.now().subtract(const Duration(days: 30)),
            updatedAt: DateTime.now(),
            isVerified: _mockUsers[email]?['isVerified'] ?? false,
            isAdmin: _mockUsers[email]?['isAdmin'] ?? false,
          );
          _sessionToken = token;
          _isLoggedIn = true;
          
          if (kDebugMode) {
            debugPrint('✅ AuthService: Session restored from SharedPreferences');
          }
        }
      }
    } catch (e) {
      debugPrint('Error initializing auth: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Login with identifier (email or phone) and password
  Future<UserProfile?> loginWithIdentifier(String identifier, String password) async {
    // Check if identifier is email or phone
    if (identifier.contains('@')) {
      return await login(identifier, password);
    } else {
      // Phone login - get email from phone number
      // First try to find user by phone in Firestore
      try {
        final usersQuery = await _firestore
            .collection('users')
            .where('phone', isEqualTo: identifier)
            .limit(1)
            .get();
        
        if (usersQuery.docs.isNotEmpty) {
          final userDoc = usersQuery.docs.first;
          final userData = userDoc.data();
          final email = userData['email'] as String?;
          if (email != null) {
            return await login(email, password);
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ Error finding user by phone: $e');
        }
      }
      throw AuthException('User not found');
    }
  }

  /// Login with email and password using Firebase REST API
  Future<UserProfile?> login(String email, String password) async {
    _setLoading(true);
    
    try {
      // Check if it's the mock admin user
      if (email.toLowerCase() == 'admin@dary.com') {
        return await _loginMockUser(email, password);
      }

      // Use Firebase REST API for all other users
      final response = await http.post(
        Uri.parse(FirebaseConfig.signInUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.toLowerCase(),
          'password': password,
          'returnSecureToken': true,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final firebaseUid = data['localId'];
        final idToken = data['idToken'];

        // Get user data from Firestore
        final userDoc = await _firestore
            .collection('users')
            .doc(firebaseUid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data()!;
          final userProfile = UserProfile(
            id: firebaseUid,
            name: userData['name'] ?? 'User',
            email: email.toLowerCase(),
            phone: userData['phone'],
            profileImageUrl: userData['profileImageUrl'],
            totalListings: userData['totalListings'] ?? 0,
            activeListings: userData['activeListings'] ?? 0,
            joinDate: userData['createdAt'] != null 
                ? (userData['createdAt'] as Timestamp).toDate()
                : DateTime.now(),
            createdAt: userData['createdAt'] != null 
                ? (userData['createdAt'] as Timestamp).toDate()
                : DateTime.now(),
            updatedAt: DateTime.now(),
            isVerified: userData['isVerified'] ?? false,
            isAdmin: userData['isAdmin'] ?? false,
          );

          // Save to local storage
          await _saveUserSession(userProfile, idToken);

          // Update state
          _currentUser = userProfile;
          _sessionToken = idToken;
          _isLoggedIn = true;

          notifyListeners();
          AppRouter.refresh();

          if (kDebugMode) {
            debugPrint('✅ Firebase Auth: User logged in successfully');
          }

          return userProfile;
        } else {
          throw AuthException('User profile not found');
        }
      } else {
        final error = jsonDecode(response.body);
        throw AuthException(error['error']['message'] ?? 'Login failed');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Firebase Auth login error: $e');
      }
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Login mock user (admin@dary.com)
  Future<UserProfile?> _loginMockUser(String email, String password) async {
    try {
      // Check if user exists in mock database
      final userData = _mockUsers[email.toLowerCase()];
      
      if (userData == null) {
        throw AuthException('User not found');
      }
      
      if (userData['password'] != password) {
        throw AuthException('Invalid password');
      }
      
      // Generate mock session token
      final sessionToken = _generateSessionToken(email);
      
      // Create user profile
      final userProfile = UserProfile(
        id: userData['id'],
        name: userData['name'],
        email: userData['email'],
        phone: userData['phone'],
        profileImageUrl: userData['profileImageUrl'],
        totalListings: userData['totalListings'],
        activeListings: userData['activeListings'],
        joinDate: DateTime.parse(userData['joinDate']),
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
        isVerified: userData['isVerified'] ?? false,
        isAdmin: userData['isAdmin'] ?? false,
      );
      
      // Store user data in Firestore for persistence
      await _storeUserInFirestore(userProfile);
      
      // Save to SharedPreferences
      await _saveUserSession(userProfile, sessionToken);
      
      // Update state
      _currentUser = userProfile;
      _sessionToken = sessionToken;
      _isLoggedIn = true;
      
      notifyListeners();
      AppRouter.refresh();
      
      if (kDebugMode) {
        debugPrint('✅ Mock Auth: Admin user logged in successfully');
      }
      
      return userProfile;
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Mock Auth login error: $e');
      }
      rethrow;
    }
  }

  /// Register new user using Firebase REST API
  Future<UserProfile?> register(String name, String email, String phone, String password) async {
    _setLoading(true);
    
    try {
      // Validate input
      if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
        throw AuthException('All fields are required');
      }
      
      if (!_isValidEmail(email)) {
        throw AuthException('Invalid email format');
      }
      
      if (password.length < 6) {
        throw AuthException('Password must be at least 6 characters');
      }

      // Create user in Firebase Auth using REST API
      final response = await http.post(
        Uri.parse(FirebaseConfig.signUpUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.toLowerCase(),
          'password': password,
          'returnSecureToken': true,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final firebaseUid = data['localId'];
        final idToken = data['idToken'];

        // Create user document in Firestore
        final userData = {
          'name': name,
          'email': email.toLowerCase(),
          'phone': phone,
          'profileImageUrl': 'https://via.placeholder.com/150/4F46E5/FFFFFF?text=${name.substring(0, 1).toUpperCase()}',
          'totalListings': 0,
          'activeListings': 0,
          'isVerified': false,
          'isAdmin': false,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        };

        await _firestore
            .collection('users')
            .doc(firebaseUid)
            .set(userData);

        // Create user profile
        final userProfile = UserProfile(
          id: firebaseUid,
          name: name,
          email: email.toLowerCase(),
          phone: phone,
          profileImageUrl: userData['profileImageUrl']?.toString(),
          totalListings: 0,
          activeListings: 0,
          joinDate: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isVerified: false,
          isAdmin: false,
        );

        // Save to local storage
        await _saveUserSession(userProfile, idToken);

        // Update state
        _currentUser = userProfile;
        _sessionToken = idToken;
        _isLoggedIn = true;

        notifyListeners();
        AppRouter.refresh();

        if (kDebugMode) {
          debugPrint('✅ Firebase Auth: User registered successfully');
        }

        return userProfile;
      } else {
        final error = jsonDecode(response.body);
        throw AuthException(error['error']['message'] ?? 'Registration failed');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Firebase Auth registration error: $e');
      }
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Store user data in Firestore
  Future<void> _storeUserInFirestore(UserProfile user) async {
    try {
      final userData = {
        'name': user.name,
        'email': user.email,
        'phone': user.phone,
        'profileImageUrl': user.profileImageUrl,
        'totalListings': user.totalListings,
        'activeListings': user.activeListings,
        'isVerified': user.isVerified,
        'isAdmin': user.isAdmin,
        'joinDate': Timestamp.fromDate(user.joinDate),
        'createdAt': Timestamp.fromDate(user.createdAt),
        'updatedAt': Timestamp.now(),
      };
      
      await _firestore
          .collection('users')
          .doc(user.id)
          .set(userData, SetOptions(merge: true));
      
      if (kDebugMode) {
        debugPrint('✅ User data stored in Firestore');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to store user in Firestore: $e');
      }
      // Don't throw error - this is not critical for login
    }
  }

  /// Logout current user
  Future<void> logout() async {
    _setLoading(true);
    
    try {
      if (kDebugMode) {
        debugPrint('✅ AuthService: User signed out');
      }
      
      // Clear secure storage (mobile platforms)
      if (!kIsWeb) {
        try {
          await _secureStorage.delete(key: _sessionTokenKey);
          await _secureStorage.delete(key: _userEmailKey);
          await _secureStorage.delete(key: _userNameKey);
          await _secureStorage.delete(key: _userPhoneKey);
          await _secureStorage.delete(key: _userIdKey);
          
          if (kDebugMode) {
            debugPrint('✅ AuthService: Secure storage cleared');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ AuthService: Failed to clear secure storage: $e');
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
      await prefs.setBool(_isLoggedInKey, false);
      
      if (kDebugMode) {
        debugPrint('✅ AuthService: SharedPreferences cleared');
      }
      
      // Update state
      _currentUser = null;
      _sessionToken = null;
      _isLoggedIn = false;
      
      notifyListeners();
      AppRouter.refresh();
      
    } catch (e) {
      debugPrint('Logout error: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Get current user (already loaded from SharedPreferences)
  Future<UserProfile?> getCurrentUser() async {
    if (_currentUser != null) {
      return _currentUser;
    }
    
    // Try to load from SharedPreferences if not already loaded
    await _initializeAuth();
    return _currentUser;
  }

  /// Save user session to secure storage (with SharedPreferences fallback)
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
            debugPrint('✅ AuthService: Session saved to secure storage');
          }
          return;
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ AuthService: Secure storage failed, falling back to SharedPreferences: $e');
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
        debugPrint('✅ AuthService: Session saved to SharedPreferences');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ AuthService: Failed to save session: $e');
      }
      rethrow;
    }
  }

  /// Clear all stored authentication data (useful for debugging)
  Future<void> clearAllStoredData() async {
    try {
      // Clear secure storage
      if (!kIsWeb) {
        try {
          await _secureStorage.deleteAll();
          if (kDebugMode) {
            debugPrint('✅ AuthService: All secure storage cleared');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ AuthService: Failed to clear secure storage: $e');
          }
        }
      }
      
      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionTokenKey);
      await prefs.remove(_userEmailKey);
      await prefs.remove(_userNameKey);
      await prefs.remove(_userPhoneKey);
      await prefs.remove(_userIdKey);
      await prefs.remove(_isLoggedInKey);
      
      if (kDebugMode) {
        debugPrint('✅ AuthService: All SharedPreferences cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ AuthService: Failed to clear all stored data: $e');
      }
    }
  }

  /// Generate mock session token
  String _generateSessionToken(String email) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'token_${email.hashCode}_$timestamp';
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Check if user is authenticated
  bool isAuthenticated() {
    return _isLoggedIn && _currentUser != null && _sessionToken != null;
  }

  /// Refresh user data (mock implementation)
  Future<void> refreshUser() async {
    if (_currentUser == null) return;
    
    _setLoading(true);
    
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Update user data from mock database
      final userData = _mockUsers[_currentUser!.email];
      if (userData != null) {
        _currentUser = UserProfile(
          id: _currentUser!.id,
          name: _currentUser!.name,
          email: _currentUser!.email,
          phone: _currentUser!.phone,
          profileImageUrl: _currentUser!.profileImageUrl,
          totalListings: userData['totalListings'],
          activeListings: userData['activeListings'],
          joinDate: _currentUser!.joinDate,
          createdAt: _currentUser!.createdAt,
          updatedAt: DateTime.now(),
          isVerified: userData['isVerified'] ?? false,
          isAdmin: userData['isAdmin'] ?? false,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Refresh user error: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Verify user (update verification status)
  Future<void> verifyUser(String email) async {
    try {
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Update verification status in mock database
      if (_mockUsers.containsKey(email)) {
        _mockUsers[email]!['isVerified'] = true;
        
        if (kDebugMode) {
          debugPrint('✅ AuthService: User $email has been verified');
        }
        
        // If this is the current user, update their profile
        if (_currentUser != null && _currentUser!.email == email) {
          _currentUser = _currentUser!.copyWith(isVerified: true);
          notifyListeners();
        }
      } else {
        throw Exception('User not found');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ AuthService: Failed to verify user $email: $e');
      }
      throw Exception('Failed to verify user: $e');
    }
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    
    try {
      // Configure Google Sign-In with OAuth client ID for web
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        clientId: FirebaseConfig.googleWebClientId,
      );

      // Sign in with Google
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        // User cancelled the sign-in
        if (kDebugMode) {
          debugPrint('⚠️ Google Sign-In cancelled by user');
        }
        return false;
      }

      // Get authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Use Firebase REST API to sign in with Google credential
      // Note: For web, we might need to use firebase_auth_web directly
      if (kIsWeb) {
        // For web, we'll store user info and create/update user in Firestore
        final email = googleUser.email;
        final name = googleUser.displayName ?? 'User';
        final photoUrl = googleUser.photoUrl;

        // Check if user exists in Firestore
        final usersQuery = await _firestore
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        UserProfile userProfile;

        if (usersQuery.docs.isNotEmpty) {
          // User exists, load their profile
          final userDoc = usersQuery.docs.first;
          final userData = userDoc.data();
          userProfile = UserProfile(
            id: userDoc.id,
            name: name,
            email: email!,
            phone: userData['phone'],
            profileImageUrl: photoUrl ?? userData['profileImageUrl'],
            totalListings: userData['totalListings'] ?? 0,
            activeListings: userData['activeListings'] ?? 0,
            joinDate: userData['createdAt'] != null 
                ? (userData['createdAt'] as Timestamp).toDate()
                : DateTime.now(),
            createdAt: userData['createdAt'] != null 
                ? (userData['createdAt'] as Timestamp).toDate()
                : DateTime.now(),
            updatedAt: DateTime.now(),
            isVerified: userData['isVerified'] ?? false,
            isAdmin: userData['isAdmin'] ?? false,
          );

          // Update user data in Firestore
          await _firestore.collection('users').doc(userDoc.id).update({
            'name': name,
            'profileImageUrl': photoUrl,
            'updatedAt': Timestamp.now(),
          });
        } else {
          // New user, create profile
          final newUserRef = _firestore.collection('users').doc();
          userProfile = UserProfile(
            id: newUserRef.id,
            name: name,
            email: email!,
            phone: null,
            profileImageUrl: photoUrl,
            totalListings: 0,
            activeListings: 0,
            joinDate: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            isVerified: false,
            isAdmin: false,
          );

          // Store user in Firestore
          await _storeUserInFirestore(userProfile);
        }

        // Generate session token
        final sessionToken = _generateSessionToken(email);

        // Save session
        await _saveUserSession(userProfile, sessionToken);

        // Update state
        _currentUser = userProfile;
        _sessionToken = sessionToken;
        _isLoggedIn = true;

        notifyListeners();
        AppRouter.refresh();

        if (kDebugMode) {
          debugPrint('✅ Google Sign-In successful');
        }

        return true;
      } else {
        // For mobile platforms, similar flow but might use different auth
        throw UnimplementedError('Google Sign-In for mobile not fully implemented');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Google Sign-In error: $e');
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update user profile
  Future<bool> updateProfile({
    required String name,
    String? phone,
    String? profileImageUrl,
  }) async {
    _setLoading(true);
    
    try {
      if (_currentUser == null) {
        throw AuthException('No user logged in');
      }

      // Update user in Firestore
      final userData = <String, dynamic>{
        'name': name,
        'updatedAt': Timestamp.now(),
      };

      if (phone != null) {
        userData['phone'] = phone;
      }

      if (profileImageUrl != null) {
        userData['profileImageUrl'] = profileImageUrl;
      }

      await _firestore
          .collection('users')
          .doc(_currentUser!.id)
          .update(userData);

      // Update local user profile
      _currentUser = _currentUser!.copyWith(
        name: name,
        phone: phone ?? _currentUser!.phone,
        profileImageUrl: profileImageUrl ?? _currentUser!.profileImageUrl,
      );

      // Update stored session
      if (_sessionToken != null) {
        await _saveUserSession(_currentUser!, _sessionToken!);
      }

      notifyListeners();

      if (kDebugMode) {
        debugPrint('✅ Profile updated successfully');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error updating profile: $e');
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }
}

/// Custom exception for authentication errors
class AuthException implements Exception {
  final String message;
  
  AuthException(this.message);
  
  @override
  String toString() => 'AuthException: $message';
}