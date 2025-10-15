import 'package:flutter/material.dart';

enum SubscriptionPlan {
  free,
  basic,
  premium,
  pro,
}

class Subscription {
  final String id;
  final SubscriptionPlan plan;
  final double price;
  final String currency;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final List<String> features;

  const Subscription({
    required this.id,
    required this.plan,
    required this.price,
    required this.currency,
    required this.startDate,
    this.endDate,
    required this.isActive,
    required this.features,
  });
}

class PaywallService {
  static Subscription? _currentSubscription;

  static Subscription? get currentSubscription => _currentSubscription;

  static Future<List<SubscriptionPlan>> getAvailablePlans() async {
    // TODO: Implement actual API call
    await Future.delayed(const Duration(seconds: 1));
    return SubscriptionPlan.values;
  }

  static Future<bool> subscribeToPlan(SubscriptionPlan plan) async {
    // TODO: Implement actual subscription logic
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }

  static Future<bool> cancelSubscription(String subscriptionId) async {
    // TODO: Implement actual cancellation logic
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }

  static Future<bool> restoreSubscription() async {
    // TODO: Implement actual restoration logic
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }
}
