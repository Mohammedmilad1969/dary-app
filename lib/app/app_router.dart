import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../screens/home_screen.dart';
import '../screens/add_property_screen.dart';
import '../screens/splash_screen.dart';
import '../features/listings/listing_screens.dart';
import '../features/profile/profile_screens.dart';
import '../features/profile/verification_screen.dart';
import '../features/analytics/analytics_screens.dart';
import '../features/admin/admin_screens.dart';
import '../features/wallet/wallet_screens.dart';
import '../features/paywall/paywall_screens.dart';
import '../features/auth/auth_screens.dart';
import '../features/saved_searches/saved_searches_screens.dart';
import '../features/notifications/notifications_screens.dart';
import '../features/chat/chat_screens.dart';
import '../providers/auth_provider.dart';
import 'main_layout.dart';

class AppRouter {
  static GoRouter? _router;
  static final GoRouterRefreshStream _refreshStream = GoRouterRefreshStream();

  static GoRouter get router {
    _router ??= _createRouter();
    return _router!;
  }

  static GoRouter _createRouter() {
    return GoRouter(
      initialLocation: '/splash',
      redirect: (context, state) async {
        // Wait for AuthProvider to initialize
        await Future.delayed(const Duration(milliseconds: 50));

        try {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          final currentPath = state.uri.toString();

          // Define public routes that don't require authentication (guest mode)
          const publicRoutes = ['/splash', '/login', '/register', '/'];

          // If user is not authenticated and trying to access protected routes
          if (!authProvider.isAuthenticated && !publicRoutes.contains(currentPath)) {
            return '/login';
          }

          // If user is authenticated and trying to access auth pages, redirect to home
          if (authProvider.isAuthenticated && ['/login', '/register'].contains(currentPath)) {
            return '/';
          }

          // No redirect needed
          return null;
        } catch (e) {
          // If there's an error accessing AuthProvider, redirect to login
          debugPrint('Auth guard error: $e');
          return '/login';
        }
      },
      refreshListenable: _refreshStream,
      routes: [
        // Splash Screen (Public)
        GoRoute(
          path: '/splash',
          name: 'splash',
          builder: (context, state) => const SplashScreen(),
        ),

        // Authentication Routes (Public)
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          name: 'register',
          builder: (context, state) => const RegisterScreen(),
        ),
        
        // Protected Routes (Require Authentication)
        GoRoute(
          path: '/',
          name: 'home',
          builder: (context, state) => MainLayout(
            currentLocation: state.uri.toString(),
            child: const HomeScreen(),
          ),
        ),
        GoRoute(
          path: '/add',
          name: 'add-property',
          builder: (context, state) => MainLayout(
            currentLocation: state.uri.toString(),
            child: const AddPropertyScreen(),
          ),
        ),
        GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (context, state) => MainLayout(
            currentLocation: state.uri.toString(),
            child: const ProfileScreen(),
          ),
        ),
        GoRoute(
          path: '/verification',
          name: 'verification',
          builder: (context, state) => const VerificationScreen(),
        ),
        GoRoute(
          path: '/analytics',
          name: 'analytics',
          builder: (context, state) => MainLayout(
            currentLocation: state.uri.toString(),
            child: const AnalyticsScreen(),
          ),
        ),
        GoRoute(
          path: '/admin',
          name: 'admin',
          builder: (context, state) => const AdminDashboard(),
        ),
        GoRoute(
          path: '/wallet',
          name: 'wallet',
          builder: (context, state) => MainLayout(
            currentLocation: state.uri.toString(),
            child: const WalletScreen(),
          ),
        ),
        GoRoute(
          path: '/paywall',
          name: 'paywall',
          builder: (context, state) => MainLayout(
            currentLocation: state.uri.toString(),
            child: const PaywallScreen(),
          ),
        ),
        GoRoute(
          path: '/saved-searches',
          name: 'saved-searches',
          builder: (context, state) => MainLayout(
            currentLocation: state.uri.toString(),
            child: const SavedSearchesScreen(),
          ),
        ),
        GoRoute(
          path: '/notification-settings',
          name: 'notification-settings',
          builder: (context, state) => const NotificationSettingsScreen(),
        ),
        
        // Chat Routes
        GoRoute(
          path: '/chat',
          name: 'chat',
          builder: (context, state) => MainLayout(
            currentLocation: state.uri.toString(),
            child: const ConversationListScreen(),
          ),
        ),
        GoRoute(
          path: '/chat/:conversationId',
          name: 'chat-conversation',
          builder: (context, state) {
            final conversationId = state.pathParameters['conversationId']!;
            return ChatScreen(
              conversationId: conversationId,
            );
          },
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
          centerTitle: true,
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 24),
              Text(
                'Page not found: ${state.uri}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void refresh() {
    _refreshStream.refresh();
  }
}

/// A custom refresh stream that listens to AuthProvider changes
class GoRouterRefreshStream extends ChangeNotifier {
  void refresh() {
    notifyListeners();
  }
}
