import 'package:flutter/services.dart';

/// Input formatter that only allows letters, numbers, and spaces
/// Blocks all symbols and special characters
class NoSymbolsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Allow only letters (a-z, A-Z), numbers (0-9), and spaces
    final allowedPattern = RegExp(r'^[a-zA-Z0-9\s]*$');
    
    if (allowedPattern.hasMatch(newValue.text)) {
      return newValue;
    }
    
    // If the new value contains symbols, return the old value
    return oldValue;
  }
}

/// Input formatter that allows letters, numbers, spaces, and basic punctuation
/// Useful for names, addresses, and descriptions
class BasicTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Allow letters, numbers, spaces, and basic punctuation (periods, commas, hyphens, apostrophes)
    final allowedPattern = RegExp(r"^[a-zA-Z0-9\s.,'-]*$");
    
    if (allowedPattern.hasMatch(newValue.text)) {
      return newValue;
    }
    
    // If the new value contains unallowed symbols, return the old value
    return oldValue;
  }
}

/// Input formatter for phone numbers (allows numbers, spaces, hyphens, and +)
class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Allow numbers, spaces, hyphens, parentheses, and plus sign
    final allowedPattern = RegExp(r'^[0-9\s\-\+\(\)]*$');
    
    if (allowedPattern.hasMatch(newValue.text)) {
      return newValue;
    }
    
    return oldValue;
  }
}

/// Input formatter for price/amount fields (allows numbers and decimal point)
class PriceFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Allow numbers and decimal point
    final allowedPattern = RegExp(r'^[0-9.]*$');
    
    if (allowedPattern.hasMatch(newValue.text)) {
      // Ensure only one decimal point
      final parts = newValue.text.split('.');
      if (parts.length > 2) {
        return oldValue;
      }
      return newValue;
    }
    
    return oldValue;
  }
}

