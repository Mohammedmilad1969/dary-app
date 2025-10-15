import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/property.dart';
import '../screens/property_detail_screen.dart';

class PropertyCard extends StatelessWidget {
  final Property property;

  const PropertyCard({
    super.key,
    required this.property,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Card(
      margin: const EdgeInsets.all(4),
      elevation: property.isFeatured ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: property.isFeatured
            ? const BorderSide(color: Colors.green, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PropertyDetailScreen(property: property),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Property Image with Status Badge
            Stack(
              children: [
                Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    color: Colors.grey[300],
                  ),
                  child: property.imageUrls.isNotEmpty
                      ? ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                          child: CachedNetworkImage(
                            imageUrl: property.imageUrls.first,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => const Icon(
                              Icons.home,
                              size: 40,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.home,
                          size: 40,
                          color: Colors.grey,
                        ),
                ),
                
                // Status Badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(property.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      property.status.statusDisplayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                // Featured Badge
                if (property.isFeatured)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, color: Colors.white, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'FEATURED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Boost Badge
                if (property.isBoosted && property.isBoostActive)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.purple,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.rocket_launch, color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            'BOOSTED',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Verified Badge
                if (property.isVerified)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.verified,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
            
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Property Title and Type
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          property.title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          property.type.typeDisplayName,
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Price
                  Text(
                    property.displayPrice,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Location
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 10, color: Colors.grey[600]),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          '${property.neighborhood}, ${property.city}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 6),
                  
                  // Property Details - Compact version
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildCompactDetailItem(Icons.bed, '${property.bedrooms}'),
                      _buildCompactDetailItem(Icons.bathtub, '${property.bathrooms}'),
                      _buildCompactDetailItem(Icons.square_foot, '${property.sizeSqm}'),
                    ],
                  ),
                  
                  const SizedBox(height: 6),
                  
                  // Key Features - Limited to 2 rows
                  Wrap(
                    spacing: 3,
                    runSpacing: 2,
                    children: _buildFeatureChips().take(3).toList(),
                  ),
                  
                  const SizedBox(height: 6),
                  
                  // Agent Info - Compact
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 7,
                        backgroundColor: Colors.green[100],
                        child: Text(
                          property.agentName.split(' ').map((n) => n[0]).join(),
                          style: TextStyle(
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          property.agentName,
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Verified Seller Badge
                      if (_isSellerVerified(property.contactEmail))
                        Icon(
                          Icons.verified,
                          size: 10,
                          color: Colors.blue,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
    
    if (property.hasBalcony) chips.add(_buildFeatureChip('Balcony'));
    if (property.hasGarden) chips.add(_buildFeatureChip('Garden'));
    if (property.hasParking) chips.add(_buildFeatureChip('Parking'));
    if (property.hasPool) chips.add(_buildFeatureChip('Pool'));
    if (property.hasGym) chips.add(_buildFeatureChip('Gym'));
    if (property.hasSecurity) chips.add(_buildFeatureChip('Security'));
    if (property.hasElevator) chips.add(_buildFeatureChip('Elevator'));
    if (property.hasAC) chips.add(_buildFeatureChip('AC'));
    if (property.hasFurnished) chips.add(_buildFeatureChip('Furnished'));
    
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
