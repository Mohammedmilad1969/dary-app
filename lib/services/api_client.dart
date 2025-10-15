import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/env_config.dart';
import '../providers/auth_provider.dart';
import '../app/app_router.dart';

/// Custom exception for authentication-related errors
class AuthException implements Exception {
  final String message;
  final int? statusCode;
  
  AuthException(this.message, {this.statusCode});
  
  @override
  String toString() => 'AuthException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

/// Global error handler for API responses
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
    if (kDebugMode) {
      debugPrint('🚨 Global Error Handler: Status $statusCode for $endpoint');
    }
    
    switch (statusCode) {
      case 401:
        await _handleUnauthorized();
        break;
      case 403:
        await _handleForbidden();
        break;
      case 404:
        await _handleNotFound(endpoint);
        break;
      case 500:
        await _handleServerError(endpoint, errorMessage);
        break;
      case 502:
      case 503:
      case 504:
        await _handleServiceUnavailable(statusCode);
        break;
      default:
        await _handleGenericError(statusCode, endpoint, errorMessage);
    }
  }
  
  /// Handle network errors globally
  static Future<void> handleNetworkError(
    String endpoint,
    dynamic error,
  ) async {
    if (kDebugMode) {
      debugPrint('🌐 Global Network Error Handler: $endpoint');
      debugPrint('🔍 Network error details: $error');
    }
    
    await _showSnackBar(
      'Network connection failed. Please check your internet connection.',
      backgroundColor: Colors.orange,
      duration: const Duration(seconds: 4),
    );
  }
  
  /// Handle 401 Unauthorized - logout and redirect to login
  static Future<void> _handleUnauthorized() async {
    if (kDebugMode) {
      debugPrint('🔐 Handling 401 Unauthorized - Logging out user');
    }
    
    try {
      if (_context != null && _context!.mounted) {
        // Get AuthProvider and logout
        final authProvider = Provider.of<AuthProvider>(_context!, listen: false);
        await authProvider.logout();
        
        // Show logout message
        await _showSnackBar(
          'Session expired. Please log in again.',
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        );
        
        // Navigate to login
        if (_context!.mounted) {
          _context!.go('/login');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error handling 401: $e');
      }
    }
  }
  
  /// Handle 403 Forbidden
  static Future<void> _handleForbidden() async {
    if (kDebugMode) {
      debugPrint('🚫 Handling 403 Forbidden');
    }
    
    await _showSnackBar(
      'Access denied. You don\'t have permission to perform this action.',
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 4),
    );
  }
  
  /// Handle 404 Not Found
  static Future<void> _handleNotFound(String endpoint) async {
    if (kDebugMode) {
      debugPrint('🔍 Handling 404 Not Found for $endpoint');
    }
    
    await _showSnackBar(
      'Resource not found. Please try again.',
      backgroundColor: Colors.orange,
      duration: const Duration(seconds: 3),
    );
  }
  
  /// Handle 500 Server Error - log to console
  static Future<void> _handleServerError(String endpoint, String? errorMessage) async {
    if (kDebugMode) {
      debugPrint('💥 SERVER ERROR (500) for $endpoint');
      debugPrint('🔍 Server error details: $errorMessage');
    }
    
    // Log to console for debugging
    print('🚨 SERVER ERROR: $endpoint - $errorMessage');
    
    await _showSnackBar(
      'Server error occurred. Our team has been notified.',
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 4),
    );
  }
  
  /// Handle Service Unavailable (502, 503, 504)
  static Future<void> _handleServiceUnavailable(int statusCode) async {
    if (kDebugMode) {
      debugPrint('⚠️ Service Unavailable ($statusCode)');
    }
    
    await _showSnackBar(
      'Service temporarily unavailable. Please try again later.',
      backgroundColor: Colors.orange,
      duration: const Duration(seconds: 4),
    );
  }
  
  /// Handle generic errors
  static Future<void> _handleGenericError(
    int statusCode,
    String endpoint,
    String? errorMessage,
  ) async {
    if (kDebugMode) {
      debugPrint('⚠️ Generic error ($statusCode) for $endpoint');
    }
    
    await _showSnackBar(
      'Request failed. Please try again.',
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 3),
    );
  }
  
  /// Show SnackBar with error message
  static Future<void> _showSnackBar(
    String message, {
    Color backgroundColor = Colors.red,
    Duration duration = const Duration(seconds: 3),
  }) async {
    try {
      if (_context != null && _context!.mounted) {
        ScaffoldMessenger.of(_context!).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: backgroundColor,
            duration: duration,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to show SnackBar: $e');
      }
    }
  }
}

