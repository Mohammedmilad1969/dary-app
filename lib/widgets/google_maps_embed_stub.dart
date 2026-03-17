// Stub file for non-web platforms
import 'package:flutter/material.dart';

/// Stub widget for non-web platforms - mobile will use WebView instead
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

  @override
  Widget build(BuildContext context) {
    // Return empty container - mobile will use WebView instead
    return const SizedBox.shrink();
  }
}


