// Stub file for non-web platforms - shows styled preview
import 'package:flutter/material.dart';

Widget buildGoogleMapsEmbed(String query, double width, double height) {
  // For non-web platforms, show a styled map preview
  return Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.grey[400]!,
          Colors.grey[350]!,
          Colors.green[100]!,
          Colors.grey[350]!,
          Colors.blue[100]!,
          Colors.grey[400]!,
        ],
        stops: const [0.0, 0.2, 0.35, 0.5, 0.7, 1.0],
      ),
    ),
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.location_on_rounded,
              size: 48,
              color: Colors.red,
            ),
          ),
        ],
      ),
    ),
  );
}
