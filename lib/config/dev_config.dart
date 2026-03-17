
/// Development environment specific configuration
/// 
/// This file contains development-specific overrides and settings
/// that are only used in the development environment.
class DevConfig {
  // Private constructor to prevent instantiation
  DevConfig._();

  /// Development-specific API settings
  static const String localApiUrl = 'http://localhost:3000/api/v1';
  static const String devApiUrl = 'https://api-dev.daryproperties.com/v1';
  
  /// Development feature flags
  static const bool enableMockData = true;
  static const bool enableApiFallback = true;
  static const bool enableDetailedLogging = true;
  static const bool enablePerformanceMonitoring = false;
  
  /// Development testing settings
  static const bool enableTestMode = true;
  static const bool enableDebugMenu = true;
  static const bool enableHotReload = true;
  
  /// Development API settings
  static const int devApiTimeoutSeconds = 60; // Longer timeout for debugging
  static const bool enableApiCaching = false; // Disable caching in dev
  
  /// Development security settings
  static const bool enableCertificatePinning = false; // Disable in dev
  static const bool enableStrictSSL = false; // Allow self-signed certificates
  
  /// Development analytics
  static const bool enableAnalytics = false; // Disable analytics in dev
  static const bool enableCrashReporting = false; // Disable crash reporting in dev
  
  /// Get development-specific configuration
  static Map<String, dynamic> getDevConfig() {
    return {
      'environment': 'development',
      'localApiUrl': localApiUrl,
      'devApiUrl': devApiUrl,
      'enableMockData': enableMockData,
      'enableApiFallback': enableApiFallback,
      'enableDetailedLogging': enableDetailedLogging,
      'enablePerformanceMonitoring': enablePerformanceMonitoring,
      'enableTestMode': enableTestMode,
      'enableDebugMenu': enableDebugMenu,
      'enableHotReload': enableHotReload,
      'devApiTimeoutSeconds': devApiTimeoutSeconds,
      'enableApiCaching': enableApiCaching,
      'enableCertificatePinning': enableCertificatePinning,
      'enableStrictSSL': enableStrictSSL,
      'enableAnalytics': enableAnalytics,
      'enableCrashReporting': enableCrashReporting,
    };
  }
}
