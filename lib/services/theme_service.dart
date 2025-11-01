import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeService {
  static Future<void> preloadFonts() async {
    try {
      await GoogleFonts.pendingFonts([
        GoogleFonts.dmSerifDisplay(),
      ]);
      debugPrint('✅ ThemeService: Fonts preloaded');
    } catch (e) {
      debugPrint('⚠️ ThemeService: Font preload error: $e');
    }
  }

  static ThemeData getLightTheme(BuildContext context) {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: Colors.green,
      brightness: Brightness.light,
      textTheme: GoogleFonts.dmSerifDisplayTextTheme(),
    );
  }

  static TextStyle getBodyStyle(
    BuildContext context, {
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
  }) {
    final theme = Theme.of(context);
    return GoogleFonts.dmSerifDisplay(
      fontSize: fontSize ?? 16,
      fontWeight: fontWeight ?? FontWeight.normal,
      color: color ?? theme.textTheme.bodyLarge?.color ?? Colors.black87,
    );
  }

  static TextStyle getHeadingStyle(
    BuildContext context, {
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) {
    final theme = Theme.of(context);
    return GoogleFonts.dmSerifDisplay(
      fontSize: fontSize ?? 24,
      fontWeight: fontWeight ?? FontWeight.bold,
      color: color ?? theme.textTheme.headlineLarge?.color ?? Colors.black,
    );
  }
}