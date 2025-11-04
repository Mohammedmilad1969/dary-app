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
import '../utils/app_animations.dart';
import '../widgets/loading_overlay.dart';
import '../providers/navigation_provider.dart';

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
    final screenChild = child;
    return Consumer4<LanguageService, ChatService, AuthProvider, NavigationProvider>(
      builder: (context, languageService, chatService, authProvider, navProvider, consumerChild) {
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
        
        return LoadingOverlay(
          isLoading: authProvider.isLoading,
          message: 'Loading...',
          child: Scaffold(
            body: screenChild,
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 0,
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Container(
                  height: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
          ),
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
    String route = '/';
    
    switch (index) {
      case 0:
        route = '/';
        break;
      case 1:
        if (authProvider.isAuthenticated) {
          route = '/add';
        } else {
          _showLoginPrompt(context, 'Add Property');
          return;
        }
        break;
      case 2:
        if (authProvider.isAuthenticated) {
          route = '/chat';
        } else {
          _showLoginPrompt(context, 'Messages');
          return;
        }
        break;
      case 3:
        if (authProvider.isAuthenticated) {
          route = '/wallet';
        } else {
          _showLoginPrompt(context, 'Wallet');
          return;
        }
        break;
      case 4:
        if (authProvider.isAuthenticated) {
          route = '/profile';
        } else {
          _showLoginPrompt(context, 'Profile');
          return;
        }
        break;
    }
    
    context.go(route);
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
    
    return Expanded(
      child: ScaleAnimation(
        onTap: () => _onTabTapped(context, index, authProvider),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.green.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: isSelected
                ? Border.all(color: Colors.green.withOpacity(0.3), width: 1.5)
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                    child: Icon(
                      icon,
                      color: isSelected ? Colors.green[700] : Colors.grey[600],
                      size: isSelected ? 28 : 24,
                    ),
                  ),
                  if (badgeCount > 0 && index == 2) // Messages tab
                    Positioned(
                      right: -6,
                      top: -6,
                      child: TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 400),
                        tween: Tween(begin: 0.0, end: 1.0),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) {
                          final clampedValue = value.clamp(0.0, 1.0);
                          return Transform.scale(
                            scale: clampedValue,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              child: Center(
                                child: Text(
                                  badgeCount > 99 ? '99+' : badgeCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: ThemeService.getBodyStyle(
                  context,
                  fontSize: isSelected ? 11 : 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.green[700] : Colors.grey[600],
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
