import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../services/user_preferences_service.dart';
import '../services/connectivity_service.dart';
import '../l10n/app_localizations.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _exitController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late AnimationController _orbsController;
  
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _exitScale;
  late Animation<double> _exitOpacity;
  late Animation<double> _shimmerPosition;
  late Animation<double> _bgScale;
  late Animation<double> _orbsOpacity;

  @override
  void initState() {
    super.initState();
    
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _orbsController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    _logoScale = CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeOutBack,
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _exitScale = Tween<double>(begin: 1.0, end: 15.0).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: Curves.easeInQuint,
      ),
    );

    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _shimmerPosition = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(
        parent: _shimmerController,
        curve: Curves.easeInOutSine,
      ),
    );

    _bgScale = Tween<double>(begin: 1.15, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: Curves.easeOutCubic,
      ),
    );

    _orbsOpacity = Tween<double>(begin: 0.0, end: 0.4).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );

    _mainController.forward();

    // Start sequence
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    try {
      final connectivity = Provider.of<ConnectivityService>(context, listen: false);
      
      // Wait for service to initialize
      await connectivity.initialized;
      
      if (connectivity.isOffline) {
        _showOfflineError();
        return;
      }

      // If online, wait for the actual splash delay
      await Future.delayed(const Duration(milliseconds: 3000));
      
      if (mounted) {
        await _handleExitSequence();
      }
    } catch (e) {
      if (mounted) context.go('/');
    }
  }

  Future<void> _handleExitSequence() async {
    // Start the zoom-in exit animation
    await _exitController.forward();
    
    if (mounted) {
      _finishNavigation();
    }
  }

  Future<void> _finishNavigation() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.initialize();
      
      if (mounted) {
        final userPrefs = UserPreferencesService();
        final hasSeenOnboarding = await userPrefs.hasSeenOnboarding();

        if (!hasSeenOnboarding) {
          context.go('/onboarding');
          return;
        }
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        _showOfflineError(); // Show error if any critical fail (like auth init without net)
      }
    }
  }

  void _showOfflineError() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.wifi_off, color: Colors.red),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context)?.noInternetConnection ?? 'No Internet'),
          ],
        ),
        content: Text(AppLocalizations.of(context)?.pleaseCheckConnection ?? 'Please check your internet connection and try again.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToNext();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mainController.dispose();
    _exitController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    _orbsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF001A16),
      body: AnimatedBuilder(
        animation: _exitController,
        builder: (context, child) {
          return Opacity(
            opacity: _exitOpacity.value,
            child: Transform.scale(
              scale: _exitScale.value,
              child: child,
            ),
          );
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Immersive Deep Gradient
            ScaleTransition(
              scale: _bgScale,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.2,
                    colors: [
                      Color(0xFF01453B),
                      Color(0xFF012B24),
                      Color(0xFF001A16),
                    ],
                  ),
                ),
              ),
            ),

            // 2. Ambient Floating Orbs
            AnimatedBuilder(
              animation: _orbsController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _orbsOpacity,
                  child: Stack(
                    children: [
                      _buildAmbientOrb(
                        context,
                        _orbsController.value * 2 * 3.1415,
                        150,
                        const Color(0xFF00FFD1).withValues(alpha: 0.08),
                        200,
                      ),
                      _buildAmbientOrb(
                        context,
                        (_orbsController.value + 0.5) * 2 * 3.1415,
                        200,
                        const Color(0xFF025141).withValues(alpha: 0.12),
                        250,
                      ),
                    ],
                  ),
                );
              },
            ),

            // 3. Central Brand Composition
            FadeTransition(
              opacity: _logoOpacity,
              child: ScaleTransition(
                scale: _logoScale,
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        _buildLayeredGlow(220, 0.15),
                        _buildLayeredGlow(180, 0.25),
                        Container(
                          width: 120, // Reduced from 160
                          height: 120, // Reduced from 160
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00FFD1).withValues(alpha: 0.4),
                                blurRadius: 30,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Image.asset(
                              'assets/images/dary_logo.png',
                              width: 80, // Reduced from 110
                              height: 80, // Reduced from 110
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        _buildShimmerOverlay(160),
                      ],
                    );
                  },
                ),
              ),
            ),

            // 4. Pro Loading Indicator
            Positioned(
              bottom: 120,
              child: Column(
                children: [
                  FadeTransition(
                    opacity: _logoOpacity.where((v) => _exitController.value == 0),
                    child: Container(
                      width: 160,
                      height: 2,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Stack(
                        children: [
                          _buildAnimatedProgressLine(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLayeredGlow(double size, double opacity) {
    return Container(
      width: size + (_pulseController.value * 20),
      height: size + (_pulseController.value * 20),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            const Color(0xFF00FFD1).withValues(alpha: opacity),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerOverlay(double size) {
    return ClipOval(
      child: AnimatedBuilder(
        animation: _shimmerController,
        builder: (context, child) {
          return ShaderMask(
            shaderCallback: (rect) {
              return LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [
                  _shimmerPosition.value - 0.3,
                  _shimmerPosition.value,
                  _shimmerPosition.value + 0.3,
                ],
                colors: [
                  Colors.transparent,
                  Colors.white.withValues(alpha: 0.2),
                  Colors.transparent,
                ],
              ).createShader(rect);
            },
            blendMode: BlendMode.srcATop,
            child: Container(
              width: size,
              height: size,
              color: Colors.transparent,
            ),
          );
        },
      ),
    );
  }

  Widget _buildAmbientOrb(BuildContext context, double angle, double radius, Color color, double size) {
    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, Colors.transparent],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedProgressLine() {
    return AnimatedBuilder(
      animation: _mainController,
      builder: (context, child) {
        return FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: Curves.easeInOut.transform(_mainController.value.clamp(0.0, 1.0)),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF00FFD1),
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00FFD1).withValues(alpha: 0.5),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

extension AnimationExtensions on Animation<double> {
  Animation<double> where(bool Function(double) condition) {
    return vmap((v) => condition(v) ? v : 0.0);
  }
  
  Animation<double> vmap(double Function(double) mapper) {
    return ProxyAnimation(this).drive(CurveTween(curve: _VMapCurve(mapper)));
  }
}

class _VMapCurve extends Curve {
  final double Function(double) mapper;
  const _VMapCurve(this.mapper);
  @override
  double transform(double t) => mapper(t);
}
