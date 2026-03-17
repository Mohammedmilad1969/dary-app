import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// Moamalat Payment Gateway Service
/// Handles payment processing using Moamalat PayForm Plus Lightbox
class MoamalatPaymentService {
  // Test credentials - Replace with production credentials
  static const String testMerchantId = '10215985153';
  static const String testTerminalId = '70070092';
  static const String testSecureKey = 'a09d57ad43522aa025359f50c725c9e9';
  
  // Production credentials
  static const String productionMerchantId = '10215985153';
  static const String productionTerminalId = '70070092';
  static const String productionSecureKey = 'a09d57ad43522aa025359f50c725c9e9';
  
  // Environment URLs
  static const String testLightboxUrl = 'https://tnpg.moamalat.net:6006/js/lightbox.js';
  static const String productionLightboxUrl = 'https://npg.moamalat.net:6006/js/lightbox.js';
  
  final bool isTestMode;
  
  MoamalatPaymentService({this.isTestMode = false}); // Production by default
  
  String get merchantId => isTestMode ? testMerchantId : productionMerchantId;
  String get terminalId => isTestMode ? testTerminalId : productionTerminalId;
  String get secureKey => isTestMode ? testSecureKey : productionSecureKey;
  String get lightboxUrl => isTestMode ? testLightboxUrl : productionLightboxUrl;

  /// Generate secure hash for Lightbox request
  /// Fields: Amount, DateTimeLocalTrxn, MerchantId, MerchantReference, TerminalId
  String generateLightboxRequestHash({
    required String amount,
    required String dateTimeLocalTrxn,
    required String merchantReference,
  }) {
    // Sort fields in ascending order
    final sortedParams = {
      'Amount': amount,
      'DateTimeLocalTrxn': dateTimeLocalTrxn,
      'MerchantId': merchantId,
      'MerchantReference': merchantReference,
      'TerminalId': terminalId,
    };
    
    // Build query string: field1=value1&field2=value2
    final queryString = sortedParams.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    
    if (kDebugMode) {
      debugPrint('🔐 Moamalat Hash Input: $queryString');
    }
    
    // Generate SHA-256 HMAC using raw bytes from hex key
    final keyBytes = _hexToBytes(secureKey);
    final messageBytes = utf8.encode(queryString);
    final hmac = Hmac(sha256, keyBytes);
    final digest = hmac.convert(messageBytes);
    
    return digest.toString().toUpperCase();
  }

  List<int> _hexToBytes(String hex) {
    var result = <int>[];
    for (var i = 0; i < hex.length; i += 2) {
      result.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return result;
  }

  /// Generate secure hash for complete callback verification
  String generateCompleteCallbackHash({
    required String amount,
    required String currency,
    required String merchantReference,
    required String paidThrough,
    required String txnDate,
    required String systemReference,
    String? networkReference,
    String? payerAccount,
    String? payerName,
    String? providerSchemeName,
  }) {
    // All parameters except SecureHash, sorted alphabetically
    final sortedParams = <String, String>{
      'Amount': amount,
      'Currency': currency,
      'MerchantId': merchantId,
      'MerchantReference': merchantReference,
      'PaidThrough': paidThrough,
      'TerminalId': terminalId,
      'TxnDate': txnDate,
    };
    
    if (networkReference != null) sortedParams['NetworkReference'] = networkReference;
    if (payerAccount != null) sortedParams['PayerAccount'] = payerAccount;
    if (payerName != null) sortedParams['PayerName'] = payerName;
    if (providerSchemeName != null) sortedParams['ProviderSchemeName'] = providerSchemeName;
    
    final queryString = sortedParams.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    
    final keyBytes = _hexToBytes(secureKey);
    final messageBytes = utf8.encode(queryString);
    final hmac = Hmac(sha256, keyBytes);
    final digest = hmac.convert(messageBytes);
    
    return digest.toString().toUpperCase();
  }

  /// Generate secure hash for error callback verification
  String generateErrorCallbackHash({
    required String amount,
    required String dateTimeLocalTrxn,
    required String errorMessage,
    required String merchantReference,
  }) {
    final sortedParams = {
      'Amount': amount,
      'DateTimeLocalTrxn': dateTimeLocalTrxn,
      'ErrorMessage': errorMessage,
      'MerchantId': merchantId,
      'MerchantReference': merchantReference,
      'TerminalId': terminalId,
    };
    
    final queryString = sortedParams.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    
    final keyBytes = _hexToBytes(secureKey);
    final messageBytes = utf8.encode(queryString);
    final hmac = Hmac(sha256, keyBytes);
    final digest = hmac.convert(messageBytes);
    
    return digest.toString().toUpperCase();
  }

  /// Format amount to smallest currency unit (1 LYD = 1000)
  String formatAmount(double amount) {
    return (amount * 1000).toInt().toString();
  }

  /// Generate transaction date time in format yyyyMMddHHmm
  String generateTransactionDateTime() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}'
           '${now.month.toString().padLeft(2, '0')}'
           '${now.day.toString().padLeft(2, '0')}'
           '${now.hour.toString().padLeft(2, '0')}'
           '${now.minute.toString().padLeft(2, '0')}';
  }

  /// Generate unique merchant reference
  String generateMerchantReference(String userId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${userId}_$timestamp';
  }
}



