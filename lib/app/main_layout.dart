import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';
import '../widgets/language_toggle_button.dart';
import '../features/chat/chat_service.dart';
import '../providers/auth_provider.dart';
import '../features/chat/chat_notification_service.dart';
import '../features/auth/login_screen.dart';
import '../services/theme_service.dart';

class MainLayout extends StatelessWidget {
  final Widget child;
  final String currentLocation;

  const MainLayout({
    super.key,
    required this.child,
    required this.currentLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer3<LanguageService, ChatService, AuthProvider>(
      builder: (context, languageService, chatService, authProvider, _) {
        // Provide current user id to chat service so it can distinguish incoming messages
        chatService.setCurrentUserId(authProvider.currentUser?.id);
        // Provide context for in-app chat notifications
        ChatNotificationService().setContext(context);
        if (authProvider.isAuthenticated && authProvider.currentUser?.id != null) {
          chatService.startListeningToUserConversations(authProvider.currentUser!.id);
        } else {
          chatService.stopListeningToUserConversations();
        }
        final totalUnreadCount = authProvider.isAuthenticated ? chatService.getTotalUnreadCount() : 0;
        
        return Scaffold(
          body: child,
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(context, 0, Icons.home, 'Home'),
                    _buildNavItem(context, 1, Icons.add_home, 'Add Property'),
                    _buildNavItem(context, 2, Icons.chat, 'Messages', badgeCount: totalUnreadCount),
                    _buildNavItem(context, 3, Icons.account_balance_wallet, 'Wallet'),
                    _buildNavItem(context, 4, Icons.person, 'Profile'),
                  ],
                ),
              ),
            ),
          ),
          floatingActionButton: null,
        );
      },
    );
  }

  int _getCurrentIndex(String location) {
    switch (location) {
      case '/':
        return 0;
      case '/add':
        return 1;
      case '/chat':
        return 2;
      case '/wallet':
        return 3;
      case '/profile':
        return 4;
      default:
        return 0;
    }
  }

  void _onTabTapped(BuildContext context, int index, AuthProvider authProvider) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        _handleAddProperty(context, authProvider);
        break;
      case 2:
        _handleChat(context, authProvider);
        break;
      case 3:
        _handleWallet(context, authProvider);
        break;
      case 4:
        _handleProfile(context, authProvider);
        break;
    }
  }

  void _handleAddProperty(BuildContext context, AuthProvider authProvider) {
    if (authProvider.isAuthenticated) {
      context.go('/add');
    } else {
      _showLoginPrompt(context, 'Add Property');
    }
  }

  void _handleChat(BuildContext context, AuthProvider authProvider) {
    if (authProvider.isAuthenticated) {
      context.go('/chat');
    } else {
      _showLoginPrompt(context, 'Messages');
    }
  }

  void _handleWallet(BuildContext context, AuthProvider authProvider) {
    if (authProvider.isAuthenticated) {
      context.go('/wallet');
    } else {
      _showLoginPrompt(context, 'Wallet');
    }
  }

  void _handleProfile(BuildContext context, AuthProvider authProvider) {
    if (authProvider.isAuthenticated) {
      context.go('/profile');
    } else {
      _showLoginPrompt(context, 'Profile');
    }
  }

  void _showLoginPrompt(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'Login Required',
          style: ThemeService.getHeadingStyle(
            context,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        content: Text(
          'Please login to access $feature',
          style: ThemeService.getBodyStyle(
            context,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: ThemeService.getBodyStyle(
                context,
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/login');
            },
            child: Text(
              'Login',
              style: ThemeService.getBodyStyle(
                context,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldShowFAB(String location) {
    return location == '/';
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon, String label, {int badgeCount = 0}) {
    final isSelected = _getCurrentIndex(currentLocation) == index;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    return GestureDetector(
      onTap: () => _onTabTapped(context, index, authProvider),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.green : Colors.grey[700],
                  size: 24,
                ),
                if (badgeCount > 0 && index == 2) // Messages tab
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        badgeCount > 99 ? '99+' : badgeCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: ThemeService.getBodyStyle(
                context,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.green : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
