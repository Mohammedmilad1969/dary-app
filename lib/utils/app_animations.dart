import 'package:flutter/material.dart';

/// Custom page transition animations
class AppPageTransitions {
  /// Slide from right transition
  static PageTransitionsTheme slideFromRight = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: CustomPageTransitionBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
      TargetPlatform.iOS: CustomPageTransitionBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    },
  );

  /// Fade transition
  static PageTransitionsTheme fade = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: CustomPageTransitionBuilder(
        transitionDuration: const Duration(milliseconds: 250),
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
      TargetPlatform.iOS: CustomPageTransitionBuilder(
        transitionDuration: const Duration(milliseconds: 250),
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    },
  );

  /// Scale and fade transition
  static PageTransitionsTheme scaleFade = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: CustomPageTransitionBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOut),
              ),
              child: child,
            ),
          );
        },
      ),
      TargetPlatform.iOS: CustomPageTransitionBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOut),
              ),
              child: child,
            ),
          );
        },
      ),
    },
  );
}

/// Custom page transition builder
class CustomPageTransitionBuilder extends PageTransitionsBuilder {
  final Duration transitionDuration;
  final Widget Function(BuildContext, Animation<double>, Animation<double>, Widget) transitionBuilder;

  const CustomPageTransitionBuilder({
    required this.transitionDuration,
    required this.transitionBuilder,
  });

  @override
  Widget buildTransitions<T extends Object?>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return transitionBuilder(context, animation, secondaryAnimation, child);
  }
}

/// Staggered animation for list items - MORE DRAMATIC
class StaggeredAnimation extends StatelessWidget {
  final int index;
  final Widget child;
  final Duration duration;
  final Curve curve;

  const StaggeredAnimation({
    super.key,
    required this.index,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.curve = Curves.easeOutBack,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: duration.inMilliseconds + (index * 80)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: curve,
      builder: (context, value, child) {
        // Clamp opacity to valid range [0.0, 1.0]
        final clampedOpacity = value.clamp(0.0, 1.0);
        return Opacity(
          opacity: clampedOpacity,
          child: Transform.translate(
            offset: Offset(0, 50 * (1 - clampedOpacity)),
            child: Transform.scale(
              scale: 0.7 + (0.3 * clampedOpacity),
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }
}

/// Scale animation on tap - MORE DRAMATIC
class ScaleAnimation extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final Duration duration;

  const ScaleAnimation({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.92,
    this.duration = const Duration(milliseconds: 200),
  });

  @override
  State<ScaleAnimation> createState() => _ScaleAnimationState();
}

class _ScaleAnimationState extends State<ScaleAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scale).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse().then((_) {
      if (widget.onTap != null) {
        widget.onTap!();
      }
    });
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Shimmer loading effect
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFFE0E0E0),
    this.highlightColor = const Color(0xFFF5F5F5),
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1.0 - _controller.value * 2, 0.0),
              end: Alignment(1.0 + _controller.value * 2, 0.0),
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// Fade in animation
class FadeInAnimation extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final double delay;

  const FadeInAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
    this.curve = Curves.easeOut,
    this.delay = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      tween: Tween(begin: 0.0, end: 1.0),
      curve: curve,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: child,
        );
      },
      child: child,
    );
  }
}

/// Slide in from bottom animation
class SlideInFromBottom extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;

  const SlideInFromBottom({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
    this.curve = Curves.easeOutCubic,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      tween: Tween(begin: 0.0, end: 1.0),
      curve: curve,
      builder: (context, value, child) {
        // Clamp opacity to valid range [0.0, 1.0]
        final clampedOpacity = value.clamp(0.0, 1.0);
        return Transform.translate(
          offset: Offset(0, 50 * (1 - clampedOpacity)),
          child: Opacity(
            opacity: clampedOpacity,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

