import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/user_profile.dart';
import '../models/property.dart';
import '../providers/auth_provider.dart';
import '../screens/property_detail_screen.dart';
import '../screens/add_property_screen.dart';
// Removed obsolete import
import '../services/property_service.dart' as property_service;
import '../services/theme_service.dart';
import '../l10n/app_localizations.dart';

class UserListingCard extends StatefulWidget {
  final UserListing listing;
  final VoidCallback? onUpdated;

  const UserListingCard({
    super.key,
    required this.listing,
    this.onUpdated,
  });

  @override
  State<UserListingCard> createState() => _UserListingCardState();
}

class _UserListingCardState extends State<UserListingCard> {
  bool _isProcessing = false;
  AppLocalizations? get l10n => AppLocalizations.of(context);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final propertyService =
        Provider.of<property_service.PropertyService>(context, listen: false);

    Property? property;
    try {
      property = propertyService.properties.firstWhere(
        (p) => p.id == widget.listing.id,
      );
    } catch (e) {
      return _buildCardFromListing(context);
    }

    final nonNullProperty = property;

    Color? borderColor;
    double borderWidth = 0;

    if (nonNullProperty.isBoosted && nonNullProperty.isBoostActive) {
      final boostAmount = nonNullProperty.boostAmount;
      if (boostAmount != null) {
        if (boostAmount >= 300) {
          borderColor = const Color(0xFFFFD700); // Gold
          borderWidth = 3;
        } else if (boostAmount >= 100) {
          borderColor = const Color(0xFFC0C0C0); // Silver
          borderWidth = 3;
        } else if (boostAmount >= 20) {
          borderColor = const Color(0xFFCD7F32); // Bronze
          borderWidth = 3;
        }
      }
    } else if (nonNullProperty.isFeatured) {
      borderColor = Colors.green;
      borderWidth = 2;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: borderColor != null
            ? Border.all(color: borderColor.withValues(alpha: 0.5), width: borderWidth)
            : Border.all(color: Colors.grey[50]!, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                    PropertyDetailScreen(property: nonNullProperty),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center, // Center menu with content
              children: [
                Expanded(
                  child: _buildPropertyContent(nonNullProperty, context),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleMenuAction(
                      context, value, nonNullProperty, propertyService),
                  icon: Icon(Icons.more_vert_rounded, color: Colors.grey[600]),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, size: 20, color: Colors.blue[700]),
                          const SizedBox(width: 12),
                          Text(l10n?.editDetails ?? 'Edit Details'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: nonNullProperty.isPublished
                          ? 'unpublish'
                          : 'publish',
                      child: Row(
                        children: [
                          Icon(
                            nonNullProperty.isPublished
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            size: 20,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(width: 12),
                          Text(nonNullProperty.isPublished
                              ? (l10n?.unpublish ?? 'Unpublish')
                              : (l10n?.publishNow ?? 'Publish Now')),
                        ],
                      ),
                    ),
                    if (nonNullProperty.isExpired || (DateTime.now().difference(nonNullProperty.createdAt).inDays >= 53))
                      PopupMenuItem(
                        value: 'renew',
                        child: Row(
                          children: [
                            const Icon(Icons.refresh_rounded, size: 20, color: Colors.green),
                            const SizedBox(width: 12),
                            Text(l10n?.renewListing ?? 'Renew Listing'),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red),
                          const SizedBox(width: 12),
                          Text(l10n?.deleteForever ?? 'Delete Forever', style: ThemeService.getDynamicStyle(context, color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyContent(Property property, BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Property Image (Slightly smaller for more text room)
        Stack(
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.grey[50],
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: widget.listing.imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        widget.listing.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.home_work_rounded, size: 40, color: Colors.grey[200]);
                        },
                      ),
                    )
                  : Icon(
                      Icons.home_work_rounded,
                      size: 40,
                      color: Colors.grey[200],
                    ),
            ),
            if (property.isPublished)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF01352D).withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: const Icon(Icons.check_rounded, size: 10, color: Colors.white),
                ),
              ),
          ],
        ),
        const SizedBox(width: 20), // Increased gutter
        
