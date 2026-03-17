import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' as scheduler;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_localizations.dart';
import 'dart:async';
import 'dart:convert';
import '../models/property.dart';
import '../models/saved_search.dart';
import '../services/saved_search_service.dart';
import '../models/notification.dart';
import '../models/user_profile.dart';
import '../services/property_service.dart' as property_service;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_installations/firebase_app_installations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

/// Push & Local Notification Service
/// 
/// Handles local notifications, property listing notifications, and FCM push notifications.
class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final Completer<String?> _tokenCompleter = Completer<String?>();
  Future<String?> get fcmTokenAsync => _tokenCompleter.future;

  // Services
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final SavedSearchService _savedSearchService = SavedSearchService();

  // Storage keys
  // State
  bool _notificationsEnabled = true;
  bool _permissionGranted = false;
  DateTime? _lastCheckTime;
  Timer? _checkTimer;
  BuildContext? _context;
  List<DaryNotification> _notifications = [];
  bool _isInitialized = false;
  String? _fcmToken;

  /// Arabic engagement messages for daily notifications
  final List<Map<String, String>> _arabicMessages = [
    {
      'title': 'اكتشف عقارات جديدة اليوم! 🏠',
      'body': 'هل تبحث عن منزل أحلامك؟ تصفح أحدث العروض الحصرية الآن في منطقتك.'
    },
    {
      'title': 'فرص استثمارية لا تعوض 📈',
      'body': 'عقارات مميزة تمت إضافتها للتو. كن أول من يطلع عليها ويقتنص الفرصة.'
    },
    {
      'title': 'هل فكرت في تجديد إعلانك؟ ✨',
      'body': 'اجعل عقارك في المقدمة واحصل على مشاهدات أكثر وتواصل أسرع مع المهتمين.'
    },
    {
      'title': 'نصيحة داري العقارية 💡',
      'body': 'العقارات ذات الأوصاف التفصيلية والصور الواضحة تحصل على تفاعل أكبر بنسبة 40%.'
    },
    {
      'title': 'تحديثات مباشرة لك 🔔',
      'body': 'تحقق من الرسائل الجديدة وتواصل مباشرة مع البائعين والمشترين.'
    },
  ];

  // Storage keys
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _lastCheckTimeKey = 'last_property_check_time';
  static const String _inAppNotificationsKey = 'in_app_notifications';

  // Getters
  bool get notificationsEnabled => _notificationsEnabled;
  bool get permissionGranted => _permissionGranted;
  DateTime? get lastCheckTime => _lastCheckTime;
  List<DaryNotification> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get isInitialized => _isInitialized;
  String? get fcmToken => _fcmToken;

  bool _isInitializing = false;

  /// Initialize the notification service
  Future<void> initialize(BuildContext context) async {
    if (_isInitialized || _isInitializing) return;
    _isInitializing = true;
    _context = context;
    
    try {
      // Initialize timezone data
      tz.initializeTimeZones();
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));

      // Initialize local notifications
      await _initializeLocalNotifications();
      
      // Request permissions
      await _requestPermissions();
      
      // Load settings
      await _loadSettings();
      
      // Initialize FCM in background so it doesn't slow down app startup on slow connections
      _initializeFCM().catchError((e) {
        if (kDebugMode) {
          debugPrint('❌ FCM Initialization error in background: $e');
        }
      });
      
      // Load in-app notifications
      await _loadInAppNotifications();
      
      // Start periodic property checking
      _startPeriodicPropertyCheck();
      
      // Schedule daily engagement notifications
      scheduleDailyNotifications();
      
      _isInitialized = true;
      _isInitializing = false;
      _notifySafely();
      
      if (kDebugMode) {
        debugPrint('🔔 NotificationService initialized successfully');
        debugPrint('🔔 FCM Token: $_fcmToken');
        debugPrint('🔔 Notifications enabled: $_notificationsEnabled');
        debugPrint('🔔 Permission granted: $_permissionGranted');
        debugPrint('🔔 Loaded ${_notifications.length} in-app notifications');
      }
    } catch (e) {
      _isInitializing = false;
      if (kDebugMode) {
        debugPrint('❌ NotificationService initialization error: $e');
      }
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    // flutter_local_notifications does not support web
    if (kIsWeb) return;

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    // Permission handler and local notifications don't support web
    if (kIsWeb) {
      _permissionGranted = true; // treat web as always granted for in-app notifications
      return;
    }
    try {
      // Request FCM permission
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      _permissionGranted = settings.authorizationStatus == AuthorizationStatus.authorized ||
                          settings.authorizationStatus == AuthorizationStatus.provisional;

      if (kDebugMode) {
        debugPrint('🔔 FCM Authorization: ${settings.authorizationStatus}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Permission request error: $e');
      }
    }
  }

  /// Initialize Firebase Cloud Messaging
  Future<void> _initializeFCM() async {
    if (kIsWeb) return;

    try {
      final messaging = FirebaseMessaging.instance;

      // ON iOS, we MUST wait for the APNs token before getting the FCM token
      // otherwise they won't be linked in the Firebase console!
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        debugPrint('🍎 Waiting for APNs token...');
        String? apnsToken;
        int retryCount = 0;
        
        // Wait up to 10 seconds for APNs token
        while (apnsToken == null && retryCount < 20) {
          apnsToken = await messaging.getAPNSToken();
          if (apnsToken == null) {
            await Future.delayed(const Duration(milliseconds: 500));
            retryCount++;
          }
        }
        
        if (apnsToken != null) {
          debugPrint('✅ APNs token obtained: $apnsToken');
        } else {
          debugPrint('⚠️ WARNING: Timeout waiting for APNs token. FCM linkage may fail!');
        }
      }

      // Force fresh FCM token registration to ensure APNs is linked on Firebase's servers.
      // A cached token may not have the APNs mapping if network failed during previous registration.
      try {
        debugPrint('🗑️ Deleting cached FCM token to force fresh registration...');
        await messaging.deleteToken();
        debugPrint('✅ Old token deleted. Requesting fresh token...');
      } catch (e) {
        debugPrint('⚠️ deleteToken failed (OK on first run): $e');
      }

      // Now get fresh FCM token — this time with APNs correctly linked
      _fcmToken = await messaging.getToken();
      debugPrint('🔔 NEW FCM Token (Generated): $_fcmToken');
      
      // Complete the future so waiting callers can proceed
      if (!_tokenCompleter.isCompleted) {
        _tokenCompleter.complete(_fcmToken);
      }

      // 🔄 CRITICAL: Update Firestore immediately if a user is already logged in
      // This fixes the 'NotRegistered' error by ensuring token is synced on startup
      try {
        final prefs = await SharedPreferences.getInstance();
        
        // Use a more reliable way to get UID
        String? userId;
        try {
          userId = FirebaseAuth.instance.currentUser?.uid;
        } catch (e) {
          debugPrint('ℹ️ FirebaseAuth not yet available, falling back to prefs');
        }
        
        userId ??= prefs.getString('user_id') ?? 
                  prefs.getString('current_user_id');
                       
        if (userId != null && _fcmToken != null) {
          debugPrint('🔄 Token sync: Updating Firestore for user $userId');
          await updateFCMToken(userId);
        } else {
          debugPrint('⚠️ Token sync deferred: userId ($userId) or token ($_fcmToken) missing');
        }
      } catch (e) {
        debugPrint('⚠️ Failed to auto-sync token: $e');
      }

      // Debugging the linkage
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final apnsToken = await messaging.getAPNSToken();
        // Get Installation ID (needed for some Firebase console sections)
        final installationId = await FirebaseInstallations.instance.getId();
        
        if (kDebugMode) {
          debugPrint('***************************************');
          debugPrint('🍎 APNs Device Token: $apnsToken');
          debugPrint('🆔 Firebase Installation ID: $installationId');
          debugPrint('🔔 FCM Token: $_fcmToken');
          if (apnsToken == null) {
            debugPrint('⚠️ CRITICAL: APNs token is NULL! Firebase CANNOT send notifications.');
          } else {
            debugPrint('✅ APNs token is linked to FCM.');
          }
          debugPrint('***************************************');
        }
      }
      
      // Subscribe to a test topic
      try {
        debugPrint('📡 Attempting to subscribe to "all" topic...');
        await messaging.subscribeToTopic('all').timeout(const Duration(seconds: 10));
        if (kDebugMode) {
          debugPrint('✅ Subscribed to "all" topic successfully');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ FAILED to subscribe to "all" topic: $e');
          debugPrint('💡 This usually means your network is blocking Google/Firebase registration traffic.');
        }
      }
      
      // Perform a quick connectivity diagnostic to Google (Disabled to reduce log spam & slow downs)
      // _runConnectivityDiagnostic();
      
      // Handle foreground messages
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          debugPrint('***************************************');
          debugPrint('🚀🚀� SIGNAL DETECTED! FCM MESSAGE RECEIVED 🚀🚀🚀');
          debugPrint('Title: ${message.notification?.title}');
          debugPrint('Body: ${message.notification?.body}');
          debugPrint('Data: ${message.data}');
          debugPrint('Message ID: ${message.messageId}');
          debugPrint('***************************************');
        }
        
        if (message.notification != null) {
          _showLocalNotification(
            title: message.notification!.title ?? 'Notification',
            body: message.notification!.body ?? '',
            payload: jsonEncode(message.data),
          );
          
          // Add to in-app notification list
          addNotification(
            title: message.notification!.title ?? 'Notification',
            message: message.notification!.body ?? '',
            type: NotificationType.system, // Default to system
            propertyId: message.data['propertyId'],
            chatId: message.data['chatId'],
          );
        }
      });

      // Handle message tap (app in background)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _onFCMMessageTapped(message);
      });

      // 🔄 Token refresh — re-save to Firestore whenever FCM rotates the token
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        if (kDebugMode) {
          debugPrint('🔄 FCM Token refreshed: $newToken');
        }
        _fcmToken = newToken;
        // The auth provider watches the token — but we also update directly if user is logged in
        if (_context != null) {
          final prefs = SharedPreferences.getInstance().then((prefs) {
            final userId = prefs.getString('current_user_id');
            if (userId != null) {
              updateFCMToken(userId);
            }
          });
        }
      });

      // Check if app was opened from a terminated state via notification
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _onFCMMessageTapped(initialMessage);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ FCM Initialization error: $e');
      }
    }
  }

  /// Handle FCM message tap and navigate
  void _onFCMMessageTapped(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint('📩 FCM Message tapped: ${message.data}');
    }
    
    final type = message.data['type'];
    final propertyId = message.data['propertyId'];
    final chatId = message.data['chatId'];

    switch (type) {
      case 'chat':
      case 'chat_message':
        _context?.go('/chat');
        break;
      case 'property':
      case 'new_listing':
        if (propertyId != null) {
          _context?.go('/property-detail/$propertyId');
        } else {
          _context?.go('/');
        }
        break;
      default:
        _context?.go('/notifications');
    }
  }

  /// Update user token in Firestore
  Future<void> updateFCMToken(String userId) async {
    // Wait for token if it's currently being fetched
    if (_fcmToken == null) {
      debugPrint('⏳ updateFCMToken: Waiting for FCM token to be generated...');
      _fcmToken = await fcmTokenAsync.timeout(
        const Duration(seconds: 15), 
        onTimeout: () => null
      );
    }
    
    if (_fcmToken == null) {
      debugPrint('⚠️ updateFCMToken: Aborted — token is still null after timeout');
      return;
    }
    
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'fcmToken': _fcmToken,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (kDebugMode) {
        debugPrint('🔔 FCM Token updated in Firestore for user $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to update FCM token in Firestore: $e');
      }
    }
  }

  /// Load notification settings from storage
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _notificationsEnabled = prefs.getBool(_notificationsEnabledKey) ?? true;
      
      final lastTimeString = prefs.getString(_lastCheckTimeKey);
      if (lastTimeString != null) {
        _lastCheckTime = DateTime.parse(lastTimeString);
      }
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to load notification settings: $e');
      }
    }
  }

  /// Load in-app notifications from storage
  Future<void> _loadInAppNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getStringList(_inAppNotificationsKey);
      
      if (notificationsJson != null) {
        _notifications = notificationsJson
            .map((item) => DaryNotification.fromJson(jsonDecode(item)))
            .toList();
            
        // Sort by newest first
        _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        _notifySafely();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to load in-app notifications: $e');
      }
    }
  }

  /// Save in-app notifications to storage
  Future<void> _saveInAppNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = _notifications
          .map((item) => jsonEncode(item.toJson()))
          .toList();
      await prefs.setStringList(_inAppNotificationsKey, notificationsJson);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to save in-app notifications: $e');
      }
    }
  }

  /// Add an in-app notification
  Future<void> addNotification({
    required String title,
    required String message,
    required NotificationType type,
    String? propertyId,
    String? chatId,
    bool showSystemAlert = true,
  }) async {
    final notification = DaryNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      timestamp: DateTime.now(),
      type: type,
      propertyId: propertyId,
      chatId: chatId,
    );
    
    _notifications.insert(0, notification);
    await _saveInAppNotifications();
    _notifySafely();
    
    // Also show local notification if enabled and explicitly requested
    if (showSystemAlert && _notificationsEnabled && _permissionGranted) {
      await _showLocalNotification(
        title: title,
        body: message,
        payload: jsonEncode(notification.toJson()),
      );
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index].isRead = true;
      await _saveInAppNotifications();
      _notifySafely();
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    for (var n in _notifications) {
      n.isRead = true;
    }
    await _saveInAppNotifications();
    _notifySafely();
  }

  /// Remove a notification
  Future<void> removeNotification(String id) async {
    _notifications.removeWhere((n) => n.id == id);
    await _saveInAppNotifications();
    _notifySafely();
  }

  /// Clear all notifications
  @override
  Future<void> clearAllNotifications() async {
    _notifications.clear();
    await _saveInAppNotifications();
    // flutter_local_notifications does not support web
    if (!kIsWeb) {
      await _localNotifications.cancelAll();
    }
    _notifySafely();
  }

  /// Check for expiring properties
  Future<List<Property>> checkExpiringProperties(String userId) async {
    try {
      // Get all properties for this user
      final allProperties = await property_service.PropertyService().getPropertiesByUser(userId);
      
      final expiringSoon = <Property>[];
      final now = DateTime.now();
      
      for (final property in allProperties) {
        if (!property.isPublished || property.isExpired) continue;
        
        // Check if property is within 7 days of expiring (53 days old since limit is 60)
        final age = now.difference(property.createdAt).inDays;
        if (age >= 53) {
          expiringSoon.add(property);
          
          // Generate an in-app notification if we haven't today
          final notificationId = 'expiry_${property.id}_${now.year}_${now.month}_${now.day}';
          if (!_notifications.any((n) => n.id.startsWith('expiry_${property.id}') && 
              n.timestamp.day == now.day && 
              n.timestamp.month == now.month)) {
            
            final l10n = _context != null ? AppLocalizations.of(_context!) : null;
            await addNotification(
              title: l10n?.propertyExpiringSoonTitle ?? 'Property Expiring Soon!',
              message: l10n?.propertyExpiringSoonMessage(property.title, 60 - age) ?? 
                  'Your listing "${property.title}" will expire in ${60 - age} days. Renew it now to keep it active!',
              type: NotificationType.propertyExpiry,
              propertyId: property.id,
            );
          }
        }
      }
      
      return expiringSoon;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error checking for expiring properties: $e');
      }
      return [];
    }
  }

  /// Check email verification status and add notification if needed
  Future<void> checkVerificationStatus(UserProfile user, [BuildContext? context]) async {
    if (!user.isVerified) {
      final effectiveContext = context ?? _context;
      final l10n = effectiveContext != null ? AppLocalizations.of(effectiveContext) : null;
      
      // Use Arabic if the current locale is Arabic
      final isArabic = l10n?.localeName == 'ar';
      final title = l10n?.emailNotVerifiedTitle ?? (isArabic ? 'البريد الإلكتروني غير مفعل' : 'Email Not Verified');
      final message = l10n?.emailNotVerifiedMessage ?? 
          (isArabic 
            ? 'يرجى تفعيل بريدك الإلكتروني للوصول إلى كافة الميزات. تحقق من بريدك الوارد لرابط التفعيل.' 
            : 'Please verify your email to unlock all features. Check your inbox for the verification link.');

      // Check if we already have this notification
      final existingIndex = _notifications.indexWhere((n) => n.type == NotificationType.verification);
      
      if (existingIndex == -1) {
        await addNotification(
          title: title,
          message: message,
          type: NotificationType.verification,
        );
      } else {
        // Update existing notification if text changed (due to language switch)
        if (_notifications[existingIndex].title != title || _notifications[existingIndex].message != message) {
          _notifications[existingIndex] = _notifications[existingIndex].copyWith(
            title: title,
            message: message,
          );
          await _saveInAppNotifications();
          _notifySafely();
        }
      }
    } else {
      // If verified, remove any existing verification notifications
      if (_notifications.any((n) => n.type == NotificationType.verification)) {
        _notifications.removeWhere((n) => n.type == NotificationType.verification);
        await _saveInAppNotifications();
        _notifySafely();
      }
    }
  }


  /// Start periodic property checking (every 60 seconds)
  void _startPeriodicPropertyCheck() {
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _checkForNewMatchingListings();
    });
  }

  /// Check for new matching listings based on saved searches
  Future<void> _checkForNewMatchingListings() async {
    if (!_notificationsEnabled || !_permissionGranted) return;

    try {
      // Get current user (mock for now)
      const currentUserId = 'current_user_123';
      
      // Get user's saved searches
      final savedSearches = _savedSearchService.list(currentUserId);
      
      for (final search in savedSearches) {
        // Check for new properties matching this search
        final newMatches = await _findNewMatchingProperties(search);
        
        if (newMatches.isNotEmpty) {
          await _showNewListingsNotification(search, newMatches);
        }
      }
      
      // Update last check time
      _lastCheckTime = DateTime.now();
      await _saveLastCheckTime();
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error checking for new listings: $e');
      }
    }
  }

  /// Find new properties matching a saved search
  Future<List<Property>> _findNewMatchingProperties(SavedSearch search) async {
    try {
      // Get all properties (mock data for now)
      final allProperties = PropertyService.getSortedProperties();
      
      // Filter properties based on search criteria
      List<Property> matchingProperties = allProperties;
      
      // Apply filters
      if (search.filters['city'] != null) {
        final city = search.filters['city'].toString();
        matchingProperties = matchingProperties
            .where((p) => p.city.toLowerCase() == city.toLowerCase())
            .toList();
      }
      
      if (search.filters['type'] != null) {
        final typeString = search.filters['type'].toString();
        final type = PropertyType.values.firstWhere(
          (t) => t.typeDisplayName.toLowerCase() == typeString.toLowerCase(),
          orElse: () => PropertyType.apartment,
        );
        matchingProperties = matchingProperties.where((p) => p.type == type).toList();
      }
      
      if (search.filters['priceRange'] != null) {
        final priceRange = search.filters['priceRange'] as Map<String, dynamic>;
        final minPrice = (priceRange['min'] as num?)?.toDouble() ?? 0;
        final maxPrice = (priceRange['max'] as num?)?.toDouble() ?? double.infinity;
        
        matchingProperties = matchingProperties.where((p) {
          final price = p.status == PropertyStatus.forRent ? p.monthlyRent : p.price;
          return price >= minPrice && price <= maxPrice;
        }).toList();
      }
      
      // Filter for new properties (created after last check)
      final cutoffTime = _lastCheckTime ?? DateTime.now().subtract(const Duration(hours: 1));
      final newProperties = matchingProperties
          .where((p) => p.createdAt.isAfter(cutoffTime))
          .toList();
      
      return newProperties;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error finding matching properties: $e');
      }
      return [];
    }
  }

  /// Show notification for new matching listings
  Future<void> _showNewListingsNotification(SavedSearch search, List<Property> newProperties) async {
    if (newProperties.isEmpty) return;

    final propertyCount = newProperties.length;
    final propertyText = propertyCount == 1 ? 'property' : 'properties';
    
    // Show local notification
    await _showLocalNotification(
      title: 'New $propertyText found!',
      body: '${search.name}: $propertyCount new $propertyText match your criteria',
      payload: jsonEncode({
        'type': 'new_listings',
        'searchId': search.id,
        'propertyCount': propertyCount,
      }),
    );

    // Show SnackBar if app is in foreground
    if (_context != null && _context!.mounted) {
      _showSnackBarNotification(search, newProperties);
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    // flutter_local_notifications does not support web
    if (kIsWeb || !_permissionGranted) return;

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'property_notifications',
      'Property Notifications',
      channelDescription: 'Notifications for new property listings',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Show SnackBar notification in app
  void _showSnackBarNotification(SavedSearch search, List<Property> newProperties) {
    if (_context == null || !_context!.mounted) return;

    final propertyCount = newProperties.length;
    final propertyText = propertyCount == 1 ? 'property' : 'properties';

    ScaffoldMessenger.of(_context!).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.home,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'New $propertyText found!',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${search.name}: $propertyCount new $propertyText',
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            _context!.go('/saved-searches');
          },
        ),
      ),
    );
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        final type = data['type'] as String?;
        
        switch (type) {
          case 'new_listings':
            _context?.go('/saved-searches');
            break;
          case 'chat_message':
            _context?.go('/chat');
            break;
          default:
            _context?.go('/');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ Error handling notification tap: $e');
        }
      }
    }
  }

  /// Toggle notifications on/off
  Future<void> toggleNotifications(bool enabled) async {
    _notificationsEnabled = enabled;
    await _saveSettings();
    _notifySafely();
    
    if (enabled) {
      _startPeriodicPropertyCheck();
    } else {
      _checkTimer?.cancel();
    }
    
    if (kDebugMode) {
      debugPrint('🔔 Notifications ${enabled ? 'enabled' : 'disabled'}');
    }
  }

  /// Save notification settings
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_notificationsEnabledKey, _notificationsEnabled);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to save notification settings: $e');
      }
    }
  }

  /// Save last check time
  Future<void> _saveLastCheckTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastCheckTimeKey, _lastCheckTime!.toIso8601String());
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to save last check time: $e');
      }
    }
  }

  /// Get FCM token for current user
  String? getFCMToken() {
    return _fcmToken;
  }

  /// Send test notification
  Future<void> sendTestNotification() async {
    // flutter_local_notifications does not support web
    if (kIsWeb) return;
    await _showLocalNotification(
      title: 'Test Notification',
      body: 'This is a test notification from Dary Properties',
      payload: jsonEncode({'type': 'test'}),
    );
  }

  /// Run a quick diagnostic to see if Google's messaging servers are reachable
  Future<void> _runConnectivityDiagnostic() async {
    if (kIsWeb) return;
    
    final hosts = ['mtalk.google.com', 'fcm.googleapis.com', 'google.com'];
    
    debugPrint('🧪 Starting Network Diagnostic for Firebase...');
    
    for (var host in hosts) {
      try {
        final result = await InternetAddress.lookup(host);
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          debugPrint('🌐 DNS Lookup: $host -> SUCCESS (${result[0].address})');
          
          // Try to connect to mtalk port (5228 for FCM)
          if (host == 'mtalk.google.com') {
            try {
              final socket = await Socket.connect(host, 5228, timeout: const Duration(seconds: 5));
              debugPrint('✅ TCP Connection: $host:5228 -> SUCCESS');
              await socket.close();
            } catch (e) {
              debugPrint('❌ TCP Connection: $host:5228 -> FAILED ($e)');
              debugPrint('🚨 PORT 5228 IS BLOCKED. Push notifications will NOT work on this network!');
            }
          }
        }
      } catch (e) {
        debugPrint('❌ DNS Lookup: $host -> FAILED ($e)');
        debugPrint('🚨 DNS is blocking Google services!');
      }
    }
    debugPrint('🧪 Diagnostic Complete.');
  }

  /// Schedule daily engagement notifications
  Future<void> scheduleDailyNotifications() async {
    if (kIsWeb || !_notificationsEnabled || !_permissionGranted) return;

    // Clear existing daily notifications to avoid duplicates
    // We'll use IDs 1000-1003 for daily notifications
    for (int i = 0; i < 4; i++) {
      await _localNotifications.cancel(1000 + i);
    }

    final now = tz.TZDateTime.now(tz.local);
    
    // Schedule 4 notifications at different times
    // 10:00 AM, 2:00 PM, 6:00 PM, 9:00 PM
    final scheduleTimes = [
      {'hour': 10, 'minute': 0},
      {'hour': 14, 'minute': 0},
      {'hour': 18, 'minute': 0},
      {'hour': 21, 'minute': 0},
    ];

    for (int i = 0; i < scheduleTimes.length; i++) {
      final message = _arabicMessages[i % _arabicMessages.length];
      final time = scheduleTimes[i];
      
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        time['hour']!,
        time['minute']!,
      );

      // If the time has already passed today, schedule it for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _localNotifications.zonedSchedule(
        1000 + i,
        message['title'],
        message['body'],
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'engagement_channel',
            'Daily Engagement',
            channelDescription: 'Daily reminders to check new properties',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // This makes it repeat daily at this time
        payload: jsonEncode({'type': 'engagement'}),
      );
      
      if (kDebugMode) {
        debugPrint('🔔 Scheduled daily notification $i at ${scheduledDate.toString()}');
      }
    }
  }

  /// Fire a random engagement notification now
  Future<void> fireEngagementNotification() async {
    if (kIsWeb || !_notificationsEnabled || !_permissionGranted) return;
    
    final random = DateTime.now().millisecond % _arabicMessages.length;
    final message = _arabicMessages[random];
    
    await _showLocalNotification(
      title: message['title']!,
      body: message['body']!,
      payload: jsonEncode({'type': 'engagement'}),
    );
    
    // Also add to in-app
    addNotification(
      title: message['title']!,
      message: message['body']!,
      type: NotificationType.system,
    );
  }

  /// Dispose resources
  @override
  void dispose() {
    isDisposed = true;
    _checkTimer?.cancel();
    super.dispose();
  }

  bool isDisposed = false;

  void _notifySafely() {
    if (WidgetsBinding.instance.schedulerPhase == scheduler.SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!isDisposed) notifyListeners();
      });
    } else {
      notifyListeners();
    }
  }
}
