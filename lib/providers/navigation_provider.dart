import 'package:flutter/foundation.dart';

/// Provider for managing navigation loading state
class NavigationProvider extends ChangeNotifier {
  bool _isNavigating = false;
  String? _currentRoute;

  bool get isNavigating => _isNavigating;
  String? get currentRoute => _currentRoute;

  void setNavigating(bool value, {String? route}) {
    _isNavigating = value;
    _currentRoute = route;
    notifyListeners();
  }

  void startNavigation(String route) {
    _isNavigating = true;
    _currentRoute = route;
    notifyListeners();
  }

  void endNavigation() {
    // Add a small delay to ensure smooth transition
    Future.delayed(const Duration(milliseconds: 300), () {
      _isNavigating = false;
      _currentRoute = null;
      notifyListeners();
    });
  }
}

