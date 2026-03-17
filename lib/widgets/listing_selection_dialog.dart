import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/theme_service.dart';
import '../models/user_profile.dart';
import 'package:intl/intl.dart';

class ListingSelectionDialog extends StatefulWidget {
  final List<UserListing> listings;
  final String packageName;
  final Function(String listingId) onListingSelected;

  const ListingSelectionDialog({
    super.key,
    required this.listings,
    required this.packageName,
    required this.onListingSelected,
  });

  @override
  State<ListingSelectionDialog> createState() => _ListingSelectionDialogState();
}

class _ListingSelectionDialogState extends State<ListingSelectionDialog> {
  String? _selectedListingId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const themeColor = Color(0xFF01352D);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 450,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n?.chooseListingToBoost ?? 'Choose Listing to Boost',
                      style: ThemeService.getDynamicStyle(
                        context,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.grey),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                l10n?.selectListingToBoost(widget.packageName) ??
                    'Select which listing you want to boost with ${widget.packageName}:',
                style: ThemeService.getDynamicStyle(
                  context,
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Listings List
            Flexible(
              child: widget.listings.isEmpty
                  ? _buildEmptyState(context, l10n)
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      itemCount: widget.listings.length,
                      itemBuilder: (context, index) {
                        final listing = widget.listings[index];
                        final isSelected = _selectedListingId == listing.id;
                        return _buildListingItem(context, listing, isSelected);
                      },
                    ),
            ),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: _selectedListingId != null
                        ? () {
                            widget.onListingSelected(_selectedListingId!);
                            Navigator.of(context).pop();
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFE2E8F0),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      l10n?.boostListing ?? 'Boost Listing',
                      style: ThemeService.getDynamicStyle(
                        context,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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

  Widget _buildListingItem(BuildContext context, UserListing listing, bool isSelected) {
    const themeColor = Color(0xFF01352D);
    
    return GestureDetector(
      onTap: () => setState(() => _selectedListingId = listing.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? themeColor.withValues(alpha: 0.04) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? themeColor : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: themeColor.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: listing.imageUrl.isNotEmpty
                  ? Image.network(
                      listing.imageUrl,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _ThumbnailPlaceholder(),
                    )
                  : _ThumbnailPlaceholder(),
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ThemeService.getDynamicStyle(
                      context,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 2),
                      Text(
                        listing.city,
                        style: ThemeService.getDynamicStyle(
                          context,
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${NumberFormat('#,###').format(listing.price)} LYD',
                        style: ThemeService.getDynamicStyle(
                          context,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: themeColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _StatBadge(
                        icon: Icons.visibility_outlined,
                        value: '${listing.views}',
                      ),
                      const SizedBox(width: 12),
                      _StatBadge(
                        icon: Icons.calendar_today_outlined,
                        value: _formatDate(context, listing.createdAt),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Selection Indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? themeColor : const Color(0xFFCBD5E1),
                  width: 2,
                ),
                color: isSelected ? themeColor : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations? l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 40,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n?.noActiveListingsToBoost ?? 'No active listings found',
              style: ThemeService.getDynamicStyle(
                context,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n?.noActiveListingsToBoost ?? 'Please create a listing first to promote it.',
              textAlign: TextAlign.center,
              style: ThemeService.getDynamicStyle(
                context,
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(BuildContext context, DateTime date) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) return l10n?.today ?? 'Today';
    if (difference == 1) return l10n?.yesterday ?? 'Yesterday';
    if (difference < 7) return l10n?.daysAgo(difference) ?? '$difference days ago';
    return DateFormat('MMM d, yyyy').format(date);
  }
}

class _ThumbnailPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      height: 70,
      color: const Color(0xFFF1F5F9),
      child: const Icon(Icons.image_outlined, color: Color(0xFF94A3B8)),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String value;

  const _StatBadge({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 4),
        Text(
          value,
          style: ThemeService.getDynamicStyle(
            context,
            fontSize: 12,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}
