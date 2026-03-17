import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// Service to monitor internet connectivity status.
class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal() {
    _init();
  }

  final Connectivity _connectivity = Connectivity();
  ConnectivityResult _lastResult = ConnectivityResult.wifi;
  bool _isOffline = false;
  Completer<void> _initCompleter = Completer<void>();

  bool get isOffline => _isOffline;
  Future<void> get initialized => _initCompleter.future;

  Future<void> _init() async {
    try {
      // Initial check
      final results = await _connectivity.checkConnectivity();
      _updateStatus(results);

      // Listen for changes
      _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
        _updateStatus(results);
      });
    } finally {
      if (!_initCompleter.isCompleted) {
        _initCompleter.complete();
      }
    }
  }

  void _updateStatus(List<ConnectivityResult> results) {
    // Current version of connectivity_plus returns a list
    // We are offline if the list is empty or only contains 'none'
    final bool newStatus = results.isEmpty || results.contains(ConnectivityResult.none);
    
    if (_isOffline != newStatus) {
      _isOffline = newStatus;
      notifyListeners();
    }
  }

  /// Manually trigger a refresh check
  Future<void> checkNow() async {
    final results = await _connectivity.checkConnectivity();
    _updateStatus(results);
  }
}
