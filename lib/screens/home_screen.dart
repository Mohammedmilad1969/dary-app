import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/property.dart';
import '../widgets/property_card.dart';
import '../widgets/property_search_filter.dart';
import '../services/language_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/language_toggle_button.dart';
import '../services/property_service.dart' as property_service;
import '../services/persistence_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Property> _filteredProperties = [];
  List<Property> _boostedProperties = [];
  List<Property> _featuredProperties = [];
  bool _isLoading = false;
  bool _isInitialized = false; // Track if we've initialized

  @override
  void initState() {
    super.initState();
    _initializePropertyService();
  }

  Future<void> _initializePropertyService() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final propertyService = Provider.of<property_service.PropertyService>(context, listen: false);
    final persistenceService = Provider.of<PersistenceService>(context, listen: false);
    
    // Initialize PropertyService to load all properties (no userId filter for home page)
    await propertyService.initialize(persistenceService: persistenceService);
    
    // Load properties after initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProperties(forceRefresh: true);
    });
  }

  void _loadProperties({bool forceRefresh = false}) {
    // Only update properties if we haven't initialized or if forced
    if (!_isInitialized || forceRefresh) {
      final propertyService = Provider.of<property_service.PropertyService>(context, listen: false);
      final allProperties = propertyService.properties;
      
      // Sort properties with boosted ones at the top
      final sortedProperties = List<Property>.from(allProperties);
      sortedProperties.sort((a, b) {
        // Boosted properties always come first
        if (a.isBoosted && !b.isBoosted) return -1;
        if (!a.isBoosted && b.isBoosted) return 1;
        
        // If both are boosted or both are not boosted, maintain original order
        return 0;
      });
      
      setState(() {
        _filteredProperties = sortedProperties;
        _boostedProperties = sortedProperties.where((p) => p.isBoosted).toList();
        _featuredProperties = sortedProperties.where((p) => p.isFeatured).toList();
        _isInitialized = true;
      });
    }
  }

  void _refreshProperties() {
    _loadProperties(forceRefresh: true);
  }

  void _onFilterChanged(List<Property> filteredProperties) {
    // Create a mutable copy and sort properties with boosted ones at the top
    final mutableList = List<Property>.from(filteredProperties);
    mutableList.sort((a, b) {
      // Boosted properties always come first
      if (a.isBoosted && !b.isBoosted) return -1;
      if (!a.isBoosted && b.isBoosted) return 1;
      
      // If both are boosted or both are not boosted, maintain original order
      return 0;
    });
    
    setState(() {
      _filteredProperties = mutableList;
      // Update boosted and featured properties to include only those matching the current filter
      _boostedProperties = mutableList.where((p) => p.isBoosted).toList();
      _featuredProperties = mutableList.where((p) => p.isFeatured).toList();
      // Don't reset radio button selection here - let _clearAllFilters handle it
    });
  }

  String? _selectedFilterType; // Track which filter is currently selected

  void _filterByType(String type) {
    // If clicking the same type again, clear the filter (show all)
    if (_selectedFilterType == type) {
      _selectedFilterType = null;
    } else {
      _selectedFilterType = type;
    }
    
    // Apply combined filters
    _applyCombinedFilters();
  }

  /// Apply combined filters: search filters + Rent/Sell filter
  void _applyCombinedFilters() {
    final propertyService = Provider.of<property_service.PropertyService>(context, listen: false);
    final allProperties = propertyService.properties;
    
    // Start with all properties
    List<Property> filtered = List<Property>.from(allProperties);
    
    // Apply Rent/Sell filter if active
    if (_selectedFilterType != null) {
      switch (_selectedFilterType!.toLowerCase()) {
        case 'rent':
          filtered = filtered.where((p) => p.status == PropertyStatus.forRent).toList();
          break;
        case 'sell':
          filtered = filtered.where((p) => p.status == PropertyStatus.forSale).toList();
          break;
      }
    }
    
    // Sort properties with boosted ones at the top
    filtered.sort((a, b) {
      // Boosted properties always come first
      if (a.isBoosted && !b.isBoosted) return -1;
      if (!a.isBoosted && b.isBoosted) return 1;
      
      // If both are boosted or both are not boosted, maintain original order
      return 0;
    });
    
    setState(() {
      _filteredProperties = filtered;
      // Update boosted and featured properties to include only those matching the current filter
      _boostedProperties = filtered.where((p) => p.isBoosted).toList();
      _featuredProperties = filtered.where((p) => p.isFeatured).toList();
    });
    
    // Trigger PropertySearchFilter to reapply its filters
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // This will cause the PropertySearchFilter to reapply its filters
      // with the current Rent/Sell filter applied
    });
  }

  bool _isFilteredByType(String type) {
    return _selectedFilterType == type.toLowerCase();
  }

  /// Clear all filters including Rent/Sell filter
  void _clearAllFilters() {
    final propertyService = Provider.of<property_service.PropertyService>(context, listen: false);
    final allProperties = propertyService.properties;
    
    // Create a mutable copy and sort properties with boosted ones at the top
    final sortedProperties = List<Property>.from(allProperties);
    sortedProperties.sort((a, b) {
      // Boosted properties always come first
      if (a.isBoosted && !b.isBoosted) return -1;
      if (!a.isBoosted && b.isBoosted) return 1;
      
      // If both are boosted or both are not boosted, maintain original order
      return 0;
    });
    
    setState(() {
      _selectedFilterType = null;
      _filteredProperties = sortedProperties;
      _boostedProperties = sortedProperties.where((p) => p.isBoosted).toList();
      _featuredProperties = sortedProperties.where((p) => p.isFeatured).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageService = Provider.of<LanguageService>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: Column(
        children: [
          // Enhanced App Bar with gradient and logo
          Container(
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
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  spreadRadius: 2,
                  blurRadius: 15,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
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
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
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
                              onPressed: () async {
                                try {
                                  await authProvider.logout();
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(l10n?.logoutSuccess ?? 'Logged out successfully'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Logout failed: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.logout_rounded, color: Colors.white),
                              tooltip: 'Logout',
                            ),
                          ),
                          const SizedBox(width: 8),
                        ] else ...[
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
                              onPressed: () => context.go('/login'),
                              icon: const Icon(Icons.login_rounded, color: Colors.white),
                              tooltip: 'Login',
                            ),
                          ),
                          const SizedBox(width: 8),
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
                          child: LanguageToggleButton(languageService: languageService),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        Expanded(
          child: Consumer<property_service.PropertyService>(
            builder: (context, propertyService, child) {
              // Update properties when PropertyService changes
              if (propertyService.properties.isNotEmpty) {
                // Only refresh if the properties have actually changed
                final currentPropertyIds = propertyService.properties.map((p) => p.id).toSet();
                final currentFilteredIds = _filteredProperties.map((p) => p.id).toSet();
                
                if (!currentPropertyIds.containsAll(currentFilteredIds) || 
                    !currentFilteredIds.containsAll(currentPropertyIds)) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _loadProperties(forceRefresh: true);
                  });
                }
              }
              
              return SingleChildScrollView(
                child: Column(
                  children: [
                    // Welcome Section
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.grey[850]!,
                            Colors.grey[800]!,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            spreadRadius: 1,
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.home_work_outlined,
                                  color: Colors.green[400],
                                  size: 28,
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
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[100],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      authProvider.isAuthenticated
                                          ? 'Discover amazing properties'
                                          : 'Browse thousands of properties',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Search and Filter Section
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      child: PropertySearchFilter(
                        onFilterChanged: _onFilterChanged,
                        allProperties: propertyService.properties,
                        onCombinedFilter: _applyCombinedFilters,
                        currentRentSellFilter: _selectedFilterType,
                        onClearAllFilters: _clearAllFilters,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                
                // Buy/Rent Cards Section
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Text(
                        'What are you looking for?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[100],
                        ),
                      ),
                      const SizedBox(height: 16),
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
                              Icon(
                                Icons.filter_list,
                                size: 16,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _selectedFilterType == 'rent' 
                                    ? 'Showing ${_filteredProperties.length} rental properties'
                                    : 'Showing ${_filteredProperties.length} sale properties',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedFilterType = null;
                                    _filteredProperties = Provider.of<property_service.PropertyService>(context, listen: false).properties;
                                  });
                                },
                                child: Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Featured Properties Section
                if (_featuredProperties.isNotEmpty) ...[
                  _buildSectionHeader(
                    title: l10n?.featuredProperties ?? 'Featured Properties',
                    icon: Icons.featured_play_list,
                    color: Colors.purple,
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: _featuredProperties.length,
                      itemBuilder: (context, index) {
                        final property = _featuredProperties[index];
                        return PropertyCard(property: property);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // All Properties Section (with boosted properties at top)
                _buildSectionHeader(
                  title: '${l10n?.allProperties ?? 'All Properties'} ${_boostedProperties.isNotEmpty ? '(Boosted at top)' : ''}',
                  icon: Icons.home_work,
                  color: Colors.indigo,
                ),
                
                // Properties List
                if (_filteredProperties.isEmpty)
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          spreadRadius: 1,
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            l10n?.noPropertiesFound ?? 'No properties found',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[200],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n?.tryAdjustingFilters ?? 'Try adjusting your search filters',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[400],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _selectedFilterType = null;
                                _filteredProperties = Provider.of<property_service.PropertyService>(context, listen: false).properties;
                              });
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Show All Properties'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
          else
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.85, // Adjusted to prevent overflow
                ),
                itemCount: _filteredProperties.length,
                itemBuilder: (context, index) {
                  final property = _filteredProperties[index];
                  return PropertyCard(property: property);
                },
              ),
            ),
                
                const SizedBox(height: 16),
              ],
            ),
          );
            },
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
    bool isActive = false,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 160, // Increased height to accommodate ACTIVE badge
        decoration: BoxDecoration(
          gradient: isActive 
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withOpacity(0.2),
                    color.withOpacity(0.1),
                  ],
                )
              : null,
          color: isActive ? null : Colors.grey[850],
          borderRadius: BorderRadius.circular(20),
          border: isActive 
              ? Border.all(color: color, width: 2) 
              : Border.all(color: Colors.grey.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: isActive 
                  ? color.withOpacity(0.3) 
                  : Colors.black.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12), // Reduced padding
              decoration: BoxDecoration(
                color: isActive 
                    ? color.withOpacity(0.2) 
                    : color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                size: 28, // Slightly smaller icon
                color: isActive ? color : color.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8), // Reduced spacing
            Text(
              title,
              style: TextStyle(
                fontSize: 15, // Slightly smaller font
                fontWeight: FontWeight.bold,
                color: isActive ? color : Colors.grey[200],
              ),
            ),
            const SizedBox(height: 2), // Reduced spacing
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11, // Slightly smaller font
                color: Colors.grey[400],
              ),
              textAlign: TextAlign.center,
            ),
            if (isActive) ...[
              const SizedBox(height: 6), // Reduced spacing
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3), // Reduced padding
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10), // Smaller radius
                ),
                child: const Text(
                  'ACTIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9, // Smaller font
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              // Show all properties and reset filters
              setState(() {
                _filteredProperties = PropertyService.getSortedProperties();
              });
            },
            style: TextButton.styleFrom(
              backgroundColor: color.withOpacity(0.2),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              'View All',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
