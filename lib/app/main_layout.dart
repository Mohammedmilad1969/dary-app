import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';
import '../widgets/language_toggle_button.dart';
import '../features/chat/chat_service.dart';
import '../providers/auth_provider.dart';
import '../features/auth/login_screen.dart';

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
        final totalUnreadCount = authProvider.isAuthenticated ? chatService.getTotalUnreadCount() : 0;
        
        return Scaffold(
          body: child,
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _getCurrentIndex(currentLocation),
            onTap: (index) => _onTabTapped(context, index, authProvider),
            selectedItemColor: Colors.green,
            unselectedItemColor: Colors.grey,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.add_home),
                label: 'Add Property',
              ),
              BottomNavigationBarItem(
                icon: _buildChatIconWithBadge(totalUnreadCount),
                label: 'Messages',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet),
                label: 'Wallet',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
          floatingActionButton: _shouldShowFAB(currentLocation)
              ? FloatingActionButton(
                  onPressed: () => _handleAddProperty(context, authProvider),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.add),
                )
              : null,
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
        title: Text('Login Required'),
        content: Text('Please login to access $feature'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/login');
            },
            child: Text('Login'),
          ),
        ],
      ),
    );
  }

  bool _shouldShowFAB(String location) {
    return location == '/';
  }

  Widget _buildChatIconWithBadge(int unreadCount) {
    return Stack(
      children: [
        const Icon(Icons.chat),
        if (unreadCount > 0)
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
                unreadCount > 99 ? '99+' : unreadCount.toString(),
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
    );
  }
}
