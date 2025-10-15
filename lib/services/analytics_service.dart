import 'package:flutter/foundation.dart';
import '../config/env_config.dart';
import '../services/api_client.dart';

/// Analytics data models
class ListingViews {
  final String propertyId;
  final int views;
  final DateTime date;

  ListingViews({
    required this.propertyId,
    required this.views,
    required this.date,
  });

  factory ListingViews.fromJson(Map<String, dynamic> json) {
    return ListingViews(
      propertyId: json['propertyId'],
      views: json['views'],
      date: DateTime.parse(json['date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'propertyId': propertyId,
      'views': views,
      'date': date.toIso8601String(),
    };
  }
}

class ContactClicks {
  final String propertyId;
  final int clicks;
  final DateTime date;

  ContactClicks({
    required this.propertyId,
    required this.clicks,
    required this.date,
  });

  factory ContactClicks.fromJson(Map<String, dynamic> json) {
    return ContactClicks(
      propertyId: json['propertyId'],
      clicks: json['clicks'],
      date: DateTime.parse(json['date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'propertyId': propertyId,
      'clicks': clicks,
      'date': date.toIso8601String(),
    };
  }
}

class PerformanceSummary {
  final String userId;
  final int totalViews;
  final int totalContactClicks;
  final double averageEngagement;
  final String topPerformingListing;
  final Map<String, int> propertyTypePerformance;

  PerformanceSummary({
    required this.userId,
    required this.totalViews,
    required this.totalContactClicks,
    required this.averageEngagement,
    required this.topPerformingListing,
    required this.propertyTypePerformance,
  });

  factory PerformanceSummary.fromJson(Map<String, dynamic> json) {
    return PerformanceSummary(
      userId: json['userId'],
      totalViews: json['totalViews'],
      totalContactClicks: json['totalContactClicks'],
      averageEngagement: json['averageEngagement'].toDouble(),
      topPerformingListing: json['topPerformingListing'],
      propertyTypePerformance: Map<String, int>.from(json['propertyTypePerformance']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'totalViews': totalViews,
      'totalContactClicks': totalContactClicks,
      'averageEngagement': averageEngagement,
      'topPerformingListing': topPerformingListing,
      'propertyTypePerformance': propertyTypePerformance,
    };
  }
}

/// Analytics service for tracking listing performance
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final ApiClient _apiClient = ApiClient();

  // Mock data for analytics
  static final Map<String, List<ListingViews>> _mockListingViews = {
    'prop_001': [
      ListingViews(propertyId: 'prop_001', views: 45, date: DateTime.now().subtract(const Duration(days: 6))),
      ListingViews(propertyId: 'prop_001', views: 52, date: DateTime.now().subtract(const Duration(days: 5))),
      ListingViews(propertyId: 'prop_001', views: 38, date: DateTime.now().subtract(const Duration(days: 4))),
      ListingViews(propertyId: 'prop_001', views: 67, date: DateTime.now().subtract(const Duration(days: 3))),
      ListingViews(propertyId: 'prop_001', views: 43, date: DateTime.now().subtract(const Duration(days: 2))),
      ListingViews(propertyId: 'prop_001', views: 59, date: DateTime.now().subtract(const Duration(days: 1))),
      ListingViews(propertyId: 'prop_001', views: 41, date: DateTime.now()),
    ],
    'prop_002': [
      ListingViews(propertyId: 'prop_002', views: 23, date: DateTime.now().subtract(const Duration(days: 6))),
      ListingViews(propertyId: 'prop_002', views: 31, date: DateTime.now().subtract(const Duration(days: 5))),
      ListingViews(propertyId: 'prop_002', views: 28, date: DateTime.now().subtract(const Duration(days: 4))),
      ListingViews(propertyId: 'prop_002', views: 35, date: DateTime.now().subtract(const Duration(days: 3))),
      ListingViews(propertyId: 'prop_002', views: 42, date: DateTime.now().subtract(const Duration(days: 2))),
      ListingViews(propertyId: 'prop_002', views: 29, date: DateTime.now().subtract(const Duration(days: 1))),
      ListingViews(propertyId: 'prop_002', views: 33, date: DateTime.now()),
    ],
    'prop_003': [
      ListingViews(propertyId: 'prop_003', views: 67, date: DateTime.now().subtract(const Duration(days: 6))),
      ListingViews(propertyId: 'prop_003', views: 74, date: DateTime.now().subtract(const Duration(days: 5))),
      ListingViews(propertyId: 'prop_003', views: 81, date: DateTime.now().subtract(const Duration(days: 4))),
      ListingViews(propertyId: 'prop_003', views: 69, date: DateTime.now().subtract(const Duration(days: 3))),
      ListingViews(propertyId: 'prop_003', views: 76, date: DateTime.now().subtract(const Duration(days: 2))),
      ListingViews(propertyId: 'prop_003', views: 83, date: DateTime.now().subtract(const Duration(days: 1))),
      ListingViews(propertyId: 'prop_003', views: 78, date: DateTime.now()),
    ],
  };

  static final Map<String, List<ContactClicks>> _mockContactClicks = {
    'prop_001': [
      ContactClicks(propertyId: 'prop_001', clicks: 3, date: DateTime.now().subtract(const Duration(days: 6))),
      ContactClicks(propertyId: 'prop_001', clicks: 5, date: DateTime.now().subtract(const Duration(days: 5))),
      ContactClicks(propertyId: 'prop_001', clicks: 2, date: DateTime.now().subtract(const Duration(days: 4))),
      ContactClicks(propertyId: 'prop_001', clicks: 7, date: DateTime.now().subtract(const Duration(days: 3))),
      ContactClicks(propertyId: 'prop_001', clicks: 4, date: DateTime.now().subtract(const Duration(days: 2))),
      ContactClicks(propertyId: 'prop_001', clicks: 6, date: DateTime.now().subtract(const Duration(days: 1))),
      ContactClicks(propertyId: 'prop_001', clicks: 3, date: DateTime.now()),
    ],
    'prop_002': [
      ContactClicks(propertyId: 'prop_002', clicks: 1, date: DateTime.now().subtract(const Duration(days: 6))),
      ContactClicks(propertyId: 'prop_002', clicks: 2, date: DateTime.now().subtract(const Duration(days: 5))),
      ContactClicks(propertyId: 'prop_002', clicks: 1, date: DateTime.now().subtract(const Duration(days: 4))),
      ContactClicks(propertyId: 'prop_002', clicks: 3, date: DateTime.now().subtract(const Duration(days: 3))),
      ContactClicks(propertyId: 'prop_002', clicks: 2, date: DateTime.now().subtract(const Duration(days: 2))),
      ContactClicks(propertyId: 'prop_002', clicks: 1, date: DateTime.now().subtract(const Duration(days: 1))),
      ContactClicks(propertyId: 'prop_002', clicks: 2, date: DateTime.now()),
    ],
    'prop_003': [
      ContactClicks(propertyId: 'prop_003', clicks: 8, date: DateTime.now().subtract(const Duration(days: 6))),
      ContactClicks(propertyId: 'prop_003', clicks: 9, date: DateTime.now().subtract(const Duration(days: 5))),
      ContactClicks(propertyId: 'prop_003', clicks: 7, date: DateTime.now().subtract(const Duration(days: 4))),
      ContactClicks(propertyId: 'prop_003', clicks: 10, date: DateTime.now().subtract(const Duration(days: 3))),
      ContactClicks(propertyId: 'prop_003', clicks: 8, date: DateTime.now().subtract(const Duration(days: 2))),
      ContactClicks(propertyId: 'prop_003', clicks: 9, date: DateTime.now().subtract(const Duration(days: 1))),
      ContactClicks(propertyId: 'prop_003', clicks: 7, date: DateTime.now()),
    ],
  };

  static final Map<String, PerformanceSummary> _mockPerformanceSummaries = {
    'user_001': PerformanceSummary(
      userId: 'user_001',
      totalViews: 1234,
      totalContactClicks: 89,
      averageEngagement: 7.2,
      topPerformingListing: 'Luxury Downtown Apartment',
      propertyTypePerformance: {
        'Apartment': 45,
        'House': 30,
        'Villa': 15,
        'Studio': 10,
      },
    ),
    'user_002': PerformanceSummary(
      userId: 'user_002',
      totalViews: 856,
      totalContactClicks: 67,
      averageEngagement: 7.8,
      topPerformingListing: 'Modern Family House',
      propertyTypePerformance: {
        'House': 50,
        'Apartment': 25,
        'Villa': 20,
        'Studio': 5,
      },
    ),
    'user_005': PerformanceSummary(
      userId: 'user_005',
      totalViews: 234,
      totalContactClicks: 23,
      averageEngagement: 9.8,
      topPerformingListing: 'Cozy Studio Apartment',
      propertyTypePerformance: {
        'Studio': 60,
        'Apartment': 30,
        'House': 10,
      },
    ),
  };

  /// Get listing views for a specific property
  Future<List<ListingViews>> getListingViews(String propertyId, {String? token}) async {
    if (EnvConfig.useMockData) {
      if (kDebugMode) {
        debugPrint('🎭 Using mock data for listing views (useMockData: true)');
      }
      await Future.delayed(const Duration(milliseconds: 500));
      return _mockListingViews[propertyId] ?? [];
    }

    try {
      if (kDebugMode) {
        debugPrint('🌐 Fetching listing views from API (useMockData: false)');
      }
      final response = await _apiClient.get('/analytics/listing-views/$propertyId', token: token);
      return (response['views'] as List)
          .map((json) => ListingViews.fromJson(json))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to fetch listing views from API, using mock data: $e');
      }
      return _mockListingViews[propertyId] ?? [];
    }
  }

  /// Get contact clicks for a specific property
  Future<List<ContactClicks>> getContactClicks(String propertyId, {String? token}) async {
    if (EnvConfig.useMockData) {
      if (kDebugMode) {
        debugPrint('🎭 Using mock data for contact clicks (useMockData: true)');
      }
      await Future.delayed(const Duration(milliseconds: 500));
      return _mockContactClicks[propertyId] ?? [];
    }

    try {
      if (kDebugMode) {
        debugPrint('🌐 Fetching contact clicks from API (useMockData: false)');
      }
      final response = await _apiClient.get('/analytics/contact-clicks/$propertyId', token: token);
      return (response['clicks'] as List)
          .map((json) => ContactClicks.fromJson(json))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to fetch contact clicks from API, using mock data: $e');
      }
      return _mockContactClicks[propertyId] ?? [];
    }
  }

  /// Get performance summary for a user
  Future<PerformanceSummary?> getPerformanceSummary(String userId, {String? token}) async {
    if (EnvConfig.useMockData) {
      if (kDebugMode) {
        debugPrint('🎭 Using mock data for performance summary (useMockData: true)');
      }
      await Future.delayed(const Duration(milliseconds: 800));
      return _mockPerformanceSummaries[userId];
    }

    try {
      if (kDebugMode) {
        debugPrint('🌐 Fetching performance summary from API (useMockData: false)');
      }
      final response = await _apiClient.get('/analytics/performance-summary/$userId', token: token);
      return PerformanceSummary.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to fetch performance summary from API, using mock data: $e');
      }
      return _mockPerformanceSummaries[userId];
    }
  }

  /// Get daily views data for charts (last 7 days)
  Future<List<Map<String, dynamic>>> getDailyViewsData(String userId, {String? token}) async {
    if (EnvConfig.useMockData) {
      if (kDebugMode) {
        debugPrint('🎭 Using mock data for daily views chart (useMockData: true)');
      }
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Generate mock daily views data
      final List<Map<String, dynamic>> dailyViews = [];
      for (int i = 6; i >= 0; i--) {
        final date = DateTime.now().subtract(Duration(days: i));
        final dayName = _getDayName(date.weekday);
        final views = 50 + (i * 10) + (date.day % 20); // Mock varying views
        
        dailyViews.add({
          'day': dayName,
          'views': views,
          'date': date,
        });
      }
      return dailyViews;
    }

    try {
      if (kDebugMode) {
        debugPrint('🌐 Fetching daily views chart data from API (useMockData: false)');
      }
      final response = await _apiClient.get('/analytics/daily-views/$userId', token: token);
      return List<Map<String, dynamic>>.from(response['dailyViews']);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to fetch daily views chart data from API, using mock data: $e');
      }
      return [];
    }
  }

