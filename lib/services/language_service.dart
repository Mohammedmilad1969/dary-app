import 'package:flutter/material.dart';

class LanguageService extends ChangeNotifier {
  static const Locale _englishLocale = Locale('en');
  static const Locale _arabicLocale = Locale('ar');
  
  Locale _currentLocale = _arabicLocale;
  
  Locale get currentLocale => _currentLocale;
  
  bool get isEnglish => _currentLocale == _englishLocale;
  bool get isArabic => _currentLocale == _arabicLocale;
  
  TextDirection get textDirection => isArabic ? TextDirection.rtl : TextDirection.ltr;
  
  void toggleLanguage() {
    _currentLocale = isEnglish ? _arabicLocale : _englishLocale;
    notifyListeners();
  }
  
  void setLanguage(Locale locale) {
    if (locale != _currentLocale) {
      _currentLocale = locale;
      notifyListeners();
    }
  }
  
  String get languageCode => _currentLocale.languageCode;
  
  String get languageName {
    switch (_currentLocale.languageCode) {
      case 'en':
        return 'English';
      case 'ar':
        return 'العربية';
      default:
        return 'English';
    }
  }
}
