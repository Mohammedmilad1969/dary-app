import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'google_maps_embed_stub.dart' as web_maps
    if (dart.library.html) 'google_maps_embed_web.dart';

/// Direct Google Maps embed widget that works on web
class GoogleMapsEmbed extends StatefulWidget {
  final String query; // e.g., "Janzour, Tripoli, Libya"
  final double width;
  final double height;

  const GoogleMapsEmbed({
    Key? key,
    required this.query,
    this.width = double.infinity,
    this.height = 250.0,
  }) : super(key: key);

  @override
  State<GoogleMapsEmbed> createState() => _GoogleMapsEmbedState();
}

class _GoogleMapsEmbedState extends State<GoogleMapsEmbed> {
  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // Use the web-specific implementation
      return web_maps.GoogleMapsEmbedWeb(
        query: widget.query,
        width: widget.width,
        height: widget.height,
      );
    } else {
      // Return empty for mobile - WebView will be used instead
      return const SizedBox.shrink();
    }
  }
}

