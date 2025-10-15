import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'chat_models.dart';

/// Notification service for handling chat notifications
class ChatNotificationService extends ChangeNotifier {
  static final ChatNotificationService _instance = ChatNotificationService._internal();
  factory ChatNotificationService() => _instance;
  ChatNotificationService._internal();

  // Storage keys
  static const String _notificationsEnabledKey = 'chat_notifications_enabled';
  static const String _lastNotificationTimeKey = 'last_notification_time';
  
  // Notification settings
  bool _notificationsEnabled = true;
  DateTime? _lastNotificationTime;
  
  // Getters
  bool get notificationsEnabled => _notificationsEnabled;
  DateTime? get lastNotificationTime => _lastNotificationTime;

  /// Initialize notification service
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _notificationsEnabled = prefs.getBool(_notificationsEnabledKey) ?? true;
      
      final lastTimeString = prefs.getString(_lastNotificationTimeKey);
      if (lastTimeString != null) {
        _lastNotificationTime = DateTime.parse(lastTimeString);
      }
      
      if (kDebugMode) {
        debugPrint('🔔 ChatNotificationService initialized - Notifications: $_notificationsEnabled');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ChatNotificationService initialization error: $e');
      }
    }
  }

  /// Show notification for new message
  Future<void> showNewMessageNotification({
    required BuildContext context,
    required ChatMessage message,
    required String senderName,
  }) async {
    if (!_notificationsEnabled) return;
    
    // Don't show notification if it's too recent (avoid spam)
    final now = DateTime.now();
    if (_lastNotificationTime != null && 
        now.difference(_lastNotificationTime!).inSeconds < 5) {
      return;
    }
    
    _lastNotificationTime = now;
    await _saveLastNotificationTime();
    
    if (kDebugMode) {
      debugPrint('🔔 Showing notification for message from $senderName');
    }
    
    // Show SnackBar notification
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.chat,
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
                      'New message from $senderName',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      message.content,
                      style: const TextStyle(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.indigo,
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
              // Navigate to chat using go_router
              context.go('/chat');
            },
          ),
        ),
      );
    }
  }

  /// Show notification for new conversation
  Future<void> showNewConversationNotification({
    required BuildContext context,
    required Conversation conversation,
  }) async {
    if (!_notificationsEnabled) return;
    
    // Don't show notification if it's too recent
    final now = DateTime.now();
    if (_lastNotificationTime != null && 
        now.difference(_lastNotificationTime!).inSeconds < 5) {
      return;
    }
    
    _lastNotificationTime = now;
    await _saveLastNotificationTime();
    
    if (kDebugMode) {
      debugPrint('🔔 Showing notification for new conversation');
    }
    
    // Show SnackBar notification
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.chat_bubble_outline,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'New conversation started',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'About ${conversation.propertyTitle}',
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
              // Navigate to chat using go_router
              context.go('/chat');
            },
          ),
        ),
      );
    }
  }

  /// Toggle notifications on/off
  Future<void> toggleNotifications(bool enabled) async {
    _notificationsEnabled = enabled;
    await _saveNotificationSettings();
    notifyListeners();
    
    if (kDebugMode) {
      debugPrint('🔔 Notifications ${enabled ? 'enabled' : 'disabled'}');
    }
  }

  /// Save notification settings to local storage
  Future<void> _saveNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_notificationsEnabledKey, _notificationsEnabled);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to save notification settings: $e');
      }
    }
  }

  /// Save last notification time to local storage
  Future<void> _saveLastNotificationTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastNotificationTimeKey, _lastNotificationTime!.toIso8601String());
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to save last notification time: $e');
      }
    }
  }

  /// Clear notification history
  Future<void> clearNotificationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastNotificationTimeKey);
      _lastNotificationTime = null;
      notifyListeners();
      
      if (kDebugMode) {
        debugPrint('🔔 Notification history cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to clear notification history: $e');
      }
    }
  }
}
