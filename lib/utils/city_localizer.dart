import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'libyan_data.dart';

class CityLocalizer {
  // Bilingual city mapping: English <-> Arabic
  static const Map<String, String> _cityToArabic = {
    'Tripoli': 'طرابلس',
    'Benghazi': 'بنغازي',
    'Ajdabiya': 'أجدابيا',
    'Misrata': 'مصراتة',
    'Al Bayda': 'البيضاء',
    'Khoms': 'الخمس',
    'Zawiya': 'الزاوية',
    'Gharyan': 'غريان',
    'Al Marj': 'المرج',
    'Tobruk': 'طبرق',
    'Sabratha': 'صبراتة',
    'Al Jumayl': 'الجميل',
    'Derna': 'درنة',
    'Janzur': 'جنزور',
    'Zuwara': 'زوارة',
    'Msallata': 'مسلاتة',
    'Sirte': 'سرت',
    'Yafran': 'يفرن',
    'Nalut': 'نالوت',
    'Bani Walid': 'بني وليد',
    'Tajoura': 'تاجوراء',
    'Brak': 'براك',
    'Shahat': 'شحات',
    'Murzuq': 'مرزق',
    'Ubari': 'أوباري',
    'Garabulli': 'القرة بوللي',
    'Waddan': 'ودان',
    'Al Qubba': 'القبة',
    'Aziziya': 'العزيزية',
    'Sabha': 'سبها',
    'Zliten': 'زليتن',
    'Tarhuna': 'ترهونة',
    'Ghat': 'غات',
    'Ghadames': 'غدامس',
    'Al Kufra': 'الكفرة',
    'Al Jufra': 'الجفرة',
    'Mizda': 'مزدة',
    'Tocra': 'توكرة',
    'Zueitina': 'الزويتينة',
    'Hun': 'هون',
    'Al Jawf': 'الجوف',
    'Zaltan': 'زلاتن',
    'Zintan': 'الزنتان',
    'Suluq': 'سلوق',
    'Umm al Rizam': 'أم الرزم',
    'Ghemines': 'قمينس',
    'Kikla': 'ككلة',
    'Sawknah': 'سوكنة',
    'Sidra': 'السدرة',
    'Brega': 'البريقة',
    'Awjila': 'أوجلة',
    'Jalu': 'جالو',
  };

  static const Map<String, String> _arabicToCity = {
    'طرابلس': 'Tripoli',
    'بنغازي': 'Benghazi',
    'أجدابيا': 'Ajdabiya',
    'مصراتة': 'Misrata',
    'البيضاء': 'Al Bayda',
    'الخمس': 'Khoms',
    'الزاوية': 'Zawiya',
    'غريان': 'Gharyan',
    'المرج': 'Al Marj',
    'طبرق': 'Tobruk',
    'صبراتة': 'Sabratha',
    'الجميل': 'Al Jumayl',
    'درنة': 'Derna',
    'جنزور': 'Janzur',
    'زوارة': 'Zuwara',
    'مسلاتة': 'Msallata',
    'سرت': 'Sirte',
    'يفرن': 'Yafran',
    'نالوت': 'Nalut',
    'بني وليد': 'Bani Walid',
    'تاجوراء': 'Tajoura',
    'براك': 'Brak',
    'شحات': 'Shahat',
    'مرزق': 'Murzuq',
    'أوباري': 'Ubari',
    'القرة بوللي': 'Garabulli',
    'ودان': 'Waddan',
    'القبة': 'Al Qubba',
    'العزيزية': 'Aziziya',
    'سبها': 'Sabha',
    'زليتن': 'Zliten',
    'ترهونة': 'Tarhuna',
    'غات': 'Ghat',
    'غدامس': 'Ghadames',
    'الكفرة': 'Al Kufra',
    'الجفرة': 'Al Jufra',
    'مزدة': 'Mizda',
    'توكرة': 'Tocra',
    'الزويتينة': 'Zueitina',
    'هون': 'Hun',
    'الجوف': 'Al Jawf',
    'زلاتن': 'Zaltan',
    'الزنتان': 'Zintan',
    'سلوق': 'Suluq',
    'أم الرزم': 'Umm al Rizam',
    'قمينس': 'Ghemines',
    'ككلة': 'Kikla',
    'سوكنة': 'Sawknah',
    'السدرة': 'Sidra',
    'البريقة': 'Brega',
    'أوجلة': 'Awjila',
    'جالو': 'Jalu',
  };

  /// Get localized city name based on current language
  static String getLocalizedCityName(BuildContext context, String cityName) {
    if (cityName == 'any') {
      final l10n = AppLocalizations.of(context);
      return l10n?.allProperties ?? 'All Cities';
    }
    
    final l10n = AppLocalizations.of(context);
    final isArabic = l10n?.localeName == 'ar';
    
    if (isArabic) {
      // If current language is Arabic, return Arabic name
      return _cityToArabic[cityName] ?? cityName;
    } else {
      // If current language is English, return English name
      return _arabicToCity[cityName] ?? cityName;
    }
  }

  /// Get bilingual city name like "Tripoli (طرابلس)"
  static String getBilingualCityName(String cityName) {
    return LibyanData.cityDisplayNames[cityName] ?? cityName;
  }

  /// Normalize city name to English (for database storage)
  static String normalizeToEnglish(String cityName) {
    return _arabicToCity[cityName] ?? cityName;
  }

  /// Get Arabic name from English name
  static String? toArabic(String englishName) {
    return _cityToArabic[englishName];
  }

  /// Get English name from Arabic name
  static String? toEnglish(String arabicName) {
    return _arabicToCity[arabicName];
  }

  /// Get list of all city names in English
  static List<String> getAllEnglishCities() {
    return LibyanData.cities;
  }

  /// Get neighborhoods for a city
  static List<String> getNeighborhoods(String city) {
    final neighborhoods = LibyanData.cityNeighborhoods[city] ?? [];
    if (neighborhoods.isEmpty) {
      return ['Other (أخرى)'];
    }
    return neighborhoods;
  }

  /// Get localized neighborhood name from bilingual string "Name (الاسم)"
  static String getLocalizedNeighborhoodName(BuildContext context, String neighborhood) {
    final l10n = AppLocalizations.of(context);
    final isArabic = l10n?.localeName == 'ar';
    
    // Check if format is "English (Arabic)"
    final RegExp regex = RegExp(r'^(.*)\s\((.*)\)$');
    final match = regex.firstMatch(neighborhood);
    
    if (match != null) {
      if (isArabic) {
        return match.group(2) ?? neighborhood;
      } else {
        return match.group(1) ?? neighborhood;
      }
    }
    
    return neighborhood;
  }
}
