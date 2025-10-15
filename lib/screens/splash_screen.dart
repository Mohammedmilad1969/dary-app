import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../services/language_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
    ));

    // Start animation and session check
    _startSplashSequence();
  }

  Future<void> _startSplashSequence() async {
    // Start the animation
    _animationController.forward();
    
    // Wait for minimum splash duration (for better UX)
    await Future.delayed(const Duration(milliseconds: 1500));
    
    // Check authentication session
    await _checkAuthenticationSession();
  }

  Future<void> _checkAuthenticationSession() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      if (kDebugMode) {
        debugPrint('🔄 SplashScreen: Starting session check...');
      }
      
      // Initialize auth provider (this will check for existing session)
      await authProvider.initialize();
      
      if (kDebugMode) {
        debugPrint('✅ SplashScreen: Session check completed');
        debugPrint('📊 SplashScreen: User authenticated: ${authProvider.isAuthenticated}');
        if (authProvider.isAuthenticated) {
          debugPrint('👤 SplashScreen: User: ${authProvider.userEmail}');
        }
      }
      
      // Wait a bit more for smooth transition
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        // Always go to homepage (guest mode)
        if (kDebugMode) {
          debugPrint('🏠 SplashScreen: Navigating to homepage (guest mode)');
          if (authProvider.isAuthenticated) {
            debugPrint('👤 SplashScreen: User is logged in: ${authProvider.userEmail}');
          } else {
            debugPrint('👤 SplashScreen: User is in guest mode');
          }
        }
        context.go('/');
      }
    } catch (e) {
      // If there's an error, go to login as fallback
      if (kDebugMode) {
        debugPrint('❌ SplashScreen: Session check error: $e');
        debugPrint('🔐 SplashScreen: Falling back to login');
      }
      if (mounted) {
        context.go('/');
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo/Icon with Animation
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.home,
                        size: 60,
                        color: Colors.green,
                      ),
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 32),
            
            // App Name with Animation
            AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      const Text(
                        'Dary',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Properties',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white.withOpacity(0.8),
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            
            const SizedBox(height: 48),
            
            // Loading Indicator
            AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Checking session...',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