/// Custom exception for API-related errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? endpoint;
  
  ApiException(this.message, {this.statusCode, this.endpoint});
  
  @override
  String toString() => 'ApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}${endpoint != null ? ' (Endpoint: $endpoint)' : ''}';
}

/// Custom exception for network-related errors
class NetworkException implements Exception {
  final String message;
  
  NetworkException(this.message);
  
  @override
  String toString() => 'NetworkException: $message';
}

/// API Client for handling HTTP requests
class ApiClient {
  // Base URL for the API - Now using environment configuration
  static String get baseUrl => EnvConfig.apiBaseUrl;
  
  // Timeout duration for requests - Now using environment configuration
  static Duration get timeoutDuration => EnvConfig.apiTimeoutDuration;
  
  // HTTP client instance
  final http.Client _client = http.Client();
  
  /// Constructor - prints configuration in debug mode
  ApiClient() {
    if (EnvConfig.enableDebugLogging) {
      debugPrint('🚀 API Client initialized');
      debugPrint('📍 Base URL: $baseUrl');
      debugPrint('⏱️ Timeout: ${timeoutDuration.inSeconds}s');
    }
  }
  
  /// Get request with optional authentication token
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? headers,
    String? token,
    Map<String, dynamic>? queryParams,
  }) async {
    return await _makeRequest(
      'GET',
      endpoint,
      headers: headers,
      token: token,
      queryParams: queryParams,
    );
  }
  
  /// Post request with optional authentication token and body
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, String>? headers,
    String? token,
    Map<String, dynamic>? body,
    List<Map<String, dynamic>>? bodyList,
  }) async {
    return await _makeRequest(
      'POST',
      endpoint,
      headers: headers,
      token: token,
      body: body,
      bodyList: bodyList,
    );
  }
  
  /// Put request with optional authentication token and body
  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, String>? headers,
    String? token,
    Map<String, dynamic>? body,
    List<Map<String, dynamic>>? bodyList,
  }) async {
    return await _makeRequest(
      'PUT',
      endpoint,
      headers: headers,
      token: token,
      body: body,
      bodyList: bodyList,
    );
  }
  
  /// Delete request with optional authentication token
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    Map<String, String>? headers,
    String? token,
    Map<String, dynamic>? queryParams,
  }) async {
    return await _makeRequest(
      'DELETE',
      endpoint,
      headers: headers,
      token: token,
      queryParams: queryParams,
    );
  }
  
  /// Patch request with optional authentication token and body
  Future<Map<String, dynamic>> patch(
    String endpoint, {
    Map<String, String>? headers,
    String? token,
    Map<String, dynamic>? body,
    List<Map<String, dynamic>>? bodyList,
  }) async {
    return await _makeRequest(
      'PATCH',
      endpoint,
      headers: headers,
      token: token,
      body: body,
      bodyList: bodyList,
    );
  }
  
  /// Upload file with multipart form data
  Future<Map<String, dynamic>> uploadFile(
    String endpoint, {
    required String filePath,
    required String fieldName,
    Map<String, String>? headers,
    String? token,
    Map<String, String>? additionalFields,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final request = http.MultipartRequest('POST', uri);
      
      // Add headers
      final requestHeaders = _buildHeaders(headers, token);
      request.headers.addAll(requestHeaders);
      
      // Add file
      final file = await http.MultipartFile.fromPath(fieldName, filePath);
      request.files.add(file);
      
      // Add additional fields
      if (additionalFields != null) {
        request.fields.addAll(additionalFields);
      }
      
      _logRequest('POST', uri.toString(), headers: requestHeaders, isMultipart: true);
      
      final streamedResponse = await request.send().timeout(timeoutDuration);
      final response = await http.Response.fromStream(streamedResponse);
      
      return _handleResponse(response, endpoint);
      
    } catch (e) {
      _logError('File upload failed', endpoint, e);
      
      // Handle network errors with global error handler
      if (e is SocketException || e is HttpException) {
        GlobalErrorHandler.handleNetworkError(endpoint, e);
        throw NetworkException('Network error: ${e.toString()}');
      }
      
      rethrow;
    }
  }
  
  /// Upload multiple files with multipart form data
  Future<Map<String, dynamic>> uploadFiles(
    String endpoint, {
    required List<String> filePaths,
    required String fieldName,
    Map<String, String>? headers,
    String? token,
    Map<String, String>? additionalFields,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final request = http.MultipartRequest('POST', uri);
      
      // Add headers
      final requestHeaders = _buildHeaders(headers, token);
      request.headers.addAll(requestHeaders);
      
      // Add files
      for (final filePath in filePaths) {
        final file = await http.MultipartFile.fromPath(fieldName, filePath);
        request.files.add(file);
      }
      
      // Add additional fields
      if (additionalFields != null) {
        request.fields.addAll(additionalFields);
      }
      
      _logRequest('POST', uri.toString(), headers: requestHeaders, isMultipart: true);
      
      final streamedResponse = await request.send().timeout(timeoutDuration);
      final response = await http.Response.fromStream(streamedResponse);
      
      return _handleResponse(response, endpoint);
      
    } catch (e) {
      _logError('Multiple files upload failed', endpoint, e);
      
      // Handle network errors with global error handler
      if (e is SocketException || e is HttpException) {
        GlobalErrorHandler.handleNetworkError(endpoint, e);
        throw NetworkException('Network error: ${e.toString()}');
      }
      
      rethrow;
    }
  }
  
  /// Core method for making HTTP requests
  Future<Map<String, dynamic>> _makeRequest(
    String method,
    String endpoint, {
    Map<String, String>? headers,
    String? token,
    Map<String, dynamic>? body,
    List<Map<String, dynamic>>? bodyList,
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final uri = _buildUri(endpoint, queryParams);
      final requestHeaders = _buildHeaders(headers, token);
      
      http.Response response;
      
      switch (method.toUpperCase()) {
        case 'GET':
          _logRequest(method, uri.toString(), headers: requestHeaders);
          response = await _client
              .get(uri, headers: requestHeaders)
              .timeout(timeoutDuration);
          break;
          
        case 'POST':
          final requestBody = _buildRequestBody(body, bodyList);
          _logRequest(method, uri.toString(), headers: requestHeaders, body: requestBody);
          response = await _client
              .post(uri, headers: requestHeaders, body: requestBody)
              .timeout(timeoutDuration);
          break;
          
        case 'PUT':
          final requestBody = _buildRequestBody(body, bodyList);
          _logRequest(method, uri.toString(), headers: requestHeaders, body: requestBody);
          response = await _client
              .put(uri, headers: requestHeaders, body: requestBody)
              .timeout(timeoutDuration);
          break;
          
        case 'PATCH':
          final requestBody = _buildRequestBody(body, bodyList);
          _logRequest(method, uri.toString(), headers: requestHeaders, body: requestBody);
          response = await _client
              .patch(uri, headers: requestHeaders, body: requestBody)
              .timeout(timeoutDuration);
          break;
          
        case 'DELETE':
          _logRequest(method, uri.toString(), headers: requestHeaders);
          response = await _client
              .delete(uri, headers: requestHeaders)
              .timeout(timeoutDuration);
          break;
          
        default:
          throw ApiException('Unsupported HTTP method: $method', endpoint: endpoint);
      }
      
      return _handleResponse(response, endpoint);
      
    } catch (e) {
      _logError('Request failed', endpoint, e);
      
      // Handle network errors with global error handler
      if (e is SocketException || e is HttpException) {
        GlobalErrorHandler.handleNetworkError(endpoint, e);
        throw NetworkException('Network error: ${e.toString()}');
      }
      
      rethrow;
    }
  }
  
  /// Build URI with query parameters
  Uri _buildUri(String endpoint, [Map<String, dynamic>? queryParams]) {
    final uri = Uri.parse('$baseUrl$endpoint');
    
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(queryParameters: queryParams.map(
        (key, value) => MapEntry(key, value.toString()),
      ));
    }
    
    return uri;
  }
  
  /// Build request headers with optional authentication token
  Map<String, String> _buildHeaders(Map<String, String>? headers, String? token) {
    final defaultHeaders = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (token != null) {
      defaultHeaders['Authorization'] = 'Bearer $token';
    }
    
    if (headers != null) {
      defaultHeaders.addAll(headers);
    }
    
    return defaultHeaders;
  }
  
  /// Build request body from Map or List
  String? _buildRequestBody(Map<String, dynamic>? body, List<Map<String, dynamic>>? bodyList) {
    if (body != null) {
      return jsonEncode(body);
    } else if (bodyList != null) {
      return jsonEncode(bodyList);
    }
    return null;
  }
  
  /// Handle HTTP response and decode JSON
  Map<String, dynamic> _handleResponse(http.Response response, String endpoint) {
    _logResponse(response, endpoint);
    
    // Check for successful status codes
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {};
      }
      
      try {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        _logError('JSON decode failed', endpoint, e);
        throw ApiException('Invalid JSON response', statusCode: response.statusCode, endpoint: endpoint);
      }
    } else {
      // Handle error responses with global error handler
      String errorMessage = 'Request failed with status ${response.statusCode}';
      
      try {
        final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
        errorMessage = errorBody['message'] ?? errorBody['error'] ?? errorMessage;
      } catch (e) {
        // If JSON decode fails, use the raw response body if available
        if (response.body.isNotEmpty) {
          errorMessage = response.body;
        }
      }
      
      // Use global error handler for HTTP errors
      GlobalErrorHandler.handleHttpError(response.statusCode, endpoint, errorMessage);
      
      throw ApiException(
        errorMessage,
        statusCode: response.statusCode,
        endpoint: endpoint,
      );
    }
  }
  
  /// Log HTTP requests for debugging
  void _logRequest(String method, String url, {Map<String, String>? headers, String? body, bool isMultipart = false}) {
    if (EnvConfig.enableDebugLogging) {
      debugPrint('🌐 API REQUEST: $method $url');
      if (EnvConfig.enableVerboseLogging && headers != null && headers.isNotEmpty) {
        debugPrint('📋 Headers: $headers');
      }
      if (EnvConfig.enableVerboseLogging && body != null && body.isNotEmpty && !isMultipart) {
        debugPrint('📦 Body: $body');
      }
      if (isMultipart) {
        debugPrint('📎 Multipart request');
      }
    }
  }
  
  /// Log HTTP responses for debugging
  void _logResponse(http.Response response, String endpoint) {
    if (EnvConfig.enableDebugLogging) {
      debugPrint('📡 API RESPONSE: ${response.statusCode} $endpoint');
      if (EnvConfig.enableVerboseLogging && response.body.isNotEmpty) {
        debugPrint('📄 Response body: ${response.body}');
      }
    }
  }
  
  /// Log errors for debugging
  void _logError(String message, String endpoint, dynamic error) {
    if (EnvConfig.enableDebugLogging) {
      debugPrint('❌ API ERROR: $message - $endpoint');
      if (EnvConfig.enableVerboseLogging) {
        debugPrint('🔍 Error details: $error');
      }
    }
  }
  
  /// Close the HTTP client
  void dispose() {
    _client.close();
  }
}

/// Singleton instance of ApiClient
final ApiClient apiClient = ApiClient();
