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

