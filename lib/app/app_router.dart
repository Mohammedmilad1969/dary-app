import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../screens/home_screen.dart';
import '../screens/add_property_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/public_user_profile_screen.dart';
import '../screens/real_estate_office_dashboard.dart';
import '../screens/property_detail_screen.dart';
import '../features/profile/profile_screens.dart';
import '../features/profile/verification_screen.dart';
import '../features/analytics/analytics_screens.dart';
import '../features/admin/admin_screens.dart';
import '../features/wallet/wallet_screens.dart';
import '../features/wallet/recharge_callback_screen.dart';
import '../features/paywall/paywall_screens.dart';
import '../features/paywall/boost_screen.dart';
import '../features/auth/auth_screens.dart';
import '../features/saved_searches/saved_searches_screens.dart';
import '../features/notifications/notifications_screens.dart';
import '../features/chat/chat_screens.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../providers/auth_provider.dart';
import '../services/property_service.dart' as property_service;
import '../models/property.dart';
import '../widgets/dary_loading_indicator.dart';
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
        final path = state.uri.path;
        final fullUri = state.uri.toString();
        debugPrint('🛣️ Router Redirect: Attempting navigation to $path (Full URI: $fullUri)');
        if (fullUri.startsWith('dary://') || fullUri.contains('dary.ly')) {
          debugPrint('🔗 Deep Link Detected: $fullUri');
        }
        
        // Wait for AuthProvider to initialize
        await Future.delayed(const Duration(milliseconds: 50));

        try {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          debugPrint('🛣️ Router Redirect: Auth State - Authenticated: ${authProvider.isAuthenticated}, User: ${authProvider.currentUser?.email}');

          // Define public routes that don't require authentication (guest mode)
          final publicRoutes = ['/splash', '/onboarding', '/login', '/register', '/forgot-password', '/'];
          final isPublicRoute = publicRoutes.contains(path) ||
                                 path.startsWith('/user/') ||
                                 path.startsWith('/property/');

          // If user is not authenticated and trying to access protected routes
          if (!authProvider.isAuthenticated && !isPublicRoute) {
            debugPrint('🛣️ Router Redirect: Not authenticated and not public route. Redirecting to /login');
            return '/login';
          }

          // If user is authenticated and trying to access auth pages, redirect appropriately
          if (authProvider.isAuthenticated) {
            // If they are on an auth page, redirect to home
            if (['/login', '/register', '/forgot-password'].contains(path)) {
              debugPrint('🛣️ Router Redirect: Authenticated user on auth page. Redirecting to home/admin');
              if (authProvider.currentUser?.isAdmin == true) return '/admin';
              return '/';
            }
          }

          // Protect office dashboard - only allow real estate offices
          if (path == '/office-dashboard') {
            if (!authProvider.isAuthenticated) {
              debugPrint('🛣️ Router Redirect: Office dashboard access without auth. Redirecting to /login');
              return '/login';
            }
            if (authProvider.currentUser?.isRealEstateOffice != true) {
              debugPrint('🛣️ Router Redirect: Not a real estate office. Redirecting to /');
              return '/'; // Redirect non-offices to home
            }
          }

          debugPrint('🛣️ Router Redirect: No redirect needed for $path');
          // No redirect needed
          return null;
        } catch (e) {
          // If there's an error accessing AuthProvider, redirect to login
          debugPrint('🛣️ Router Redirect ERROR: $e');
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
        GoRoute(
          path: '/onboarding',
          name: 'onboarding',
          builder: (context, state) => const OnboardingScreen(),
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
        GoRoute(
          path: '/forgot-password',
          name: 'forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),

        
        // Public User Profile Route (must be before protected routes to avoid conflicts)
        GoRoute(
          path: '/user/:userId',
          name: 'public-user-profile',
          builder: (context, state) {
            final userId = state.pathParameters['userId']!;
            return MainLayout(
              currentLocation: state.uri.toString(),
              child: PublicUserProfileScreen(userId: userId),
            );
          },
        ),
        
        // Protected Routes (Require Authentication)
        GoRoute(
          path: '/',
          name: 'home',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: MainLayout(
              currentLocation: state.uri.toString(),
              child: const HomeScreen(),
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
                child: child,
              );
            },
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
          path: '/office-dashboard',
          name: 'office-dashboard',
          builder: (context, state) => MainLayout(
            currentLocation: state.uri.toString(),
            child: const RealEstateOfficeDashboard(),
          ),
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
          path: '/recharge',
          name: 'recharge-callback',
          builder: (context, state) {
            final status = state.uri.queryParameters['status'];
            final message = state.uri.queryParameters['msg'];
            return RechargeCallbackScreen(status: status, message: message);
          },
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
          path: '/boost',
          name: 'boost',
          builder: (context, state) => MainLayout(
            currentLocation: state.uri.toString(),
            child: const BoostScreen(),
          ),
        ),
        GoRoute(
          path: '/boost/:propertyId',
          name: 'boost-property',
          builder: (context, state) {
            final propertyId = state.pathParameters['propertyId'] ?? '';
            return MainLayout(
              currentLocation: state.uri.toString(),
              child: BoostScreen(propertyId: propertyId.isEmpty ? null : propertyId),
            );
          },
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
        
        // Property Detail Route (public - viewable without login)
        GoRoute(
          path: '/property/:propertyId',
          name: 'property-detail',
          pageBuilder: (context, state) {
            final propertyId = state.pathParameters['propertyId']!;
            return CustomTransitionPage(
              key: state.pageKey,
              child: _PropertyDetailLoader(propertyId: propertyId),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            );
          },
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
      errorBuilder: (context, state) {
        final l10n = AppLocalizations.of(context);
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n?.error ?? 'Error'),
            centerTitle: true,
            backgroundColor: const Color(0xFF01352D),
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
                  '${l10n?.pageNotFound ?? 'Page not found'}: ${state.uri}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.go('/'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF01352D),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(l10n?.goHome ?? 'Go Home'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static void refresh() {
    _refreshStream.refresh();
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  void refresh() {
    notifyListeners();
  }
}

class _PropertyDetailLoader extends StatefulWidget {
  final String propertyId;

  const _PropertyDetailLoader({required this.propertyId});

  @override
  State<_PropertyDetailLoader> createState() => _PropertyDetailLoaderState();
}

class _PropertyDetailLoaderState extends State<_PropertyDetailLoader> {
  bool _isLoading = true;
  String? _error;
  Property? _property;

  @override
  void initState() {
    super.initState();
    _loadProperty();
  }

  Future<void> _loadProperty() async {
    try {
      final propertySvc = property_service.PropertyService();
      final property = await propertySvc.getPropertyById(widget.propertyId);
      
      if (mounted) {
        if (property != null) {
          setState(() {
            _property = property;
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = AppLocalizations.of(context)?.propertyNotFound ?? 'Property not found';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '${AppLocalizations.of(context)?.errorLoadingProperty ?? 'Error loading property'}: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_property != null) {
      return PropertyDetailScreen(property: _property!);
    }

    final l10n = AppLocalizations.of(context);
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFF01352D),
          foregroundColor: Colors.white,
          title: Text(l10n?.loading ?? 'Loading...'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const DaryLoadingIndicator(
                color: Color(0xFF01352D),
              ),
              const SizedBox(height: 16),
              Text(
                l10n?.loadingProperty ?? 'Loading property...',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF01352D),
        foregroundColor: Colors.white,
        title: Text(l10n?.error ?? 'Error'),
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
            const SizedBox(height: 16),
            Text(
              _error ?? (l10n?.error ?? 'Unknown error'),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF01352D),
                foregroundColor: Colors.white,
              ),
              child: Text(l10n?.goHome ?? 'Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}
