import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/property.dart';
import '../models/user_profile.dart';
import '../models/wallet.dart' as wallet_models;
import '../providers/auth_provider.dart';
import '../services/property_service.dart' as property_service;
import '../services/analytics_service.dart';
import 'package:dary/services/theme_service.dart';

import '../screens/property_detail_screen.dart';
import '../features/paywall/paywall_screens.dart';
import '../widgets/dary_loading_indicator.dart';
import '../l10n/app_localizations.dart';

class RealEstateOfficeDashboard extends StatefulWidget {
  const RealEstateOfficeDashboard({super.key});

  @override
  State<RealEstateOfficeDashboard> createState() => _RealEstateOfficeDashboardState();
}

class _RealEstateOfficeDashboardState extends State<RealEstateOfficeDashboard> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AnalyticsService _analyticsService = AnalyticsService();
  UserProfile? _officeProfile;
  List<Property> _properties = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';
  String _selectedTimeRange = '7d'; // 7d, 30d, 90d, all
  
  // Analytics data
  List<Map<String, dynamic>> _dailyViewsData = [];
  List<Map<String, dynamic>> _propertyTypeData = [];
  List<Map<String, dynamic>> _propertyStatusData = [];
  PerformanceSummary? _performanceSummary;
  
  // Stats
  int _totalViews = 0;
  int _totalContactClicks = 0;
  int _phoneClicks = 0;
  int _whatsappClicks = 0;
  
  double _walletBalance = 0.0;
  int _activeListings = 0;
  int _soldListings = 0;
  int _rentedListings = 0;
  double _averageViewsPerProperty = 0.0;
  double _conversionRate = 0.0;
  List<Map<String, dynamic>> _topPerformers = [];
  
  // Wallet & Finance
  List<wallet_models.Transaction> _transactions = [];
  double _totalSpent = 0.0;
  double _totalRecharged = 0.0;
  double _boostSpending = 0.0;
  double _slotSpending = 0.0;
  int _activeBoosts = 0;
  List<Property> _boostedProperties = [];
  Map<String, Map<String, int>> _propertyMetrics = {};
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadDashboardData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id;
      
      if (userId == null) {
        if (mounted) context.go('/login');
        return;
      }

      // Load office profile
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        _officeProfile = UserProfile(
          id: userId,
          name: userData['name'] ?? '',
          email: userData['email'] ?? '',
          phone: userData['phone'],
          profileImageUrl: userData['profileImageUrl'],
          totalListings: userData['totalListings'] ?? 0,
          activeListings: userData['activeListings'] ?? 0,
          propertyLimit: userData['propertyLimit'] ?? 3,
          joinDate: (userData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          createdAt: (userData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          updatedAt: (userData['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          isVerified: userData['isVerified'] ?? false,
          isAdmin: userData['isAdmin'] ?? false,
          isRealEstateOffice: true,
        );
      }

      // Load properties
      final propertyService = property_service.PropertyService();
      final allProperties = await propertyService.getPropertiesByUser(userId);
      _properties = allProperties;

      // Load analytics data
      final results = await Future.wait([
        _analyticsService.getDailyViewsData(userId),
        _analyticsService.getPropertyTypePerformanceData(userId),
        _analyticsService.getPerformanceSummary(userId),
        _calculateContactClicks(userId),
        _loadWalletData(userId),
        _loadTransactions(userId),
        _loadBoostData(userId),
        _analyticsService.getClickBreakdown(userId),
        _analyticsService.getPropertySpecificMetrics(userId),
      ]);

      _dailyViewsData = results[0] as List<Map<String, dynamic>>;
      _propertyTypeData = results[1] as List<Map<String, dynamic>>;
      _performanceSummary = results[2] as PerformanceSummary?;
      _totalContactClicks = results[3] as int;
      _walletBalance = results[4] as double;
      _transactions = results[5] as List<wallet_models.Transaction>;
      _boostedProperties = results[6] as List<Property>;
      
      final clickBreakdown = results[7] as Map<String, int>;
      _phoneClicks = clickBreakdown['phone'] ?? 0;
      _whatsappClicks = clickBreakdown['whatsapp'] ?? 0;

      _propertyMetrics = results[8] as Map<String, Map<String, int>>;

      // Calculate comprehensive stats
      _calculateStats();
      _calculatePropertyStatusData();
      await _calculateTopPerformers();
      _calculateFinanceStats();
      
    } catch (e) {
      debugPrint('Error loading dashboard: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<int> _calculateContactClicks(String userId) async {
    int totalClicks = 0;
    for (final property in _properties) {
      try {
        final clicksQuery = await _firestore
            .collection('analytics')
            .doc('contact_clicks')
            .collection('clicks')
            .where('propertyId', isEqualTo: property.id)
            .get();
        totalClicks += clicksQuery.docs.length;
      } catch (e) {
        debugPrint('Error calculating contact clicks: $e');
      }
    }
    return totalClicks;
  }

  Future<double> _loadWalletData(String userId) async {
    try {
      final walletDoc = await _firestore.collection('wallet').doc(userId).get();
      if (walletDoc.exists) {
        return (walletDoc.data()?['balance'] ?? 0).toDouble();
      }
    } catch (e) {
      debugPrint('Error loading wallet: $e');
    }
    return 0.0;
  }

  Future<List<wallet_models.Transaction>> _loadTransactions(String userId) async {
    try {
      final transactionsSnapshot = await _firestore
          .collection('wallet')
          .doc(userId)
          .collection('transactions')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      
      return transactionsSnapshot.docs.map((doc) {
        final data = doc.data();
        return wallet_models.Transaction.fromFirestore(doc.id, data);
      }).toList();
    } catch (e) {
      debugPrint('Error loading transactions: $e');
      return [];
    }
  }

  Future<List<Property>> _loadBoostData(String userId) async {
    try {
      final now = Timestamp.now();
      final boostedPropertiesSnapshot = await _firestore
          .collection('properties')
          .where('userId', isEqualTo: userId)
          .where('isBoosted', isEqualTo: true)
          .where('boostExpiresAt', isGreaterThan: now)
          .get();
      
      return boostedPropertiesSnapshot.docs.map((doc) {
        final data = doc.data();
        return Property.fromFirestore(doc.id, data);
      }).toList();
    } catch (e) {
      debugPrint('Error loading boost data: $e');
      return [];
    }
  }

  void _calculateFinanceStats() {
    _totalSpent = 0.0;
    _totalRecharged = 0.0;
    _boostSpending = 0.0;
    _slotSpending = 0.0;
    
    for (final transaction in _transactions) {
      if (transaction.type == wallet_models.TransactionType.purchase) {
        _totalSpent += transaction.amount;
        // Check if it's a boost or slot purchase
        final description = transaction.description.toLowerCase();
        if (description.contains('boost') || description.contains('top listing')) {
          _boostSpending += transaction.amount;
        } else if (description.contains('package') || description.contains('slot')) {
          _slotSpending += transaction.amount;
        }
      } else if (transaction.type == wallet_models.TransactionType.recharge) {
        _totalRecharged += transaction.amount;
      }
    }
    
    _activeBoosts = _boostedProperties.length;
  }

  void _calculateStats() {
    _totalViews = _properties.fold(0, (sum, p) => sum + p.views);
    _activeListings = _properties.where((p) => 
      p.status == PropertyStatus.forSale || p.status == PropertyStatus.forRent
    ).length;
    _soldListings = _properties.where((p) => p.status == PropertyStatus.sold).length;
    _rentedListings = _properties.where((p) => p.status == PropertyStatus.rented).length;
    
    _averageViewsPerProperty = _properties.isNotEmpty 
        ? _totalViews / _properties.length 
        : 0.0;
    
    _conversionRate = _totalViews > 0 
        ? (_totalContactClicks / _totalViews * 100) 
        : 0.0;
  }

  void _calculatePropertyStatusData() {
    final statusCounts = <String, int>{
      'For Sale': 0,
      'For Rent': 0,
      'Sold': 0,
      'Rented': 0,
    };

    for (final property in _properties) {
      switch (property.status) {
        case PropertyStatus.forSale:
          statusCounts['For Sale'] = (statusCounts['For Sale'] ?? 0) + 1;
          break;
        case PropertyStatus.forRent:
          statusCounts['For Rent'] = (statusCounts['For Rent'] ?? 0) + 1;
          break;
        case PropertyStatus.sold:
          statusCounts['Sold'] = (statusCounts['Sold'] ?? 0) + 1;
          break;
        case PropertyStatus.rented:
          statusCounts['Rented'] = (statusCounts['Rented'] ?? 0) + 1;
          break;
      }
    }

    final colors = [0xFF4CAF50, 0xFF2196F3, 0xFFFF9800, 0xFF9C27B0];
    int colorIndex = 0;
    
    _propertyStatusData = statusCounts.entries
        .where((entry) => entry.value > 0)
        .map((entry) {
          final data = {
            'status': entry.key,
            'count': entry.value,
            'color': colors[colorIndex % colors.length],
          };
          colorIndex++;
          return data;
        })
        .toList();
  }

  Future<void> _calculateTopPerformers() async {
    final List<Map<String, dynamic>> performers = [];
    
    for (final property in _properties) {
      int contactClicks = 0;
      try {
        final clicksQuery = await _firestore
            .collection('analytics')
            .doc('contact_clicks')
            .collection('clicks')
            .where('propertyId', isEqualTo: property.id)
            .get();
        contactClicks = clicksQuery.docs.length;
      } catch (e) {
        debugPrint('Error calculating contact clicks for ${property.id}: $e');
      }
      
      performers.add({
        'property': property,
        'views': property.views,
        'contactClicks': contactClicks,
        'engagement': property.views > 0 ? (contactClicks / property.views * 100) : 0.0,
      });
    }
    
    performers.sort((a, b) {
      // Sort by views first, then by contact clicks
      final viewsCompare = (b['views'] as int).compareTo(a['views'] as int);
      if (viewsCompare != 0) return viewsCompare;
      return (b['contactClicks'] as int).compareTo(a['contactClicks'] as int);
    });
    
    _topPerformers = performers.take(5).toList();
  }

  List<Property> get _filteredProperties {
    switch (_selectedFilter) {
      case 'active':
        return _properties.where((p) => 
          p.status == PropertyStatus.forSale || p.status == PropertyStatus.forRent
        ).toList();
      case 'sold':
        return _properties.where((p) => p.status == PropertyStatus.sold).toList();
      case 'rented':
        return _properties.where((p) => p.status == PropertyStatus.rented).toList();
      case 'expired':
        return _properties.where((p) => p.isExpired).toList();
      default:
        return _properties;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F7FA),
        body: Center(
          child: DaryLoadingIndicator(
            color: Color(0xFF01352D),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        color: const Color(0xFF01352D),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderSection(),
              _buildStatsOverview(),
              _buildTimeRangeSelector(),
              _buildTabBar(),
              _buildTabContent(),
              const SizedBox(height: 100), // Space for bottom nav
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/add').then((_) => _loadDashboardData());
        },
        backgroundColor: const Color(0xFF01352D),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          AppLocalizations.of(context)?.addPropertyTitle ?? 'Add Property',
          style: ThemeService.getDynamicStyle(
            context,
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFF01352D),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/profile');
          }
        },
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.business_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Text(
            AppLocalizations.of(context)?.officeDashboard ?? 'Office Dashboard',
            style: ThemeService.getDynamicStyle(
              context,
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: _loadDashboardData,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF01352D),
            Color(0xFF015144),
          ],
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                backgroundImage: _officeProfile?.profileImageUrl != null &&
                        _officeProfile!.profileImageUrl!.isNotEmpty
                    ? NetworkImage(_officeProfile!.profileImageUrl!)
                    : null,
                child: _officeProfile?.profileImageUrl == null ||
                        _officeProfile!.profileImageUrl!.isEmpty
                    ? const Icon(Icons.business_rounded, color: Colors.white, size: 40)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _officeProfile?.name ?? (AppLocalizations.of(context)?.realEstateOffice ?? 'Real Estate Office'),
                      style: ThemeService.getDynamicStyle(
                        context,
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified_rounded, color: Colors.white, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                AppLocalizations.of(context)?.realEstateOffice ?? 'Real Estate Office',
                                style: ThemeService.getDynamicStyle(
                                  context,
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_officeProfile?.isVerified == true) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    Icons.layers_rounded,
                    AppLocalizations.of(context)?.propertyLimit ?? 'Property Limit',
                    AppLocalizations.of(context)?.packageCredits(_officeProfile?.propertyLimit ?? 3) ?? '${_officeProfile?.propertyLimit ?? 3} credits',
                  ),
                ),
                Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.3)),
                Expanded(
                  child: _buildInfoItem(
                    Icons.list_rounded,
                    AppLocalizations.of(context)?.totalListings ?? 'Total Listings',
                    '${_officeProfile?.totalListings ?? 0}',
                  ),
                ),
                Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.3)),
                Expanded(
                  child: _buildInfoItem(
                    Icons.check_circle_rounded,
                    AppLocalizations.of(context)?.active ?? 'Active',
                    '$_activeListings',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: ThemeService.getDynamicStyle(
            context,
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: ThemeService.getDynamicStyle(
            context,
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsOverview() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)?.overview ?? 'Overview',
            style: ThemeService.getDynamicStyle(
              context,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  AppLocalizations.of(context)?.totalViews ?? 'Total Views',
                  _totalViews.toString(),
                  Icons.visibility_rounded,
                  Colors.blue,
                  AppLocalizations.of(context)?.avgViews(_averageViewsPerProperty.toStringAsFixed(1)) ?? '${_averageViewsPerProperty.toStringAsFixed(1)} avg',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  AppLocalizations.of(context)?.contactClicks ?? 'Contact Clicks',
                  _totalContactClicks.toString(),
                  Icons.phone_rounded,
                  Colors.green,
                  AppLocalizations.of(context)?.ratePercentage(_conversionRate.toStringAsFixed(1)) ?? '${_conversionRate.toStringAsFixed(1)}% rate',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  AppLocalizations.of(context)?.phoneCalls ?? 'Phone Calls',
                  _phoneClicks.toString(),
                  Icons.phone_in_talk_rounded,
                  Colors.blue[700]!,
                  AppLocalizations.of(context)?.leadsPercentage(_totalContactClicks > 0 ? (_phoneClicks / _totalContactClicks * 100).toStringAsFixed(0) : '0') ?? '${_totalContactClicks > 0 ? (_phoneClicks / _totalContactClicks * 100).toStringAsFixed(0) : 0}% of leads',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  AppLocalizations.of(context)?.whatsapp ?? 'WhatsApp',
                  _whatsappClicks.toString(),
                  Icons.chat_bubble_rounded,
                  Colors.green[600]!,
                  AppLocalizations.of(context)?.leadsPercentage(_totalContactClicks > 0 ? (_whatsappClicks / _totalContactClicks * 100).toStringAsFixed(0) : '0') ?? '${_totalContactClicks > 0 ? (_whatsappClicks / _totalContactClicks * 100).toStringAsFixed(0) : 0}% of leads',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  AppLocalizations.of(context)?.walletBalance ?? 'Wallet Balance',
                  '${_walletBalance.toStringAsFixed(0)} LYD',
                  Icons.account_balance_wallet_rounded,
                  Colors.orange,
                  AppLocalizations.of(context)?.available ?? 'Available',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  AppLocalizations.of(context)?.soldRented ?? 'Sold/Rented',
                  '${_soldListings + _rentedListings}',
                  Icons.check_circle_rounded,
                  const Color(0xFF01352D),
                  AppLocalizations.of(context)?.transactionCompleted ?? 'Completed',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildQuickActionsRow(),
        ],
      ),
    );
  }

  Widget _buildQuickActionsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionButton(
            AppLocalizations.of(context)?.buyCredits ?? 'Buy Credits',
            Icons.layers_rounded,
            Colors.blue,
            () => _showCreditsModal(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildQuickActionButton(
            AppLocalizations.of(context)?.boost ?? 'Boost',
            Icons.rocket_launch_rounded,
            Colors.orange,
            () => _showBoostPropertiesModal(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildQuickActionButton(
            AppLocalizations.of(context)?.wallet ?? 'Wallet',
            Icons.account_balance_wallet_rounded,
            Colors.green,
            () => context.push('/wallet'),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: ThemeService.getDynamicStyle(
                context,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              Text(
                subtitle,
                style: ThemeService.getDynamicStyle(
                  context,
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: ThemeService.getDynamicStyle(
              context,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: ThemeService.getDynamicStyle(
              context,
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildTimeRangeChip('7d', AppLocalizations.of(context)?.daysCount(7) ?? '7 Days'),
          const SizedBox(width: 8),
          _buildTimeRangeChip('30d', AppLocalizations.of(context)?.daysCount(30) ?? '30 Days'),
          const SizedBox(width: 8),
          _buildTimeRangeChip('90d', AppLocalizations.of(context)?.daysCount(90) ?? '90 Days'),
          const SizedBox(width: 8),
          _buildTimeRangeChip('all', AppLocalizations.of(context)?.allTime ?? 'All Time'),
        ],
      ),
    );
  }

  Widget _buildTimeRangeChip(String value, String label) {
    final isSelected = _selectedTimeRange == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedTimeRange = value;
          _loadDashboardData();
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF01352D) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF01352D) : Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: ThemeService.getDynamicStyle(
                context,
                color: isSelected ? Colors.white : Colors.black87,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: const Color(0xFF01352D),
          borderRadius: BorderRadius.circular(16),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: ThemeService.getDynamicStyle(
          context,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
        tabs: [
          Tab(text: AppLocalizations.of(context)?.analytics ?? 'Analytics'),
          Tab(text: AppLocalizations.of(context)?.properties ?? 'Properties'),
          Tab(text: AppLocalizations.of(context)?.performance ?? 'Performance'),
          Tab(text: AppLocalizations.of(context)?.wallet ?? 'Wallet'),
          Tab(text: AppLocalizations.of(context)?.actions ?? 'Actions'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return SizedBox(
      height: MediaQuery.of(context).size.height - 400,
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildAnalyticsTab(),
          _buildPropertiesTab(),
          _buildPerformanceTab(),
          _buildWalletTab(),
          _buildQuickActionsTab(),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _buildDailyViewsChart(),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildPropertyTypeChart()),
              const SizedBox(width: 12),
              Expanded(child: _buildPropertyStatusChart()),
            ],
          ),
          const SizedBox(height: 20),
          _buildEngagementMetrics(),
        ],
      ),
    );
  }

  Widget _buildDailyViewsChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)?.viewsOverTime ?? 'Views Over Time',
            style: ThemeService.getDynamicStyle(
              context,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true, drawVerticalLine: false),
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
                            style: ThemeService.getDynamicStyle(context, fontSize: 10),
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
                          style: ThemeService.getDynamicStyle(context, fontSize: 10),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _dailyViewsData.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value['views'].toDouble());
                    }).toList(),
                    isCurved: true,
                    color: const Color(0xFF01352D),
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF01352D).withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyTypeChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)?.byType ?? 'By Type',
            style: ThemeService.getDynamicStyle(
              context,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: _propertyTypeData.isEmpty
                ? Center(
                    child: Text(
                      AppLocalizations.of(context)?.noData ?? 'No data',
                      style: ThemeService.getDynamicStyle(context, color: Colors.grey),
                    ),
                  )
                : PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: _propertyTypeData.map((data) {
                        return PieChartSectionData(
                          color: Color(data['color']),
                          value: data['count'].toDouble(),
                          title: '${data['count']}',
                          radius: 50,
                          titleStyle: ThemeService.getDynamicStyle(
                            context,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _propertyTypeData.map((data) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Color(data['color']),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _getLocalizedPropertyType(data['type']),
                    style: ThemeService.getDynamicStyle(context, fontSize: 10),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyStatusChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)?.byStatus ?? 'By Status',
            style: ThemeService.getDynamicStyle(
              context,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: _propertyStatusData.isEmpty
                ? Center(
                    child: Text(
                      AppLocalizations.of(context)?.noData ?? 'No data',
                      style: ThemeService.getDynamicStyle(context, color: Colors.grey),
                    ),
                  )
                : PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: _propertyStatusData.map((data) {
                        return PieChartSectionData(
                          color: Color(data['color']),
                          value: data['count'].toDouble(),
                          title: '${data['count']}',
                          radius: 50,
                          titleStyle: ThemeService.getDynamicStyle(
                            context,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _propertyStatusData.map((data) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Color(data['color']),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _getLocalizedStatus(data['status']),
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementMetrics() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)?.engagementMetrics ?? 'Engagement Metrics',
            style: ThemeService.getDynamicStyle(
              context,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildMetricRow(AppLocalizations.of(context)?.avgViewsPerProperty ?? 'Average Views per Property', _averageViewsPerProperty.toStringAsFixed(1), Icons.visibility_rounded),
          const Divider(),
          _buildMetricRow(AppLocalizations.of(context)?.conversionRate ?? 'Conversion Rate', '${_conversionRate.toStringAsFixed(2)}%', Icons.trending_up_rounded),
          const Divider(),
          _buildMetricRow(AppLocalizations.of(context)?.totalProperties ?? 'Total Properties', _properties.length.toString(), Icons.home_rounded),
          const Divider(),
          _buildMetricRow(AppLocalizations.of(context)?.activeListings ?? 'Active Listings', _activeListings.toString(), Icons.check_circle_rounded),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF01352D)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: ThemeService.getDynamicStyle(
                context,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
          Text(
            value,
            style: ThemeService.getDynamicStyle(
              context,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF01352D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertiesTab() {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilterSection(),
            const SizedBox(height: 20),
            if (_filteredProperties.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(Icons.inbox_rounded, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)?.noPropertiesFound ?? 'No properties found',
                        style: ThemeService.getDynamicStyle(
                          context,
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredProperties.length,
                itemBuilder: (context, index) {
                  final property = _filteredProperties[index];
                  return _buildDetailedPropertyCard(property);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Row(
      children: [
        Expanded(
          child: _buildFilterChip('all', AppLocalizations.of(context)?.all ?? 'All'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildFilterChip('active', AppLocalizations.of(context)?.active ?? 'Active'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildFilterChip('sold', AppLocalizations.of(context)?.sold ?? 'Sold'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildFilterChip('rented', AppLocalizations.of(context)?.rented ?? 'Rented'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildFilterChip('expired', AppLocalizations.of(context)?.expired ?? 'Expired'),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF01352D) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF01352D) : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: ThemeService.getDynamicStyle(
              context,
              color: isSelected ? Colors.white : Colors.black87,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPerformanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)?.topPerformingProperties ?? 'Top Performing Properties',
            style: ThemeService.getDynamicStyle(
              context,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          if (_topPerformers.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Text(
                  AppLocalizations.of(context)?.noPerformanceData ?? 'No performance data available',
                  style: ThemeService.getDynamicStyle(
                    context,
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            )
          else
            ..._topPerformers.asMap().entries.map((entry) {
              final index = entry.key;
              final data = entry.value;
              final property = data['property'] as Property;
              final views = data['views'] as int;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF01352D),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: ThemeService.getDynamicStyle(
                            context,
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            property.title,
                            style: ThemeService.getDynamicStyle(
                              context,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.visibility_rounded, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                AppLocalizations.of(context)?.viewsCount(views) ?? '$views views',
                                style: ThemeService.getDynamicStyle(
                                  context,
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PropertyDetailScreen(property: property),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildWalletTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _buildWalletOverview(),
          const SizedBox(height: 20),
          _buildSpendingAnalytics(),
          const SizedBox(height: 20),
          _buildTransactionHistory(),
        ],
      ),
    );
  }

  Widget _buildWalletOverview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF01352D),
            Color(0xFF015144),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)?.walletBalance ?? 'Wallet Balance',
            style: ThemeService.getDynamicStyle(
              context,
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_walletBalance.toStringAsFixed(0)} LYD',
            style: ThemeService.getDynamicStyle(
              context,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildWalletStat(
                  AppLocalizations.of(context)?.totalSpent ?? 'Total Spent',
                  '${_totalSpent.toStringAsFixed(0)} LYD',
                  Icons.arrow_downward_rounded,
                  Colors.red[300]!,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildWalletStat(
                  AppLocalizations.of(context)?.totalRecharged ?? 'Total Recharged',
                  '${_totalRecharged.toStringAsFixed(0)} LYD',
                  Icons.arrow_upward_rounded,
                  Colors.green[300]!,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.push('/wallet'),
            icon: const Icon(Icons.account_balance_wallet_rounded),
            label: Text(
              AppLocalizations.of(context)?.manageWallet ?? 'Manage Wallet',
              style: ThemeService.getDynamicStyle(
                context,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF01352D),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: ThemeService.getDynamicStyle(
              context,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: ThemeService.getDynamicStyle(
              context,
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingAnalytics() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)?.spendingBreakdown ?? 'Spending Breakdown',
            style: ThemeService.getDynamicStyle(
              context,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildSpendingRow(AppLocalizations.of(context)?.boostPackages ?? 'Boost Packages', _boostSpending, Icons.rocket_launch_rounded, Colors.orange),
          const Divider(),
          _buildSpendingRow(AppLocalizations.of(context)?.propertySlots ?? 'Property Slots', _slotSpending, Icons.layers_rounded, Colors.blue),
          const Divider(),
          _buildSpendingRow(AppLocalizations.of(context)?.activeBoosts ?? 'Active Boosts', _activeBoosts.toDouble(), Icons.star_rounded, Colors.amber),
        ],
      ),
    );
  }

  Widget _buildSpendingRow(String label, double value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: ThemeService.getDynamicStyle(
                context,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
          Text(
            label == (AppLocalizations.of(context)?.activeBoosts ?? 'Active Boosts') 
                ? '$_activeBoosts'
                : '${value.toStringAsFixed(0)} LYD',
            style: ThemeService.getDynamicStyle(
              context,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF01352D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionHistory() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)?.recentTransactions ?? 'Recent Transactions',
            style: ThemeService.getDynamicStyle(
              context,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          if (_transactions.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Text(
                  AppLocalizations.of(context)?.noTransactionsYet ?? 'No transactions yet',
                  style: ThemeService.getDynamicStyle(
                    context,
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            )
          else
            ..._transactions.take(10).map((transaction) {
              final isPurchase = transaction.type == wallet_models.TransactionType.purchase;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (isPurchase ? Colors.red : Colors.green).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isPurchase ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                        color: isPurchase ? Colors.red : Colors.green,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getLocalizedTransactionDescription(transaction.description),
                            style: ThemeService.getDynamicStyle(
                              context,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getLocalizedDate(transaction.createdAt),
                            style: ThemeService.getDynamicStyle(
                              context,
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${isPurchase ? '-' : '+'}${transaction.amount.toStringAsFixed(0)} LYD',
                      style: ThemeService.getDynamicStyle(
                        context,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isPurchase ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildQuickActionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            AppLocalizations.of(context)?.quickActions ?? 'Quick Actions',
            style: ThemeService.getDynamicStyle(
              context,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          _buildQuickActionCard(
            AppLocalizations.of(context)?.buyMoreSlots ?? 'Buy More Slots',
            'Increase your property listing limit',
            Icons.layers_rounded,
            Colors.blue,
            () => _showCreditsModal(),
          ),
          const SizedBox(height: 12),
          _buildQuickActionCard(
            AppLocalizations.of(context)?.boostProperties ?? 'Boost Properties',
            'Boost your properties for better visibility',
            Icons.rocket_launch_rounded,
            Colors.orange,
            () => _showBoostPropertiesModal(),
          ),
          const SizedBox(height: 12),
          _buildQuickActionCard(
            AppLocalizations.of(context)?.rechargeWallet ?? 'Recharge Wallet',
            'Add funds to your wallet',
            Icons.account_balance_wallet_rounded,
            Colors.green,
            () => context.push('/wallet'),
          ),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.of(context)?.activeBoosts ?? 'Active Boosts',
            style: ThemeService.getDynamicStyle(
              context,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          if (_boostedProperties.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.rocket_launch_outlined, size: 60, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)?.noActiveBoosts ?? 'No active boosts',
                      style: ThemeService.getDynamicStyle(
                        context,
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._boostedProperties.map((property) {
              final boostExpiresAt = property.boostExpiresAt;
              final isExpiring = boostExpiresAt != null &&
                  boostExpiresAt.difference(DateTime.now()).inHours < 24;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isExpiring ? Colors.orange : Colors.green,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.rocket_launch_rounded,
                        color: Colors.orange,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            property.title,
                            style: ThemeService.getDynamicStyle(
                              context,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            boostExpiresAt != null
                                ? '${AppLocalizations.of(context)?.expires ?? 'Expires'}: ${DateFormat('MMM dd, yyyy').format(boostExpiresAt)}'
                                : (AppLocalizations.of(context)?.boostActive ?? 'Boost active'),
                            style: ThemeService.getDynamicStyle(
                              context,
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isExpiring)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          AppLocalizations.of(context)?.expiring ?? 'Expiring',
                          style: ThemeService.getDynamicStyle(
                            context,
                            fontSize: 10,
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: ThemeService.getDynamicStyle(
                      context,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: ThemeService.getDynamicStyle(
                      context,
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }

  void _showCreditsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PaywallScreen(),
    ).then((_) => _loadDashboardData());
  }

  void _showBoostPropertiesModal() {
    // Navigate to a boost selection screen or show a modal
    // For now, navigate to paywall screen
    context.push('/paywall').then((_) => _loadDashboardData());
  }

  Widget _buildDetailedPropertyCard(Property property) {
    // Legacy metrics fallback (if needed, but property fields are preferred)
    final metrics = _propertyMetrics[property.id] ?? {};
    
    // Prefer data from property document (instant updates), fallback to analytics service
    final phoneClicks = property.phoneClicks > 0 ? property.phoneClicks : (metrics['phone'] ?? 0);
    final whatsappClicks = property.whatsappClicks > 0 ? property.whatsappClicks : (metrics['whatsapp'] ?? 0);
    final favorites = property.saveCount > 0 ? property.saveCount : (metrics['favorites'] ?? 0);
    
    final totalInteractions = phoneClicks + whatsappClicks;
    final engagementRate = property.views > 0 
        ? (totalInteractions / property.views * 100).toStringAsFixed(1) 
        : '0.0';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: property.isBoostActive 
            ? Border.all(color: const Color(0xFFFFD700), width: 2)
            : null,
      ),
      child: Column(
        children: [
          // Top section: Image and Basic Info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 100,
                    height: 80,
                    child: property.imageUrls.isNotEmpty
                        ? Image.network(
                            property.imageUrls.first,
                            fit: BoxFit.cover,
                          )
                        : Container(color: Colors.grey[200], child: const Icon(Icons.home)),
                  ),
                ),
                const SizedBox(width: 12),
                // Titles and Status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              property.title,
                              style: ThemeService.getDynamicStyle(
                                context,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _buildStatusBadge(property),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${NumberFormat('#,###').format(property.price)} LYD',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF01352D),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${AppLocalizations.of(context)?.listed ?? 'Listed'} ${_getTimeAgo(property.createdAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Stats Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCompactMetric(Icons.visibility_outlined, '${property.views}', AppLocalizations.of(context)?.all ?? 'Views'),
                _buildCompactMetric(Icons.phone_in_talk_outlined, '$phoneClicks', AppLocalizations.of(context)?.calls ?? 'Calls', color: Colors.blue),
                _buildCompactMetric(Icons.chat_bubble_outline, '$whatsappClicks', AppLocalizations.of(context)?.whatsapp ?? 'WhatsApp', color: Colors.green),
                _buildCompactMetric(Icons.favorite_border, '$favorites', AppLocalizations.of(context)?.propertySaved ?? 'Property Saved', color: Colors.red),
              ],
            ),
          ),
          
          // Bottom Actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)?.engagementRate(engagementRate) ?? 'Engagement Rate: $engagementRate%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                Row(
                  children: [
                    if (property.isExpired)
                      TextButton.icon(
                        onPressed: () async {
                          final authProvider = Provider.of<AuthProvider>(context, listen: false);
                          final currentUser = authProvider.currentUser;
                          if (currentUser != null && !currentUser.canAddProperty) {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => const PaywallScreen(),
                            );
                            return;
                          }

                          final proceed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              title: Text(AppLocalizations.of(context)?.renewPropertyConfirm ?? 'Renew Property?', style: const TextStyle(fontWeight: FontWeight.bold)),
                              content: Text(AppLocalizations.of(context)?.renewPropertyDescription ?? 'Renewing this property will deduct 1 posting point. Continue?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel', style: const TextStyle(color: Colors.grey)),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF01352D),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: Text(AppLocalizations.of(context)?.renew ?? 'Renew'),
                                ),
                              ],
                            ),
                          );

                          if (proceed != true) return;

                          final propertyService = Provider.of<property_service.PropertyService>(context, listen: false);
                          final success = await propertyService.renewProperty(property.id);
                          if (success) {
                            await authProvider.refreshUser();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(AppLocalizations.of(context)?.propertyUpdatedSuccessfully ?? 'Property renewed successfully!'), backgroundColor: const Color(0xFF01352D)),
                              );
                              _loadDashboardData();
                            }
                          }
                        },
                        icon: const Icon(Icons.refresh_rounded, size: 16, color: Colors.green),
                        label: Text(AppLocalizations.of(context)?.renew ?? 'Renew', style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(60, 30)),
                      )
                    else if (!property.isBoostActive)
                      TextButton.icon(
                        onPressed: () => _showBoostPropertiesModal(), 
                        icon: const Icon(Icons.rocket_launch, size: 16, color: Colors.orange),
                        label: Text(AppLocalizations.of(context)?.boost ?? 'Boost', style: const TextStyle(color: Colors.orange, fontSize: 12)),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(60, 30)),
                      ),
                    const SizedBox(width: 8),
                    IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.grey),
                        onPressed: () {
                          // Ideally navigate to edit, but for now placeholder
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edit feature coming soon')));
                        },
                        tooltip: 'Edit',
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactMetric(IconData icon, String value, String label, {Color? color}) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color ?? Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              value,
              style: ThemeService.getDynamicStyle(
                context,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color ?? Colors.black87,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(Property property) {
    Color color;
    String text;
    
    switch (property.status) {
      case PropertyStatus.forSale:
        color = Colors.blue;
        text = AppLocalizations.of(context)?.statusForSale ?? 'For Sale';
        break;
      case PropertyStatus.forRent:
        color = const Color(0xFF01352D);
        text = AppLocalizations.of(context)?.statusForRent ?? 'For Rent';
        break;
      case PropertyStatus.sold:
        color = Colors.red;
        text = AppLocalizations.of(context)?.statusSold ?? 'Sold';
        break;
      case PropertyStatus.rented:
        color = Colors.orange;
        text = AppLocalizations.of(context)?.statusRented ?? 'Rented';
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (property.isExpired) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
            ),
            child: Text(
              AppLocalizations.of(context)?.expired ?? 'Expired',
              style: ThemeService.getDynamicStyle(
                context,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  String _getTimeAgo(DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inDays > 0) return AppLocalizations.of(context)?.timeAgoDays(difference.inDays) ?? '${difference.inDays} days ago';
    if (difference.inHours > 0) return AppLocalizations.of(context)?.timeAgoHours(difference.inHours) ?? '${difference.inHours} hours ago';
    return AppLocalizations.of(context)?.now ?? 'Just now';
  }

  String _getLocalizedPropertyType(String type) {
    final l10n = AppLocalizations.of(context);
    switch (type.toLowerCase()) {
      case 'apartment': return l10n?.typeApartment ?? type;
      case 'house': return l10n?.typeHouse ?? type;
      case 'villa': return l10n?.typeVilla ?? type;
      case 'vacation home':
      case 'vacationhome': return l10n?.typeVacationHome ?? type;
      case 'townhouse': return l10n?.typeTownhouse ?? type;
      case 'studio': return l10n?.typeStudio ?? type;
      case 'penthouse': return l10n?.typePenthouse ?? type;
      case 'commercial': return l10n?.typeCommercial ?? type;
      case 'land': return l10n?.typeLand ?? type;
      default: return type;
    }
  }

  String _getLocalizedStatus(String status) {
    final l10n = AppLocalizations.of(context);
    switch (status) {
      case 'For Sale': return l10n?.statusForSale ?? status;
      case 'For Rent': return l10n?.statusForRent ?? status;
      case 'Sold': return l10n?.statusSold ?? status;
      case 'Rented': return l10n?.statusRented ?? status;
      default: return status;
    }
  }

  String _getLocalizedTransactionDescription(String description) {
    if (description.isEmpty) return description;
    final l10n = AppLocalizations.of(context);
    
    // 1. Recharged via Moamalat Card
    if (description == 'Recharged via Moamalat Card') {
      return l10n?.transactionRechargeMoamalat ?? description;
    }
    
    // 2. Purchase [Package] - Add [Count] property slots
    final purchaseRegex = RegExp(r'^Purchase (.*) - Add (\d+) property slots$');
    final purchaseMatch = purchaseRegex.firstMatch(description);
    if (purchaseMatch != null) {
      final packageName = purchaseMatch.group(1) ?? '';
      final slotsCount = purchaseMatch.group(2) ?? '';
      return l10n?.transactionPurchaseSlots(_getLocalizedPackageName(packageName), slotsCount) ?? description;
    }
    
    // 3. Top Listing Purchase - [Name]
    if (description.startsWith('Top Listing Purchase - ')) {
      final name = description.replaceFirst('Top Listing Purchase - ', '');
      return l10n?.transactionTopListing(_getLocalizedPackageName(name)) ?? description;
    }
    
    // 4. Boost New Listing: Plus
    if (description == 'Boost New Listing: Plus') {
      return l10n?.transactionBoostPlus ?? description;
    }
    
    // 5. Voucher Recharge
    if (description == 'Voucher Recharge') {
      return l10n?.transactionVoucherRecharge ?? description;
    }
    
    // 6. Admin Manual Credit
    if (description == 'Admin Manual Credit') {
      return l10n?.transactionAdminCredit ?? description;
    }
    
    // 7. Refund - [Reason]
    if (description.startsWith('Refund - ')) {
      final reason = description.replaceFirst('Refund - ', '');
      return l10n?.transactionRefund(reason) ?? description;
    }
    
    return description;
  }

  String _getLocalizedPackageName(String name) {
    if (name.isEmpty) return name;
    final l10n = AppLocalizations.of(context);
    final normalized = name.toLowerCase().trim();
    
    if (normalized == 'starter') return l10n?.packageStarter ?? name;
    if (normalized == 'professional') return l10n?.packageProfessional ?? name;
    if (normalized == 'enterprise') return l10n?.packageEnterprise ?? name;
    if (normalized == 'elite') return l10n?.packageElite ?? name;
    if (normalized == 'top listing') return l10n?.packageTopListing ?? name;
    
    // Handle durations in names
    if (normalized.contains('1 day')) return name.replaceFirst(RegExp('1 [Dd]ay', caseSensitive: false), l10n?.package1Day ?? '1 Day');
    if (normalized.contains('3 days')) return name.replaceFirst(RegExp('3 [Dd]ays', caseSensitive: false), l10n?.package3Days ?? '3 Days');
    if (normalized.contains('1 week')) return name.replaceFirst(RegExp('1 [Ww]eek', caseSensitive: false), l10n?.package1Week ?? '1 Week');
    if (normalized.contains('1 month')) return name.replaceFirst(RegExp('1 [Mm]onth', caseSensitive: false), l10n?.package1Month ?? '1 Month');
    if (normalized.contains('top listing')) return name.replaceFirst(RegExp('top listing', caseSensitive: false), l10n?.packageTopListing ?? 'Top Listing');

    return name;
  }

  String _getLocalizedDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final timeStr = DateFormat('hh:mm a', locale).format(date);

    if (difference.inDays == 0) {
      return l10n?.todayAt(timeStr) ?? 'Today $timeStr';
    } else if (difference.inDays == 1) {
      return l10n?.yesterdayAt(timeStr) ?? 'Yesterday $timeStr';
    } else if (difference.inDays < 7) {
      return l10n?.daysAgo(difference.inDays.toString()) ?? '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM dd, yyyy • hh:mm a', locale).format(date);
    }
  }
}
