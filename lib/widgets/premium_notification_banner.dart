import 'package:flutter/material.dart';
import 'dart:async';
import '../services/theme_service.dart';

class PremiumNotificationBanner extends StatefulWidget {
  final String title;
  final String message;
  final String? imageUrl;
  final String? initials;
  final VoidCallback onTap;
  final VoidCallback onDismiss;
  final Duration duration;

  const PremiumNotificationBanner({
    super.key,
    required this.title,
    required this.message,
    this.imageUrl,
    this.initials,
    required this.onTap,
    required this.onDismiss,
    this.duration = const Duration(seconds: 4),
  });

  @override
  State<PremiumNotificationBanner> createState() => _PremiumNotificationBannerState();

  static void show(
    BuildContext context, {
    required String title,
    required String message,
    String? imageUrl,
    String? initials,
    required VoidCallback onTap,
    Duration duration = const Duration(seconds: 4),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 70,
        left: 16,
        right: 16,
        child: PremiumNotificationBanner(
          title: title,
          message: message,
          imageUrl: imageUrl,
          initials: initials,
          duration: duration,
          onTap: () {
            onTap();
            overlayEntry.remove();
          },
          onDismiss: () {
            if (overlayEntry.mounted) {
              overlayEntry.remove();
            }
          },
        ),
      ),
    );

    overlay.insert(overlayEntry);
  }
}

class _PremiumNotificationBannerState extends State<PremiumNotificationBanner> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();

    _dismissTimer = Timer(widget.duration, () {
      _dismiss();
    });
  }

  void _dismiss() {
    if (mounted) {
      _controller.reverse().then((_) {
        widget.onDismiss();
      });
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    return SlideTransition(
      position: _offsetAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: GestureDetector(
          onVerticalDragUpdate: (details) {
            if (details.primaryDelta! < -10) {
              _dismiss();
            }
          },
          onTap: widget.onTap,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF01352D), // Brand dark green
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  // Avatar or Icon
                  _buildAvatar(theme),
                  const SizedBox(width: 12),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          style: ThemeService.getDynamicStyle(
                            context,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.message,
                          style: ThemeService.getDynamicStyle(
                            context,
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.9),
                            height: 1.2,
                          ),
                          maxLines: 1, // Keep it to 1 line for foreground banners
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // View Action
                  Text(
                    isRTL ? 'عرض' : 'View',
                    style: ThemeService.getDynamicStyle(
                      context,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(ThemeData theme) {
    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: NetworkImage(widget.imageUrl!),
            fit: BoxFit.cover,
          ),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
        ),
      );
    } else if (widget.initials != null && widget.initials!.isNotEmpty) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: theme.colorScheme.secondary.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(
          widget.initials!,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      );
    } else {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.chat_bubble_outline,
          color: Colors.white,
          size: 24,
        ),
      );
    }
  }
}
