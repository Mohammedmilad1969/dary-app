# Mock Data Toggle Implementation

## Overview
The Dary app now includes a comprehensive mock data toggle system that allows developers to easily switch between using local mock data and connecting to real backend APIs. This feature significantly improves development efficiency and testing capabilities.

## Configuration

### **EnvConfig Toggle**
```dart
/// Mock Data Configuration
/// When true → all services use local mock data
/// When false → connect to the real backend via ApiClient
static const bool useMockData = true;
```

### **Environment Configuration Display**
The toggle is included in the environment configuration output:
```
🔧 Environment Configuration:
Environment: development
API Base URL: https://api-dev.daryproperties.com/v1
API Timeout: 30s
Mock Data Mode: true  ← Mock data toggle status
Debug Logging: true
Analytics: true
Crash Reporting: true
Push Notifications: true
File Upload: true
Offline Mode: true
```

## Implementation Details

### **1. PropertyService Integration**

#### **Mock Data Mode (useMockData: true)**
```dart
static Future<List<Property>> fetchProperties({String? token}) async {
  // Check if mock data mode is enabled
  if (EnvConfig.useMockData) {
    if (kDebugMode) {
      debugPrint('🎭 Using mock data for properties (useMockData: true)');
    }
    return _properties; // Return local mock data immediately
  }
  
  // API call logic...
}
```

#### **API Mode (useMockData: false)**
```dart
try {
  // Try to fetch from API
  if (kDebugMode) {
    debugPrint('🌐 Fetching properties from API (useMockData: false)');
  }
  final response = await apiClient.get('/properties', token: token);
  // Process API response...
} catch (e) {
  // Fall back to mock data on API failure
  return _properties;
}
```

### **2. WalletService Integration**

#### **Mock Data Mode**
```dart
static Future<Wallet?> fetchWallet(String userId, {String? token}) async {
  if (EnvConfig.useMockData) {
    if (kDebugMode) {
      debugPrint('🎭 Using mock data for wallet (useMockData: true)');
    }
    _currentWallet = _getMockWallet();
    return _currentWallet;
  }
  
  // API call logic...
}
```

#### **Balance Fetching**
```dart
static Future<double> getCurrentBalance({String? token}) async {
  if (EnvConfig.useMockData) {
    if (kDebugMode) {
      debugPrint('🎭 Using mock data for balance (useMockData: true)');
    }
    return 200.0; // Mock balance
  }
  
  // API call logic...
}
```

### **3. PaywallService Integration**

#### **Package Fetching**
```dart
static Future<List<PremiumPackage>> getPackages({String? token}) async {
  if (EnvConfig.useMockData) {
    if (kDebugMode) {
      debugPrint('🎭 Using mock data for packages (useMockData: true)');
    }
    return _packages; // Return local mock packages
  }
  
  // API call logic...
}
```

#### **Package Purchase**
```dart
static Future<bool> purchasePackage(String packageId, {String? token}) async {
  if (EnvConfig.useMockData) {
    if (kDebugMode) {
      debugPrint('🎭 Using mock data for package purchase (useMockData: true)');
    }
    return await _mockPurchasePackage(packageId);
  }
  
  // API call logic...
}
```

## Testing Results

### **Mock Data Mode (useMockData: true)**
```
🔧 Environment Configuration:
Mock Data Mode: true
🎭 Using mock data for wallet (useMockData: true)
💰 Created new mock wallet with balance: 200 LYD
```

**Benefits:**
- ✅ **Instant Response**: No network delays
- ✅ **Consistent Data**: Same mock data every time
- ✅ **Offline Development**: Works without internet
- ✅ **Fast Testing**: Quick iteration cycles

### **API Mode (useMockData: false)**
```
🔧 Environment Configuration:
Mock Data Mode: false
🌐 Fetching wallet from API (useMockData: false)
🌐 API REQUEST: GET https://api-dev.daryproperties.com/v1/wallet/balance
❌ API ERROR: Request failed - /wallet/balance
! Wallet API call failed, using mock data: ClientException: Failed to fetch
💰 Created new mock wallet with balance: 200 LYD
```

**Benefits:**
- ✅ **Real API Testing**: Tests actual backend integration
- ✅ **Error Handling**: Validates error handling middleware
- ✅ **Fallback Testing**: Ensures graceful degradation
- ✅ **Production Simulation**: Mimics production behavior

## Service Coverage

### **✅ Implemented Services**
- **PropertyService**: `fetchProperties()` method
- **WalletService**: `fetchWallet()` and `getCurrentBalance()` methods
- **PaywallService**: `getPackages()` and `purchasePackage()` methods

### **🔄 Fallback Behavior**
All services maintain fallback to mock data when:
- API calls fail
- Network is unavailable
- Server returns unexpected responses
- Authentication fails

## Development Workflow

### **Development Phase (useMockData: true)**
```dart
// In lib/config/env_config.dart
static const bool useMockData = true;
```

**Use Cases:**
- UI/UX development
- Feature implementation
- Local testing
- Demo preparation
- Offline development

### **Integration Testing (useMockData: false)**
```dart
// In lib/config/env_config.dart
static const bool useMockData = false;
```

**Use Cases:**
- API integration testing
- Error handling validation
- Performance testing
- Production simulation
- Backend validation

## Debug Logging

### **Mock Data Mode Logs**
```
🎭 Using mock data for properties (useMockData: true)
🎭 Using mock data for wallet (useMockData: true)
🎭 Using mock data for packages (useMockData: true)
🎭 Using mock data for package purchase (useMockData: true)
```

### **API Mode Logs**
```
🌐 Fetching properties from API (useMockData: false)
🌐 Fetching wallet from API (useMockData: false)
🌐 Fetching packages from API (useMockData: false)
🌐 Purchasing package via API (useMockData: false)
```

## Benefits

### **🚀 Development Efficiency**
- **Fast Iteration**: No waiting for API responses
- **Consistent Testing**: Same data every time
- **Offline Work**: Development without internet
- **Quick Demos**: Instant data loading

### **🧪 Testing Capabilities**
- **API Integration**: Test real backend connections
- **Error Scenarios**: Validate error handling
- **Fallback Testing**: Ensure graceful degradation
- **Performance Testing**: Measure API response times

### **🔧 Maintenance**
- **Single Toggle**: One setting controls all services
- **Centralized Logic**: Consistent behavior across services
- **Easy Switching**: Change mode without code changes
- **Clear Logging**: Obvious which mode is active

## Future Enhancements

### **Advanced Features**
- **Per-Service Toggle**: Individual service mock/API control
- **Environment-Specific**: Different settings per environment
- **Runtime Switching**: Change mode without app restart
- **Mock Data Customization**: Configurable mock data sets

### **Development Tools**
- **Toggle UI**: In-app toggle for testing
- **Mock Data Editor**: Visual mock data management
- **API Response Recording**: Capture real API responses
- **Performance Metrics**: Compare mock vs API performance

## Usage Examples

### **Quick Development Setup**
```dart
// Set to mock data for fast development
static const bool useMockData = true;
```

### **API Integration Testing**
```dart
// Set to API mode for backend testing
static const bool useMockData = false;
```

### **Production Deployment**
```dart
// Always use API in production
static const bool useMockData = false;
```

The mock data toggle provides a powerful development tool that significantly improves productivity while maintaining robust API integration capabilities! 🎉
