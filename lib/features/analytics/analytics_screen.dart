import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../services/analytics_service.dart';
import '../../services/language_service.dart';
import '../../widgets/language_toggle_button.dart';
import '../../widgets/dary_loading_indicator.dart';

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
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: DaryLoadingIndicator(color: Color(0xFF01352D)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // Modern Gradient App Bar
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/profile');
                }
              },
            ),
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF01352D),
                    Color(0xFF024035),
                    Color(0xFF015F4D),
                  ],
                ),
              ),
              child: FlexibleSpaceBar(
                background: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      right: -50,
                      top: -50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -30,
                      bottom: -30,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    // Content
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.analytics_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n?.analytics ?? 'Analytics',
                                      style: GoogleFonts.poppins(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Track your property performance',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: Colors.white.withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                                onPressed: _loadAnalyticsData,
                              ),
                              LanguageToggleButton(languageService: languageService),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: DaryLoadingIndicator(color: Color(0xFF01352D)),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
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
                  
                  const SizedBox(height: 100), // Bottom padding
                ]),
              ),
            ),
        ],
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
                color: const Color(0xFF01352D),
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
                          color: const Color(0xFF01352D),
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
                (_performanceSummary!.totalViews / _performanceSummary!.propertyTypePerformance.values.fold(0, (sum, count) => sum + count)).toStringAsFixed(1),
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
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE6F4F2),
              Color(0xFFFFFFFF),
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
                          color: Colors.blue.withValues(alpha: 0.3),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)?.analyticsAssistant ?? 'Analytics Assistant',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          AppLocalizations.of(context)?.aiPoweredInsights ?? 'AI-Powered Performance Insights',
                          style: const TextStyle(
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
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return insights;
    
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
        'title': l10n.noViewsTitle,
        'message': l10n.noViewsMessage,
        'suggestions': [
          l10n.checkPublished,
          l10n.addHighQualityPhotos,
          l10n.writeClearTitles,
          l10n.considerBoosting,
        ],
      });
    } else if (avgViewsPerListing < 10) {
      insights.add({
        'type': 'warning',
        'title': l10n.lowVisibilityTitle,
        'message': l10n.lowVisibilityMessage(avgViewsPerListing.toStringAsFixed(1)),
        'suggestions': [
          l10n.improvePhotos,
          l10n.detailedDescriptions,
          l10n.addMorePhotos,
          l10n.considerBoosting,
          l10n.verifyPricing,
        ],
      });
    }

    if (engagementRate < 5.0 && summary.totalViews > 0) {
      insights.add({
        'type': 'warning',
        'title': l10n.lowEngagementTitle,
        'message': l10n.lowEngagementMessage(engagementRate.toStringAsFixed(1)),
        'suggestions': [
          l10n.compellingDescriptions,
          l10n.includeAmenities,
          l10n.verifyContactInfo,
          l10n.adjustPricing,
          l10n.addLocationDetails,
        ],
      });
    }

    if (contactRate < 2.0 && summary.totalViews > 0) {
      insights.add({
        'type': 'warning',
        'title': l10n.veryLowContactTitle,
        'message': l10n.veryLowContactMessage(contactRate.toStringAsFixed(1)),
        'suggestions': [
          l10n.reviewPricing,
          l10n.completeInfo,
          l10n.highlightPoints,
          l10n.visiblePhoneNumber,
          l10n.respondQuickly,
        ],
      });
    }

    if (totalListings == 0) {
      insights.add({
        'type': 'info',
        'title': l10n.noListingsTitle,
        'message': l10n.noListingsMessage,
        'suggestions': [
          l10n.addFirstProperty,
          l10n.addHighQualityPhotos,
          l10n.fillDetails,
          l10n.publishVisible,
        ],
      });
    } else if (totalListings == 1) {
      insights.add({
        'type': 'info',
        'title': l10n.increaseExposureTitle,
        'message': l10n.increaseExposureMessage,
        'suggestions': [
          l10n.addMoreProperties,
          l10n.eachPropertyVisibility,
          l10n.diversify,
        ],
      });
    }

    // Success messages
    if (engagementRate >= 10.0 && summary.totalViews > 50) {
      insights.add({
        'type': 'success',
        'title': l10n.greatEngagementTitle,
        'message': l10n.greatEngagementMessage(engagementRate.toStringAsFixed(1)),
        'suggestions': [
          l10n.maintainQuality,
          l10n.keepUpdated,
          l10n.addRegularly,
        ],
      });
    }

    if (contactRate >= 5.0 && summary.totalContactClicks > 0) {
      insights.add({
        'type': 'success',
        'title': l10n.goodContactTitle,
        'message': l10n.goodContactMessage(contactRate.toStringAsFixed(1)),
        'suggestions': [
          l10n.respond24h,
          l10n.keepContactUpdated,
          l10n.beProfessional,
        ],
      });
    }


    // If no specific issues, provide general tips
    if (insights.isEmpty && summary.totalViews > 0) {
      insights.add({
        'type': 'success',
        'title': l10n.doingGreatTitle,
        'message': l10n.doingGreatMessage,
        'suggestions': [
          l10n.keepDescriptionsFresh,
          l10n.monitorWeekly,
          l10n.boostPeakTimes,
          l10n.gatherFeedback,
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
        borderColor = const Color(0xFF01352D);
        backgroundColor = const Color(0xFF01352D).withValues(alpha: 0.06);
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
            Text(
              AppLocalizations.of(context)?.suggestions ?? 'Suggestions:',
              style: const TextStyle(
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
