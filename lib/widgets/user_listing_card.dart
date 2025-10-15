import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_profile.dart';
import '../providers/auth_provider.dart';

class UserListingCard extends StatelessWidget {
  final UserListing listing;

  const UserListingCard({
    super.key,
    required this.listing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Viewing ${listing.title}'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Property Image Placeholder
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
              
              // Property Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            listing.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Verified User Badge
                        Consumer<AuthProvider>(
                          builder: (context, authProvider, child) {
                            if (authProvider.currentUser?.isVerified == true) {
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.verified,
                                    size: 16,
                                    color: Colors.blue,
                                  ),
                                ],
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${listing.price.toStringAsFixed(0)} • ${listing.city}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.visibility,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${listing.views} views',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const Spacer(),
                        // Boost Status Badge
                        if (listing.isBoosted && listing.isBoostActive) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber[100],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 10,
                                  color: Colors.amber[700],
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  'BOOSTED',
                                  style: TextStyle(
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
                        // Active/Inactive Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: listing.isActive 
                                ? Colors.green[100] 
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            listing.isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: listing.isActive 
                                  ? Colors.green[700] 
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Boost Details
                    if (listing.isBoosted && listing.boostStatusText != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        listing.boostStatusText!,
                        style: TextStyle(
                          fontSize: 11,
                          color: listing.isBoostActive ? Colors.amber[700] : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
