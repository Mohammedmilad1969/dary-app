import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'chat_models.dart';
import '../../l10n/app_localizations.dart';
import '../../services/notification_service.dart';
import '../../models/notification.dart';
import '../../widgets/premium_notification_banner.dart';

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
  BuildContext? _context;
  
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

  /// Provide an app-level context to use for in-app banners
  void setContext(BuildContext context) {
    _context = context;
  }

  /// Show notification for new message
  Future<void> showNewMessageNotification({
    BuildContext? context,
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
    
    // Show system notification via NotificationService
    final effectiveContext = context ?? _context;
    if (effectiveContext != null) {
      await NotificationService().addNotification(
        title: AppLocalizations.of(effectiveContext)?.newMessageFrom(senderName) ?? 'New message from $senderName',
        message: message.content,
        type: NotificationType.chatMessage,
        chatId: message.conversationId,
        showSystemAlert: true, // Show system alert so it appears in notification center/history
      );
    }

    // Show Premium Notification Banner for foreground
    final ctx = context ?? _context;
    if (ctx != null && ctx.mounted) {
      final String initials = senderName.split(' ').take(2).map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').join();
      
      PremiumNotificationBanner.show(
        ctx,
        title: AppLocalizations.of(ctx)?.newMessageFrom(senderName) ?? 'New message from $senderName',
        message: message.content,
        initials: initials,
        onTap: () {
          // Navigate to chat using go_router
          ctx.go('/chat');
        },
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
    
    // Show system notification via NotificationService
    if (context.mounted) {
      await NotificationService().addNotification(
        title: AppLocalizations.of(context)?.newConversationStarted ?? 'New conversation started',
        message: AppLocalizations.of(context)?.aboutProperty(conversation.propertyTitle ?? '') ?? 'About ${conversation.propertyTitle}',
        type: NotificationType.chatMessage,
        chatId: conversation.id,
        showSystemAlert: true, // Show system alert
      );
    }

    // Show Premium Notification Banner
    if (context.mounted) {
      PremiumNotificationBanner.show(
        context,
        title: AppLocalizations.of(context)?.newConversationStarted ?? 'New conversation started',
        message: AppLocalizations.of(context)?.aboutProperty(conversation.propertyTitle ?? '') ?? 'About ${conversation.propertyTitle}',
        onTap: () {
          // Navigate to chat using go_router
          context.go('/chat');
        },
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
