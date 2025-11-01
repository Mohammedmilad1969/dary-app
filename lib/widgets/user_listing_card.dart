import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_profile.dart';
import '../models/property.dart';
import '../providers/auth_provider.dart';
import '../screens/property_detail_screen.dart';
import '../screens/add_property_screen.dart';
import '../services/property_service.dart' as property_service;
import '../services/theme_service.dart';

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

  @override
  Widget build(BuildContext context) {
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
    if (nonNullProperty == null) {
      return _buildCardFromListing(context);
    }

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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: nonNullProperty.isBoosted
          ? 4
          : (nonNullProperty.isFeatured ? 3 : 1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: borderColor != null
            ? BorderSide(color: borderColor, width: borderWidth)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  PropertyDetailScreen(property: nonNullProperty),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: _buildPropertyContent(nonNullProperty, context),
              ),
              PopupMenuButton<String>(
                onSelected: (value) => _handleMenuAction(
                    context, value, nonNullProperty, propertyService),
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Edit', style: TextStyle(color: Colors.blue)),
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
                              ? Icons.visibility_off
                              : Icons.visibility,
                          size: 20,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(width: 8),
                        Text(nonNullProperty.isPublished
                            ? 'Unpublish'
                            : 'Publish'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyContent(Property property, BuildContext context) {
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: Colors.grey[300],
          ),
          child: const Icon(
            Icons.home,
            size: 30,
            color: Colors.grey,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.listing.title,
                      style: ThemeService.getBodyStyle(
                        context,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      if (authProvider.currentUser?.isVerified == true) {
                        return const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.verified,
                            size: 16,
                            color: Colors.blue,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
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
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.visibility, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.listing.views} views',
                    style: ThemeService.getBodyStyle(
                      context,
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  if (widget.listing.isBoosted &&
                      widget.listing.isBoostActive) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star,
                              size: 10, color: Colors.amber[700]),
                          const SizedBox(width: 2),
                          Text(
                            'BOOSTED',
                            style: ThemeService.getBodyStyle(
                              context,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: property.isPublished
                          ? Colors.green[100]
                          : Colors.orange[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      property.isPublished
                          ? 'Published'
                          : 'Unpublished',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: property.isPublished
                            ? Colors.green[700]
                            : Colors.orange[700],
                      ),
                    ),
                  ),
                ],
              ),
              if (widget.listing.isBoosted &&
                  widget.listing.boostStatusText != null) ...[
                const SizedBox(height: 4),
                Text(
                  widget.listing.boostStatusText!,
                  style: TextStyle(
                    fontSize: 11,
                    color: widget.listing.isBoostActive
                        ? Colors.amber[700]
                        : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardFromListing(BuildContext context) {
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
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Edit', style: TextStyle(color: Colors.blue)),
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
                      Text(widget.listing.isPublished ? 'Unpublish' : 'Publish'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
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
                    ? 'Property unpublished successfully'
                    : 'Failed to unpublish property',
                success);
            if (success) widget.onUpdated?.call();
          }
          break;

        case 'publish':
          final propertyId = property?.id ?? widget.listing.id;
          final success = await propertyService.publishProperty(propertyId);
          if (mounted) {
            _showSnackBar(
                context,
                success
                    ? 'Property published successfully'
                    : 'Failed to publish property',
                success);
            if (success) widget.onUpdated?.call();
          }
          break;

        case 'delete':
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete Property'),
              content: const Text(
                  'Are you sure you want to delete this property? This action cannot be undone.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style:
                      TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );

          if (confirmed == true) {
            final success =
                await propertyService.deleteProperty(widget.listing.id);
            _showSnackBar(
                context,
                success
                    ? 'Property deleted successfully'
                    : 'Failed to delete property',
                success);
            if (success) widget.onUpdated?.call();
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

  void _showSnackBar(BuildContext context, String message, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }
}
