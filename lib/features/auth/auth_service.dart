import 'package:flutter/material.dart';

class AuthService {
  static bool _isLoggedIn = false;
  static String? _currentUser;

  static bool get isLoggedIn => _isLoggedIn;
  static String? get currentUser => _currentUser;

  static Future<bool> login(String email, String password) async {
    // TODO: Implement actual authentication logic
    await Future.delayed(const Duration(seconds: 1));
    _isLoggedIn = true;
    _currentUser = email;
    return true;
  }

  static Future<void> logout() async {
    _isLoggedIn = false;
    _currentUser = null;
  }

  static Future<bool> register(String email, String password) async {
    // TODO: Implement actual registration logic
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }
}

class AuthController extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await AuthService.login(email, password);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await AuthService.logout();
    notifyListeners();
  }
}
