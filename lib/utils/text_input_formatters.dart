import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Input formatter that only allows letters, numbers, and spaces
/// Blocks all symbols and special characters
/// Supports both English and Arabic characters
class NoSymbolsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Allow letters (English a-z, A-Z and Arabic Unicode ranges), numbers (0-9), and spaces
    // Arabic ranges: \u0600-\u06FF (Basic Arabic), \u0750-\u077F (Arabic Supplement)
    // \u08A0-\u08FF (Arabic Extended-A), \uFB50-\uFDFF (Arabic Presentation Forms-A)
    // \uFE70-\uFEFF (Arabic Presentation Forms-B)
    final allowedPattern = RegExp(r'^[a-zA-Z\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF0-9\s]*$');
    
    if (allowedPattern.hasMatch(newValue.text)) {
      return newValue;
    }
    
    // If the new value contains symbols, return the old value
    return oldValue;
  }
}

/// Input formatter that allows letters, numbers, spaces, and basic punctuation
/// Useful for names, addresses, and descriptions
/// Supports both English and Arabic characters
class BasicTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Allow letters (English a-z, A-Z and Arabic Unicode ranges), numbers (0-9), 
    // spaces, and basic punctuation (periods, commas, hyphens, apostrophes)
    // Arabic ranges: \u0600-\u06FF (Basic Arabic), \u0750-\u077F (Arabic Supplement)
    // \u08A0-\u08FF (Arabic Extended-A), \uFB50-\uFDFF (Arabic Presentation Forms-A)
    // \uFE70-\uFEFF (Arabic Presentation Forms-B)
    final allowedPattern = RegExp(r"^[a-zA-Z\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF0-9\s.,'-]*$");
    
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


/// Input formatter that formats numbers with thousand separators (e.g. 1,000,000)
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  static final NumberFormat _formatter = NumberFormat.decimalPattern();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove non-digit chars
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    // If simple deletion resulting in empty string
    if (newText.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Parse and format
    try {
      int value = int.parse(newText);
      String formatted = _formatter.format(value);
      
      return newValue.copyWith(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    } catch (e) {
      return oldValue;
    }
  }
}
