import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/property.dart';
import '../screens/property_detail_screen.dart';
import '../services/theme_service.dart';
import '../services/analytics_service.dart';
import '../utils/app_animations.dart';
import 'dary_loading_indicator.dart';

// Set Libya timezone offset (GMT+2)
const libyaTimeZone = Duration(hours: 2);

// Note: _getTimeAgo moved to _PropertyCardState to access context

class PropertyCard extends StatefulWidget {
  final Property property;

  const PropertyCard({
    super.key,
    required this.property,
  });

  @override
  State<PropertyCard> createState() => _PropertyCardState();
}

class _PropertyCardState extends State<PropertyCard> {
  late PageController _pageController;
  int _currentImageIndex = 0;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _getLocalizedTimeAgo(DateTime date) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final libyaDate = now.toUtc().add(libyaTimeZone);
    final propertyDate = date.toUtc().add(libyaTimeZone);
    final difference = libyaDate.difference(propertyDate);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}${l10n?.daysShort ?? 'd'}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}${l10n?.hoursShort ?? 'h'}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}${l10n?.minutesShort ?? 'm'}';
    } else {
      return l10n?.now ?? 'Now';
    }
  }

  void _navigateToDetails() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            PropertyDetailScreen(property: widget.property),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.05),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  // Launch phone call
  Future<void> _launchPhone() async {
    final phone = widget.property.contactPhone;
    if (phone.isNotEmpty) {
      try {
        await AnalyticsService().logContactClick(widget.property.id, 'phone');
        await FirebaseFirestore.instance.collection('properties').doc(widget.property.id).update({
          'phone_clicks': FieldValue.increment(1),
        });
      } catch (e) {
        debugPrint('Analytics error: $e');
      }

      final uri = Uri.parse('tel:$phone');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } else {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n?.phoneNumberNotAvailable ?? 'Phone number not available')),
        );
      }
    }
  }

  // Launch WhatsApp
  Future<void> _launchWhatsApp() async {
    final phone = widget.property.contactPhone;
    if (phone.isNotEmpty) {
      try {
        await AnalyticsService().logContactClick(widget.property.id, 'whatsapp');
        await FirebaseFirestore.instance.collection('properties').doc(widget.property.id).update({
          'whatsapp_clicks': FieldValue.increment(1),
        });
      } catch (e) {
        debugPrint('Analytics error: $e');
      }

      String cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
      if (!cleanPhone.startsWith('+')) {
        cleanPhone = '+218$cleanPhone';
      }
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      final message = l10n?.interestedInProperty(widget.property.title) ?? 'Hi, I\'m interested in your property: ${widget.property.title}';
      final uri = Uri.parse('https://wa.me/${cleanPhone.replaceAll('+', '')}?text=${Uri.encodeComponent(message)}');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } else {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n?.whatsAppNotAvailable ?? 'WhatsApp not available')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.property.imageUrls;
    
    Color? borderColor;
    Color? glowColor;
    double borderWidth = 0;
    String? packageName;
    Color? packageBgColor;
    Color? packageTextColor;
    IconData? packageIcon;
    
    if (widget.property.isBoosted && widget.property.isBoostActive) {
      final boostAmount = widget.property.boostAmount;
      if (boostAmount != null) {
        if (boostAmount >= 300) {
          borderColor = const Color(0xFFFFD700); // Gold
          glowColor = const Color(0xFFFFD700);
          borderWidth = 3;
          packageName = AppLocalizations.of(context)?.boostElite ?? 'ELITE';
          packageBgColor = const Color(0xFFFFD700);
          packageTextColor = Colors.black;
          packageIcon = Icons.diamond;
        } else if (boostAmount >= 100) {
          borderColor = const Color(0xFFC0C0C0); // Silver
          glowColor = const Color(0xFFA0A0A0);
          borderWidth = 3;
          packageName = AppLocalizations.of(context)?.boostPremium ?? 'PREMIUM';
          packageBgColor = const Color(0xFFE8E8E8);
          packageTextColor = Colors.grey[800];
          packageIcon = Icons.local_fire_department; // Flame
        } else if (boostAmount >= 50) {
          borderColor = const Color(0xFF10B981); // Emerald Green
          glowColor = const Color(0xFF10B981);
          borderWidth = 3;
          packageName = AppLocalizations.of(context)?.boostEmerald ?? 'EMERALD';
          packageBgColor = const Color(0xFF10B981);
          packageTextColor = Colors.white;
          packageIcon = Icons.rocket_launch; // Rocket
        } else if (boostAmount >= 20) {
          borderColor = const Color(0xFFCD7F32); // Bronze
          glowColor = const Color(0xFFCD7F32);
          borderWidth = 3;
          packageName = AppLocalizations.of(context)?.boostPlus ?? 'PLUS';
          packageBgColor = const Color(0xFFCD7F32);
          packageTextColor = Colors.white;
          packageIcon = Icons.bolt; // Lightning
        }
      }
    } else if (widget.property.isFeatured) {
      borderColor = const Color(0xFF01352D);
      borderWidth = 2;
    }
    
    return ScaleAnimation(
      onTap: _navigateToDetails,
      scale: 0.98,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 600),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          final clampedOpacity = value.clamp(0.0, 1.0);
          return Transform.scale(
            scale: 0.8 + (0.2 * clampedOpacity),
            child: Opacity(
              opacity: clampedOpacity,
              child: child,
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: glowColor?.withValues(alpha: 0.3) ?? Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: borderColor != null
                  ? BorderSide(color: borderColor, width: borderWidth)
                  : BorderSide(color: Colors.grey[200]!, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: 'property_${widget.property.id}',
                  child: AspectRatio(
                    aspectRatio: 1.1,
                    child: Stack(
                      fit: StackFit.expand,
                    children: [
                      if (images.isNotEmpty)
                        PageView.builder(
                          controller: _pageController,
                          itemCount: images.length,
                          physics: const AlwaysScrollableScrollPhysics(),
                          onPageChanged: (index) => setState(() => _currentImageIndex = index),
                          itemBuilder: (context, index) {
                            return InkWell(
                              onTap: _navigateToDetails,
                              child: CachedNetworkImage(
                                imageUrl: images[index],
                                fit: BoxFit.cover,
                                fadeInDuration: const Duration(milliseconds: 500),
                                fadeInCurve: Curves.easeIn,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey[100],
                                  child: const Center(
                                    child: DaryLoadingIndicator(
                                      size: 30,
                                      strokeWidth: 2,
                                      color: Color(0xFF01352D),
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey[100],
                                  child: const Icon(Icons.home_rounded, size: 40, color: Colors.grey),
                                ),
                              ),
                            );
                          },
                        )
                      else
                        GestureDetector(
                          onTap: _navigateToDetails,
                          child: Container(
                            color: Colors.grey[100],
                            child: const Icon(Icons.home_rounded, size: 40, color: Colors.grey),
                          ),
                        ),
                        
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.4),
                                  Colors.transparent,
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.6),
                                ],
                                stops: const [0.0, 0.2, 0.7, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),

                      Positioned(
                        top: 14,
                        left: 14,
                        right: 14,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  color: _getStatusColor(widget.property.status).withValues(alpha: 0.85),
                                  child: Text(
                                    widget.property.status.getLocalizedName(context).toUpperCase(),
                                    style: ThemeService.getDynamicStyle(
                                      context,
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => setState(() => _isFavorite = !_isFavorite),
                              child: ClipOval(
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    color: Colors.black.withValues(alpha: 0.2),
                                    child: Icon(
                                      _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                      color: _isFavorite ? Colors.red : Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (packageName != null)
                        Positioned(
                          top: 50,
                          left: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: packageBgColor,
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(8),
                                bottomRight: Radius.circular(8),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(packageIcon, size: 12, color: packageTextColor),
                                const SizedBox(width: 4),
                                Text(
                                  packageName,
                                  style: ThemeService.getDynamicStyle(
                                    context,
                                    color: packageTextColor,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      Positioned(
                        bottom: 14,
                        left: 14,
                        right: 14,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.property.getLocalizedPrice(context),
                              style: ThemeService.getDynamicStyle(
                                context,
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (images.length > 1)
                              Row(
                                children: List.generate(
                                  images.length > 6 ? 6 : images.length,
                                  (index) {
                                    final isActive = index == _currentImageIndex;
                                    return AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      margin: const EdgeInsets.only(right: 4),
                                      width: isActive ? 20 : 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(3),
                                        color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.5),
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _navigateToDetails,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  widget.property.title,
                                  style: ThemeService.getDynamicStyle(
                                    context,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1A1A1A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF01352D).withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    widget.property.type.getLocalizedName(context),
                                    style: ThemeService.getDynamicStyle(
                                      context,
                                      color: const Color(0xFF01352D),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded, size: 12, color: Color(0xFF01352D)),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  '${widget.property.neighborhood}, ${widget.property.city}',
                                  style: ThemeService.getDynamicStyle(
                                    context,
                                    color: Colors.grey[600],
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  _getLocalizedTimeAgo(widget.property.createdAt),
                                  style: ThemeService.getDynamicStyle(
                                    context,
                                    color: Colors.grey[400],
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.end,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildModernStat(Icons.bed_rounded, '${widget.property.bedrooms}', AppLocalizations.of(context)?.bedrooms ?? 'Beds'),
                                _buildModernStat(Icons.bathtub_rounded, '${widget.property.bathrooms}', AppLocalizations.of(context)?.bathrooms ?? 'Baths'),
                                _buildModernStat(Icons.square_foot_rounded, '${widget.property.sizeSqm}', AppLocalizations.of(context)?.sqmSuffix ?? 'm²'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildActionButton(
                                  icon: Icons.phone_rounded,
                                  label: AppLocalizations.of(context)?.call ?? 'Call',
                                  color: const Color(0xFF01352D),
                                  onTap: _launchPhone,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildActionButton(
                                  icon: FontAwesomeIcons.whatsapp,
                                  label: AppLocalizations.of(context)?.whatsAppShort ?? 'WA',
                                  color: const Color(0xFF25D366),
                                  onTap: _launchWhatsApp,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildModernStat(IconData icon, String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF01352D)),
        const SizedBox(width: 4),
        Text(
          value,
          style: ThemeService.getDynamicStyle(
            context,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: ThemeService.getDynamicStyle(
                    context,
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(PropertyStatus status) {
    switch (status) {
      case PropertyStatus.forSale:
        return Colors.blue;
      case PropertyStatus.forRent:
        return const Color(0xFF01352D);
      case PropertyStatus.sold:
        return Colors.red;
      case PropertyStatus.rented:
        return Colors.orange;
    }
  }
}
