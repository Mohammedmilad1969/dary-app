import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../services/notification_service.dart';
import '../../services/language_service.dart';
import '../../widgets/language_toggle_button.dart';

/// Notification Settings Screen
/// 
/// Allows users to manage their notification preferences including
/// FCM settings, local notifications, and saved search notifications.
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final notificationService = Provider.of<NotificationService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notificationSettings),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          Consumer<LanguageService>(
            builder: (context, languageService, child) {
              return LanguageToggleButton(languageService: languageService);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notification Status Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          notificationService.notificationsEnabled
                              ? Icons.notifications_active
                              : Icons.notifications_off,
                          color: notificationService.notificationsEnabled
                              ? Colors.green
                              : Colors.grey,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          l10n.notificationStatus,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      notificationService.notificationsEnabled
                          ? l10n.notificationsEnabled
                          : l10n.notificationsDisabled,
                      style: TextStyle(
                        color: notificationService.notificationsEnabled
                            ? Colors.green[700]
                            : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: Text(l10n.enableNotifications),
                      subtitle: Text(l10n.enableNotificationsSubtitle),
                      value: notificationService.notificationsEnabled,
                      onChanged: (value) {
                        notificationService.toggleNotifications(value);
                      },
                      activeColor: Colors.green,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // FCM Token Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          notificationService.permissionGranted
                              ? Icons.cloud_done
                              : Icons.cloud_off,
                          color: notificationService.permissionGranted
                              ? Colors.green
                              : Colors.orange,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          l10n.firebaseCloudMessaging,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      notificationService.permissionGranted
                          ? l10n.fcmEnabled
                          : l10n.fcmDisabled,
                      style: TextStyle(
                        color: notificationService.permissionGranted
                            ? Colors.green[700]
                            : Colors.orange[700],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (notificationService.fcmToken != null) ...[
                      Text(
                        l10n.fcmToken,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: SelectableText(
                          notificationService.fcmToken!,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.fcmTokenDescription,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ] else ...[
                      Text(
                        l10n.fcmTokenNotAvailable,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Notification Types Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.category,
                          color: Colors.green,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          l10n.notificationTypes,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // New Listings Notifications
                    ListTile(
                      leading: const Icon(Icons.home, color: Colors.green),
                      title: Text(l10n.newListingsNotifications),
                      subtitle: Text(l10n.newListingsNotificationsSubtitle),
                      trailing: Switch(
                        value: notificationService.notificationsEnabled,
                        onChanged: (value) {
                          notificationService.toggleNotifications(value);
                        },
                        activeColor: Colors.green,
                      ),
                    ),
                    
                    const Divider(),
                    
                    // Chat Notifications
                    ListTile(
                      leading: const Icon(Icons.chat, color: Colors.blue),
                      title: Text(l10n.chatNotifications),
                      subtitle: Text(l10n.chatNotificationsSubtitle),
                      trailing: Switch(
                        value: notificationService.notificationsEnabled,
                        onChanged: (value) {
                          notificationService.toggleNotifications(value);
                        },
                        activeColor: Colors.green,
                      ),
                    ),
                    
                    const Divider(),
                    
                    // Price Drop Notifications
                    ListTile(
                      leading: const Icon(Icons.trending_down, color: Colors.red),
                      title: Text(l10n.priceDropNotifications),
                      subtitle: Text(l10n.priceDropNotificationsSubtitle),
                      trailing: Switch(
                        value: notificationService.notificationsEnabled,
                        onChanged: (value) {
                          notificationService.toggleNotifications(value);
                        },
                        activeColor: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Test Notifications Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.bug_report,
                          color: Colors.orange,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          l10n.testNotifications,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.testNotificationsDescription,
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              notificationService.sendTestNotification();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.testNotificationSent),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                            icon: const Icon(Icons.send),
                            label: Text(l10n.sendTestNotification),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              notificationService.clearAllNotifications();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.notificationsCleared),
                                  backgroundColor: Colors.blue,
                                ),
                              );
                            },
                            icon: const Icon(Icons.clear_all),
                            label: Text(l10n.clearAllNotifications),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green,
                              side: const BorderSide(color: Colors.green),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Last Check Time Card
            if (notificationService.lastCheckTime != null)
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule,
                            color: Colors.purple,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            l10n.lastCheckTime,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDateTime(notificationService.lastCheckTime!),
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.lastCheckTimeDescription,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}
