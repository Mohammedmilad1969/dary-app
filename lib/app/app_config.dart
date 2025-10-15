import 'package:flutter/material.dart';

class AppConfig {
  static const String appName = 'Dary';
  static const String appVersion = '1.0.0';
  static const bool isDebugMode = true;
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: Colors.indigo,
      brightness: Brightness.light,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: Colors.indigo,
      brightness: Brightness.dark,
    );
  }
}

class AppRoutes {
  static const String home = '/';
  static const String auth = '/auth';
  static const String listings = '/listings';
  static const String profile = '/profile';
  static const String wallet = '/wallet';
  static const String paywall = '/paywall';
}
