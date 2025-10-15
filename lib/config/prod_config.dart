import 'env_config.dart';

/// Production environment specific configuration
/// 
/// This file contains production-specific overrides and settings
/// that are only used in the production environment.
class ProdConfig {
  // Private constructor to prevent instantiation
  ProdConfig._();

  /// Production-specific API settings
  static const String prodApiUrl = 'https://api.daryproperties.com/v1';
  static const String cdnUrl = 'https://cdn.daryproperties.com';
  
  /// Production feature flags
  static const bool enableMockData = false;
  static const bool enableApiFallback = true; // Keep fallback for reliability
  static const bool enableDetailedLogging = false;
  static const bool enablePerformanceMonitoring = true;
  
  /// Production testing settings
  static const bool enableTestMode = false;
  static const bool enableDebugMenu = false;
  static const bool enableHotReload = false;
  
  /// Production API settings
  static const int prodApiTimeoutSeconds = 15; // Shorter timeout for production
  static const bool enableApiCaching = true; // Enable caching in production
  
  /// Production security settings
  static const bool enableCertificatePinning = true; // Enable in production
  static const bool enableStrictSSL = true; // Strict SSL in production
  
  /// Production analytics
  static const bool enableAnalytics = true; // Enable analytics in production
  static const bool enableCrashReporting = true; // Enable crash reporting in production
  
  /// Production performance settings
  static const bool enableImageOptimization = true;
  static const bool enableLazyLoading = true;
  static const bool enableCodeSplitting = true;
  
  /// Production monitoring
  static const bool enableErrorTracking = true;
  static const bool enablePerformanceTracking = true;
  static const bool enableUserBehaviorTracking = true;
  
  /// Get production-specific configuration
  static Map<String, dynamic> getProdConfig() {
    return {
      'environment': 'production',
      'prodApiUrl': prodApiUrl,
      'cdnUrl': cdnUrl,
      'enableMockData': enableMockData,
      'enableApiFallback': enableApiFallback,
      'enableDetailedLogging': enableDetailedLogging,
      'enablePerformanceMonitoring': enablePerformanceMonitoring,
      'enableTestMode': enableTestMode,
      'enableDebugMenu': enableDebugMenu,
      'enableHotReload': enableHotReload,
      'prodApiTimeoutSeconds': prodApiTimeoutSeconds,
      'enableApiCaching': enableApiCaching,
      'enableCertificatePinning': enableCertificatePinning,
      'enableStrictSSL': enableStrictSSL,
      'enableAnalytics': enableAnalytics,
      'enableCrashReporting': enableCrashReporting,
      'enableImageOptimization': enableImageOptimization,
      'enableLazyLoading': enableLazyLoading,
      'enableCodeSplitting': enableCodeSplitting,
      'enableErrorTracking': enableErrorTracking,
      'enablePerformanceTracking': enablePerformanceTracking,
      'enableUserBehaviorTracking': enableUserBehaviorTracking,
    };
  }
}
