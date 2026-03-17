import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeService {
  static final Map<String, TextStyle> _styleCache = {};

  static Future<void> preloadFonts() async {
    try {
      await GoogleFonts.pendingFonts([
        GoogleFonts.inter(),
        GoogleFonts.outfit(),
        GoogleFonts.cairo(),
      ]);
      debugPrint('✅ ThemeService: Fonts preloaded');
    } catch (e) {
      debugPrint('⚠️ ThemeService: Font preload error: $e');
    }
  }

  static ThemeData getLightTheme(String languageCode) {
    final isEnglish = languageCode == 'en';
    
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: const Color(0xFF01352D),
      brightness: Brightness.light,
      textTheme: isEnglish 
          ? GoogleFonts.outfitTextTheme()
          : GoogleFonts.cairoTextTheme(),
      fontFamily: isEnglish ? GoogleFonts.outfit().fontFamily : GoogleFonts.cairo().fontFamily,
    );
  }

  static TextStyle getBodyStyle(
    BuildContext context, {
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
  }) {
    final theme = Theme.of(context);
    final locale = Localizations.maybeLocaleOf(context);
    final isEnglish = locale == null || locale.languageCode == 'en';
    
    final baseStyle = isEnglish ? GoogleFonts.outfit() : GoogleFonts.cairo();
    
    return baseStyle.copyWith(
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
    final locale = Localizations.maybeLocaleOf(context);
    final isEnglish = locale == null || locale.languageCode == 'en';

    final baseStyle = isEnglish ? GoogleFonts.outfit() : GoogleFonts.cairo();

    return baseStyle.copyWith(
      fontSize: fontSize ?? 24,
      fontWeight: fontWeight ?? FontWeight.bold,
      color: color ?? theme.textTheme.headlineLarge?.color ?? Colors.black,
    );
  }

  static TextStyle getDynamicStyle(
    BuildContext context, {
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
    TextDecoration? decoration,
    FontStyle? fontStyle,
    List<Shadow>? shadows,
  }) {
    final locale = Localizations.maybeLocaleOf(context);
    final isEnglish = locale == null || locale.languageCode == 'en';

    // Create a cache key based on the parameters
    final cacheKey = '${isEnglish}_${fontSize}_${fontWeight}_${color?.hashCode}_${letterSpacing}_${height}_${decoration}_${fontStyle}_${shadows?.length}';
    
    if (_styleCache.containsKey(cacheKey)) {
      return _styleCache[cacheKey]!;
    }

    final baseStyle = isEnglish ? GoogleFonts.outfit() : GoogleFonts.cairo();
    
    final style = baseStyle.copyWith(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      decoration: decoration,
      fontStyle: fontStyle,
      shadows: shadows,
    );

    // Simple cache management - clear if it gets too large
    if (_styleCache.length > 100) _styleCache.clear();
    _styleCache[cacheKey] = style;
    
    return style;
  }
}
