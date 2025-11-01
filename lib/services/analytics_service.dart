import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/env_config.dart';
import '../services/api_client.dart';
import '../models/property.dart';
import '../services/property_service.dart';

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
    try {
      if (kDebugMode) {
        debugPrint('🔥 Fetching performance summary from Firebase (useMockData: false)');
      }
      
      // Get user's properties from Firebase
      final propertiesSnapshot = await FirebaseFirestore.instance
          .collection('properties')
          .where('userId', isEqualTo: userId)
          .get();
      
      if (propertiesSnapshot.docs.isEmpty) {
        return null;
      }
      
      // Calculate performance metrics
      num totalViews = 0;
      num totalContactClicks = 0;
      String topPerformingListing = '';
      int maxViews = 0;
      Map<String, int> propertyTypePerformance = {};
      final firestore = FirebaseFirestore.instance;
      
      for (final propertyDoc in propertiesSnapshot.docs) {
        final propertyData = propertyDoc.data();
        final propertyId = propertyDoc.id;
        final views = (propertyData['views'] ?? 0).toInt();
        final title = propertyData['title'] ?? 'Unknown';
        final type = propertyData['type'] ?? 'Unknown';
        
        // Get contact clicks from analytics collection (not from property document)
        int contactClicks = 0;
        try {
          final contactClicksQuery = await firestore
              .collection('analytics')
              .doc('contact_clicks')
              .collection('clicks')
              .where('propertyId', isEqualTo: propertyId)
              .get();
          
          contactClicks = contactClicksQuery.docs.length;
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ Error fetching contact clicks for property $propertyId: $e');
          }
        }
        
        totalViews += views;
        totalContactClicks += contactClicks;
        
        if (views > maxViews) {
          maxViews = views;
          topPerformingListing = title;
        }
        
        propertyTypePerformance[type] = (propertyTypePerformance[type] ?? 0) + 1;
      }
      
      final averageEngagement = totalViews > 0 ? (totalContactClicks / totalViews * 100) : 0.0;
      
      if (kDebugMode) {
        debugPrint('📊 Performance Summary:');
        debugPrint('   Total Views: $totalViews');
        debugPrint('   Total Contact Clicks: $totalContactClicks');
        debugPrint('   Average Engagement: ${averageEngagement.toStringAsFixed(2)}%');
      }
      
      return PerformanceSummary(
        userId: userId,
        totalViews: totalViews.toInt(),
        totalContactClicks: totalContactClicks.toInt(),
        averageEngagement: averageEngagement,
        topPerformingListing: topPerformingListing.isEmpty ? 'N/A' : topPerformingListing,
        propertyTypePerformance: propertyTypePerformance,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to fetch performance summary from Firebase, using mock data: $e');
      }
      return _mockPerformanceSummaries[userId];
    }
  }

  /// Get daily views data for charts (last 7 days)
  Future<List<Map<String, dynamic>>> getDailyViewsData(String userId, {String? token}) async {
    try {
      if (kDebugMode) {
        debugPrint('🔥 Fetching daily views data from Firebase (useMockData: false)');
      }
      
      // Get user's properties from Firebase
      final propertiesSnapshot = await FirebaseFirestore.instance
          .collection('properties')
          .where('userId', isEqualTo: userId)
          .get();
      
      // Generate daily views data based on property views
      final List<Map<String, dynamic>> dailyViews = [];
      final now = DateTime.now();
      
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dayName = _getDayName(date.weekday);
        
        // Calculate total views for this day (mock calculation based on property count)
        num totalViews = 0;
        for (final propertyDoc in propertiesSnapshot.docs) {
          final propertyData = propertyDoc.data();
          final views = (propertyData['views'] ?? 0).toInt();
          // Distribute views across days (mock distribution)
          totalViews += (views / 7).round() + (date.day % 5);
        }
        
        dailyViews.add({
          'day': dayName,
          'views': totalViews.toInt(),
          'date': date,
        });
      }
      
      return dailyViews;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to fetch daily views data from Firebase, using mock data: $e');
      }
      
      // Fallback to mock data
      final List<Map<String, dynamic>> dailyViews = [];
      for (int i = 6; i >= 0; i--) {
        final date = DateTime.now().subtract(Duration(days: i));
        final dayName = _getDayName(date.weekday);
        final views = 50 + (i * 10) + (date.day % 20);
        
        dailyViews.add({
          'day': dayName,
          'views': views,
          'date': date,
        });
      }
      return dailyViews;
    }
  }

  /// Get property type performance data for pie chart
  Future<List<Map<String, dynamic>>> getPropertyTypePerformanceData(String userId, {String? token}) async {
    try {
      if (kDebugMode) {
        debugPrint('🔥 Fetching property type performance data from Firebase (useMockData: false)');
      }
      
      // Get user's properties from Firebase
      final propertiesSnapshot = await FirebaseFirestore.instance
          .collection('properties')
          .where('userId', isEqualTo: userId)
          .get();
      
      // Count properties by type
      final Map<String, int> typeCounts = {};
      for (final propertyDoc in propertiesSnapshot.docs) {
        final propertyData = propertyDoc.data();
        final type = propertyData['type'] ?? 'Unknown';
        typeCounts[type] = (typeCounts[type] ?? 0) + 1;
      }
      
      // Convert to chart data format
      final List<Map<String, dynamic>> chartData = [];
      final colors = [0xFF4CAF50, 0xFF2196F3, 0xFFFF9800, 0xFF9C27B0, 0xFFF44336];
      int colorIndex = 0;
      
      typeCounts.forEach((type, count) {
        chartData.add({
          'type': type,
          'count': count,
          'color': colors[colorIndex % colors.length],
        });
        colorIndex++;
      });
      
      // If no properties, return mock data
      if (chartData.isEmpty) {
        return [
          {'type': 'Apartment', 'count': 45, 'color': 0xFF4CAF50},
          {'type': 'House', 'count': 30, 'color': 0xFF2196F3},
          {'type': 'Villa', 'count': 15, 'color': 0xFFFF9800},
          {'type': 'Studio', 'count': 10, 'color': 0xFF9C27B0},
        ];
      }
      
      return chartData;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to fetch property type performance data from Firebase, using mock data: $e');
      }
      
      // Fallback to mock data
      return [
        {'type': 'Apartment', 'count': 45, 'color': 0xFF4CAF50},
        {'type': 'House', 'count': 30, 'color': 0xFF2196F3},
        {'type': 'Villa', 'count': 15, 'color': 0xFFFF9800},
        {'type': 'Studio', 'count': 10, 'color': 0xFF9C27B0},
      ];
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
