import 'package:flutter/material.dart';

class DaryLoadingIndicator extends StatefulWidget {
  final double size;
  final Color? color;
  final double strokeWidth;

  const DaryLoadingIndicator({
    super.key,
    this.size = 40.0,
    this.color,
    this.strokeWidth = 3.0,
  });

  @override
  State<DaryLoadingIndicator> createState() => _DaryLoadingIndicatorState();
}

class _DaryLoadingIndicatorState extends State<DaryLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Default to Dary primary color if none provided
    final targetColor = widget.color ?? const Color(0xFF01352D);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scaleValue = 1.0 + (0.05 * (1.0 - (_controller.value - 0.5).abs() * 2));
        
        return Transform.scale(
          scale: scaleValue,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background subtle track
                CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: widget.strokeWidth,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    targetColor.withOpacity(0.15),
                  ),
                ),
                // Spinning track
                RotationTransition(
                  turns: Tween(begin: 0.0, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _controller,
                      curve: Curves.easeInOutCubic,
                    ),
                  ),
                  child: CircularProgressIndicator(
                    value: 0.25,
                    strokeWidth: widget.strokeWidth,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(targetColor),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
