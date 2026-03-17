import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import '../models/user_profile.dart';
import '../firebase_options.dart';
import '../app/app_router.dart';
import '../config/firebase_config.dart';

class AuthService extends ChangeNotifier {
  // Firestore instance for user data storage
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Firebase Auth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
  static const String _verificationIdKey = 'pending_verification_id';
  static const String _verificationPhoneKey = 'pending_verification_phone';
  static const String _isTestModeKey = 'pending_is_test_mode';
  static const String _pendingNameKey = 'pending_user_name';
  static const String _pendingEmailKey = 'pending_user_email';
  static const String _pendingUidKey = 'pending_user_uid';

  UserProfile? _currentUser;
  String? _sessionToken;
  bool _isLoggedIn = false;
  bool _isLoading = false;



  String? _verificationId;
  DateTime? _lastEmailSentTime;

  // Getters
  UserProfile? get currentUser => _currentUser;
  String? get sessionToken => _sessionToken;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;

  AuthService() {
    _initializeAuth();
  }

  /// Check if current user is a Google user based on Firebase provider info
  bool _checkIfGoogleUser() {
    final user = _auth.currentUser;
    if (user == null) return false;
    return user.providerData.any((info) => info.providerId == 'google.com');
  }

  /// Initialize authentication state from stored data
  Future<void> _initializeAuth() async {
    _setLoading(true);
    
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      // 1. Try to restore active session
      bool sessionRestored = false;
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
              profileImageUrl: null,
              isGoogleUser: _checkIfGoogleUser(),
              totalListings: 0,
              activeListings: 0,
              joinDate: DateTime.now(),
              createdAt: DateTime.now().subtract(const Duration(days: 30)),
              updatedAt: DateTime.now(),
              isVerified: true,
              isAdmin: false,
            );
            _sessionToken = token;
            _isLoggedIn = true;
            sessionRestored = true;
            _refreshUserFromFirestore();
            
