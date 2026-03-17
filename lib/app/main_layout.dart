import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../services/language_service.dart';
import '../features/chat/chat_service.dart';
import '../providers/auth_provider.dart';
import '../features/chat/chat_notification_service.dart';
import '../utils/app_animations.dart';
import '../widgets/loading_overlay.dart';
import '../providers/navigation_provider.dart';
import '../l10n/app_localizations.dart';
import '../services/notification_service.dart';
import '../services/connectivity_service.dart';

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
    return Consumer5<LanguageService, ChatService, AuthProvider, NavigationProvider, ConnectivityService>(
      builder: (context, languageService, chatService, authProvider, navProvider, connectivity, consumerChild) {
        final l10n = AppLocalizations.of(context);
        final isOffline = connectivity.isOffline;

        // Use post-frame callback for side effects to avoid 'setState() called during build'
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Provide current user id to chat service so it can distinguish incoming messages
          chatService.setCurrentUserId(authProvider.currentUser?.id);
          // Provide context for in-app chat notifications
          ChatNotificationService().setContext(context);
          // Initialize generic notification service with context for localization
          NotificationService().initialize(context);
          
          if (authProvider.isAuthenticated && authProvider.currentUser?.id != null) {
            chatService.startListeningToUserConversations(authProvider.currentUser!.id);
          } else {
            chatService.stopListeningToUserConversations();
          }
        });

        final totalUnreadCount = authProvider.isAuthenticated ? chatService.getTotalUnreadCount() : 0;
        
        return LoadingOverlay(
          isLoading: authProvider.isLoading,
          message: 'Loading...',
          child: Scaffold(
            body: Stack(
              children: [
                screenChild,
                if (isOffline)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 10,
                    left: 20,
                    right: 20,
                    child: FadeInAnimation(
                      delay: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade800,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    l10n?.noInternetConnection ?? 'No Internet',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    l10n?.pleaseCheckConnection ?? 'Check your connection',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    spreadRadius: 0,
                    blurRadius: 24,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: SafeArea(
                child: Container(
                  height: 80, // Slightly taller for better spacing
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildNavItem(context, 0, Icons.home_rounded, l10n?.home ?? 'Home'),
                      _buildNavItem(context, 1, Icons.chat_bubble_rounded, l10n?.messages ?? 'Messages', badgeCount: totalUnreadCount),
                      _buildNavItem(context, 2, Icons.add, l10n?.addProperty ?? 'Add Property', isCenterButton: true),
                      _buildNavItem(context, 3, Icons.account_balance_wallet_rounded, l10n?.wallet ?? 'Wallet'),
                      _buildNavItem(context, 4, Icons.person_rounded, l10n?.profile ?? 'Profile'),
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
      case '/office-dashboard':
        return 0;
      case '/chat':
        return 1;
      case '/add':
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
          route = '/chat';
        } else {
          context.go('/login');
          return;
        }
        break;
      case 2:
        if (authProvider.isAuthenticated) {
          route = '/add';
        } else {
          context.go('/login');
          return;
        }
        break;
      case 3:
        if (authProvider.isAuthenticated) {
          route = '/wallet';
        } else {
          context.go('/login');
          return;
        }
        break;
      case 4:
        if (authProvider.isAuthenticated) {
          route = '/profile';
        } else {
          context.go('/login');
          return;
        }
        break;
    }
    
    context.go(route);
  }




  bool _shouldShowFAB(String location) {
    return location == '/';
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon, String label, {int badgeCount = 0, bool isCenterButton = false}) {
    final isSelected = _getCurrentIndex(currentLocation) == index;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Special handling for the center button (Add Property) - Hexagonal style
    if (isCenterButton) {
      return Expanded(
        child: ScaleAnimation(
          onTap: () => _onTabTapped(context, index, authProvider),
          child: Center(
            child: Stack(
              children: [
                // Shadow layer
                Positioned(
                  left: 0,
                  top: 4,
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: ClipPath(
                      clipper: HexagonClipper(),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF01352D).withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),
                ),
                // Main hexagon button
                SizedBox(
                  width: 56,
                  height: 56,
                  child: ClipPath(
                    clipper: HexagonClipper(),
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF01352D), // Brand color
                            Color(0xFF015144), // Slightly lighter brand color
                          ],
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return Expanded(
      child: ScaleAnimation(
        onTap: () => _onTabTapped(context, index, authProvider),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF01352D).withValues(alpha: 0.12) : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: isSelected ? const Color(0xFF01352D) : Colors.grey[700],
                      size: 22, // Slightly smaller to fit circle better
                    ),
                  ),
                  if (badgeCount > 0 && index == 1) // Messages tab
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            badgeCount > 9 ? '9+' : '$badgeCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? const Color(0xFF01352D) : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom clipper for hexagon shape
class HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2.2;
    
    // Create hexagon path (6 sides)
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 30) * math.pi / 180;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    return path;
  }
  
  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
