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
}
