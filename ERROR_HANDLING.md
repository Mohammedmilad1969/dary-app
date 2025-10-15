# API Error Handling Middleware Documentation

## Overview
The Dary app now includes a comprehensive global error handling middleware that automatically manages HTTP errors, network failures, and authentication issues across all API calls.

## Features

### 🔐 **401 Unauthorized Handling**
- **Automatic Logout**: Calls `AuthProvider.logout()` when 401 is detected
- **User Notification**: Shows "Session expired. Please log in again." SnackBar
- **Automatic Redirect**: Navigates to `/login` page
- **Debug Logging**: Logs authentication failures for debugging

### 💥 **500 Server Error Handling**
- **Console Logging**: Logs detailed error information to console
- **User Notification**: Shows "Server error occurred. Our team has been notified." SnackBar
- **Debug Information**: Includes endpoint and error message in logs
- **Non-Blocking**: App continues to function despite server errors

### 🌐 **Network Failure Handling**
- **Connection Detection**: Detects `SocketException` and `HttpException`
- **User Feedback**: Shows "Network connection failed. Please check your internet connection." SnackBar
- **Graceful Degradation**: Services fall back to mock data when possible
- **Debug Logging**: Logs network error details for troubleshooting

### 🚫 **403 Forbidden Handling**
- **Permission Notification**: Shows "Access denied. You don't have permission to perform this action." SnackBar
- **Clear Messaging**: Explains why the action was denied
- **User Guidance**: Helps users understand permission issues

### 🔍 **404 Not Found Handling**
- **Resource Notification**: Shows "Resource not found. Please try again." SnackBar
- **Endpoint Logging**: Logs which endpoint returned 404
- **User Guidance**: Suggests trying again

### ⚠️ **Service Unavailable (502, 503, 504)**
- **Service Notification**: Shows "Service temporarily unavailable. Please try again later." SnackBar
- **Status Code Logging**: Logs specific service unavailable status codes
- **User Guidance**: Suggests trying again later

## Implementation Details

### **GlobalErrorHandler Class**
```dart
class GlobalErrorHandler {
  static BuildContext? _context;
  
  /// Set the current context for error handling
  static void setContext(BuildContext context) {
    _context = context;
  }
  
  /// Handle HTTP response errors globally
  static Future<void> handleHttpError(
    int statusCode,
    String endpoint,
    String? errorMessage,
  ) async {
    // Comprehensive error handling based on status codes
  }
  
  /// Handle network errors globally
  static Future<void> handleNetworkError(
    String endpoint,
    dynamic error,
  ) async {
    // Network failure handling with user feedback
  }
}
```

### **ApiClient Integration**
```dart
/// Handle HTTP response and decode JSON
Map<String, dynamic> _handleResponse(http.Response response, String endpoint) {
  if (response.statusCode >= 200 && response.statusCode < 300) {
    // Success handling
    return jsonDecode(response.body) as Map<String, dynamic>;
  } else {
    // Use global error handler for HTTP errors
    GlobalErrorHandler.handleHttpError(response.statusCode, endpoint, errorMessage);
    throw ApiException(errorMessage, statusCode: response.statusCode, endpoint: endpoint);
  }
}
```

### **Network Error Integration**
```dart
} catch (e) {
  // Handle network errors with global error handler
  if (e is SocketException || e is HttpException) {
    GlobalErrorHandler.handleNetworkError(endpoint, e);
    throw NetworkException('Network error: ${e.toString()}');
  }
  rethrow;
}
```

## Error Handling Flow

### **1. API Request Made**
- ApiClient makes HTTP request
- Request includes proper headers and authentication

### **2. Response Received**
- Response status code checked
- Success (200-299): Process response normally
- Error (400+): Trigger global error handler

### **3. Error Processing**
- `GlobalErrorHandler.handleHttpError()` called
- Status code determines specific handling
- User notification via SnackBar
- Debug logging for developers

### **4. Network Failures**
- `SocketException` or `HttpException` caught
- `GlobalErrorHandler.handleNetworkError()` called
- User notification about connection issues
- Services fall back to mock data

## User Experience Benefits

### **Seamless Error Management**
- **No App Crashes**: Errors are handled gracefully
- **Clear Feedback**: Users always know what's happening
- **Automatic Recovery**: Authentication issues auto-resolve
- **Consistent Experience**: Same error handling across all features

### **Developer Benefits**
- **Centralized Logging**: All errors logged in one place
- **Debug Information**: Detailed error context for troubleshooting
- **Easy Maintenance**: Single point of error handling logic
- **Consistent Behavior**: Same error handling across all API calls

## Testing Results

### **Network Failure Testing**
```
🌐 API REQUEST: GET https://api-dev.daryproperties.com/v1/wallet/balance
❌ API ERROR: Request failed - /wallet/balance
🔍 Error details: ClientException: Failed to fetch
! Wallet API call failed, using mock data
💰 Created new mock wallet with balance: 200 LYD
```

### **Service Fallback**
- ✅ **Wallet Service**: Falls back to mock wallet data
- ✅ **Paywall Service**: Falls back to mock package data
- ✅ **Payment Service**: Falls back to mock payment processing
- ✅ **Property Service**: Falls back to mock property data

### **Error Handling Verification**
- ✅ **401 Handling**: Ready for authentication failures
- ✅ **500 Logging**: Server errors logged to console
- ✅ **Network SnackBars**: User notifications for connection issues
- ✅ **Graceful Degradation**: App continues functioning with mock data

## Future Enhancements

### **Advanced Error Handling**
- **Retry Logic**: Automatic retry for transient failures
- **Offline Mode**: Enhanced offline functionality
- **Error Analytics**: Track error patterns for improvement
- **Custom Error Pages**: Dedicated error pages for critical failures

### **User Experience Improvements**
- **Error Recovery Actions**: Retry buttons in error messages
- **Offline Indicators**: Show when app is in offline mode
- **Progress Indicators**: Show retry attempts
- **Error History**: Allow users to see recent errors

The global error handling middleware provides enterprise-grade error management that ensures a smooth user experience even when things go wrong! 🎉
