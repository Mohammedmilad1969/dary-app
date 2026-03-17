// Web-specific file - only imported on web
// ignore_for_file: avoid_web_libraries_in_flutter
import 'package:flutter/material.dart';
import '../services/theme_service.dart';
import 'dart:math' as math;

/// Web-specific Google Maps embed widget using static map image
class GoogleMapsEmbedWeb extends StatelessWidget {
  final String query;
  final double width;
  final double height;

  const GoogleMapsEmbedWeb({
    Key? key,
    required this.query,
    required this.width,
    required this.height,
  }) : super(key: key);

  // Get approximate coordinates for Libyan locations
  Map<String, double> _getCoordinates() {
    final lowerQuery = query.toLowerCase();
    
    // Common Libyan cities and neighborhoods
    if (lowerQuery.contains('tripoli') || lowerQuery.contains('طرابلس')) {
      if (lowerQuery.contains('janzour') || lowerQuery.contains('جنزور')) {
        return {'lat': 32.8500, 'lon': 13.0200};
      } else if (lowerQuery.contains('ain zara') || lowerQuery.contains('عين زارة')) {
        return {'lat': 32.8400, 'lon': 13.2300};
      } else if (lowerQuery.contains('hay al-andalus') || lowerQuery.contains('حي الأندلس')) {
        return {'lat': 32.8700, 'lon': 13.1000};
      } else if (lowerQuery.contains('tajoura') || lowerQuery.contains('تاجوراء')) {
        return {'lat': 32.8800, 'lon': 13.3500};
      } else if (lowerQuery.contains('souq al-juma') || lowerQuery.contains('سوق الجمعة')) {
        return {'lat': 32.9000, 'lon': 13.2000};
      }
      return {'lat': 32.8872, 'lon': 13.1913};
    } else if (lowerQuery.contains('benghazi') || lowerQuery.contains('بنغازي')) {
      return {'lat': 32.1167, 'lon': 20.0667};
    } else if (lowerQuery.contains('misrata') || lowerQuery.contains('مصراتة')) {
      return {'lat': 32.3754, 'lon': 15.0926};
    } else if (lowerQuery.contains('zawiya') || lowerQuery.contains('الزاوية')) {
      return {'lat': 32.7542, 'lon': 12.7278};
    } else if (lowerQuery.contains('sabha') || lowerQuery.contains('سبها')) {
      return {'lat': 27.0377, 'lon': 14.4283};
    } else if (lowerQuery.contains('sirte') || lowerQuery.contains('سرت')) {
      return {'lat': 31.2087, 'lon': 16.5908};
    } else if (lowerQuery.contains('tobruk') || lowerQuery.contains('طبرق')) {
      return {'lat': 32.0836, 'lon': 23.9764};
    } else if (lowerQuery.contains('zliten') || lowerQuery.contains('زليتن')) {
      return {'lat': 32.4679, 'lon': 14.5689};
    } else if (lowerQuery.contains('khoms') || lowerQuery.contains('الخمس')) {
      return {'lat': 32.6497, 'lon': 14.2644};
    } else if (lowerQuery.contains('derna') || lowerQuery.contains('درنة')) {
      return {'lat': 32.7636, 'lon': 22.6373};
    }
    
    // Default to Tripoli center
    return {'lat': 32.8872, 'lon': 13.1913};
  }

  @override
  Widget build(BuildContext context) {
    final coords = _getCoordinates();
    final lat = coords['lat']!;
    final lon = coords['lon']!;
    
    // Zoom level 15 for neighborhood view
    const zoom = 15;
    
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Map tiles grid
          _buildMapTiles(lat, lon, zoom),
          
          // Center pin marker
          Center(
            child: Transform.translate(
              offset: const Offset(0, -20),
              child: Icon(
                Icons.location_on,
                color: Colors.red[700],
                size: 48,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
          ),
          
          // Location label
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.map,
                    size: 14,
                    color: Color(0xFF01352D),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'OpenStreetMap',
                    style: ThemeService.getDynamicStyle(
                      context,
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapTiles(double lat, double lon, int zoom) {
    final centerTileX = _lonToTileX(lon, zoom);
    final centerTileY = _latToTileY(lat, zoom);
    
    // Create a 3x3 grid of tiles centered on the location
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
      ),
      itemCount: 9,
      itemBuilder: (context, index) {
        final row = index ~/ 3 - 1;
        final col = index % 3 - 1;
        final tileX = centerTileX + col;
        final tileY = centerTileY + row;
        final url = 'https://tile.openstreetmap.org/$zoom/$tileX/$tileY.png';
        
        return Image.network(
          url,
          fit: BoxFit.cover,
          headers: const {
            'User-Agent': 'Dary Real Estate App',
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[300],
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.grey[200],
            );
          },
        );
      },
    );
  }

  // Convert longitude to tile X coordinate
  int _lonToTileX(double lon, int zoom) {
    return ((lon + 180.0) / 360.0 * (1 << zoom)).floor();
  }

  // Convert latitude to tile Y coordinate  
  int _latToTileY(double lat, int zoom) {
    final latRad = lat * math.pi / 180.0;
    final n = 1 << zoom;
    return ((1.0 - (math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) / math.pi)) / 2.0 * n).floor();
  }
}
