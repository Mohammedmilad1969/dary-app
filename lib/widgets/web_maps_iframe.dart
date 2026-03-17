// Web-only file for Google Maps iframe embed
// ignore_for_file: avoid_web_libraries_in_flutter
import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

Widget buildGoogleMapsEmbed(String query, double width, double height) {
  // Google Maps embed URL - no API key needed for embed
  final encodedQuery = Uri.encodeComponent(query);
  final embedUrl = 'https://www.google.com/maps?q=$encodedQuery&output=embed&z=15';
  
  // Create unique view ID using timestamp and query hash
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final String viewId = 'google-maps-${query.hashCode.abs()}-$timestamp';
  
  // Check if view ID is already registered, if so, add timestamp to make it unique
  // Register iframe factory
  ui_web.platformViewRegistry.registerViewFactory(
    viewId,
    (int viewId) {
      // Create iframe element
      final iframe = html.IFrameElement()
        ..src = embedUrl
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.margin = '0'
        ..style.padding = '0'
        ..allowFullscreen = true
        ..allow = 'fullscreen';
      
      return iframe;
    },
  );
  
  // Return HtmlElementView wrapped in a container
  return Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: Colors.grey[300]!,
        width: 1,
      ),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: HtmlElementView(viewType: viewId),
    ),
  );
}