  /// Get property type performance data for pie chart
  Future<List<Map<String, dynamic>>> getPropertyTypePerformanceData(String userId, {String? token}) async {
    if (EnvConfig.useMockData) {
      if (kDebugMode) {
        debugPrint('🎭 Using mock data for property type performance chart (useMockData: true)');
      }
      await Future.delayed(const Duration(milliseconds: 300));
      
      return [
        {'type': 'Apartment', 'count': 45, 'color': 0xFF4CAF50},
        {'type': 'House', 'count': 30, 'color': 0xFF2196F3},
        {'type': 'Villa', 'count': 15, 'color': 0xFFFF9800},
        {'type': 'Studio', 'count': 10, 'color': 0xFF9C27B0},
      ];
    }

    try {
      if (kDebugMode) {
        debugPrint('🌐 Fetching property type performance chart data from API (useMockData: false)');
      }
      final response = await _apiClient.get('/analytics/property-type-performance/$userId', token: token);
      return List<Map<String, dynamic>>.from(response['propertyTypes']);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to fetch property type performance chart data from API, using mock data: $e');
      }
      return [];
    }
  }

  /// Helper method to get day name
  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Mon';
      case 2: return 'Tue';
      case 3: return 'Wed';
      case 4: return 'Thu';
      case 5: return 'Fri';
      case 6: return 'Sat';
      case 7: return 'Sun';
      default: return 'Mon';
    }
  }
}
