import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../services/notification_service.dart';
import '../../services/language_service.dart';
import '../../services/theme_service.dart';
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
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          l10n.notificationSettings,
          style: ThemeService.getDynamicStyle(
            context,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: const Color(0xFF01352D),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.go('/profile'),
        ),
        actions: [
          Consumer<LanguageService>(
            builder: (context, languageService, child) {
              return LanguageToggleButton(languageService: languageService);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context, notificationService.notificationsEnabled),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(context, l10n.generalPreferences),
                  const SizedBox(height: 12),
                  _buildSwitchCard(
                    icon: Icons.notifications_active_rounded,
                    title: l10n.enableNotifications,
                    subtitle: l10n.enableNotificationsSubtitle,
                    value: notificationService.notificationsEnabled,
                    onChanged: (value) => notificationService.toggleNotifications(value),
                    activeColor: const Color(0xFF01352D),
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle(context, l10n.notificationTypes),
                  const SizedBox(height: 12),
                  _buildTypeCard(
                    icon: Icons.home_work_rounded,
                    title: l10n.newListingsNotifications,
                    subtitle: l10n.newListingsNotificationsSubtitle,
                    value: notificationService.notificationsEnabled,
                    onChanged: (value) => notificationService.toggleNotifications(value),
                    iconColor: const Color(0xFF01352D),
                  ),
                  const SizedBox(height: 12),
                  _buildTypeCard(
                    icon: Icons.chat_bubble_rounded,
                    title: l10n.chatNotifications,
                    subtitle: l10n.chatNotificationsSubtitle,
                    value: notificationService.notificationsEnabled,
                    onChanged: (value) => notificationService.toggleNotifications(value),
                    iconColor: const Color(0xFF2196F3),
                  ),
                  const SizedBox(height: 12),
                  _buildTypeCard(
                    icon: Icons.trending_down_rounded,
                    title: l10n.priceDropNotifications,
                    subtitle: l10n.priceDropNotificationsSubtitle,
                    value: notificationService.notificationsEnabled,
                    onChanged: (value) => notificationService.toggleNotifications(value),
                    iconColor: const Color(0xFFE91E63),
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle(context, l10n.maintenance),
                  const SizedBox(height: 12),
                  _buildMaintenanceCard(notificationService, l10n),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isEnabled) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      decoration: const BoxDecoration(
        color: Color(0xFF01352D),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isEnabled ? Icons.notifications_on_rounded : Icons.notifications_off_rounded,
              color: isEnabled ? Colors.white : Colors.white.withValues(alpha: 0.5),
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isEnabled ? l10n.notificationsActive : l10n.notificationsPaused,
            style: ThemeService.getHeadingStyle(
              context,
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isEnabled 
                ? l10n.notificationsActiveDesc
                : l10n.notificationsPausedDesc,
            style: ThemeService.getBodyStyle(
              context,
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title.toUpperCase(),
      style: ThemeService.getDynamicStyle(
        context,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: Colors.grey[600],
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildSwitchCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color activeColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: activeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: activeColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3142),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: value,
                  onChanged: onChanged,
                  activeColor: activeColor,
                  activeTrackColor: activeColor.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color iconColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: SwitchListTile.adaptive(
        secondary: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF01352D),
      ),
    );
  }

  Widget _buildMaintenanceCard(NotificationService service, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.auto_fix_high_rounded, color: Colors.orange[700], size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.troubleshooting,
                style: ThemeService.getHeadingStyle(
                  context,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFE65100),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionBtn(
                  onPressed: () {
                    service.sendTestNotification();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.testNotificationSent)),
                    );
                  },
                  icon: Icons.send_rounded,
                  label: l10n.test,
                  color: const Color(0xFF01352D),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionBtn(
                  onPressed: () {
                    service.clearAllNotifications();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.notificationsCleared)),
                    );
                  },
                  icon: Icons.delete_sweep_rounded,
                  label: l10n.clear,
                  color: Colors.red[700]!,
                  isOutlined: true,
                ),
              ),
            ],
          ),
          if (service.lastCheckTime != null) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.lastSync,
                  style: ThemeService.getBodyStyle(context, fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  _formatDateTime(context, service.lastCheckTime!),
                  style: ThemeService.getHeadingStyle(context, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionBtn({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
    bool isOutlined = false,
  }) {
    if (isOutlined) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _formatDateTime(BuildContext context, DateTime dateTime) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) return l10n.timeAgoSeconds(difference.inSeconds);
    if (difference.inMinutes < 60) return l10n.timeAgoMinutes(difference.inMinutes);
    if (difference.inHours < 24) return l10n.timeAgoHours(difference.inHours);
    return l10n.timeAgoDays(difference.inDays);
  }
}
