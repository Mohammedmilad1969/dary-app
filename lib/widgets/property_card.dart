import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:dary/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../models/property.dart';
import '../screens/property_detail_screen.dart';
import '../services/theme_service.dart';
import '../providers/auth_provider.dart';
import '../utils/app_animations.dart';

// Set Libya timezone offset (GMT+2)
const libyaTimeZone = Duration(hours: 2);

/// Helper function to format time ago (e.g., "2 hours ago", "3 days ago")
String _getTimeAgo(DateTime date) {
  final now = DateTime.now();
  final libyaDate = now.toUtc().add(libyaTimeZone);
  final propertyDate = date.toUtc().add(libyaTimeZone);
  final difference = libyaDate.difference(propertyDate);
  
  if (difference.inDays > 0) {
    return '${difference.inDays} ${difference.inDays == 1 ? "day" : "days"} ago';
  } else if (difference.inHours > 0) {
    return '${difference.inHours} ${difference.inHours == 1 ? "hour" : "hours"} ago';
  } else if (difference.inMinutes > 0) {
    return '${difference.inMinutes} ${difference.inMinutes == 1 ? "minute" : "minutes"} ago';
  } else {
    return 'Just now';
  }
}

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    // Determine border color and width based on boost amount
    Color? borderColor;
    double borderWidth = 0;
    
    if (widget.property.isBoosted && widget.property.isBoostActive) {
      final boostAmount = widget.property.boostAmount;
      if (boostAmount != null) {
        if (boostAmount >= 300) {
          // Gold border for 300+ LYD
          borderColor = const Color(0xFFFFD700); // Gold color
          borderWidth = 3;
        } else if (boostAmount >= 100) {
          // Silver border for 100+ LYD
          borderColor = const Color(0xFFC0C0C0); // Silver color
          borderWidth = 3;
        } else if (boostAmount >= 20) {
          // Bronze border for 20+ LYD
          borderColor = const Color(0xFFCD7F32); // Bronze color
          borderWidth = 3;
        }
      }
    } else if (widget.property.isFeatured) {
      // Green border for featured properties
      borderColor = Colors.green;
      borderWidth = 2;
    }
    
    return Hero(
      tag: 'property_${widget.property.id}',
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 600),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          // Clamp opacity to valid range [0.0, 1.0]
          final clampedOpacity = value.clamp(0.0, 1.0);
          return Transform.scale(
            scale: 0.8 + (0.2 * clampedOpacity),
            child: Opacity(
              opacity: clampedOpacity,
              child: child,
            ),
          );
        },
        child: Card(
          margin: EdgeInsets.zero, // Remove margins - spacing handled by parent grid/list
          clipBehavior: Clip.antiAlias,
          elevation: widget.property.isBoosted ? 10 : (widget.property.isFeatured ? 6 : 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: borderColor != null
                ? BorderSide(color: borderColor, width: borderWidth)
                : BorderSide.none,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        PropertyDetailScreen(property: widget.property),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeTransition(
                        opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.0, 0.3),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          )),
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                              CurvedAnimation(parent: animation, curve: Curves.easeOut),
                            ),
                            child: child,
                          ),
                        ),
                      );
                    },
                    transitionDuration: const Duration(milliseconds: 400),
                  ),
                );
              },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Big cover image with badges
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: SizedBox(
                height: 160,
                width: double.infinity,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: widget.property.imageUrls.isNotEmpty
                          ? PageView.builder(
                              controller: _pageController,
                              onPageChanged: (index) {
                                setState(() {
                                  _currentImageIndex = index;
                                });
                              },
                              itemCount: widget.property.imageUrls.length,
                              itemBuilder: (context, index) {
                                return CachedNetworkImage(
                                  imageUrl: widget.property.imageUrls[index],
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => const Icon(
                                    Icons.home,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            )
                          : const Icon(Icons.home, size: 48, color: Colors.grey),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: _buildBadge(context, widget.property.status.statusDisplayName, _getStatusColor(widget.property.status)),
                    ),
                    if (widget.property.isBoosted && widget.property.isBoostActive)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: _buildBadge(context, 'Premium', Colors.purple),
                      )
                    else if (widget.property.isFeatured)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: _buildBadge(context, 'Featured', Colors.amber),
                      ),
                    // Image indicators
                    if (widget.property.imageUrls.length > 1)
                      Positioned(
                        bottom: 12,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            widget.property.imageUrls.length,
                            (index) => Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentImageIndex == index
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.4),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            // Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Agent and listed time
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.green[100],
                        child: Text(
                          widget.property.agentName.split(' ').map((n) => n.isNotEmpty ? n[0] : '').join(),
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green[700]),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.property.agentName,
                          style: ThemeService.getBodyStyle(context, fontSize: 12, color: Colors.grey[700]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          _getTimeAgo(widget.property.createdAt),
                          style: ThemeService.getBodyStyle(context, fontSize: 10, color: Colors.grey[700]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Property Title
                  Text(
                    widget.property.title,
                    style: ThemeService.getBodyStyle(context, fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.property.type.typeDisplayName,
                    style: ThemeService.getBodyStyle(context, fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.property.displayPrice,
                    style: ThemeService.getBodyStyle(context, fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 13, color: Colors.grey[700]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${widget.property.neighborhood}, ${widget.property.city}',
                          style: ThemeService.getBodyStyle(context, fontSize: 12, color: Colors.grey[600]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _buildMetric(context, Icons.bed, '${widget.property.bedrooms}'),
                      _buildMetric(context, Icons.bathtub, '${widget.property.bathrooms}'),
                      _buildMetric(context, Icons.square_foot, '${widget.property.sizeSqm} m²'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          context,
                          icon: Icons.call,
                          label: 'Call',
                          color: Colors.deepPurple,
                          onTap: () {
                            final authProvider = Provider.of<AuthProvider>(context, listen: false);
                            if (!authProvider.isAuthenticated) {
                              _showLoginPrompt(context);
                              return;
                            }
                            _onCallTap(context);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildActionButton(
                          context,
                          icon: Icons.chat,
                          label: 'WhatsApp',
                          color: const Color(0xFF25D366),
                          onTap: () {
                            final authProvider = Provider.of<AuthProvider>(context, listen: false);
                            if (!authProvider.isAuthenticated) {
                              _showLoginPrompt(context);
                              return;
                            }
                            _onWhatsAppTap(context);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
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

  Widget _buildBadge(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Text(
        text,
        style: ThemeService.getBodyStyle(
          context,
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMetric(BuildContext context, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.grey[600]),
        const SizedBox(width: 3),
        Text(
          text,
          style: ThemeService.getBodyStyle(
            context,
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  void _showLoginPrompt(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Required'),
        content: const Text('Please login to contact the seller.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to login page
              context.go('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, {required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return ScaleAnimation(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: ThemeService.getBodyStyle(context, fontSize: 12, fontWeight: FontWeight.w600, color: color),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onCallTap(BuildContext context) async {
    final phoneNumber = widget.property.contactPhone;
    
    if (phoneNumber.isEmpty) {
      // If no phone number, navigate to detail page
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PropertyDetailScreen(property: widget.property),
        ),
      );
      return;
    }
    
    // Format phone number (remove any non-digit characters except +)
    final cleanedPhone = phoneNumber.replaceAll(' ', '').replaceAll('-', '').replaceAll('(', '').replaceAll(')', '');
    final uri = Uri(scheme: 'tel', path: cleanedPhone);
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cannot make phone call from this device')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _onWhatsAppTap(BuildContext context) async {
    final phoneNumber = widget.property.contactPhone;
    
    if (phoneNumber.isEmpty) {
      // If no phone number, navigate to detail page
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PropertyDetailScreen(property: widget.property),
        ),
      );
      return;
    }
    
    // Format phone number for WhatsApp (remove any non-digit characters except +)
    final cleanedPhone = phoneNumber.replaceAll(' ', '').replaceAll('-', '').replaceAll('(', '').replaceAll(')', '');
    
    // Create WhatsApp message with property details
    final message = 'Hello! I am interested in this property:\n'
        '${widget.property.title}\n'
        'Location: ${widget.property.city}, ${widget.property.neighborhood}\n'
        'Price: ${widget.property.status == PropertyStatus.forRent ? "LYD ${widget.property.monthlyRent}/month" : "LYD ${widget.property.price}"}\n'
        'Type: ${widget.property.type.typeDisplayName}';
    
    // Format for WhatsApp - handle Libya country code (+218)
    String whatsappNumber;
    if (cleanedPhone.startsWith('+218')) {
      // Already has Libya country code
      whatsappNumber = cleanedPhone.substring(1); // Remove the +
    } else if (cleanedPhone.startsWith('218')) {
      // Has country code without +
      whatsappNumber = cleanedPhone;
    } else if (cleanedPhone.startsWith('09') || cleanedPhone.startsWith('9')) {
      // Libyan local number, add country code
      whatsappNumber = '218${cleanedPhone.startsWith('09') ? cleanedPhone.substring(1) : cleanedPhone}';
    } else {
      // Assume it already has country code, just remove + if present
      whatsappNumber = cleanedPhone.startsWith('+') ? cleanedPhone.substring(1) : cleanedPhone;
    }
    
    final uri = Uri.parse('https://wa.me/$whatsappNumber?text=${Uri.encodeComponent(message)}');
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cannot open WhatsApp from this device')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _buildDetailItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactDetailItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: Colors.grey[600]),
        const SizedBox(width: 2),
        Text(
          text,
          style: TextStyle(
            fontSize: 9,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildFeatureChips() {
    List<Widget> chips = [];
    
    if (widget.property.hasBalcony) chips.add(_buildFeatureChip('Balcony'));
    if (widget.property.hasGarden) chips.add(_buildFeatureChip('Garden'));
    if (widget.property.hasParking) chips.add(_buildFeatureChip('Parking'));
    if (widget.property.hasPool) chips.add(_buildFeatureChip('Pool'));
    if (widget.property.hasGym) chips.add(_buildFeatureChip('Gym'));
    if (widget.property.hasSecurity) chips.add(_buildFeatureChip('Security'));
    if (widget.property.hasElevator) chips.add(_buildFeatureChip('Elevator'));
    if (widget.property.hasAC) chips.add(_buildFeatureChip('AC'));
    if (widget.property.hasFurnished) chips.add(_buildFeatureChip('Furnished'));
    
    // Limit to 4 chips to avoid overflow
    return chips.take(4).toList();
  }

  Widget _buildFeatureChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 7,
          color: Colors.green[700],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getStatusColor(PropertyStatus status) {
    switch (status) {
      case PropertyStatus.forSale:
        return Colors.blue;
      case PropertyStatus.forRent:
        return Colors.green;
      case PropertyStatus.sold:
        return Colors.red;
      case PropertyStatus.rented:
        return Colors.orange;
    }
  }

  bool _isSellerVerified(String contactEmail) {
    // Import AuthService to check seller verification status
    // For now, we'll use a simple mapping based on known verified emails
    const verifiedEmails = [
      'john.doe@example.com',
      'jane.smith@example.com', 
      'small@test.com',
      't',
    ];
    return verifiedEmails.contains(contactEmail);
  }
}
