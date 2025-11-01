import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/auth_provider.dart';
import '../../services/analytics_service.dart';
import '../../services/language_service.dart';
import '../../widgets/language_toggle_button.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  bool _isLoading = true;
  
  List<Map<String, dynamic>> _dailyViewsData = [];
  List<Map<String, dynamic>> _propertyTypeData = [];
  PerformanceSummary? _performanceSummary;

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;
      
      if (currentUser != null) {
        // Load all analytics data in parallel
        final results = await Future.wait([
          _analyticsService.getDailyViewsData(currentUser.id),
          _analyticsService.getPropertyTypePerformanceData(currentUser.id),
          _analyticsService.getPerformanceSummary(currentUser.id),
        ]);

        setState(() {
          _dailyViewsData = results[0] as List<Map<String, dynamic>>;
          _propertyTypeData = results[1] as List<Map<String, dynamic>>;
          _performanceSummary = results[2] as PerformanceSummary?;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.errorLoadingAnalytics ?? 'Error loading analytics data'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageService = Provider.of<LanguageService>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n?.analytics ?? 'Analytics'),
          centerTitle: true,
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          actions: [
            LanguageToggleButton(languageService: languageService),
          ],
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.analytics ?? 'Analytics'),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalyticsData,
          ),
          LanguageToggleButton(languageService: languageService),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnalyticsData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Cards
                    _buildSummaryCards(l10n),
                    
                    const SizedBox(height: 24),
                    
                    // AI Assistant Bot
                    _buildAnalyticsAssistant(l10n),
                    
                    const SizedBox(height: 24),
                    
                    // Daily Views Chart
                    _buildDailyViewsChart(l10n),
                    
                    const SizedBox(height: 24),
                    
                    // Property Type Performance Chart
                    _buildPropertyTypeChart(l10n),
                    
                    const SizedBox(height: 24),
                    
                    // Performance Details
                    _buildPerformanceDetails(l10n),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCards(AppLocalizations? l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.performanceOverview ?? 'Performance Overview',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                title: l10n?.topPerformingListing ?? 'Top Performing Listing',
                value: _performanceSummary?.topPerformingListing ?? 'N/A',
                icon: Icons.star,
                color: Colors.amber,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                title: l10n?.averageEngagement ?? 'Average Engagement',
                value: '${_performanceSummary?.averageEngagement.toStringAsFixed(1) ?? '0.0'}%',
                icon: Icons.trending_up,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                title: l10n?.totalViews ?? 'Total Views',
                value: '${_performanceSummary?.totalViews ?? 0}',
                icon: Icons.visibility,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                title: l10n?.totalContacts ?? 'Total Contacts',
                value: '${_performanceSummary?.totalContactClicks ?? 0}',
                icon: Icons.phone,
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyViewsChart(AppLocalizations? l10n) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n?.dailyViews ?? 'Daily Views (Last 7 Days)',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _getMaxViews() * 1.2,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < _dailyViewsData.length) {
                            return Text(
                              _dailyViewsData[value.toInt()]['day'],
                              style: const TextStyle(fontSize: 12),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: _dailyViewsData.asMap().entries.map((entry) {
                    final index = entry.key;
                    final data = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: data['views'].toDouble(),
                          color: Colors.green,
                          width: 20,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyTypeChart(AppLocalizations? l10n) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n?.propertyTypePerformance ?? 'Property Type Performance',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: _propertyTypeData.map((data) {
                    return PieChartSectionData(
                      color: Color(data['color']),
                      value: data['count'].toDouble(),
                      title: '${data['type']}\n${data['count']}',
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Legend
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: _propertyTypeData.map((data) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Color(data['color']),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      data['type'],
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceDetails(AppLocalizations? l10n) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n?.detailedMetrics ?? 'Detailed Metrics',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_performanceSummary != null) ...[
              _buildMetricRow(
                l10n?.totalListings ?? 'Total Listings',
                '${_performanceSummary!.propertyTypePerformance.values.fold(0, (sum, count) => sum + count)}',
                Icons.home,
              ),
              _buildMetricRow(
                l10n?.averageViewsPerListing ?? 'Average Views per Listing',
                '${(_performanceSummary!.totalViews / _performanceSummary!.propertyTypePerformance.values.fold(0, (sum, count) => sum + count)).toStringAsFixed(1)}',
                Icons.visibility,
              ),
              _buildMetricRow(
                l10n?.contactConversionRate ?? 'Contact Conversion Rate',
                '${(_performanceSummary!.totalContactClicks / _performanceSummary!.totalViews * 100).toStringAsFixed(1)}%',
                Icons.phone,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  double _getMaxViews() {
    if (_dailyViewsData.isEmpty) return 100;
    return _dailyViewsData.map((data) => data['views'] as int).reduce((a, b) => a > b ? a : b).toDouble();
  }

  Widget _buildAnalyticsAssistant(AppLocalizations? l10n) {
    if (_performanceSummary == null) return const SizedBox.shrink();

    final insights = _analyzePerformance();
    
    return Card(
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue[50]!,
              Colors.green[50]!,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bot Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.smart_toy,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Analytics Assistant',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'AI-Powered Performance Insights',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              
              // Insights Messages
              ...insights.map((insight) => _buildInsightMessage(insight)).toList(),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _analyzePerformance() {
    final insights = <Map<String, dynamic>>[];
    
    if (_performanceSummary == null) return insights;
    
    final summary = _performanceSummary!;
    final totalListings = summary.propertyTypePerformance.values.fold(0, (sum, count) => sum + count);
    final avgViewsPerListing = totalListings > 0 ? summary.totalViews / totalListings : 0.0;
    final engagementRate = summary.averageEngagement;
    final contactRate = summary.totalViews > 0 
        ? (summary.totalContactClicks / summary.totalViews * 100) 
        : 0.0;

    // Analyze performance issues
    if (summary.totalViews == 0) {
      insights.add({
        'type': 'error',
        'title': 'No Views Detected',
        'message': 'Your properties have received no views. This might be because:\n'
            '• Properties are not published\n'
            '• Poor quality images or missing photos\n'
            '• Unclear or unappealing titles\n'
            '• Properties might be hidden or inactive',
        'suggestions': [
          'Check if all properties are published',
          'Add high-quality photos to all properties',
          'Write clear, descriptive titles',
          'Consider boosting your properties for visibility',
        ],
      });
    } else if (avgViewsPerListing < 10) {
      insights.add({
        'type': 'warning',
        'title': 'Low Visibility',
        'message': 'Your properties are getting very few views (average ${avgViewsPerListing.toStringAsFixed(1)} per listing).\n'
            'This suggests your listings need better optimization.',
        'suggestions': [
          'Improve property photos quality',
          'Write more detailed and appealing descriptions',
          'Add more photos (at least 5-10 per property)',
          'Consider using the boost feature to increase visibility',
          'Verify your pricing is competitive',
        ],
      });
    }

    if (engagementRate < 5.0 && summary.totalViews > 0) {
      insights.add({
        'type': 'warning',
        'title': 'Low Engagement Rate',
        'message': 'Your engagement rate is ${engagementRate.toStringAsFixed(1)}%, which is below average.\n'
            'This means people view your properties but don\'t take action.',
        'suggestions': [
          'Add more compelling property descriptions',
          'Include all amenities and features',
          'Verify contact information is correct',
          'Consider adjusting pricing to be more competitive',
          'Add property location details (neighborhood, nearby amenities)',
        ],
      });
    }

    if (contactRate < 2.0 && summary.totalViews > 0) {
      insights.add({
        'type': 'warning',
        'title': 'Very Low Contact Rate',
        'message': 'Only ${contactRate.toStringAsFixed(1)}% of viewers are contacting you.\n'
            'This suggests properties might be overpriced or lack important information.',
        'suggestions': [
          'Review and adjust pricing to market rates',
          'Add complete property information',
          'Highlight unique selling points',
          'Ensure contact phone number is visible',
          'Respond quickly to inquiries when they come',
        ],
      });
    }

    if (totalListings == 0) {
      insights.add({
        'type': 'info',
        'title': 'No Listings Yet',
        'message': 'You don\'t have any active listings. Start by adding your first property!',
        'suggestions': [
          'Click "Add Property" to create your first listing',
          'Add high-quality photos',
          'Fill in all property details completely',
          'Publish your property to make it visible',
        ],
      });
    } else if (totalListings == 1) {
      insights.add({
        'type': 'info',
        'title': 'Increase Your Exposure',
        'message': 'Having only one listing limits your visibility. Consider adding more properties.',
        'suggestions': [
          'Add more properties to increase your portfolio',
          'Each property increases your overall visibility',
          'Diversify property types and locations',
        ],
      });
    }

    // Success messages
    if (engagementRate >= 10.0 && summary.totalViews > 50) {
      insights.add({
        'type': 'success',
        'title': 'Great Engagement!',
        'message': 'Your engagement rate of ${engagementRate.toStringAsFixed(1)}% is excellent!\n'
            'Keep up the good work by maintaining quality listings.',
        'suggestions': [
          'Continue maintaining high-quality listings',
          'Keep property information updated',
          'Add new properties regularly',
        ],
      });
    }

    if (contactRate >= 5.0 && summary.totalContactClicks > 0) {
      insights.add({
        'type': 'success',
        'title': 'Good Contact Conversion',
        'message': 'Your contact rate of ${contactRate.toStringAsFixed(1)}% shows good conversion.\n'
            'Make sure to respond promptly to all inquiries.',
        'suggestions': [
          'Respond to inquiries within 24 hours',
          'Keep contact information up to date',
          'Be professional and helpful in communications',
        ],
      });
    }

    // If no specific issues, provide general tips
    if (insights.isEmpty && summary.totalViews > 0) {
      insights.add({
        'type': 'info',
        'title': 'Performance Tips',
        'message': 'Your properties are performing well! Here are some tips to improve further:',
        'suggestions': [
          'Update property photos regularly',
          'Keep descriptions fresh and detailed',
          'Monitor analytics weekly',
          'Consider boosting properties during peak times',
          'Gather and respond to user feedback',
        ],
      });
    }

    return insights;
  }

  Widget _buildInsightMessage(Map<String, dynamic> insight) {
    final type = insight['type'] as String;
    final title = insight['title'] as String;
    final message = insight['message'] as String;
    final suggestions = insight['suggestions'] as List<String>;

    Color borderColor;
    Color backgroundColor;
    IconData icon;

    switch (type) {
      case 'error':
        borderColor = Colors.red;
        backgroundColor = Colors.red[50]!;
        icon = Icons.error_outline;
        break;
      case 'warning':
        borderColor = Colors.orange;
        backgroundColor = Colors.orange[50]!;
        icon = Icons.warning;
        break;
      case 'success':
        borderColor = Colors.green;
        backgroundColor = Colors.green[50]!;
        icon = Icons.check_circle_outline;
        break;
      default:
        borderColor = Colors.blue;
        backgroundColor = Colors.blue[50]!;
        icon = Icons.info_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: borderColor, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: borderColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
          if (suggestions.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Suggestions:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            ...suggestions.map((suggestion) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: TextStyle(
                      fontSize: 14,
                      color: borderColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      suggestion,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ],
      ),
    );
  }
}
