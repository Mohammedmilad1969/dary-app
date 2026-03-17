import 'package:intl/intl.dart';

/// Formats a number with commas as thousand separators
/// Example: 1000 -> "1,000", 1234567 -> "1,234,567"
String formatNumberWithCommas(num value) {
  final formatter = NumberFormat('#,###');
  return formatter.format(value);
}

/// Formats a price with commas and currency
/// Example: 1000 -> "1,000 LYD", 1234567 -> "1,234,567 LYD"
String formatPriceWithCommas(num price, {String currency = 'LYD'}) {
  final formattedNumber = formatNumberWithCommas(price);
  return '$formattedNumber $currency';
}

/// Formats a date using a pattern and locale, but ensures numbers are always English
/// This is used to display years and days in English even when the month name is in Arabic
String formatDateWithEnglishNumbers(DateTime date, String pattern, String locale) {
  String formatted = DateFormat(pattern, locale).format(date);
  if (locale == 'ar') {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    for (int i = 0; i < 10; i++) {
      formatted = formatted.replaceAll(arabicDigits[i], i.toString());
    }
  }
  return formatted;
}

