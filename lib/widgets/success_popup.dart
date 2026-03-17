import 'package:flutter/material.dart';
import '../services/theme_service.dart';

/// A beautiful animated success popup with a checkmark animation
class SuccessPopup extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String buttonText;
  final VoidCallback? onButtonPressed;
  final Color? primaryColor;

  const SuccessPopup({
    super.key,
    required this.title,
    this.subtitle,
    this.buttonText = 'Done',
    this.onButtonPressed,
    this.primaryColor,
  });

  /// Show the success popup as a dialog
  static Future<void> show(
    BuildContext context, {
    required String title,
    String? subtitle,
    String buttonText = 'Done',
    VoidCallback? onButtonPressed,
    Color? primaryColor,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SuccessPopup(
        title: title,
        subtitle: subtitle,
        buttonText: buttonText,
        onButtonPressed: onButtonPressed,
        primaryColor: primaryColor,
      ),
    );
  }

  @override
  State<SuccessPopup> createState() => _SuccessPopupState();
}

class _SuccessPopupState extends State<SuccessPopup>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _checkController;
  late AnimationController _rippleController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;
  late Animation<double> _rippleAnimation;

  @override
  void initState() {
    super.initState();

    // Scale animation for the circle
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    // Check mark drawing animation
    _checkController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _checkAnimation = CurvedAnimation(
      parent: _checkController,
      curve: Curves.easeInOut,
    );

    // Ripple animation
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _rippleAnimation = CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeOut,
    );

    // Start animations in sequence
    _scaleController.forward().then((_) {
      _checkController.forward();
      _rippleController.forward();
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _checkController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.primaryColor ?? const Color(0xFF01352D);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 300),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.easeOut,
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.8 + (0.2 * value),
            child: Opacity(
              opacity: value,
              child: child,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated checkmark with ripple
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Ripple effect
                    AnimatedBuilder(
                      animation: _rippleAnimation,
                      builder: (context, child) {
                        return Container(
                          width: 100 + (40 * _rippleAnimation.value),
                          height: 100 + (40 * _rippleAnimation.value),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primaryColor.withOpacity(
                              0.2 * (1 - _rippleAnimation.value),
                            ),
                          ),
                        );
                      },
                    ),
                    // Second ripple (delayed)
                    AnimatedBuilder(
                      animation: _rippleAnimation,
                      builder: (context, child) {
                        final delayedValue = (_rippleAnimation.value - 0.2).clamp(0.0, 1.0) / 0.8;
                        return Container(
                          width: 100 + (30 * delayedValue),
                          height: 100 + (30 * delayedValue),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primaryColor.withOpacity(
                              0.15 * (1 - delayedValue),
                            ),
                          ),
                        );
                      },
                    ),
                    // Main circle with gradient
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              primaryColor,
                              primaryColor.withValues(alpha: 0.8),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: AnimatedBuilder(
                          animation: _checkAnimation,
                          builder: (context, child) {
                            return CustomPaint(
                              painter: _CheckPainter(
                                progress: _checkAnimation.value,
                                color: Colors.white,
                                strokeWidth: 5,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Title
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 400),
                tween: Tween(begin: 0.0, end: 1.0),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: ThemeService.getDynamicStyle(
                    context,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
              if (widget.subtitle != null) ...[
                const SizedBox(height: 12),
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 500),
                  tween: Tween(begin: 0.0, end: 1.0),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 15 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    widget.subtitle!,
                    textAlign: TextAlign.center,
                    style: ThemeService.getDynamicStyle(
                      context,
                      fontSize: 15,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 28),
              // Button
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 600),
                tween: Tween(begin: 0.0, end: 1.0),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 10 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onButtonPressed?.call();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 4,
                      shadowColor: primaryColor.withValues(alpha: 0.4),
                    ),
                    child: Text(
                      widget.buttonText,
                      style: ThemeService.getDynamicStyle(
                        context,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
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
}

/// Custom painter for drawing an animated checkmark
class _CheckPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _CheckPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    
    // Check mark path points (relative to center)
    final start = Offset(center.dx - 18, center.dy + 2);
    final middle = Offset(center.dx - 4, center.dy + 16);
    final end = Offset(center.dx + 20, center.dy - 12);

    final path = Path();

    if (progress <= 0.5) {
      // Draw first part of check (from start to middle)
      final firstProgress = progress * 2;
      path.moveTo(start.dx, start.dy);
      path.lineTo(
        start.dx + (middle.dx - start.dx) * firstProgress,
        start.dy + (middle.dy - start.dy) * firstProgress,
      );
    } else {
      // Draw complete first part
      path.moveTo(start.dx, start.dy);
      path.lineTo(middle.dx, middle.dy);
      
      // Draw second part of check (from middle to end)
      final secondProgress = (progress - 0.5) * 2;
      path.lineTo(
        middle.dx + (end.dx - middle.dx) * secondProgress,
        middle.dy + (end.dy - middle.dy) * secondProgress,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CheckPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

