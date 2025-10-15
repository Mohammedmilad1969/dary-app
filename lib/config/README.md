# Environment Configuration Guide

## Overview
The Dary Properties app uses a centralized environment configuration system to manage different settings for development, staging, and production environments.

## Configuration Files

### Main Configuration
- `lib/config/env_config.dart` - Main environment configuration
- `lib/config/dev_config.dart` - Development-specific settings
- `lib/config/staging_config.dart` - Staging-specific settings  
- `lib/config/prod_config.dart` - Production-specific settings

## Switching Environments

To switch between environments, update the `_currentEnvironment` variable in `lib/config/env_config.dart`:

```dart
// Change this line to switch environments
static const Environment _currentEnvironment = Environment.development;
// static const Environment _currentEnvironment = Environment.staging;
// static const Environment _currentEnvironment = Environment.production;
```

## Environment-Specific Settings

### Development Environment
- **API URL**: `https://api-dev.daryproperties.com/v1`
- **Debug Logging**: Enabled
- **Analytics**: Disabled
- **Crash Reporting**: Disabled
- **Certificate Pinning**: Disabled
- **Mock Data Fallback**: Enabled

### Staging Environment
- **API URL**: `https://api-staging.daryproperties.com/v1`
- **Debug Logging**: Enabled
- **Analytics**: Enabled (for testing)
- **Crash Reporting**: Enabled (for testing)
- **Certificate Pinning**: Disabled
- **Test Features**: Enabled

### Production Environment
- **API URL**: `https://api.daryproperties.com/v1`
- **Debug Logging**: Disabled
- **Analytics**: Enabled
- **Crash Reporting**: Enabled
- **Certificate Pinning**: Enabled
- **Performance Monitoring**: Enabled

## Configuration Properties

### API Configuration
- `apiBaseUrl` - Base URL for API requests
- `apiTimeoutSeconds` - Request timeout duration
- `apiTimeoutDuration` - Timeout as Duration object

### Feature Flags
- `enableAnalytics` - Enable/disable analytics
- `enableCrashReporting` - Enable/disable crash reporting
- `enablePushNotifications` - Enable/disable push notifications
- `enableFileUpload` - Enable/disable file upload
- `enableOfflineMode` - Enable/disable offline mode

### Debug Settings
- `enableDebugLogging` - Enable/disable debug logging
- `enableVerboseLogging` - Enable/disable verbose logging

### App Configuration
- `appName` - Application name
- `appVersion` - Application version
- `appBuildNumber` - Build number

### Security Configuration
- `enableCertificatePinning` - Enable/disable certificate pinning
- `enableBiometricAuth` - Enable/disable biometric authentication
- `sessionTimeoutMinutes` - Session timeout duration

## Usage Examples

### In API Client
```dart
// API client automatically uses environment configuration
final response = await apiClient.get('/properties');
```

### In Services
```dart
// Services can access environment configuration
if (EnvConfig.enableAnalytics) {
  // Track analytics event
}
```

### In UI Components
```dart
// UI can check environment-specific features
if (EnvConfig.enableDebugMenu) {
  // Show debug menu
}
```

## Local Development

For local development with a local API server, uncomment the local URL in `env_config.dart`:

```dart
// Uncomment for local testing
static const String _localApiBaseUrl = 'http://localhost:3000/api/v1';
```

Then update the `apiBaseUrl` getter to use the local URL:

```dart
static String get apiBaseUrl {
  // Use local URL for development
  return _localApiBaseUrl;
  
  // Or use environment-specific URLs
  switch (_currentEnvironment) {
    case Environment.development:
      return _devApiBaseUrl;
    // ...
  }
}
```

## Environment Variables (Future Enhancement)

For production deployments, consider using environment variables or build-time configuration:

```dart
// Example with environment variables
static String get apiBaseUrl {
  const String? envUrl = String.fromEnvironment('API_BASE_URL');
  if (envUrl != null && envUrl.isNotEmpty) {
    return envUrl;
  }
  return _getDefaultApiUrl();
}
```

## Best Practices

1. **Never commit sensitive data** to configuration files
2. **Use environment-specific configs** for different settings
3. **Test all environments** before deployment
4. **Use feature flags** for gradual rollouts
5. **Monitor configuration changes** in production
6. **Document all configuration options** clearly

## Troubleshooting

### Common Issues
1. **API calls failing**: Check if the correct environment URL is configured
2. **Logging not working**: Verify `enableDebugLogging` is true
3. **Analytics not tracking**: Check if `enableAnalytics` is enabled
4. **Certificate errors**: Verify `enableCertificatePinning` setting

### Debug Configuration
Use `EnvConfig.printConfig()` to print current configuration:

```dart
void main() {
  EnvConfig.printConfig();
  runApp(const DaryApp());
}
```

This will output the current environment configuration to the console.