        // Property Info
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.listing.title,
                        style: ThemeService.getDynamicStyle(
                          context,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF111111),
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (property.isVerified)
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(Icons.verified_rounded, size: 16, color: Color(0xFF2196F3)),
                      ),
                    if (property.isFeatured)
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(Icons.star_rounded, size: 16, color: Color(0xFFFFB300)),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      property.getLocalizedPrice(context),
                      style: ThemeService.getDynamicStyle(
                        context,
                        fontSize: 15,
                        color: const Color(0xFF01352D),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '• ${widget.listing.city}',
                      style: ThemeService.getDynamicStyle(
                        context,
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Luxury Metadata Wrap (To handle narrow screens)
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _buildMetaIcon(Icons.king_bed_outlined, '${property.bedrooms}'),
                    _buildMetaIcon(Icons.bathtub_outlined, '${property.bathrooms}'),
                    _buildMetaIcon(Icons.square_foot_rounded, '${property.sizeSqm}m²'),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Views and Expiry Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.remove_red_eye_outlined, size: 12, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.listing.views}',
                            style: ThemeService.getDynamicStyle(
                              context,
                              fontSize: 11,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildExpiryIndicator(widget.listing),
                  ],
                ),
                const SizedBox(height: 10),
                
                // Status Badges Wrap (To prevent overflow)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Published Badge (Glassmorphic)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: property.isPublished
                            ? const Color(0xFF01352D).withValues(alpha: 0.08)
                            : Colors.orange.withValues(alpha: 0.08), 
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: property.isPublished
                              ? const Color(0xFF01352D).withValues(alpha: 0.1)
                              : Colors.orange.withValues(alpha: 0.1),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        (property.isPublished ? (l10n?.publishedStatus ?? 'Published') : (l10n?.unpublishedStatus ?? 'Unpublished')).toUpperCase(),
                        style: ThemeService.getDynamicStyle(
                          context,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          color: property.isPublished
                              ? const Color(0xFF01352D)
                              : Colors.orange[900],
                        ),
                      ),
                    ),
                    
                    // Boosted Badge (Glow)
                    if (widget.listing.isBoosted && widget.listing.isBoostActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF01352D), Color(0xFF025C4E)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF01352D).withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.bolt_rounded, size: 10, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              (l10n?.boostedStatusBadge ?? 'BOOSTED').toUpperCase(),
                              style: ThemeService.getDynamicStyle(
                                context,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                
                // Boost status text if available
                if (widget.listing.isBoosted) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.listing.getLocalizedBoostStatus(context) ?? '',
                    style: ThemeService.getDynamicStyle(
                      context,
                      fontSize: 11,
                      color: widget.listing.isBoostActive
                          ? Colors.amber[800]
                          : Colors.grey[500],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
  }

  Widget _buildExpiryIndicator(UserListing listing) {
    final now = DateTime.now();
    final expiryDate = listing.createdAt.add(const Duration(days: 60));
    final difference = expiryDate.difference(now);
    final daysLeft = difference.inDays;

    if (listing.isExpired || daysLeft <= 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red[100]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 12, color: Colors.red[700]),
            const SizedBox(width: 4),
            Text(
              l10n?.expiredStatus ?? 'Expired',
              style: ThemeService.getDynamicStyle(
                context,
                fontSize: 10,
                color: Colors.red[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    Color bgColor = const Color(0xFFF0F9F4);
    Color textColor = const Color(0xFF108548);
    IconData icon = Icons.timer_outlined;
    String label = '$daysLeft days left';

    if (daysLeft < 7) {
      bgColor = Colors.orange[50]!;
      textColor = Colors.orange[800]!;
      icon = Icons.warning_amber_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: textColor),
          const SizedBox(width: 5),
          Text(
            l10n?.daysLeftCount(daysLeft) ?? '$daysLeft days left',
            style: ThemeService.getDynamicStyle(
              context,
              fontSize: 10,
              color: textColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardFromListing(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.listing.title,
                    style: ThemeService.getBodyStyle(
                      context,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${widget.listing.price.toStringAsFixed(0)} • ${widget.listing.city}',
                    style: ThemeService.getBodyStyle(
                      context,
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(
                  context,
                  value,
                  null,
                  Provider.of<property_service.PropertyService>(context,
                      listen: false)),
              itemBuilder: (BuildContext context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      const Icon(Icons.edit, size: 20, color: Colors.blue),
                      const SizedBox(width: 8),
                       Text(
                        l10n?.edit ?? 'Edit', 
                        style: ThemeService.getDynamicStyle(context, color: Colors.blue),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: widget.listing.isPublished ? 'unpublish' : 'publish',
                  child: Row(
                    children: [
                      Icon(
                        widget.listing.isPublished
                            ? Icons.visibility_off
                            : Icons.visibility,
                        size: 20,
                        color: Colors.grey[700],
                      ),
                      const SizedBox(width: 8),
                      Text(widget.listing.isPublished ? (l10n?.unpublish ?? 'Unpublish') : (l10n?.publish ?? 'Publish')),
                    ],
                  ),
                ),
                if (widget.listing.isExpired || (DateTime.now().difference(widget.listing.createdAt).inDays >= 53))
                PopupMenuItem(
                  value: 'renew',
                  child: Row(
                    children: [
                      const Icon(Icons.refresh, size: 20, color: Colors.green),
                      const SizedBox(width: 8),
                       Text(
                        l10n?.renew ?? 'Renew', 
                        style: ThemeService.getDynamicStyle(context, color: Colors.green),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete, size: 20, color: Colors.red),
                      const SizedBox(width: 8),
                       Text(
                        l10n?.delete ?? 'Delete', 
                        style: ThemeService.getDynamicStyle(context, color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleMenuAction(
    BuildContext context,
    String action,
    Property? property,
    property_service.PropertyService propertyService,
  ) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      switch (action) {
        case 'edit':
          // Navigate to edit property screen
          final propertyToEdit = property ?? propertyService.properties.firstWhere(
            (p) => p.id == widget.listing.id,
            orElse: () => throw Exception('Property not found'),
          );
          
          if (mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AddPropertyScreen(propertyToEdit: propertyToEdit),
              ),
            ).then((_) {
              // Refresh listings after returning from edit screen
              widget.onUpdated?.call();
            });
          }
          break;
          
        case 'unpublish':
          final propertyId = property?.id ?? widget.listing.id;
          final success = await propertyService.unpublishProperty(propertyId);
          if (mounted) {
            _showSnackBar(
                context,
                success
                    ? (l10n?.unpublishSuccess ?? 'Property unpublished successfully')
                    : (l10n?.unpublishFailed ?? 'Failed to unpublish property'),
                success);
            if (success) {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final currentUser = authProvider.currentUser;
              if (currentUser != null) {
                await ProfileService.loadUserProperties(currentUser.id);
              }
              widget.onUpdated?.call();
            }
          }
          break;

        case 'publish':
          final propertyId = property?.id ?? widget.listing.id;
          
          final success = await propertyService.publishProperty(propertyId);
          if (mounted) {
            if (!success && propertyService.errorMessage != null) {
              _showSnackBar(context, propertyService.errorMessage!, false);
            } else {
              _showSnackBar(
                  context,
                  success
                      ? (l10n?.publishSuccess ?? 'Property published successfully')
                      : (l10n?.publishFailed ?? 'Failed to publish property'),
                  success);
            }
            
            if (success) {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.refreshUser();
              final currentUser = authProvider.currentUser;
              if (currentUser != null) {
                await ProfileService.loadUserProperties(currentUser.id);
              }
              widget.onUpdated?.call();
            }
          }
          break;

        case 'renew':
          final propertyId = property?.id ?? widget.listing.id;
          
          final proceed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(l10n?.renewListing ?? 'Renew Listing', style: const TextStyle(fontWeight: FontWeight.bold)),
              content: Text(l10n?.renewPropertyDescription ?? 'Renewing this property will deduct 1 posting point. Continue?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l10n?.cancel ?? 'Cancel', style: const TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF01352D),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(l10n?.renew ?? 'Renew'),
                ),
              ],
            ),
          );

          if (proceed != true) {
            setState(() { _isProcessing = false; });
            return;
          }

          final success = await propertyService.renewProperty(propertyId);
          if (mounted) {
            if (!success && propertyService.errorMessage != null) {
              _showSnackBar(context, propertyService.errorMessage!, false);
            } else {
              _showSnackBar(
                  context,
                  success
                      ? (l10n?.renewSuccess ?? 'Property renewed successfully')
                      : (l10n?.renewFailed ?? 'Failed to renew property'),
                  success);
            }
            
            if (success) {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.refreshUser();
              widget.onUpdated?.call();
            }
          }
          break;

        case 'delete':
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
            title: Text(l10n?.deletePropertyTitle ?? 'Delete Property'),
            content: Text(
                l10n?.deletePropertyConfirm ?? 'Are you sure you want to delete this property?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n?.cancel ?? 'Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style:
                    TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text(l10n?.delete ?? 'Delete'),
              ),
            ],
          ),
          );

          if (confirmed == true) {
            final success =
                await propertyService.deleteProperty(widget.listing.id);
            if (mounted) {
              _showSnackBar(
                  context,
                  success
                      ? l10n?.deleteSuccess ?? 'Property deleted'
                      : l10n?.deleteFailed ?? 'Failed to delete property',
                  success);
              if (success) {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                await authProvider.refreshUser();
                final currentUser = authProvider.currentUser;
                if (currentUser != null) {
                  await ProfileService.loadUserProperties(currentUser.id);
                }
                widget.onUpdated?.call();
              }
            }
          }
          break;
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Widget _buildMetaIcon(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[400]),
        const SizedBox(width: 4),
        Text(
          value,
          style: ThemeService.getDynamicStyle(
            context,
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _showSnackBar(BuildContext context, String message, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }
}
