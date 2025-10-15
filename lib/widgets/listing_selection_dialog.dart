import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/user_profile.dart';

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
    
    return AlertDialog(
      title: Text('Choose Listing to Boost'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Select which listing you want to boost with ${widget.packageName}:',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          if (widget.listings.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No active listings found. Please create a listing first.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else
            SizedBox(
              height: 300,
              width: double.maxFinite,
              child: ListView.builder(
                itemCount: widget.listings.length,
                itemBuilder: (context, index) {
                  final listing = widget.listings[index];
                  final isSelected = _selectedListingId == listing.id;
                  
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: isSelected ? Colors.green[50] : null,
                    child: RadioListTile<String>(
                      title: Text(
                        listing.title,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${listing.city} • \$${listing.price.toStringAsFixed(0)}'),
                          Text(
                            '${listing.views} views • Created ${_formatDate(listing.createdAt)}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      value: listing.id,
                      groupValue: _selectedListingId,
                      onChanged: (String? value) {
                        setState(() {
                          _selectedListingId = value;
                        });
                      },
                      activeColor: Colors.green,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedListingId != null
              ? () {
                  widget.onListingSelected(_selectedListingId!);
                  Navigator.of(context).pop();
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: const Text('Boost Listing'),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return 'today';
    } else if (difference == 1) {
      return 'yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else if (difference < 30) {
      final weeks = (difference / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else {
      final months = (difference / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    }
  }
}
