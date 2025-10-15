import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'dart:convert';
import '../models/property.dart';
import '../models/saved_search.dart';
import '../services/saved_search_service.dart';

/// Web-Compatible Notification Service
/// 
/// Handles local notifications and property listing notifications with saved search matching.
/// FCM support can be added later when web compatibility issues are resolved.
class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Services
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final SavedSearchService _savedSearchService = SavedSearchService();

  // Storage keys
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _lastCheckTimeKey = 'last_property_check_time';

  // State
  bool _notificationsEnabled = true;
  bool _permissionGranted = false;
  DateTime? _lastCheckTime;
  Timer? _checkTimer;
  BuildContext? _context;

  // Getters
  bool get notificationsEnabled => _notificationsEnabled;
  bool get permissionGranted => _permissionGranted;
  DateTime? get lastCheckTime => _lastCheckTime;
  String? get fcmToken => null; // Placeholder for FCM token

  /// Initialize the notification service
  Future<void> initialize(BuildContext context) async {
    _context = context;
    
    try {
      // Initialize local notifications
      await _initializeLocalNotifications();
      
      // Request permissions
      await _requestPermissions();
      
      // Load settings
      await _loadSettings();
      
      // Start periodic property checking
      _startPeriodicPropertyCheck();
      
      if (kDebugMode) {
        debugPrint('🔔 NotificationService initialized successfully');
        debugPrint('🔔 Notifications enabled: $_notificationsEnabled');
        debugPrint('🔔 Permission granted: $_permissionGranted');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ NotificationService initialization error: $e');
      }
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
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
    try {
      // Request local notification permission
      final localPermission = await Permission.notification.request();

      _permissionGranted = localPermission == PermissionStatus.granted;

      if (kDebugMode) {
        debugPrint('🔔 Local Permission: $localPermission');
        debugPrint('🔔 Permission granted: $_permissionGranted');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Permission request error: $e');
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
    if (!_permissionGranted) return;

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
    notifyListeners();
    
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
    return null; // FCM not available in web-compatible version
  }

  /// Send test notification
  Future<void> sendTestNotification() async {
    await _showLocalNotification(
      title: 'Test Notification',
      body: 'This is a test notification from Dary Properties',
      payload: jsonEncode({'type': 'test'}),
    );
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Dispose resources
  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }
}
