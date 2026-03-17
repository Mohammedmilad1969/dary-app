import 'package:flutter/material.dart';
import 'dary_loading_indicator.dart';

/// Global loading overlay widget
class LoadingOverlay extends StatefulWidget {
  final Widget child;
  final bool isLoading;
  final String? message;

  const LoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.message,
  });

  @override
  State<LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<LoadingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    // Initialize animation state based on initial loading state
    if (widget.isLoading) {
      _controller.value = 1.0;
    } else {
      _controller.value = 0.0;
    }
  }

  @override
  void didUpdateWidget(LoadingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading && !oldWidget.isLoading) {
      _controller.forward();
    } else if (!widget.isLoading && oldWidget.isLoading) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.isLoading)
          FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DaryLoadingIndicator(
                        size: 40,
                        color: Colors.green,
                      ),
                      if (widget.message != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          widget.message!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Page transition loading wrapper
class PageTransitionLoading extends StatelessWidget {
  final Widget child;
  final bool isLoading;

  const PageTransitionLoading({
    super.key,
    required this.child,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: isLoading,
      message: 'Loading...',
      child: child,
    );
  }
}