            // Sync with SDK if not already signed in (don't await to avoid slowing startup)
            if (_auth.currentUser == null) {
              debugPrint('ℹ️ AuthService: Syncing restored session with SDK');
              // We can't easily sync without password, but if they are already signed into SDK, we're good.
              // If not, we'll try to sync during the next authenticated action or wait for next login.
            }
          }
        } catch (e) {
          debugPrint('⚠️ AuthService: Secure storage failed: $e');
        }
      }
      
      if (!sessionRestored) {
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
              profileImageUrl: null,
              isGoogleUser: _checkIfGoogleUser(),
              totalListings: 0,
              activeListings: 0,
              joinDate: DateTime.now(),
              createdAt: DateTime.now().subtract(const Duration(days: 30)),
              updatedAt: DateTime.now(),
              isVerified: true,
              isAdmin: false,
            );
            _sessionToken = token;
            _isLoggedIn = true;
            _refreshUserFromFirestore();

            // Sync with SDK if not already signed in
            if (_auth.currentUser == null) {
              debugPrint('ℹ️ AuthService: Syncing restored session with SDK (prefs)');
            }
          }
        }
      }

      // 4. Cleanup old pending profile data since OTP is removed
      await prefs.remove(_pendingUidKey);
      await prefs.remove(_pendingNameKey);
      await prefs.remove(_pendingEmailKey);
      await prefs.remove(_verificationIdKey);
      await prefs.remove(_verificationPhoneKey);
      await prefs.remove(_isTestModeKey);

    } catch (e) {
      debugPrint('Error initializing auth: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Clear error state (placeholder for consistent API)
  void _clearError() {
    // Current AuthService doesn't keep a dedicated error string state,
    // but the Provider/UI expects this method to exist if called.
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
        debugPrint('ℹ️ AuthService: lookupPhone for $identifier (Key: ${DefaultFirebaseOptions.currentPlatform.apiKey.substring(0,5)}...)');
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

      // Use Firebase REST API for all other users
      final apiKey = DefaultFirebaseOptions.currentPlatform.apiKey;
      if (kDebugMode) {
        debugPrint('ℹ️ AuthService: Login attempt (REST) with key end: ...${apiKey.substring(max(0, apiKey.length - 5))}');
      }
      final signInUrl = 'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$apiKey';
      
      final response = await http.post(
        Uri.parse(signInUrl),
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
            coverImageUrl: userData['coverImageUrl'],
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
            isRealEstateOffice: userData['isRealEstateOffice'] ?? false,
            isGoogleUser: _checkIfGoogleUser() || (userData['isGoogleUser'] ?? false),
            propertyLimit: (userData['propertyLimit'] as num?)?.toInt() ?? 3,
            postingCredits: (userData['postingCredits'] as num?)?.toInt() ?? 0,
            freeTierResetDate: userData['freeTierResetDate'] != null 
                ? (userData['freeTierResetDate'] as Timestamp).toDate()
                : null,
          );

          if (kDebugMode) {
            debugPrint('✅ Login - User Profile Loaded:');
            debugPrint('   isRealEstateOffice: ${userProfile.isRealEstateOffice}');
            debugPrint('   propertyLimit: ${userProfile.propertyLimit}');
          }

          // Save to local storage
          await _saveUserSession(userProfile, idToken);

          // Update state
          _currentUser = userProfile;
          _sessionToken = idToken;
          _isLoggedIn = true;

          // Sync with Firebase Auth SDK to enable token refresh
          try {
            if (_auth.currentUser?.uid != firebaseUid) {
              debugPrint('ℹ️ AuthService: Syncing with SDK for $email');
              await _auth.signInWithEmailAndPassword(email: email.toLowerCase(), password: password);
              debugPrint('✅ AuthService: SDK Sync successful');
            } else {
              debugPrint('ℹ️ AuthService: SDK already synced for $email');
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint('⚠️ AuthService: SDK Sync during login failed: $e');
            }
            // We don't throw here because REST login succeeded
          }

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

      // Check if phone number is available
      final normalizedPhone = _normalizePhone(phone);
      final firebasePhone = _formatPhoneForFirebase(phone);
      final isAvailable = await isPhoneAvailable(normalizedPhone);
      if (!isAvailable) {
        throw AuthException('This phone number is already registered. Please use a different one.');
      }

      // Create user in Firebase Auth using REST API
      final firebaseApiKey = DefaultFirebaseOptions.currentPlatform.apiKey;
      final signUpUrl = Uri.parse(
          'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$firebaseApiKey');

      final response = await http.post(
        signUpUrl,
        body: jsonEncode({
          'email': email.toLowerCase(),
          'password': password,
          'returnSecureToken': true,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      String? firebaseUid;
      String? idToken;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        firebaseUid = data['localId'];
        idToken = data['idToken'];
      } else {
        final error = jsonDecode(response.body);
        final message = error['error']?['message'] ?? 'Registration failed';
        
        if (message == 'EMAIL_EXISTS') {
           if (kDebugMode) {
             debugPrint('ℹ️ AuthService: Email exists, attempting to sign in and proceed.');
           }
           try {
             final authResult = await _auth.signInWithEmailAndPassword(email: email, password: password);
             firebaseUid = authResult.user?.uid;
             idToken = await authResult.user?.getIdToken();
             if (firebaseUid == null) throw AuthException('EMAIL_EXISTS');
           } catch (e) {
             if (kDebugMode) {
               debugPrint('❌ AuthService: Failed to sign in existing user: $e');
             }
             throw AuthException('EMAIL_EXISTS');
           }
        } else {
          if (kDebugMode) {
            debugPrint('❌ Firebase Auth Registration Failed: ${response.statusCode} - ${response.body}');
          }
          throw AuthException(message);
        }
      }

      if (firebaseUid == null) {
        throw AuthException('Could not retrieve user ID. Please try again.');
      }

      // Prepare profile data
      final now = DateTime.now();
      final userProfile = UserProfile(
        id: firebaseUid,
        name: name,
        email: email.toLowerCase(),
        phone: firebasePhone,
        totalListings: 0,
        activeListings: 0,
        joinDate: now,
        createdAt: now,
        updatedAt: now,
        isVerified: false, // User must verify profile later
        isAdmin: false,
        isRealEstateOffice: false,
        isGoogleUser: _checkIfGoogleUser(),
        propertyLimit: 3,
        postingCredits: 3, // Give new users 3 free posting points
        freeTierResetDate: null,
      );

      // Store user profile in Firestore
      await _storeUserInFirestore(userProfile);
      
      // Save session
      await _saveUserSession(userProfile, idToken ?? '');
      
      // Update state
      _currentUser = userProfile;
      _sessionToken = idToken;
      _isLoggedIn = true;

      // Sync with Firebase Auth SDK to enable token refresh
      try {
        if (_auth.currentUser?.uid != firebaseUid) {
          debugPrint('ℹ️ AuthService: Syncing with SDK for new user $email');
          await _auth.signInWithEmailAndPassword(email: email.toLowerCase(), password: password);
          debugPrint('✅ AuthService: SDK Sync successful');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ AuthService: SDK Sync during registration failed: $e');
        }
      }

      // Send verification email automatically upon registration
      if (idToken != null) {
        try {
          await sendEmailVerification(idToken);
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ AuthService: Failed to send initial verification email: $e');
          }
          // Don't throw - user is already registered and can resend later
        }
      }

      return userProfile;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Firebase Auth registration error details: $e');
      }
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Helper to format phone number for Firebase (E.164)
  String _formatPhoneForFirebase(String phone) {
    if (phone.isEmpty) return phone;
    
    // If it already starts with +, assume user provided full E.164
    if (phone.startsWith('+')) return phone;
    
    // Normalize to digits only for analysis
    String digits = phone.replaceAll(RegExp(r'\D'), '');
    
    // 1. Recognize US/Canada Test Numbers (11 digits starting with 1, or 10 digits that look like test)
    if ((digits.length == 11 && digits.startsWith('1')) || 
        (digits.length == 10 && digits.contains('555'))) {
      return digits.startsWith('1') ? '+$digits' : '+1$digits';
    }
    
    // 2. Recognize existing international numbers (11+ digits)
    if (digits.length >= 11) {
      // If it already starts with 218, just add +
      if (digits.startsWith('218')) return '+$digits';
      // Otherwise assume it's already a full international number (like US or other)
      return '+$digits';
    }
    
    // 3. Handle local Libyan numbers
    // Case 09x... -> remove 0 and add +218
    if (digits.startsWith('0')) {
      return '+218${digits.substring(1)}';
    }
    
    // Default: assume local Libyan number
    return '+218$digits';
  }

  /// Store user data in Firestore
  Future<void> _storeUserInFirestore(UserProfile user) async {
    try {
      final userData = {
        'name': user.name,
        'email': user.email,
        'phone': user.phone,
        'profileImageUrl': user.profileImageUrl,
        'coverImageUrl': user.coverImageUrl,
        'totalListings': user.totalListings,
        'activeListings': user.activeListings,
        'isVerified': user.isVerified,
        'isAdmin': user.isAdmin,
        'isRealEstateOffice': user.isRealEstateOffice,
        'isGoogleUser': user.isGoogleUser,
        'propertyLimit': user.propertyLimit,
        'postingCredits': user.postingCredits,
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
      
      // Sign out from SDK
      try {
        await _auth.signOut();
        final GoogleSignIn googleSignIn = GoogleSignIn();
        if (await googleSignIn.isSignedIn()) {
          await googleSignIn.signOut();
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ AuthService: SDK Sign out failed: $e');
        }
      }
      
      notifyListeners();
      AppRouter.refresh();
      
    } catch (e) {
      debugPrint('Logout error: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Get current user (loads from Firestore to get latest data including office status)
  Future<UserProfile?> getCurrentUser() async {
    if (_currentUser != null) {
      // Try to refresh from Firestore to get latest status (async, non-blocking)
      _refreshUserFromFirestore();
      return _currentUser;
    }
    
    // Try to load from SharedPreferences if not already loaded
    await _initializeAuth();
    
    // After loading from storage, also fetch latest from Firestore
    if (_currentUser != null) {
      await _refreshUserFromFirestore();
    }
    
    return _currentUser;
  }
  
  /// Refresh current user from Firestore (helper method)
  Future<void> _refreshUserFromFirestore() async {
    if (_currentUser == null) return;
    
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(_currentUser!.id)
          .get();
      
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        _currentUser = UserProfile(
          id: _currentUser!.id,
          name: userData['name'] ?? _currentUser!.name,
          email: userData['email'] ?? _currentUser!.email,
          phone: userData['phone'] ?? _currentUser!.phone,
          profileImageUrl: userData['profileImageUrl'] ?? _currentUser!.profileImageUrl,
          coverImageUrl: userData['coverImageUrl'] ?? _currentUser!.coverImageUrl,
          totalListings: userData['totalListings'] ?? _currentUser!.totalListings,
          activeListings: userData['activeListings'] ?? _currentUser!.activeListings,
          joinDate: userData['createdAt'] != null 
              ? (userData['createdAt'] as Timestamp).toDate()
              : _currentUser!.joinDate,
          createdAt: userData['createdAt'] != null 
              ? (userData['createdAt'] as Timestamp).toDate()
              : _currentUser!.createdAt,
          updatedAt: DateTime.now(),
          isVerified: userData['isVerified'] ?? _currentUser!.isVerified,
          isAdmin: userData['isAdmin'] ?? _currentUser!.isAdmin,
          isRealEstateOffice: userData['isRealEstateOffice'] ?? false,
          isGoogleUser: _checkIfGoogleUser() || (userData['isGoogleUser'] ?? false),
          propertyLimit: (userData['propertyLimit'] as num?)?.toInt() ?? _currentUser!.propertyLimit,
          postingCredits: (userData['postingCredits'] as num?)?.toInt() ?? 0,
          freeTierResetDate: userData['freeTierResetDate'] != null 
              ? (userData['freeTierResetDate'] as Timestamp).toDate()
              : _currentUser!.freeTierResetDate,
        );
        // Check verification status if we have a token
        if (_sessionToken != null) {
          await checkEmailVerification(_sessionToken!);
        }

        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to refresh user from Firestore: $e');
      }
    }
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

  /// Get a fresh ID token, refreshing if necessary
  Future<String?> getFreshToken() async {
    try {
      if (_auth.currentUser != null) {
        final token = await _auth.currentUser!.getIdToken(true);
        if (token != null) {
          _sessionToken = token;
          return token;
        }
      }
      return _sessionToken;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ AuthService: Failed to get fresh token: $e');
      }
      return _sessionToken;
    }
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

  /// Refresh user data from Firestore
  Future<void> refreshUser() async {
    if (_currentUser == null) return;
    
    _setLoading(true);
    
    try {
      // Load fresh user data from Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(_currentUser!.id)
          .get();
      
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        _currentUser = UserProfile(
          id: _currentUser!.id,
          name: userData['name'] ?? _currentUser!.name,
          email: userData['email'] ?? _currentUser!.email,
          phone: userData['phone'] ?? _currentUser!.phone,
          profileImageUrl: userData['profileImageUrl'] ?? _currentUser!.profileImageUrl,
          coverImageUrl: userData['coverImageUrl'] ?? _currentUser!.coverImageUrl,
          totalListings: userData['totalListings'] ?? _currentUser!.totalListings,
          activeListings: userData['activeListings'] ?? _currentUser!.activeListings,
          joinDate: userData['createdAt'] != null 
              ? (userData['createdAt'] as Timestamp).toDate()
              : _currentUser!.joinDate,
          createdAt: userData['createdAt'] != null 
              ? (userData['createdAt'] as Timestamp).toDate()
              : _currentUser!.createdAt,
          updatedAt: DateTime.now(),
          isVerified: userData['isVerified'] ?? _currentUser!.isVerified,
          isAdmin: userData['isAdmin'] ?? _currentUser!.isAdmin,
          isRealEstateOffice: userData['isRealEstateOffice'] ?? false,
          propertyLimit: (userData['propertyLimit'] as num?)?.toInt() ?? _currentUser!.propertyLimit,
          postingCredits: (userData['postingCredits'] as num?)?.toInt() ?? 0,
          freeTierResetDate: userData['freeTierResetDate'] != null 
              ? (userData['freeTierResetDate'] as Timestamp).toDate()
              : _currentUser!.freeTierResetDate,
        );
        
        if (kDebugMode) {
          debugPrint('✅ User data refreshed from Firestore:');
          debugPrint('   isRealEstateOffice: ${_currentUser!.isRealEstateOffice}');
          debugPrint('   propertyLimit: ${_currentUser!.propertyLimit}');
        }
        
        // Save updated session
        await _saveUserSession(_currentUser!, _sessionToken ?? '');
        notifyListeners();
        AppRouter.refresh();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Refresh user error: $e');
      }
    } finally {
      _setLoading(false);
    }
  }




  /// Verify user (update verification status)
  Future<void> verifyUser(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userDoc = querySnapshot.docs.first;
        await _firestore.collection('users').doc(userDoc.id).update({
          'isVerified': true,
          'updatedAt': Timestamp.now(),
        });
        
        if (_currentUser != null && _currentUser!.email == email.toLowerCase()) {
          _currentUser = _currentUser!.copyWith(isVerified: true);
          notifyListeners();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ AuthService: Failed to verify user: $e');
      }
      rethrow;
    }
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    
    try {
      if (kIsWeb) {
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
            email: email,
            phone: userData['phone'],
            profileImageUrl: photoUrl ?? userData['profileImageUrl'],
            coverImageUrl: userData['coverImageUrl'],
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
            isRealEstateOffice: userData['isRealEstateOffice'] ?? false,
            isGoogleUser: true,
            propertyLimit: (userData['propertyLimit'] as num?)?.toInt() ?? 5,
            postingCredits: (userData['postingCredits'] as num?)?.toInt() ?? 0,
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
            email: email,
            phone: null,
            profileImageUrl: photoUrl,
            coverImageUrl: null,
            totalListings: 0,
            activeListings: 0,
            joinDate: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            isVerified: false,
            isAdmin: false,
            isRealEstateOffice: false,
            isGoogleUser: true,
            propertyLimit: 5,
            postingCredits: 3, // Give new users 3 free posting points
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
          debugPrint('✅ Google Sign-In successful (Web)');
        }

        return true;
      } else {
        // Mobile platform implementation
        final GoogleSignIn googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
        );

        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser == null) return false;

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        
        // Sign in to Firebase with the credential
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final UserCredential firebaseResult = await _auth.signInWithCredential(credential);
        final User? firebaseUser = firebaseResult.user;

        if (firebaseUser == null) throw AuthException('Firebase Sign-In failed');

        // Check if user exists in Firestore
        final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();
        
        UserProfile userProfile;
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          userProfile = UserProfile(
            id: firebaseUser.uid,
            name: userData['name'] ?? firebaseUser.displayName ?? 'User',
            email: firebaseUser.email ?? '',
            phone: userData['phone'],
            profileImageUrl: firebaseUser.photoURL ?? userData['profileImageUrl'],
            coverImageUrl: userData['coverImageUrl'],
            totalListings: userData['totalListings'] ?? 0,
            activeListings: userData['activeListings'] ?? 0,
            joinDate: userData['createdAt'] != null 
                ? (userData['createdAt'] as Timestamp).toDate()
                : DateTime.now(),
            createdAt: userData['createdAt'] != null 
                ? (userData['createdAt'] as Timestamp).toDate()
                : DateTime.now(),
            updatedAt: DateTime.now(),
            isVerified: userData['isVerified'] ?? firebaseUser.emailVerified,
            isAdmin: userData['isAdmin'] ?? false,
            isRealEstateOffice: userData['isRealEstateOffice'] ?? false,
            isGoogleUser: true,
            propertyLimit: (userData['propertyLimit'] as num?)?.toInt() ?? 3,
            postingCredits: (userData['postingCredits'] as num?)?.toInt() ?? 0,
            freeTierResetDate: userData['freeTierResetDate'] != null 
                ? (userData['freeTierResetDate'] as Timestamp).toDate()
                : null,
          );
        } else {
          // New user
          userProfile = UserProfile(
            id: firebaseUser.uid,
            name: firebaseUser.displayName ?? 'User',
            email: firebaseUser.email ?? '',
            phone: null,
            profileImageUrl: firebaseUser.photoURL,
            coverImageUrl: null,
            totalListings: 0,
            activeListings: 0,
            joinDate: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            isVerified: firebaseUser.emailVerified,
            isAdmin: false,
            isRealEstateOffice: false,
            isGoogleUser: true,
            propertyLimit: 3,
            postingCredits: 3, // Give new users 3 free posting points
          );
          await _storeUserInFirestore(userProfile);
        }

        final idToken = await firebaseUser.getIdToken();
        await _saveUserSession(userProfile, idToken ?? '');

        _currentUser = userProfile;
        _sessionToken = idToken;
        _isLoggedIn = true;

        notifyListeners();
        AppRouter.refresh();

        if (kDebugMode) {
          debugPrint('✅ Google Sign-In successful (Mobile)');
        }
        
        return true;
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
    String? coverImageUrl,
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

      if (coverImageUrl != null) {
        userData['coverImageUrl'] = coverImageUrl;
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
        coverImageUrl: coverImageUrl ?? _currentUser!.coverImageUrl,
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
  
  /// Send password reset email
  Future<void> resetPassword(String email) async {
    _setLoading(true);
    
    try {
      final response = await http.post(
        Uri.parse(FirebaseConfig.resetPasswordUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'requestType': 'PASSWORD_RESET',
          'email': email.toLowerCase(),
        }),
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw AuthException(error['error']['message'] ?? 'Failed to send reset email');
      }
      
      if (kDebugMode) {
        debugPrint('✅ Password reset email sent to $email');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Password reset error: $e');
      }
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Send email verification
  Future<void> sendEmailVerification([String? idToken]) async {
    // 1. Check if it's a mock token first (useful for admin@dary.com)
    final tokenToUse = idToken ?? _sessionToken;
    if (tokenToUse != null && tokenToUse.startsWith('token_')) {
      debugPrint('ℹ️ Mock AuthService: Simulating verification email for mock user');
      _lastEmailSentTime = DateTime.now();
      return;
    }

    // 2. Try SDK if user is signed in to SDK - most reliable and handles refresh
    if (_auth.currentUser != null) {
      try {
        debugPrint('ℹ️ AuthService: Attempting SDK email verification for ${_auth.currentUser!.email}');
        await _auth.currentUser!.sendEmailVerification();
        _lastEmailSentTime = DateTime.now();
        if (kDebugMode) {
          debugPrint('✅ Verification email sent via SDK');
        }
        return;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ AuthService: SDK sendEmailVerification error: $e');
        }
        // Fall back to REST if SDK fails
      }
    }

    // 3. Fallback to REST API
    final token = idToken ?? await getFreshToken();
    
    if (token == null) {
      debugPrint('❌ AuthService: No token available for verification email');
      throw AuthException('No authentication token available');
    }

    // Basic JWT validation check
    if (!token.contains('.') || token.length < 50) {
      debugPrint('❌ AuthService: Invalid token format detected: Token is too short or not a JWT');
      throw AuthException('Your session has expired. Please log out and log back in.');
    }

    final apiKey = DefaultFirebaseOptions.currentPlatform.apiKey;
    if (kDebugMode) {
      debugPrint('ℹ️ AuthService: Using REST API for verification email (Key end: ...${apiKey.substring(max(0, apiKey.length - 5))})');
      debugPrint('ℹ️ AuthService: Token start: ${token.substring(0, min(15, token.length))} (Length: ${token.length})');
      if (_auth.currentUser == null) {
        debugPrint('⚠️ AuthService: SDK user is still NULL during verification');
      }
    }

    // Prevent sending too frequently (e.g., once every 30 seconds)
    if (_lastEmailSentTime != null && 
        DateTime.now().difference(_lastEmailSentTime!).inSeconds < 30) {
      debugPrint('ℹ️ Skipping email verification: Sent too recently');
      return;
    }

    try {
      final verifyUrl = 'https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key=$apiKey';
      final response = await http.post(
        Uri.parse(verifyUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'requestType': 'VERIFY_EMAIL',
          'idToken': token,
        }),
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        final message = error['error']?['message'] ?? 'Failed to send verification email';
        debugPrint('⚠️ Failed to send verification email: $message');
        
        if (message == 'TOO_MANY_ATTEMPTS_TRY_LATER') {
          throw AuthException('Too many attempts. Please try again later.');
        }
        throw AuthException(message);
      } else {
        _lastEmailSentTime = DateTime.now();
        if (kDebugMode) {
          debugPrint('✅ Verification email sent');
        }
      }
    } catch (e) {
      debugPrint('❌ Error sending verification email: $e');
      rethrow;
    }
  }

  /// Check if phone number is already in use
  Future<bool> isPhoneAvailable(String phone) async {
    final normalized = _normalizePhone(phone);
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('phone', isEqualTo: normalized)
          .limit(1)
          .get();
      return snapshot.docs.isEmpty;
    } catch (e) {
      debugPrint('❌ Error checking phone availability: $e');
      return false; // Assume not available on error to be safe
    }
  }

  /// Delete account fully with optional password confirmation (for normal users)
  /// Google users can re-authenticate by choosing Google again.
  Future<void> deleteAccount({String? password}) async {
    if (_currentUser == null) {
      throw AuthException('You must be logged in to delete your account');
    }

    try {
      _setLoading(true);
      String? freshIdToken;

      if (_currentUser!.isGoogleUser) {
        // 1a. Re-authenticate Google user
        final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser == null) throw AuthException('Authentication cancelled');

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final UserCredential firebaseResult = await _auth.currentUser!.reauthenticateWithCredential(credential);
        freshIdToken = await firebaseResult.user?.getIdToken();
      } else {
        // 1b. Re-authenticate normal user with password
        if (password == null || password.isEmpty) {
          throw AuthException('Password is required to delete this account');
        }

        final authResponse = await http.post(
          Uri.parse(FirebaseConfig.signInUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': _currentUser!.email,
            'password': password,
            'returnSecureToken': true,
          }),
        );

        if (authResponse.statusCode != 200) {
          throw AuthException('Incorrect password. Please try again.');
        }

        final authData = jsonDecode(authResponse.body);
        freshIdToken = authData['idToken'];
      }

      if (freshIdToken == null) throw AuthException('Failed to obtain fresh authentication token');
      final uid = _currentUser!.id;

      // 2. Delete all user properties
      final propertiesSnapshot = await _firestore
          .collection('properties')
          .where('userId', isEqualTo: uid)
          .get();
      
      final batch = _firestore.batch();
      for (var doc in propertiesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // 3. Delete wallet and transactions
      final transactionsSnapshot = await _firestore
          .collection('wallet')
          .doc(uid)
          .collection('transactions')
          .get();
      
      for (var doc in transactionsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(_firestore.collection('wallet').doc(uid));

      // 4. Delete user document
      batch.delete(_firestore.collection('users').doc(uid));

      // 5. Execute Firestore deletions
      await batch.commit();

      // 6. Delete from Firebase Auth
      final deleteResponse = await http.post(
        Uri.parse(FirebaseConfig.deleteAccountUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idToken': freshIdToken,
        }),
      );


      if (deleteResponse.statusCode != 200) {
        final error = jsonDecode(deleteResponse.body);
        debugPrint('⚠️ Auth deletion partial failure: ${error['error']['message']}');
      }

      // 7. Clear local session
      await logout();

    } catch (e) {
      debugPrint('❌ Error deleting account: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Check if email is verified using Firebase REST API
  Future<bool> checkEmailVerification(String idToken) async {
    try {
      final response = await http.post(
        Uri.parse(FirebaseConfig.getUserUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idToken': idToken,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final users = data['users'] as List;
        if (users.isNotEmpty) {
          final isVerified = users[0]['emailVerified'] as bool? ?? false;
          
          // Update Firestore if verification status changed
          if (_currentUser != null && _currentUser!.isVerified != isVerified) {
            await _firestore.collection('users').doc(_currentUser!.id).update({
              'isVerified': isVerified,
              'updatedAt': Timestamp.now(),
            });
            _currentUser = _currentUser!.copyWith(isVerified: isVerified);
            notifyListeners();
          }
          return isVerified;
        }
      }
    } catch (e) {
      debugPrint('❌ Error checking email verification: $e');
    }
    return false;
  }



  /// Normalize phone number to consistent format (remove leading 0 and country code)
  String _normalizePhone(String phone) {
    // Remove all non-digits
    String digits = phone.replaceAll(RegExp(r'\D'), '');
    
    // Handle international prefix +218 etc
    if (digits.startsWith('218')) {
      digits = digits.substring(3);
    }
    
    // Remove leading zero if present
    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    
    return digits;
  }
}

/// Custom exception for authentication errors
class AuthException implements Exception {
  final String message;
  
  AuthException(this.message);
  
  @override
  String toString() => 'AuthException: $message';
}