import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_localizations.dart';
import '../services/notification_service.dart';
import '../models/notification.dart';
import 'package:intl/intl.dart';
import '../services/theme_service.dart';

class NotificationPopup extends StatelessWidget {
  const NotificationPopup({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final notificationService = Provider.of<NotificationService>(context);
    final notifications = notificationService.notifications;

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Container(
      width: screenWidth > 600 ? 380 : screenWidth * 0.9,
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.7,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n?.notifications ?? 'Notifications',
                  style: ThemeService.getDynamicStyle(
                    context,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF01352D),
                  ),
                ),
                if (notifications.isNotEmpty)
                  TextButton(
                    onPressed: () => notificationService.markAllAsRead(),
                    child: Text(
                      l10n?.markAllAsRead ?? 'Mark all as read',
                      style: ThemeService.getDynamicStyle(
                        context,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF015F4D),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          
          // List
          Flexible(
            child: notifications.isEmpty
                ? _buildEmptyState(context)
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: notifications.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, indent: 24, endIndent: 24),
                    itemBuilder: (context, index) {
                      return _NotificationItem(
                        notification: notifications[index],
                        onTap: () {
                          notificationService.markAsRead(notifications[index].id);
                          _handleNotificationTap(context, notifications[index]);
                        },
                      );
                    },
                  ),
          ),
          
          // Footer
          if (notifications.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: TextButton(
                onPressed: () => notificationService.clearAllNotifications(),
                child: Text(
                  l10n?.clearAllNotifications ?? 'Clear all',
                  style: ThemeService.getDynamicStyle(
                    context,
                    fontSize: 13,
                    color: Colors.red[600],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF01352D).withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 32,
              color: const Color(0xFF01352D).withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n?.noNotificationsYet ?? 'No notifications yet',
            style: ThemeService.getDynamicStyle(
              context,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D3142),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n?.notificationsDiscoverySubtitle ?? 'We\'ll notify you when something important happens',
            textAlign: TextAlign.center,
            style: ThemeService.getDynamicStyle(
              context,
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(BuildContext context, DaryNotification notification) {
    Navigator.of(context).pop(); // Close popup
    
    switch (notification.type) {
      case NotificationType.propertyExpiry:
        if (notification.propertyId != null) {
          context.go('/property/${notification.propertyId}');
        }
        break;
      case NotificationType.chatMessage:
        context.go('/chat');
        break;
      case NotificationType.newListing:
        context.go('/saved-searches');
        break;
      default:
        break;
    }
  }
}

class _NotificationItem extends StatelessWidget {
  final DaryNotification notification;
  final VoidCallback onTap;

  const _NotificationItem({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: notification.isRead ? Colors.transparent : const Color(0xFF01352D).withValues(alpha: 0.03),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIcon(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: ThemeService.getDynamicStyle(
                              context,
                              fontSize: 15,
                              fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.bold,
                              color: const Color(0xFF2D3142),
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF015F4D),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: ThemeService.getDynamicStyle(
                        context,
                        fontSize: 13,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTimestamp(context, notification.timestamp),
                      style: ThemeService.getDynamicStyle(
                        context,
                        fontSize: 11,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    IconData iconData;
    Color iconColor;
    Color bgColor;

    switch (notification.type) {
      case NotificationType.propertyExpiry:
        iconData = Icons.timer_outlined;
        iconColor = Colors.orange[700]!;
        bgColor = Colors.orange[50]!;
        break;
      case NotificationType.chatMessage:
        iconData = Icons.chat_bubble_outline_rounded;
        iconColor = Colors.blue[700]!;
        bgColor = Colors.blue[50]!;
        break;
      case NotificationType.newListing:
        iconData = Icons.home_work_outlined;
        iconColor = const Color(0xFF015F4D);
        bgColor = const Color(0xFF015F4D).withValues(alpha: 0.1);
        break;
      default:
        iconData = Icons.notifications_none_rounded;
        iconColor = Colors.grey[700]!;
        bgColor = Colors.grey[100]!;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(iconData, color: iconColor, size: 20),
    );
  }

  String _formatTimestamp(BuildContext context, DateTime timestamp) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) return l10n?.timeAgoSeconds(0) ?? 'Just now';
    if (difference.inMinutes < 60) return l10n?.timeAgoMinutes(difference.inMinutes) ?? '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return l10n?.timeAgoHours(difference.inHours) ?? '${difference.inHours}h ago';
    if (difference.inDays < 7) return l10n?.timeAgoDays(difference.inDays) ?? '${difference.inDays}d ago';
    
    return DateFormat('MMM d, h:mm a').format(timestamp);
  }
}
