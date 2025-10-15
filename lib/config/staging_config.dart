import 'env_config.dart';

/// Staging environment specific configuration
/// 
/// This file contains staging-specific overrides and settings
/// that are only used in the staging environment.
class StagingConfig {
  // Private constructor to prevent instantiation
  StagingConfig._();

  /// Staging-specific API settings
  static const String stagingApiUrl = 'https://api-staging.daryproperties.com/v1';
  static const String stagingCdnUrl = 'https://cdn-staging.daryproperties.com';
  
  /// Staging feature flags
  static const bool enableMockData = false;
  static const bool enableApiFallback = true;
  static const bool enableDetailedLogging = true; // More logging for testing
  static const bool enablePerformanceMonitoring = true;
  
  /// Staging testing settings
  static const bool enableTestMode = true; // Enable test features
  static const bool enableDebugMenu = true; // Enable debug menu for testing
  static const bool enableHotReload = true;
  
  /// Staging API settings
  static const int stagingApiTimeoutSeconds = 30; // Medium timeout
  static const bool enableApiCaching = true; // Enable caching
  
  /// Staging security settings
  static const bool enableCertificatePinning = false; // Disable for testing
  static const bool enableStrictSSL = true; // Keep SSL strict
  
  /// Staging analytics
  static const bool enableAnalytics = true; // Enable for testing analytics
  static const bool enableCrashReporting = true; // Enable for testing crash reporting
  
  /// Staging testing features
  static const bool enableTestData = true;
  static const bool enableBetaFeatures = true;
  static const bool enableExperimentalFeatures = true;
  
  /// Staging monitoring
  static const bool enableErrorTracking = true;
  static const bool enablePerformanceTracking = true;
  static const bool enableUserBehaviorTracking = false; // Disable in staging
  
  /// Get staging-specific configuration
  static Map<String, dynamic> getStagingConfig() {
    return {
      'environment': 'staging',
      'stagingApiUrl': stagingApiUrl,
      'stagingCdnUrl': stagingCdnUrl,
      'enableMockData': enableMockData,
      'enableApiFallback': enableApiFallback,
      'enableDetailedLogging': enableDetailedLogging,
      'enablePerformanceMonitoring': enablePerformanceMonitoring,
      'enableTestMode': enableTestMode,
      'enableDebugMenu': enableDebugMenu,
      'enableHotReload': enableHotReload,
      'stagingApiTimeoutSeconds': stagingApiTimeoutSeconds,
      'enableApiCaching': enableApiCaching,
      'enableCertificatePinning': enableCertificatePinning,
      'enableStrictSSL': enableStrictSSL,
      'enableAnalytics': enableAnalytics,
      'enableCrashReporting': enableCrashReporting,
      'enableTestData': enableTestData,
      'enableBetaFeatures': enableBetaFeatures,
      'enableExperimentalFeatures': enableExperimentalFeatures,
      'enableErrorTracking': enableErrorTracking,
      'enablePerformanceTracking': enablePerformanceTracking,
      'enableUserBehaviorTracking': enableUserBehaviorTracking,
    };
  }
}
