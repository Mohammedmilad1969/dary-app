import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:dary/services/theme_service.dart';
import 'package:dary/services/property_service.dart' as property_service;
import 'package:dary/providers/auth_provider.dart';
import 'package:dary/services/language_service.dart';
import 'package:dary/widgets/property_card.dart';
import 'package:dary/widgets/property_search_filter.dart';
import 'package:dary/widgets/language_toggle_button.dart';
import 'package:dary/models/property.dart';
import 'package:dary/features/paywall/paywall_screens.dart';
import 'package:dary/widgets/home_chatbot.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Property> _filteredProperties = [];
  List<Property> _featuredProperties = [];
  String? _selectedFilterType;
  bool _isLoading = false;
  String _searchQuery = '';
  bool _filtersApplied = false; // Track if filters have been applied
  
  // Filter state preservation
  PropertyType? _filterType;
  PropertyStatus? _filterStatus;
  String? _filterCity;
  int? _filterBedrooms;
  int? _filterBathrooms;
  int? _filterKitchens;
  String _filterMinPrice = '';
  String _filterMaxPrice = '';
  String _filterMinSize = '';
  String _filterMaxSize = '';
  
  // Scroll controller for header animation
  late ScrollController _scrollController;
  double _scrollOffset = 0.0;
  bool _isHeaderVisible = true;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _searchController = TextEditingController();
    _loadProperties();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final currentOffset = _scrollController.offset;
    final delta = currentOffset - _scrollOffset;
    
    // Show header only when at the top (within 50px of top)
    final shouldShowHeader = currentOffset <= 50;
    
    if (shouldShowHeader != _isHeaderVisible) {
      setState(() {
        _isHeaderVisible = shouldShowHeader;
      });
    }
    
    _scrollOffset = currentOffset;
  }

  void _loadProperties({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
    });

    final propertyService = Provider.of<property_service.PropertyService>(context, listen: false);
    
    // Ensure properties are loaded from Firebase
    if (propertyService.properties.isEmpty) {
      await propertyService.initialize();
    }
    
    // Get all properties
    final allProperties = List<Property>.from(propertyService.properties);
    
    print('🏠 Loading properties: ${allProperties.length} total');
    for (int i = 0; i < allProperties.length && i < 3; i++) {
      print('🏠 Property ${i + 1}: ${allProperties[i].title} in ${allProperties[i].city}');
    }
    
    // Sort properties with actively boosted ones first
    allProperties.sort((a, b) {
      // Actively boosted properties first
      if (a.isBoostActive && !b.isBoostActive) return -1;
      if (!a.isBoostActive && b.isBoostActive) return 1;
      
      // Among actively boosted properties, sort by boost amount (300 > 100 > 20)
      if (a.isBoostActive && b.isBoostActive) {
        final aBoostAmount = a.boostAmount ?? 0.0;
        final bBoostAmount = b.boostAmount ?? 0.0;
        return bBoostAmount.compareTo(aBoostAmount);
      }
      
      // Among non-actively boosted properties, sort by creation date (newest first)
      return b.createdAt.compareTo(a.createdAt);
    });

    // Filter featured properties (actively boosted ones)
    _featuredProperties = allProperties.where((property) => property.isBoostActive).toList();
    
    // Apply current filter if any
    if (_selectedFilterType != null) {
      _filteredProperties = allProperties.where((property) {
        switch (_selectedFilterType) {
          case 'rent':
            return property.status == PropertyStatus.forRent;
          case 'sell':
            return property.status == PropertyStatus.forSale;
          case 'featured':
            return property.isBoostActive;
          case 'new':
            return DateTime.now().difference(property.createdAt).inDays <= 7;
          default:
            return true;
        }
      }).toList();
    } else {
      _filteredProperties = List<Property>.from(allProperties);
    }

    print('🏠 Final filtered properties: ${_filteredProperties.length}');
    print('🏠 Featured properties: ${_featuredProperties.length}');

    setState(() {
      _isLoading = false;
    });
  }

  void _onFilterChanged(List<Property> filteredProperties) {
    // Mark that filters have been applied
    _filtersApplied = true;
    
    // Apply the same priority sorting to properties from advanced filter
    final sortedProperties = List<Property>.from(filteredProperties);
    sortedProperties.sort((a, b) {
      // Both actively boosted - sort by boost amount (higher first)
      if (a.isBoostActive && b.isBoostActive) {
        final aBoost = a.boostAmount ?? 0.0;
        final bBoost = b.boostAmount ?? 0.0;
        return bBoost.compareTo(aBoost);
      }
      // Only a is actively boosted - a comes first
      if (a.isBoostActive && !b.isBoostActive) {
        return -1;
      }
      // Only b is actively boosted - b comes first
      if (!a.isBoostActive && b.isBoostActive) {
        return 1;
      }
      // Neither actively boosted - sort by creation date (newer first)
      return b.createdAt.compareTo(a.createdAt);
    });
    
    setState(() {
      _filteredProperties = sortedProperties;
      _featuredProperties = sortedProperties.where((p) => p.isBoostActive).toList();
    });
    
    print('🔧 Advanced filter applied: ${sortedProperties.length} properties');
    print('⭐ Boosted properties: ${_featuredProperties.length}');
    
    // Debug: Show detailed sorting info from advanced filter
    print('🔧 Advanced filter sorting debug:');
    for (int i = 0; i < sortedProperties.length && i < 10; i++) {
      final prop = sortedProperties[i];
      print('Position ${i + 1}: "${prop.title}" - Boosted: ${prop.isBoosted}, Amount: ${prop.boostAmount ?? 0.0} LYD');
    }
  }

  void _applySearchAndFilters() {
    print('🔍 _applySearchAndFilters called');
    final propertyService = Provider.of<property_service.PropertyService>(context, listen: false);
    final allProperties = List<Property>.from(propertyService.properties);
    
    // Apply search filter
    List<Property> filtered = allProperties;
    if (_searchQuery.isNotEmpty) {
      filtered = allProperties.where((property) {
        final query = _searchQuery.toLowerCase();
        return property.title.toLowerCase().contains(query) ||
               property.city.toLowerCase().contains(query) ||
               property.neighborhood.toLowerCase().contains(query) ||
               property.description.toLowerCase().contains(query);
      }).toList();
      
      // Mark that search/filters have been applied if search is active
      if (!_filtersApplied && _searchQuery.isNotEmpty) {
        _filtersApplied = true;
      }
    }
    
    // Apply Rent/Sell filter
    if (_selectedFilterType != null) {
      filtered = filtered.where((property) {
        if (_selectedFilterType == 'rent') {
          return property.status == PropertyStatus.forRent;
        } else if (_selectedFilterType == 'sell') {
          return property.status == PropertyStatus.forSale;
        }
        return true;
      }).toList();
    }
    
    // Sort by boost priority: 300 LYD > 100 LYD > 20 LYD > non-boosted
    filtered.sort((a, b) {
      // Both actively boosted - sort by boost amount (higher first)
      if (a.isBoostActive && b.isBoostActive) {
        final aBoost = a.boostAmount ?? 0.0;
        final bBoost = b.boostAmount ?? 0.0;
        return bBoost.compareTo(aBoost);
      }
      // Only a is actively boosted - a comes first
      if (a.isBoostActive && !b.isBoostActive) {
        return -1;
      }
      // Only b is actively boosted - b comes first
      if (!a.isBoostActive && b.isBoostActive) {
        return 1;
      }
      // Neither actively boosted - sort by creation date (newer first)
      return b.createdAt.compareTo(a.createdAt);
    });
    
    setState(() {
      _filteredProperties = filtered;
      _featuredProperties = filtered.where((p) => p.isBoostActive).toList();
    });
    
    print('🔍 Search query: "$_searchQuery"');
    print('🏠 Filtered properties: ${_filteredProperties.length}');
    print('⭐ Boosted properties: ${_featuredProperties.length}');
    
    // Debug: Show all boost amounts
    final boostedProps = filtered.where((p) => p.isBoostActive).toList();
    print('📊 Active boost amounts: ${boostedProps.map((p) => '${p.boostAmount} LYD').join(', ')}');
    
    // Debug: Show detailed sorting info
    print('🔍 Detailed sorting debug:');
    for (int i = 0; i < filtered.length && i < 10; i++) {
      final prop = filtered[i];
      print('Position ${i + 1}: "${prop.title}" - Boosted: ${prop.isBoosted}, Active: ${prop.isBoostActive}, Amount: ${prop.boostAmount ?? 0.0} LYD, Package: ${prop.boostPackageName}, Expires: ${prop.boostExpiresAt}');
    }
    
    // Debug: Show sorting comparison
    print('🔍 Sorting comparison debug:');
    for (int i = 0; i < filtered.length - 1 && i < 5; i++) {
      final a = filtered[i];
      final b = filtered[i + 1];
      final aBoost = a.boostAmount ?? 0.0;
      final bBoost = b.boostAmount ?? 0.0;
      
      String comparison = '';
      if (a.isBoostActive && b.isBoostActive) {
        comparison = 'Both actively boosted: ${aBoost} vs ${bBoost}';
      } else if (a.isBoostActive && !b.isBoostActive) {
        comparison = 'A actively boosted (${aBoost}) vs B not actively boosted';
      } else if (!a.isBoostActive && b.isBoostActive) {
        comparison = 'A not actively boosted vs B actively boosted (${bBoost})';
      } else {
        comparison = 'Both not actively boosted';
      }
      
      print('Compare ${i + 1} vs ${i + 2}: ${comparison}');
    }
  }

  void _filterByType(String type) {
    setState(() {
      _selectedFilterType = _selectedFilterType == type ? null : type;
    });
    _applySearchAndFilters();
  }

  bool _isFilteredByType(String type) {
    return _selectedFilterType == type;
  }

  void _clearAllFilters() {
    setState(() {
      _selectedFilterType = null;
      _searchQuery = '';
      _filtersApplied = false; // Reset the flag when clearing filters
    });
    _searchController.clear();
    _applySearchAndFilters();
  }

  void _showUpgradeModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PaywallScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageService = Provider.of<LanguageService>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Scrollable content
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Spacer to account for the overlay header
              SliverToBoxAdapter(
                child: SizedBox(height: MediaQuery.of(context).size.height * 0.5),
              ),
              
              // Main content
              SliverToBoxAdapter(
                child: Consumer<property_service.PropertyService>(
                  builder: (context, propertyService, child) {
                    // Update properties when PropertyService changes
                    // Don't reload if filters have been applied - user intentionally wants to see 0 results
                    if (propertyService.properties.isNotEmpty && _filteredProperties.isEmpty && !_filtersApplied) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _loadProperties(forceRefresh: true);
                      });
                    }
                    
                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Loading indicator
                          if (_isLoading) ...[
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                          
                          // Action Cards Section
                          Row(
                            children: [
                              Expanded(
                                child: _buildActionCard(
                                  icon: Icons.home,
                                  title: l10n?.rent ?? 'Rent',
                                  subtitle: 'Find rental properties',
                                  onTap: () => _filterByType('rent'),
                                  isActive: _isFilteredByType('rent'),
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildActionCard(
                                  icon: Icons.sell,
                                  title: l10n?.sell ?? 'Sell',
                                  subtitle: 'Find properties for sale',
                                  onTap: () => _filterByType('sell'),
                                  isActive: _isFilteredByType('sell'),
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          // Filter Status Indicator
                          if (_selectedFilterType != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.green.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.filter_list, color: Colors.green[700], size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Filtered by: ${_selectedFilterType!.toUpperCase()}',
                                    style: TextStyle(
                                      color: Colors.green[700],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: _clearAllFilters,
                                    child: Icon(Icons.close, color: Colors.green[700], size: 16),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          
                          const SizedBox(height: 24),
                          
                          // Search and Filter Section
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Column(
                              children: [
                                // Search Bar
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: TextField(
                                    controller: _searchController,
                                    style: const TextStyle(color: Colors.black87),
                                    decoration: InputDecoration(
                                      hintText: 'Search properties...',
                                      hintStyle: TextStyle(color: Colors.grey[500]),
                                      prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        _searchQuery = value;
                                      });
                                      _applySearchAndFilters();
                                    },
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Advanced Filter Button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (context) => PropertySearchFilter(
                                          onFilterChanged: _onFilterChanged,
                                          allProperties: Provider.of<property_service.PropertyService>(context, listen: false).properties,
                                          currentRentSellFilter: _selectedFilterType,
                                          onClearAllFilters: _clearAllFilters,
                                          onFilterValuesChanged: (values) {
                                            setState(() {
                                              _filterType = values['type'];
                                              _filterStatus = values['status'];
                                              _filterCity = values['city'];
                                              _filterBedrooms = values['bedrooms'];
                                              _filterBathrooms = values['bathrooms'];
                                              _filterKitchens = values['kitchens'];
                                              _filterMinPrice = values['minPrice'] ?? '';
                                              _filterMaxPrice = values['maxPrice'] ?? '';
                                              _filterMinSize = values['minSize'] ?? '';
                                              _filterMaxSize = values['maxSize'] ?? '';
                                            });
                                          },
                                          initialType: _filterType,
                                          initialStatus: _filterStatus,
                                          initialCity: _filterCity,
                                          initialBedrooms: _filterBedrooms,
                                          initialBathrooms: _filterBathrooms,
                                          initialKitchens: _filterKitchens,
                                          initialMinPrice: _filterMinPrice,
                                          initialMaxPrice: _filterMaxPrice,
                                          initialMinSize: _filterMinSize,
                                          initialMaxSize: _filterMaxSize,
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.filter_list, color: Colors.white),
                                    label: const Text(
                                      'Advanced Filters',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Quick Actions Section - Show for both authenticated and guest users
                          Row(
                            children: [
                              Expanded(
                                child: _buildQuickAccessButton(
                                  icon: Icons.upgrade,
                                  title: 'Upgrade Ad',
                                  subtitle: 'Boost your listing',
                                  onTap: () {
                                    if (authProvider.isAuthenticated) {
                                      _showUpgradeModal();
                                    } else {
                                      context.go('/login');
                                    }
                                  },
                                  color: Colors.amber,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              
              // Featured Properties Section
              if (_featuredProperties.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildSectionHeader(
                      title: l10n?.featuredProperties ?? 'Featured Properties',
                      icon: Icons.featured_play_list,
                      color: Colors.purple,
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: PropertyCard(
                          property: _featuredProperties[index],
                        ),
                      );
                    },
                    childCount: _featuredProperties.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
              
              // Regular Properties Section (non-featured)
              if (_filteredProperties.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildSectionHeader(
                      title: l10n?.allProperties ?? 'Regular Properties',
                      icon: Icons.home_work,
                      color: Colors.blue,
                    ),
                  ),
                ),
              // Show empty state if no properties
              if (_filteredProperties.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.home_outlined,
                          size: 100,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'No properties found',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your search or filters',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_filteredProperties.isNotEmpty)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      // Get non-featured properties to avoid duplication
                      final nonFeaturedProperties = _filteredProperties.where((property) => !property.isBoostActive).toList();
                      if (index >= nonFeaturedProperties.length) return null;
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: PropertyCard(
                          property: nonFeaturedProperties[index],
                        ),
                      );
                    },
                    childCount: _filteredProperties.where((property) => !property.isBoostActive).length,
                  ),
                ),
              
              // Extra space for bottom navigation
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          
          // Chatbot widget
          const HomeChatbot(),
          
          // Overlay header that slides up on scroll
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            top: _isHeaderVisible ? 0 : -MediaQuery.of(context).size.height * 0.5,
            left: 0,
            right: 0,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.green[800]!,
                    Colors.green[600]!,
                    Colors.green[500]!,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    children: [
                      // Top row with logo and actions
                      Row(
                        children: [
                          // Logo Section
                          Row(
                            children: [
                              // Logo Icon
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.home_work_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 15),
                              // Logo Text
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'DARY',
                                    style: ThemeService.getHeadingStyle(
                                      context,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ).copyWith(
                                      letterSpacing: 1.2,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.3),
                                          offset: const Offset(0, 2),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    'داري',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Spacer(),
                          // Action buttons with enhanced styling
                          Row(
                            children: [
                              if (authProvider.isAuthenticated) ...[
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.search, color: Colors.white),
                                    onPressed: () {
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (context) => PropertySearchFilter(
                                          onFilterChanged: _onFilterChanged,
                                          allProperties: Provider.of<property_service.PropertyService>(context, listen: false).properties,
                                          currentRentSellFilter: _selectedFilterType,
                                          onClearAllFilters: _clearAllFilters,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.logout, color: Colors.white),
                                  onPressed: () async {
                                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                                    if (!authProvider.isLoading) {
                                      print('🔐 Logout button pressed - starting logout process');
                                      try {
                                        await authProvider.logout();
                                        print('🔐 Logout button pressed - logout process completed');
                                        // Navigate to login page after logout
                                        if (context.mounted) {
                                          context.go('/login');
                                        }
                                      } catch (e) {
                                        print('🔐 Logout error: $e');
                                      }
                                    } else {
                                      print('🔐 Logout button pressed - already logging out, ignoring');
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              LanguageToggleButton(languageService: languageService),
                            ],
                          ),
                        ],
                      ),
                      const Spacer(), // Push content to center
                      
                      // Welcome Section in the center of the header
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            // Welcome Icon
                            Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Icon(
                                authProvider.isAuthenticated ? Icons.person : Icons.home,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    authProvider.isAuthenticated 
                                        ? 'Welcome back!' 
                                        : 'Find Your Dream Home',
                                    style: ThemeService.getHeadingStyle(
                                      context,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    authProvider.isAuthenticated
                                        ? 'Discover amazing properties'
                                        : 'Browse thousands of properties',
                                    style: ThemeService.getBodyStyle(
                                      context,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(), // Push content to center
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isActive,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? color : Colors.grey[200]!,
            width: isActive ? 2 : 1,
          ),
          boxShadow: isActive ? [
            BoxShadow(
              color: color.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isActive ? color : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isActive ? Colors.white : Colors.grey[600],
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: ThemeService.getHeadingStyle(
                context,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isActive ? color : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: ThemeService.getBodyStyle(
                context,
                color: Colors.grey[600],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
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
                    title,
                    style: ThemeService.getHeadingStyle(
                      context,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: ThemeService.getBodyStyle(
                      context,
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: ThemeService.getHeadingStyle(
            context,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () {
            // Navigate to view all properties
            context.go('/properties');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              'View All',
              style: ThemeService.getBodyStyle(
                context,
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}