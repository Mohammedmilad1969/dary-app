import 'package:flutter/foundation.dart';

/// Environment configuration for the Dary Properties app
/// 
/// This class manages environment-specific settings like API URLs,
/// feature flags, and other configuration values.
class EnvConfig {
  // Private constructor to prevent instantiation
  EnvConfig._();

  /// Current environment
  static const Environment _currentEnvironment = Environment.production;

  /// API Configuration
  static const String _devApiBaseUrl = 'https://api-dev.daryproperties.com/v1';
  static const String _stagingApiBaseUrl = 'https://api-staging.daryproperties.com/v1';
  static const String _prodApiBaseUrl = 'https://api.daryproperties.com/v1';
  
  /// Local development URL (uncomment for local testing)
  // static const String _localApiBaseUrl = 'http://localhost:3000/api/v1';

  /// Get the API base URL based on current environment
  static String get apiBaseUrl {
    switch (_currentEnvironment) {
      case Environment.development:
        return _devApiBaseUrl;
      case Environment.staging:
        return _stagingApiBaseUrl;
      case Environment.production:
        return _prodApiBaseUrl;
    }
  }

  /// API timeout duration in seconds
  static const int apiTimeoutSeconds = 30;

  /// Request timeout duration
  static Duration get apiTimeoutDuration => const Duration(seconds: apiTimeoutSeconds);

  /// Feature Flags
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;
  static const bool enablePushNotifications = true;
  static const bool enableFileUpload = true;
  static const bool enableOfflineMode = true;
  
  /// Mock Data Configuration
  /// When true → all services use local mock data
  /// When false → connect to the real backend via ApiClient
  static const bool useMockData = false;

  /// Debug Settings
  static bool get enableDebugLogging => kDebugMode;
  static bool get enableVerboseLogging => kDebugMode;

  /// App Configuration
  static const String appName = 'Dary Properties';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  /// Payment Configuration
  static const String defaultCurrency = 'LYD';
  static const List<String> supportedCurrencies = ['LYD', 'USD', 'EUR'];

  /// File Upload Configuration
  static const int maxImageSizeMB = 10;
  static const int maxImagesPerProperty = 10;
  static const List<String> allowedImageFormats = ['jpg', 'jpeg', 'png', 'webp'];

  /// Cache Configuration
  static const int cacheExpirationHours = 24;
  static const int maxCacheSizeMB = 100;

  /// Security Configuration
  static const bool enableCertificatePinning = false;
  static const bool enableBiometricAuth = true;
  static const int sessionTimeoutMinutes = 30;

  /// Environment Information
  static Environment get environment => _currentEnvironment;
  static bool get isDevelopment => _currentEnvironment == Environment.development;
  static bool get isStaging => _currentEnvironment == Environment.staging;
  static bool get isProduction => _currentEnvironment == Environment.production;

  /// Get environment-specific configuration
  static Map<String, dynamic> getEnvironmentConfig() {
    return {
      'environment': _currentEnvironment.name,
      'apiBaseUrl': apiBaseUrl,
      'apiTimeoutSeconds': apiTimeoutSeconds,
      'enableAnalytics': enableAnalytics,
      'enableCrashReporting': enableCrashReporting,
      'enablePushNotifications': enablePushNotifications,
      'enableFileUpload': enableFileUpload,
      'enableOfflineMode': enableOfflineMode,
      'useMockData': useMockData,
      'enableDebugLogging': enableDebugLogging,
      'enableVerboseLogging': enableVerboseLogging,
      'appName': appName,
      'appVersion': appVersion,
      'appBuildNumber': appBuildNumber,
      'defaultCurrency': defaultCurrency,
      'supportedCurrencies': supportedCurrencies,
      'maxImageSizeMB': maxImageSizeMB,
      'maxImagesPerProperty': maxImagesPerProperty,
      'allowedImageFormats': allowedImageFormats,
      'cacheExpirationHours': cacheExpirationHours,
      'maxCacheSizeMB': maxCacheSizeMB,
      'enableCertificatePinning': enableCertificatePinning,
      'enableBiometricAuth': enableBiometricAuth,
      'sessionTimeoutMinutes': sessionTimeoutMinutes,
    };
  }

  /// Print environment configuration (debug only)
  static void printConfig() {
    if (kDebugMode) {
      debugPrint('🔧 Environment Configuration:');
      debugPrint('Environment: ${_currentEnvironment.name}');
      debugPrint('API Base URL: $apiBaseUrl');
      debugPrint('API Timeout: ${apiTimeoutSeconds}s');
      debugPrint('Mock Data Mode: $useMockData');
      debugPrint('Debug Logging: $enableDebugLogging');
      debugPrint('Analytics: $enableAnalytics');
      debugPrint('Crash Reporting: $enableCrashReporting');
      debugPrint('Push Notifications: $enablePushNotifications');
      debugPrint('File Upload: $enableFileUpload');
      debugPrint('Offline Mode: $enableOfflineMode');
    }
  }
}

/// Available environments
enum Environment {
  development,
  staging,
  production,
}

/// Extension for Environment enum
extension EnvironmentExtension on Environment {
  String get name {
    switch (this) {
      case Environment.development:
        return 'development';
      case Environment.staging:
        return 'staging';
      case Environment.production:
        return 'production';
    }
  }

  String get displayName {
    switch (this) {
      case Environment.development:
        return 'Development';
      case Environment.staging:
        return 'Staging';
      case Environment.production:
        return 'Production';
    }
  }
}
