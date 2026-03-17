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
import '../widgets/dary_loading_indicator.dart';
import 'package:dary/models/property.dart';
import 'package:dary/features/paywall/paywall_screens.dart';
import 'package:dary/widgets/home_chatbot.dart';

import '../l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/city_localizer.dart';
import '../utils/text_input_formatters.dart';
import '../utils/app_animations.dart';
import '../services/notification_service.dart';
import '../widgets/notification_popup.dart';

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
  
  // New dropdown filter states for price and size
  int? _selectedMinPrice;
  int? _selectedMaxPrice;
  int? _selectedMinSize;
  int? _selectedMaxSize;
  
  // Additional filter states
  String? _filterNeighborhood;
  PropertyCondition? _filterCondition;
  int? _filterFloors;
  bool _filterFeaturedOnly = false;
  
  // Feature filters
  bool _filterHasParking = false;
  bool _filterHasPool = false;
  bool _filterHasGarden = false;
  bool _filterHasElevator = false;
  bool _filterHasFurnished = false;
  bool _filterHasAC = false;
  
  // Price options for dropdown
  static const List<int> _priceOptions = [
    50000,
    100000,
    150000,
    200000,
    300000,
    500000,
    750000,
    1000000,
    1500000,
    2000000,
    3000000,
    5000000,
  ];
  
  // Size options for dropdown (in sqm)
  static const List<int> _sizeOptions = [
    50,
    75,
    100,
    150,
    200,
    250,
    300,
    400,
    500,
    750,
    1000,
  ];
  
  // Floors options
  static const List<int> _floorsOptions = [1, 2, 3, 4, 5];
  
  // Sorting state
  bool? _priceSortAscending; // null = no sort, false = descending (high to low), true = ascending (low to high)
  bool? _dateSortAscending; // null = no sort, false = descending (latest first), true = ascending (oldest first)
  
  // Grid view state
  bool _isGridView = false; // false = 1 column (list), true = 2 columns (grid)
  
  // Scroll controller for header animation
  late ScrollController _scrollController;
  final double _scrollOffset = 0.0;
  final bool _isHeaderVisible = true;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _searchController = TextEditingController();
    _loadProperties();
    _checkExpiringProperties();
  }

  Future<void> _checkExpiringProperties() async {
    // Wait for auth to be ready
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isAuthenticated && authProvider.currentUser != null) {
      final notificationService = Provider.of<NotificationService>(context, listen: false);
      final expiring = await notificationService.checkExpiringProperties(authProvider.currentUser!.id);
      
      if (expiring.isNotEmpty && mounted) {
        _showExpiryAlert(expiring);
      }
    }
  }

  void _showExpiryAlert(List<Property> expiring) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n?.listingsExpiringSoon ?? 'Listings Expiring Soon!',
                style: ThemeService.getDynamicStyle(context, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n?.listingsExpiryWarning ??
                  'The following properties are about to expire. Please renew them to keep them visible to public.',
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 16),
            ...expiring.take(3).map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.home_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      p.title,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )),
            if (expiring.length > 3)
              Text(
                l10n?.andMoreCount(expiring.length - 3) ?? '...and ${expiring.length - 3} more',
                style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n?.later ?? 'Later', style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => _renewAllExpiring(ctx, expiring),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF01352D),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(l10n?.renewAll(expiring.length) ?? 'Renew All (${expiring.length})'),
          ),
        ],
      ),
    );
  }

  Future<void> _renewAllExpiring(BuildContext dialogCtx, List<Property> expiring) async {
    final l10n = AppLocalizations.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;
    if (userId == null) return;

    // Check current points
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final currentPoints = (userDoc.data()?['postingCredits'] as num?)?.toInt() ?? 0;
    final needed = expiring.length;

    if (currentPoints < needed) {
      if (dialogCtx.mounted) Navigator.pop(dialogCtx);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.notEnoughPointsToRenew(currentPoints, needed) ??
                  'Not enough points. You have $currentPoints pts but need $needed pts.',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            action: SnackBarAction(
              label: l10n?.buyPoints ?? 'Buy Points',
              textColor: Colors.white,
              onPressed: () => context.go('/paywall'),
            ),
          ),
        );
      }
      return;
    }

    if (dialogCtx.mounted) Navigator.pop(dialogCtx);

    final propertyService = Provider.of<property_service.PropertyService>(context, listen: false);
    int renewedCount = 0;
    for (final property in expiring) {
      final success = await propertyService.renewProperty(property.id);
      if (success) renewedCount++;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.renewedSuccessfully(renewedCount) ?? '$renewedCount properties renewed successfully!',
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      _loadProperties();
    }
  }

  void _showNotificationsPopup(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    
    // Position it below the notification button
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.2),
      builder: (context) {
        final mediaQuery = MediaQuery.of(context);
        final isSmallScreen = mediaQuery.size.width < 600;
        
        return Stack(
          children: [
            Positioned(
              top: 70,
              right: isSmallScreen ? (mediaQuery.size.width * 0.05) : 20,
              left: isSmallScreen ? (mediaQuery.size.width * 0.05) : null,
              child: Material(
                color: Colors.transparent,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isSmallScreen ? mediaQuery.size.width * 0.9 : 380,
                  ),
                  child: const NotificationPopup(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeaderBadgeButton({
    required IconData icon,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white, size: 22),
            onPressed: onTap,
          ),
        ),
        if (badgeCount > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                badgeCount > 9 ? '9+' : '$badgeCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Header is now always visible and fixed at top - no scroll animation needed
    // Keep this method for potential future use but don't hide/show header
  }

  void _loadProperties({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
    });

    final propertyService = Provider.of<property_service.PropertyService>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Ensure properties are loaded from Firebase
    if (propertyService.properties.isEmpty || forceRefresh) {
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
      
      // Apply sorting based on selected sort type
      if (_priceSortAscending != null) {
        // Price sorting - extract numeric price value
        double aPrice = a.status == PropertyStatus.forRent
            ? (a.monthlyRent > 0 ? a.monthlyRent : (a.dailyRent > 0 ? a.dailyRent * 30 : 0))
            : a.price;
        double bPrice = b.status == PropertyStatus.forRent
            ? (b.monthlyRent > 0 ? b.monthlyRent : (b.dailyRent > 0 ? b.dailyRent * 30 : 0))
            : b.price;
        return _priceSortAscending! ? aPrice.compareTo(bPrice) : bPrice.compareTo(aPrice);
      } else if (_dateSortAscending != null) {
        // Date sorting
        return _dateSortAscending! ? a.createdAt.compareTo(b.createdAt) : b.createdAt.compareTo(a.createdAt);
      }
      
      // Default: Among non-actively boosted properties, sort by creation date (newest first)
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



    if (!mounted) return;
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
      // Neither actively boosted - apply sorting based on selected sort type
      if (_priceSortAscending != null) {
        // Price sorting - extract numeric price value
        double aPrice = a.status == PropertyStatus.forRent
            ? (a.monthlyRent > 0 ? a.monthlyRent : (a.dailyRent > 0 ? a.dailyRent * 30 : 0))
            : a.price;
        double bPrice = b.status == PropertyStatus.forRent
            ? (b.monthlyRent > 0 ? b.monthlyRent : (b.dailyRent > 0 ? b.dailyRent * 30 : 0))
            : b.price;
        return _priceSortAscending! ? aPrice.compareTo(bPrice) : bPrice.compareTo(aPrice);
      } else if (_dateSortAscending != null) {
        // Date sorting
        return _dateSortAscending! ? a.createdAt.compareTo(b.createdAt) : b.createdAt.compareTo(a.createdAt);
      }
      // Default: Neither actively boosted - sort by creation date (newer first)
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
    List<Property> filtered = allProperties.where((p) => p.isPublished && !p.isEffectivelyExpired).toList();
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((property) {
        final query = _searchQuery.toLowerCase();
        return property.id.toLowerCase().contains(query) ||
               property.title.toLowerCase().contains(query) ||
               property.city.toLowerCase().contains(query) ||
               property.neighborhood.toLowerCase().contains(query) ||
               property.description.toLowerCase().contains(query) ||
               property.agentName.toLowerCase().contains(query);
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
      // Neither actively boosted - apply sorting based on selected sort type
      if (_priceSortAscending != null) {
        // Price sorting - extract numeric price value
        double aPrice = a.status == PropertyStatus.forRent
            ? (a.monthlyRent > 0 ? a.monthlyRent : (a.dailyRent > 0 ? a.dailyRent * 30 : 0))
            : a.price;
        double bPrice = b.status == PropertyStatus.forRent
            ? (b.monthlyRent > 0 ? b.monthlyRent : (b.dailyRent > 0 ? b.dailyRent * 30 : 0))
            : b.price;
        return _priceSortAscending! ? aPrice.compareTo(bPrice) : bPrice.compareTo(aPrice);
      } else if (_dateSortAscending != null) {
        // Date sorting
        return _dateSortAscending! ? a.createdAt.compareTo(b.createdAt) : b.createdAt.compareTo(a.createdAt);
      }
      // Default: Neither actively boosted - sort by creation date (newer first)
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
        comparison = 'Both actively boosted: $aBoost vs $bBoost';
      } else if (a.isBoostActive && !b.isBoostActive) {
        comparison = 'A actively boosted ($aBoost) vs B not actively boosted';
      } else if (!a.isBoostActive && b.isBoostActive) {
        comparison = 'A not actively boosted vs B actively boosted ($bBoost)';
      } else {
        comparison = 'Both not actively boosted';
      }
      
      print('Compare ${i + 1} vs ${i + 2}: $comparison');
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
      _priceSortAscending = null; // Clear price sort
      _dateSortAscending = null; // Clear date sort
      
      // Clear advanced filters too
      _filterCity = null;
      _filterType = null;
      _filterStatus = null;
      _filterBedrooms = null;
      _filterBathrooms = null;
      _filterKitchens = null;
      _filterNeighborhood = null;
      _filterCondition = null;
      _filterFloors = null;
      _selectedMinPrice = null;
      _selectedMaxPrice = null;
      _selectedMinSize = null;
      _selectedMaxSize = null;
      _filterHasParking = false;
      _filterHasPool = false;
      _filterHasGarden = false;
      _filterHasElevator = false;
      _filterHasFurnished = false;
      _filterHasAC = false;
      _filterFeaturedOnly = false;
    });
    _searchController.clear();
    _applySearchAndFilters();
  }

  
  // Build featured properties list (1 column) or grid (2 columns) with improved spacing
  Widget _buildFeaturedPropertiesList(List<Property> properties) {
    if (properties.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    
    if (_isGridView) {
      // 2-column grid view with better spacing
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.53,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index >= properties.length) return null;
              
              return StaggeredAnimation(
                index: index,
                child: PropertyCard(
                  property: properties[index],
                ),
              );
            },
            childCount: properties.length,
          ),
        ),
      );
    } else {
      // 1-column list view with improved spacing
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index >= properties.length) return null;
            
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: StaggeredAnimation(
                index: index,
                child: PropertyCard(
                  property: properties[index],
                ),
              ),
            );
          },
          childCount: properties.length,
        ),
      );
    }
  }

  // Build properties list (1 column) or grid (2 columns) with improved spacing
  Widget _buildPropertiesList(List<Property> properties) {
    final nonFeaturedProperties = properties.where((property) => !property.isBoostActive).toList();
    
    if (_isGridView) {
      // 2-column grid view with better spacing
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.53,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index >= nonFeaturedProperties.length) return null;
              
              return StaggeredAnimation(
                index: index,
                child: PropertyCard(
                  property: nonFeaturedProperties[index],
                ),
              );
            },
            childCount: nonFeaturedProperties.length,
          ),
        ),
      );
    } else {
      // 1-column list view with improved spacing
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index >= nonFeaturedProperties.length) return null;
            
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: StaggeredAnimation(
                index: index,
                child: PropertyCard(
                  property: nonFeaturedProperties[index],
                ),
              ),
            );
          },
          childCount: nonFeaturedProperties.length,
        ),
      );
    }
  }
  
  // Build sort button with premium modern design
  Widget _buildSortButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return ScaleAnimation(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF01352D),
                    const Color(0xFF01352D).withValues(alpha: 0.85),
                  ],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Colors.grey[50]!,
                  ],
                ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive 
                ? const Color(0xFF01352D).withValues(alpha: 0.3)
                : Colors.grey[300]!,
            width: isActive ? 2 : 1.5,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF01352D).withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: const Color(0xFF01352D).withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isActive 
                    ? Colors.white.withValues(alpha: 0.2)
                    : const Color(0xFF01352D).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
              child: Icon(
                icon,
                key: ValueKey(isActive),
                  color: isActive ? Colors.white : const Color(0xFF01352D),
                  size: 18,
              ),
            ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: ThemeService.getDynamicStyle(
                context,
                color: isActive ? Colors.white : Colors.grey[700],
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                fontSize: 15,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Build sort button (old version kept for reference but not used)
  Widget _buildSortButtonOld({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF01352D).withValues(alpha: 0.05) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? const Color(0xFF01352D) : Colors.grey[300]!,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? const Color(0xFF01352D) : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive ? const Color(0xFF01352D) : Colors.grey[700],
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Build grid view toggle button with premium modern design
  Widget _buildGridViewButton({
    required bool isGridView,
    required VoidCallback onTap,
  }) {
    return ScaleAnimation(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isGridView
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF01352D),
                    const Color(0xFF01352D).withValues(alpha: 0.85),
                  ],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Colors.grey[50]!,
                  ],
                ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isGridView 
                ? const Color(0xFF01352D).withValues(alpha: 0.3)
                : Colors.grey[300]!,
            width: isGridView ? 2 : 1.5,
          ),
          boxShadow: isGridView
              ? [
                  BoxShadow(
                    color: const Color(0xFF01352D).withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: const Color(0xFF01352D).withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isGridView 
                ? Colors.white.withValues(alpha: 0.2)
                : const Color(0xFF01352D).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
        ),
        child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
          child: Icon(
              isGridView ? Icons.view_module_rounded : Icons.view_list_rounded,
            key: ValueKey(isGridView),
              color: isGridView ? Colors.white : const Color(0xFF01352D),
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  void _showUpgradeModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PaywallScreen(),
    );
  }


  List<Property> _processProperties(List<Property> source) {
    // Only published and non-expired properties
    var filtered = source.where((p) => p.isPublished && !p.isEffectivelyExpired).toList();
    
    // Type filter
    if (_selectedFilterType != null) {
      filtered = filtered.where((property) {
        if (_selectedFilterType == 'rent') return property.status == PropertyStatus.forRent;
        if (_selectedFilterType == 'sell') return property.status == PropertyStatus.forSale;
        if (_selectedFilterType == 'featured') return property.isBoostActive;
        if (_selectedFilterType == 'new') return DateTime.now().difference(property.createdAt).inDays <= 7;
        return true;
      }).toList();
    }
    
    // Sort
    filtered.sort((a, b) {
      if (a.isBoostActive && b.isBoostActive) {
        return (b.boostAmount ?? 0).compareTo(a.boostAmount ?? 0);
      }
      if (a.isBoostActive) return -1;
      if (b.isBoostActive) return 1;
      
      if (_priceSortAscending != null) {
        double aPrice = a.status == PropertyStatus.forRent
            ? (a.monthlyRent > 0 ? a.monthlyRent : (a.dailyRent > 0 ? a.dailyRent * 30 : 0))
            : a.price;
        double bPrice = b.status == PropertyStatus.forRent
            ? (b.monthlyRent > 0 ? b.monthlyRent : (b.dailyRent > 0 ? b.dailyRent * 30 : 0))
            : b.price;
        return _priceSortAscending! ? aPrice.compareTo(bPrice) : bPrice.compareTo(aPrice);
      } else if (_dateSortAscending != null) {
        return _dateSortAscending! ? a.createdAt.compareTo(b.createdAt) : b.createdAt.compareTo(a.createdAt);
      }
      return b.createdAt.compareTo(a.createdAt);
    });
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageService = Provider.of<LanguageService>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final propertyService = Provider.of<property_service.PropertyService>(context);
    
    List<Property> displayProperties;
    List<Property> displayFeatured;
    
    if (_filtersApplied) {
       displayProperties = _filteredProperties;
       displayFeatured = _featuredProperties;
    } else {
       displayProperties = _processProperties(propertyService.properties);
       displayFeatured = displayProperties.where((p) => p.isBoostActive).toList();
    }
    
    final headerHeight = MediaQuery.of(context).size.height * 0.5;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Scrollable content - header image scrolls with content
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header image - scrolls normally (first element in scroll view)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: headerHeight,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Background hero image - scrolls with content
                        Image.asset(
                          'assets/images/home_intro.jpg',
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                        ),
                        // Dark gradient overlay
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black54,
                                Colors.black26,
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        // Header content (logo, actions, welcome text)
                        SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Top row with logo and actions
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Logo
                                    Image.asset(
                                      'assets/images/dary_logo.png',
                                      height: 40,
                                      width: 40,
                                      fit: BoxFit.contain,
                                    ),
                                    const Spacer(),
                                    // Action buttons
                                    Row(
                                      children: [
                                        if (authProvider.isAuthenticated) ...[
                                          Consumer<NotificationService>(
                                            builder: (context, notificationService, _) {
                                              return _buildHeaderBadgeButton(
                                                icon: Icons.notifications_rounded,
                                                onTap: () => _showNotificationsPopup(context),
                                                badgeCount: notificationService.unreadCount,
                                              );
                                            },
                                          ),
                                          const SizedBox(width: 12),
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.white.withValues(alpha: 0.3),
                                                width: 1,
                                              ),
                                            ),
                                            child: IconButton(
                                              icon: const Icon(Icons.search, color: Colors.white),
                                              onPressed: _openPropertyFilter,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                        ],
                                        if (!authProvider.isAuthenticated) ...[
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.white.withValues(alpha: 0.3),
                                                width: 1,
                                              ),
                                            ),
                                            child: IconButton(
                                              icon: const Icon(Icons.login_rounded, color: Colors.white),
                                              onPressed: () => context.go('/login'),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                        ],
                                        LanguageToggleButton(languageService: languageService),
                                      ],
                                    ),
                                  ],
                                ),
                                // Stats row at bottom
                                Align(
                                  alignment: Alignment.bottomLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 20),
                                    child: Row(
                                      children: [
                                        _buildHeroStat(
                                          label: l10n?.activeListingsLabel ?? 'Active listings',
                                          value: '${displayProperties.length}',
                                        ),
                                        const SizedBox(width: 16),
                                        _buildHeroStat(
                                          label: l10n?.featuredProperties ?? 'Featured Properties',
                                          value: '${displayFeatured.length}',
                                        ),
                                      ],
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
              
              // Main content - Upgrade Ads first
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
                    
                    return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Loading indicator with animation
                          if (_isLoading) ...[
                          const Padding(
                            padding: EdgeInsets.all(20),
                            child: FadeInAnimation(
                              duration: Duration(milliseconds: 300),
                              child: Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: DaryLoadingIndicator(
                                    strokeWidth: 3,
                                    color: Color(0xFF01352D),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          ],
                          
                          // Upgrade Ad and Property Limit Buttons Row - MOVED TO TOP
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                          child: IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: _buildQuickAccessButton(
                                        icon: Icons.auto_graph_rounded,
                                        title: l10n?.upgradeAd ?? 'Upgrade Ad',
                                        subtitle: l10n?.boostYourAd ?? 'Boost visibility',
                                        color: const Color(0xFF01352D),
                                        onTap: () {
                                          if (authProvider.isAuthenticated) {
                                            context.push('/boost');
                                          } else {
                                            context.go('/login');
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildQuickAccessButton(
                                        icon: Icons.add_to_photos_rounded,
                                        title: l10n?.moreCredits ?? 'More Credits',
                                        subtitle: l10n?.buyMoreCredits ?? 'Buy credit packages',
                                        color: const Color(0xFF015F4D),
                                        onTap: () {
                                          if (authProvider.isAuthenticated) {
                                            context.push('/paywall');
                                          } else {
                                            context.go('/login');
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              
              // Filter Bar - scrolls with content (after header image)
              SliverToBoxAdapter(
                child: _buildFixedFilterBar(context, l10n),
              ),
              
              // Featured Properties Section
              if (displayFeatured.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: _buildSectionHeader(
                      title: l10n?.featuredProperties ?? 'Featured Properties',
                      icon: Icons.star_rounded,
                      color: Colors.amber[700]!,
                    ),
                  ),
                ),
                _buildFeaturedPropertiesList(displayFeatured),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
              
              // Regular Properties Section (non-featured)
              if (displayProperties.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: _buildSectionHeader(
                      title: l10n?.allProperties ?? 'All Properties',
                      icon: Icons.home_work_rounded,
                      color: const Color(0xFF01352D),
                    ),
                  ),
                ),
                _buildPropertiesList(displayProperties),
              ],
              // Show empty state if no properties with enhanced styling
              if (displayProperties.isEmpty)
                SliverToBoxAdapter(
                        child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
                    padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.grey[50]!,
                          Colors.white,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.grey[200]!, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                          ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                          padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                            color: const Color(0xFF01352D).withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                                ),
                                child: Icon(
                            Icons.search_off_rounded,
                            size: 64,
                            color: const Color(0xFF01352D).withValues(alpha: 0.6),
                                ),
                              ),
                        const SizedBox(height: 24),
                                    Text(
                                    l10n?.noPropertiesFound ?? 'No properties found',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    l10n?.tryAdjustingFilters ?? 'Try adjusting your search or filters\nto find what you\'re looking for',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.grey[600],
                                      height: 1.5,
                                    ),
                                  ),
                                  ],
                                ),
                              ),
                ),

              
              // Extra space for bottom navigation
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
                    ],
                  ),
          
          
          // Filter Button (floating next to Chatbot)
          Positioned(
            bottom: 20,
            right: 90, // To the left of the chatbot (20 + 56 + 14 spacing)
            child: Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _openPropertyFilter,
                  borderRadius: BorderRadius.circular(28),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.tune_rounded,
                        color: Color(0xFF01352D),
                        size: 24,
                      ),
                      if (_hasActiveFilters())
                        Positioned(
                          top: 14,
                          right: 14,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.amber,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Chatbot widget
          const HomeChatbot(),
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
    return ScaleAnimation(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: 0.15),
                    color.withValues(alpha: 0.08),
                  ],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.grey[50]!,
                    Colors.white,
                  ],
                ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? color.withValues(alpha: 0.4) : Colors.grey[200]!,
            width: isActive ? 2.5 : 1.5,
          ),
          boxShadow: isActive
              ? [
            BoxShadow(
                    color: color.withValues(alpha: 0.25),
                    spreadRadius: 0,
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: color.withValues(alpha: 0.1),
                    spreadRadius: 0,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    spreadRadius: 0,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
                ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: isActive
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color,
                          color.withValues(alpha: 0.85),
                        ],
                      )
                    : null,
                color: isActive ? null : Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  icon,
                  key: ValueKey(isActive),
                  color: isActive ? Colors.white : Colors.grey[600],
                  size: 28,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: ThemeService.getHeadingStyle(
                context,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isActive ? color : Colors.grey[800],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: ThemeService.getBodyStyle(
                context,
                color: isActive ? Colors.grey[700] : Colors.grey[600],
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Format price for display
  String _formatPrice(int price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(price % 1000000 == 0 ? 0 : 1)}M LYD';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K LYD';
    }
    return '$price LYD';
  }

  // Save filter values from PropertySearchFilter
  void _onFilterValuesChanged(Map<String, dynamic> filterValues) {
    print('💾 Saving filter values: $filterValues');
    setState(() {
      _searchQuery = filterValues['searchText'] ?? '';
      _filterType = filterValues['type'];
      _filterStatus = filterValues['status'];
      _filterCity = filterValues['city'];
      _filterNeighborhood = filterValues['neighborhood'];
      _filterBedrooms = filterValues['bedrooms'];
      _filterBathrooms = filterValues['bathrooms'];
      _filterKitchens = filterValues['kitchens'];
      
      // Handle formatted type (remove commas if any)
      final minPrice = (filterValues['minPrice'] ?? '').toString().replaceAll(',', '');
      final maxPrice = (filterValues['maxPrice'] ?? '').toString().replaceAll(',', '');
      _selectedMinPrice = minPrice.isNotEmpty ? int.tryParse(minPrice) : null;
      _selectedMaxPrice = maxPrice.isNotEmpty ? int.tryParse(maxPrice) : null;
      
      // Update size values
      final minSize = (filterValues['minSize'] ?? '').toString().replaceAll(',', '');
      final maxSize = (filterValues['maxSize'] ?? '').toString().replaceAll(',', '');
      _selectedMinSize = minSize.isNotEmpty ? int.tryParse(minSize) : null;
      _selectedMaxSize = maxSize.isNotEmpty ? int.tryParse(maxSize) : null;
      
      _filterFeaturedOnly = filterValues['featuredOnly'] ?? false;
      _filterHasParking = filterValues['hasParking'] ?? false;
      _filterHasPool = filterValues['hasPool'] ?? false;
      _filterHasGarden = filterValues['hasGarden'] ?? false;
      _filterHasElevator = filterValues['hasElevator'] ?? false;
      _filterHasFurnished = filterValues['hasFurnished'] ?? false;
      _filterHasAC = filterValues['hasAC'] ?? false;
    });
    print('💾 Filter values saved - City: $_filterCity, Status: $_filterStatus, Type: $_filterType');
  }


  void _openPropertyFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: PropertySearchFilter(
          onFilterChanged: _onFilterChanged,
          allProperties: Provider.of<property_service.PropertyService>(context, listen: false).properties,
          currentRentSellFilter: _selectedFilterType,
          onClearAllFilters: _clearAllFilters,
          onFilterValuesChanged: _onFilterValuesChanged,
          // Pass current filter values for state preservation
          initialSearchText: _searchQuery,
          initialCity: _filterCity,
          initialType: _filterType,
          initialStatus: _filterStatus,
          initialBedrooms: _filterBedrooms,
          initialBathrooms: _filterBathrooms,
          initialKitchens: _filterKitchens,
          initialMinPrice: _selectedMinPrice?.toString(),
          initialMaxPrice: _selectedMaxPrice?.toString(),
          initialMinSize: _selectedMinSize?.toString(),
          initialMaxSize: _selectedMaxSize?.toString(),
          initialNeighborhood: _filterNeighborhood,
          initialFeaturedOnly: _filterFeaturedOnly,
          initialHasParking: _filterHasParking,
          initialHasPool: _filterHasPool,
          initialHasGarden: _filterHasGarden,
          initialHasElevator: _filterHasElevator,
          initialHasFurnished: _filterHasFurnished,
          initialHasAC: _filterHasAC,
        ),
      ),
    );
  }

  // Check if any advanced filters are active
  bool _hasActiveFilters() {

    return _filterCity != null ||
        _filterNeighborhood != null ||
        _filterType != null ||
        _filterCondition != null ||
        _filterBedrooms != null ||
        _filterBathrooms != null ||
        _filterKitchens != null ||
        _filterFloors != null ||
        _selectedMinPrice != null ||
        _selectedMaxPrice != null ||
        _selectedMinSize != null ||
        _selectedMaxSize != null ||
        _filterHasParking ||
        _filterHasPool ||
        _filterHasGarden ||
        _filterHasElevator ||
        _filterHasFurnished ||
        _filterHasAC ||
        _filterFeaturedOnly;
  }

  // Clear all advanced filters
  void _clearAdvancedFilters() {
    setState(() {
      _filterCity = null;
      _filterNeighborhood = null;
      _filterType = null;
      _filterCondition = null;
      _filterBedrooms = null;
      _filterBathrooms = null;
      _filterKitchens = null;
      _filterFloors = null;
      _filterMinPrice = '';
      _filterMaxPrice = '';
      _filterMinSize = '';
      _filterMaxSize = '';
      _selectedMinPrice = null;
      _selectedMaxPrice = null;
      _selectedMinSize = null;
      _selectedMaxSize = null;
      _filterHasParking = false;
      _filterHasPool = false;
      _filterHasGarden = false;
      _filterHasElevator = false;
      _filterHasFurnished = false;
      _filterHasAC = false;
      _filterFeaturedOnly = false;
    });
    _applyAdvancedFilters();
  }

  // Apply advanced filters to properties
  Future<void> _applyAdvancedFilters() async {
    setState(() => _isLoading = true);
    
    try {
      final propertyService = Provider.of<property_service.PropertyService>(context, listen: false);
      
      // Determine status from filter type
      PropertyStatus? status;
      if (_selectedFilterType == 'rent') {
        status = PropertyStatus.forRent;
      } else if (_selectedFilterType == 'sell') {
        status = PropertyStatus.forSale;
      } else {
        status = _filterStatus;
      }

      // Collect active feature filters
      List<String> activeFeatures = [];
      if (_filterHasParking) activeFeatures.add('hasParking');
      if (_filterHasPool) activeFeatures.add('hasPool');
      if (_filterHasGarden) activeFeatures.add('hasGarden');
      if (_filterHasElevator) activeFeatures.add('hasElevator');
      if (_filterHasFurnished) activeFeatures.add('hasFurnished');
      if (_filterHasAC) activeFeatures.add('hasAC');

      // 1. Fetch from cached properties (Use cached list instead of server query)
      final allProperties = propertyService.properties;
      List<Property> currentFiltered = List.from(allProperties);

      // Apply initial filters (search, city, type, status, price, beds)
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        currentFiltered = currentFiltered.where((p) =>
          p.title.toLowerCase().contains(query) ||
          p.description.toLowerCase().contains(query) ||
          p.city.toLowerCase().contains(query) ||
          (p.neighborhood.toLowerCase().contains(query) ?? false)
        ).toList();
      }

      if (_filterCity != null) {
        currentFiltered = currentFiltered.where((p) => p.city == _filterCity).toList();
      }

      if (_filterType != null) {
        currentFiltered = currentFiltered.where((p) => p.type == _filterType).toList();
      }

      if (status != null) {
        currentFiltered = currentFiltered.where((p) => p.status == status).toList();
      }

      if (_selectedMinPrice != null) {
        currentFiltered = currentFiltered.where((p) {
           double price = p.status == PropertyStatus.forRent ? p.monthlyRent : p.price;
           return price >= _selectedMinPrice!;
        }).toList();
      }

      if (_selectedMaxPrice != null) {
        currentFiltered = currentFiltered.where((p) {
           double price = p.status == PropertyStatus.forRent ? p.monthlyRent : p.price;
           return price <= _selectedMaxPrice!;
        }).toList();
      }

      if (_filterBedrooms != null) {
        currentFiltered = currentFiltered.where((p) => p.bedrooms == _filterBedrooms!).toList();
      }

      // 2. Apply remaining fine-grained filters in memory
      // (For fields not supported natively by the basic search query)
      List<Property> filtered = currentFiltered.where((p) {
        if (!p.isPublished || p.isEffectivelyExpired) return false;

        // Apply bathrooms filter (exact match)
        if (_filterBathrooms != null && p.bathrooms != _filterBathrooms!) return false;

        // Apply kitchens filter (exact match)
        if (_filterKitchens != null && p.kitchens != _filterKitchens!) return false;

        // Apply neighborhood filter (text match)
        if (_filterNeighborhood != null && !p.neighborhood.contains(_filterNeighborhood!)) return false;

        // Apply condition filter
        if (_filterCondition != null && p.condition != _filterCondition) return false;

        // Apply floors filter
        if (_filterFloors != null && p.floors != _filterFloors) return false;

        // Apply featured/premium filter
        if (_filterFeaturedOnly && !p.isBoostActive) return false;

        // Apply min size filter
        if (_selectedMinSize != null && p.sizeSqm < _selectedMinSize!) return false;

        // Apply max size filter
        if (_selectedMaxSize != null && p.sizeSqm > _selectedMaxSize!) return false;

        // Apply feature filters
        if (activeFeatures.isNotEmpty) {
          for (final feature in activeFeatures) {
            bool matches = false;
            switch (feature) {
              case 'hasParking': matches = p.hasParking; break;
              case 'hasPool': matches = p.hasPool; break;
              case 'hasGarden': matches = p.hasGarden; break;
              case 'hasElevator': matches = p.hasElevator; break;
              case 'hasFurnished': matches = p.hasFurnished; break;
              case 'hasAC': matches = p.hasAC; break;
            }
            if (!matches) return false;
          }
        }

        return true;
      }).toList();

      // Sort: boosted first, then by date (or user selection)
      filtered.sort((a, b) {
        if (a.isBoostActive && !b.isBoostActive) return -1;
        if (!a.isBoostActive && b.isBoostActive) return 1;
        if (a.isBoostActive && b.isBoostActive) {
          return (b.boostAmount ?? 0).compareTo(a.boostAmount ?? 0);
        }
        if (_priceSortAscending != null) {
          double aPrice = a.status == PropertyStatus.forRent
              ? (a.monthlyRent > 0 ? a.monthlyRent : (a.dailyRent > 0 ? a.dailyRent * 30 : 0))
              : a.price;
          double bPrice = b.status == PropertyStatus.forRent
              ? (b.monthlyRent > 0 ? b.monthlyRent : (b.dailyRent > 0 ? b.dailyRent * 30 : 0))
              : b.price;
          return _priceSortAscending! ? aPrice.compareTo(bPrice) : bPrice.compareTo(aPrice);
        } else if (_dateSortAscending != null) {
          return _dateSortAscending! ? a.createdAt.compareTo(b.createdAt) : b.createdAt.compareTo(a.createdAt);
        }
        return b.createdAt.compareTo(a.createdAt);
      });

      if (mounted) {
        setState(() {
          _filteredProperties = filtered;
          _featuredProperties = filtered.where((p) => p.isBoostActive).toList();
          _filtersApplied = _hasActiveFilters() || _searchQuery.isNotEmpty;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Fallback or error handling
      }
    }
  }

  // Build compact filter dropdown
  Widget _buildFilterDropdown<T>({
    required T? value,
    required String hint,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    ValueChanged<T?>? onChanged,
  }) {
    final bool isEnabled = onChanged != null;
    
    // Build the full items list including "All" option
    final allItems = isEnabled ? [
      DropdownMenuItem<T>(
        value: null,
        child: Text('All', style: ThemeService.getDynamicStyle(context, fontSize: 13, color: Colors.grey[600])),
      ),
      ...items,
    ] : <DropdownMenuItem<T>>[];
    
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: !isEnabled 
            ? Colors.grey[200] 
            : (value != null ? const Color(0xFF01352D).withValues(alpha: 0.08) : Colors.grey[100]),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: !isEnabled 
              ? Colors.grey[400]! 
              : (value != null ? const Color(0xFF01352D) : Colors.grey[300]!),
          width: value != null ? 1.5 : 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Row(
            children: [
              Icon(icon, size: 16, color: isEnabled ? Colors.grey[600] : Colors.grey[500]),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  hint,
                  style: ThemeService.getDynamicStyle(
                    context,
                    fontSize: 12, 
                    color: isEnabled ? Colors.grey[600] : Colors.grey[500],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          icon: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: value != null ? const Color(0xFF01352D) : Colors.grey[600]),
          isExpanded: true,
          isDense: true,
          style: ThemeService.getDynamicStyle(context, fontSize: 13, color: Colors.black87),
          selectedItemBuilder: isEnabled ? (context) {
            // Must match the items list exactly (including "All" at index 0)
            return allItems.map((item) {
              final itemValue = item.value;
              final displayText = itemValue == null ? 'All' : _getDropdownLabel(itemValue);
              return Row(
                children: [
                  Icon(icon, size: 16, color: itemValue != null ? const Color(0xFF01352D) : Colors.grey[600]),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      displayText,
                      style: ThemeService.getDynamicStyle(
                        context,
                        fontSize: 12, 
                        color: itemValue != null ? const Color(0xFF01352D) : Colors.grey[600],
                        fontWeight: itemValue != null ? FontWeight.w600 : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              );
            }).toList();
          } : null,
          items: isEnabled ? allItems : null,
          onChanged: isEnabled ? onChanged : null,
        ),
      ),
    );
  }

  String _getDropdownLabel(dynamic value, {bool isPrice = false, bool isSize = false}) {
    if (value is PropertyType) {
      return value.typeDisplayName;
    } else if (value is PropertyCondition) {
      return value.conditionDisplayName;
    } else if (value is int) {
      if (isPrice) {
        return _formatPrice(value);
      } else if (isSize) {
        return '$value m²';
      }
      return '$value';
    } else if (value is String) {
      return value;
    }
    return value.toString();
  }

  // Build compact filter chip for horizontal scroll
  Widget _buildCompactFilterChip(String label, String? value, IconData icon, VoidCallback? onTap) {
    final bool hasValue = value != null && value.isNotEmpty;
    final bool isDisabled = onTap == null;
    
    return ScaleAnimation(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isDisabled 
            ? Colors.grey[100] 
            : (hasValue ? const Color(0xFF01352D) : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDisabled 
              ? Colors.grey[300]! 
              : (hasValue ? const Color(0xFF01352D) : Colors.grey[300]!),
            width: 1,
          ),
          boxShadow: hasValue ? [
            BoxShadow(
              color: const Color(0xFF01352D).withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon, 
              size: 16, 
              color: isDisabled 
                ? Colors.grey[400] 
                : (hasValue ? Colors.white : const Color(0xFF01352D)),
            ),
            const SizedBox(width: 8),
            Text(
              hasValue ? value : label,
              style: ThemeService.getDynamicStyle(
                context,
                fontSize: 13, 
                color: isDisabled 
                  ? Colors.grey[400] 
                  : (hasValue ? Colors.white : Colors.black87), 
                fontWeight: hasValue ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            if (!isDisabled) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded, 
                size: 16, 
                color: hasValue ? Colors.white70 : Colors.grey[500],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Check if more filters are active
  bool _hasMoreFilters() {
    return _filterCondition != null ||
        _filterFloors != null ||
        _filterHasParking ||
        _filterHasPool ||
        _filterHasGarden ||
        _filterHasElevator ||
        _filterHasFurnished ||
        _filterHasAC ||
        _filterFeaturedOnly;
  }

  // Show filter bottom sheet
  void _showFilterBottomSheet(String filterType) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.5,
              minChildSize: 0.3,
              maxChildSize: 0.85,
              expand: false,
              builder: (context, scrollController) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Title
                      Text(
                        _getFilterTitle(filterType),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      // Filter content - scrollable
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          child: _buildFilterContent(filterType, setModalState),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Apply button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _applyAdvancedFilters();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF01352D),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(AppLocalizations.of(context)?.apply ?? 'Apply', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  String _getFilterTitle(String filterType) {
    final l10n = AppLocalizations.of(context);
    switch (filterType) {
      case 'city': return l10n?.selectCity ?? 'Select City';
      case 'neighborhood': return l10n?.selectNeighborhood ?? 'Select Neighborhood';
      case 'type': return l10n?.propertyType ?? 'Property Type';
      case 'beds': return l10n?.bedrooms ?? 'Bedrooms';
      case 'baths': return l10n?.bathrooms ?? 'Bathrooms';
      case 'price': return l10n?.priceRange ?? 'Price Range';
      case 'size': return l10n?.sizeRange ?? 'Size Range';
      case 'more': return l10n?.moreFilters ?? 'More Filters';
      default: return l10n?.filters ?? 'Filters';
    }
  }

  Widget _buildFilterContent(String filterType, StateSetter setModalState) {
    switch (filterType) {
      case 'city':
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: CityLocalizer.getAllEnglishCities().map((city) => ChoiceChip(
            label: Text(CityLocalizer.getLocalizedCityName(context, city)),
            selected: _filterCity == city,
            onSelected: (selected) {
              setModalState(() {
                setState(() {
                  _filterCity = selected ? city : null;
                  _filterNeighborhood = null;
                });
              });
            },
            selectedColor: const Color(0xFF01352D),
            labelStyle: TextStyle(color: _filterCity == city ? Colors.white : Colors.black87),
          )).toList(),
        );
      case 'neighborhood':
        final neighborhoods = _filterCity != null ? CityLocalizer.getNeighborhoods(_filterCity!) : [];
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: neighborhoods.map((n) => ChoiceChip(
            label: Text(CityLocalizer.getLocalizedNeighborhoodName(context, n), style: const TextStyle(fontSize: 12)),
            selected: _filterNeighborhood == n,
            onSelected: (selected) {
              setModalState(() {
                setState(() => _filterNeighborhood = selected ? n : null);
              });
            },
            selectedColor: const Color(0xFF01352D),
            labelStyle: TextStyle(color: _filterNeighborhood == n ? Colors.white : Colors.black87, fontSize: 12),
          )).toList(),
        );
      case 'type':
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PropertyType.values.map((type) => ChoiceChip(
            label: Text(type.getLocalizedName(context)),
            selected: _filterType == type,
            onSelected: (selected) {
              setModalState(() {
                setState(() => _filterType = selected ? type : null);
              });
            },
            selectedColor: const Color(0xFF01352D),
            labelStyle: TextStyle(color: _filterType == type ? Colors.white : Colors.black87),
          )).toList(),
        );
      case 'beds':
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(10, (i) => i + 1).map((num) => ChoiceChip(
            label: Text('$num'),
            selected: _filterBedrooms == num,
            onSelected: (selected) {
              setModalState(() {
                setState(() => _filterBedrooms = selected ? num : null);
              });
            },
            selectedColor: const Color(0xFF01352D),
            labelStyle: TextStyle(color: _filterBedrooms == num ? Colors.white : Colors.black87),
          )).toList(),
        );
      case 'baths':
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(10, (i) => i + 1).map((num) => ChoiceChip(
            label: Text('$num'),
            selected: _filterBathrooms == num,
            onSelected: (selected) {
              setModalState(() {
                setState(() => _filterBathrooms = selected ? num : null);
              });
            },
            selectedColor: const Color(0xFF01352D),
            labelStyle: TextStyle(color: _filterBathrooms == num ? Colors.white : Colors.black87),
          )).toList(),
        );
      case 'price':
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Min Price', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [null, ..._priceOptions].map((price) => ChoiceChip(
                label: Text(price == null ? 'Any' : _formatPrice(price)),
                selected: _selectedMinPrice == price,
                onSelected: (selected) {
                  setModalState(() {
                    setState(() => _selectedMinPrice = selected ? price : null);
                  });
                },
                selectedColor: const Color(0xFF01352D),
                labelStyle: TextStyle(color: _selectedMinPrice == price ? Colors.white : Colors.black87, fontSize: 12),
              )).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Max Price', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [null, ..._priceOptions].map((price) => ChoiceChip(
                label: Text(price == null ? 'Any' : _formatPrice(price)),
                selected: _selectedMaxPrice == price,
                onSelected: (selected) {
                  setModalState(() {
                    setState(() => _selectedMaxPrice = selected ? price : null);
                  });
                },
                selectedColor: const Color(0xFF01352D),
                labelStyle: TextStyle(color: _selectedMaxPrice == price ? Colors.white : Colors.black87, fontSize: 12),
              )).toList(),
            ),
          ],
        );
      case 'size':
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Min Size (m²)', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [null, ..._sizeOptions].map((size) => ChoiceChip(
                label: Text(size == null ? 'Any' : '$size'),
                selected: _selectedMinSize == size,
                onSelected: (selected) {
                  setModalState(() {
                    setState(() => _selectedMinSize = selected ? size : null);
                  });
                },
                selectedColor: const Color(0xFF01352D),
                labelStyle: TextStyle(color: _selectedMinSize == size ? Colors.white : Colors.black87),
              )).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Max Size (m²)', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [null, ..._sizeOptions].map((size) => ChoiceChip(
                label: Text(size == null ? 'Any' : '$size'),
                selected: _selectedMaxSize == size,
                onSelected: (selected) {
                  setModalState(() {
                    setState(() => _selectedMaxSize = selected ? size : null);
                  });
                },
                selectedColor: const Color(0xFF01352D),
                labelStyle: TextStyle(color: _selectedMaxSize == size ? Colors.white : Colors.black87),
              )).toList(),
            ),
          ],
        );
      case 'more':
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Condition', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: PropertyCondition.values.map((c) => ChoiceChip(
                label: Text(c.conditionDisplayName, style: const TextStyle(fontSize: 12)),
                selected: _filterCondition == c,
                onSelected: (selected) {
                  setModalState(() {
                    setState(() => _filterCondition = selected ? c : null);
                  });
                },
                selectedColor: const Color(0xFF01352D),
                labelStyle: TextStyle(color: _filterCondition == c ? Colors.white : Colors.black87, fontSize: 12),
              )).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Floors', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(10, (i) => i + 1).map((num) => ChoiceChip(
                label: Text('$num'),
                selected: _filterFloors == num,
                onSelected: (selected) {
                  setModalState(() {
                    setState(() => _filterFloors = selected ? num : null);
                  });
                },
                selectedColor: const Color(0xFF01352D),
                labelStyle: TextStyle(color: _filterFloors == num ? Colors.white : Colors.black87),
              )).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Features', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(label: const Text('Parking'), selected: _filterHasParking, onSelected: (v) { setModalState(() => setState(() => _filterHasParking = v)); }, selectedColor: const Color(0xFF01352D), checkmarkColor: Colors.white),
                FilterChip(label: const Text('Pool'), selected: _filterHasPool, onSelected: (v) { setModalState(() => setState(() => _filterHasPool = v)); }, selectedColor: const Color(0xFF01352D), checkmarkColor: Colors.white),
                FilterChip(label: const Text('Garden'), selected: _filterHasGarden, onSelected: (v) { setModalState(() => setState(() => _filterHasGarden = v)); }, selectedColor: const Color(0xFF01352D), checkmarkColor: Colors.white),
                FilterChip(label: const Text('Elevator'), selected: _filterHasElevator, onSelected: (v) { setModalState(() => setState(() => _filterHasElevator = v)); }, selectedColor: const Color(0xFF01352D), checkmarkColor: Colors.white),
                FilterChip(label: const Text('Furnished'), selected: _filterHasFurnished, onSelected: (v) { setModalState(() => setState(() => _filterHasFurnished = v)); }, selectedColor: const Color(0xFF01352D), checkmarkColor: Colors.white),
                FilterChip(label: const Text('A/C'), selected: _filterHasAC, onSelected: (v) { setModalState(() => setState(() => _filterHasAC = v)); }, selectedColor: const Color(0xFF01352D), checkmarkColor: Colors.white),
                FilterChip(label: const Text('Premium Only'), selected: _filterFeaturedOnly, onSelected: (v) { setModalState(() => setState(() => _filterFeaturedOnly = v)); }, selectedColor: const Color(0xFF01352D), checkmarkColor: Colors.white),
              ],
            ),
          ],
        );
      default:
        return const SizedBox();
    }
  }

  // Simple Filter Card for Rent/Sell
  Widget _buildSimpleFilterCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isActive,
  }) {
    return ScaleAnimation(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF01352D) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          gradient: isActive
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF01352D),
                    Color(0xFF015144),
                  ],
                )
              : null,
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF01352D).withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
          border: Border.all(
            color: isActive ? Colors.transparent : Colors.grey[200]!,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isActive ? Colors.white.withValues(alpha: 0.2) : const Color(0xFF01352D).withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isActive ? Colors.white : const Color(0xFF01352D),
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: ThemeService.getDynamicStyle(
                context,
                color: isActive ? Colors.white : const Color(0xFF01352D),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: ThemeService.getDynamicStyle(
                context,
                color: isActive ? Colors.white.withValues(alpha: 0.8) : Colors.grey[600],
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Sort Button with Label and Direction Indicator
  Widget _buildSortButtonWithLabel({
    required IconData icon,
    required String label,
    required bool isActive,
    required bool? isAscending,
    required VoidCallback onTap,
    String? ascendingLabel,
    String? descendingLabel,
  }) {
    final activeAscLabel = ascendingLabel ?? 'Low to High';
    final activeDescLabel = descendingLabel ?? 'High to Low';
    
    return ScaleAnimation(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF01352D) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? const Color(0xFF01352D) : Colors.grey[200]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isActive 
                ? const Color(0xFF01352D).withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isActive ? Colors.white : const Color(0xFF01352D),
                  size: 20,
                ),
                if (isActive) ...[
                  const SizedBox(width: 6),
                  Icon(
                    isAscending == true
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isActive
                  ? (isAscending == true ? activeAscLabel : activeDescLabel)
                  : label,
              style: ThemeService.getDynamicStyle(
                context,
                color: isActive ? Colors.white : Colors.grey[600],
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Simple View Toggle Button - Icon only
  Widget _buildSimpleViewButton({
    required bool isGridView,
    required VoidCallback onTap,
  }) {
    return ScaleAnimation(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isGridView ? const Color(0xFF01352D) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isGridView ? const Color(0xFF01352D) : Colors.grey[200]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isGridView 
                ? const Color(0xFF01352D).withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          isGridView ? Icons.grid_view_rounded : Icons.view_list_rounded,
          color: isGridView ? Colors.white : const Color(0xFF01352D),
          size: 24,
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
    return ScaleAnimation(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color,
              color.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: ThemeService.getDynamicStyle(
                      context,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: ThemeService.getDynamicStyle(
                      context,
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroStat({
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.25),
            Colors.white.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: ThemeService.getDynamicStyle(
              context,
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: ThemeService.getDynamicStyle(
              context,
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 10),
        Text(
          title,
          style: ThemeService.getDynamicStyle(
            context,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildFixedFilterBar(BuildContext context, AppLocalizations? l10n) {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Rent/Sell Toggle
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: _buildSimpleFilterCard(
                    icon: Icons.home_outlined,
                    title: l10n?.rent ?? 'Rent',
                    subtitle: l10n?.rentalProperties ?? 'Rental properties',
                    onTap: () => _filterByType('rent'),
                    isActive: _isFilteredByType('rent'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSimpleFilterCard(
                    icon: Icons.sell_outlined,
                    title: l10n?.sell ?? 'Sell',
                    subtitle: l10n?.propertiesForSale ?? 'Properties for sale',
                    onTap: () => _filterByType('sell'),
                    isActive: _isFilteredByType('sell'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: ThemeService.getDynamicStyle(context, color: Colors.black87, fontSize: 15),
                inputFormatters: [BasicTextFormatter()],
                decoration: InputDecoration(
                  hintText: l10n?.searchPropertiesCities ?? 'Search properties, cities...',
                  hintStyle: ThemeService.getDynamicStyle(context, color: Colors.grey[400], fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF01352D), size: 22),
                  filled: true,
                  fillColor: Colors.grey[50], // Very light background
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF01352D), width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                  _applySearchAndFilters();
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Compact Scrollable Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                // Advanced Filter Button
                GestureDetector(
                onTap: _openPropertyFilter,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF01352D), Color(0xFF024638)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.filter_list, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(l10n?.advanced ?? 'Advanced', style: ThemeService.getDynamicStyle(context, fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                if (_hasActiveFilters()) ...[
                  GestureDetector(
                    onTap: _clearAdvancedFilters,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.red[300]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.clear, size: 14, color: Colors.red[700]),
                          const SizedBox(width: 4),
                          Text(
                            Localizations.localeOf(context).languageCode == 'ar' ? 'مسح' : (l10n?.clearFilters ?? 'Clear'),
                            style: TextStyle(fontSize: 12, color: Colors.red[700], fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                _buildCompactFilterChip(l10n?.city ?? 'City', _filterCity != null ? CityLocalizer.getLocalizedCityName(context, _filterCity!) : null, Icons.location_city, () => _showFilterBottomSheet('city')),
                const SizedBox(width: 6),
                _buildCompactFilterChip(l10n?.area ?? 'Area', _filterNeighborhood != null ? CityLocalizer.getLocalizedNeighborhoodName(context, _filterNeighborhood!) : null, Icons.location_on, _filterCity != null ? () => _showFilterBottomSheet('neighborhood') : null),
                const SizedBox(width: 6),
                _buildCompactFilterChip(l10n?.type ?? 'Type', _filterType?.getLocalizedName(context), Icons.home_work, () => _showFilterBottomSheet('type')),
                const SizedBox(width: 6),
                _buildCompactFilterChip(l10n?.beds ?? 'Beds', _filterBedrooms?.toString(), Icons.bed, () => _showFilterBottomSheet('beds')),
                const SizedBox(width: 6),
                _buildCompactFilterChip(l10n?.baths ?? 'Baths', _filterBathrooms?.toString(), Icons.bathtub, () => _showFilterBottomSheet('baths')),
                const SizedBox(width: 6),
                _buildCompactFilterChip(l10n?.price ?? 'Price', _selectedMinPrice != null || _selectedMaxPrice != null ? (l10n?.set ?? 'Set') : null, Icons.attach_money, () => _showFilterBottomSheet('price')),
                const SizedBox(width: 6),
                _buildCompactFilterChip(l10n?.size ?? 'Size', _selectedMinSize != null || _selectedMaxSize != null ? (l10n?.set ?? 'Set') : null, Icons.square_foot, () => _showFilterBottomSheet('size')),
                const SizedBox(width: 6),
                _buildCompactFilterChip(l10n?.more ?? 'More', _hasMoreFilters() ? '•' : null, Icons.tune, () => _showFilterBottomSheet('more')),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Sort and View Toggle Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: _buildSortButtonWithLabel(
                    icon: Icons.attach_money_rounded,
                    label: l10n?.price ?? 'Price',
                    isActive: _priceSortAscending != null,
                    isAscending: _priceSortAscending == true,
                    onTap: () {
                      setState(() {
                        if (_priceSortAscending == null) {
                          _priceSortAscending = false;
                          _dateSortAscending = null;
                        } else if (_priceSortAscending == false) {
                          _priceSortAscending = true;
                        } else {
                          _priceSortAscending = null;
                        }
                      });
                      _applySearchAndFilters();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSortButtonWithLabel(
                    icon: Icons.calendar_today_rounded,
                    label: l10n?.date ?? 'Date',
                    isActive: _dateSortAscending != null,
                    isAscending: _dateSortAscending == true,
                    ascendingLabel: l10n?.sortByOldest ?? 'Oldest',
                    descendingLabel: l10n?.sortByNewest ?? 'Newest',
                    onTap: () {
                      setState(() {
                        if (_dateSortAscending == null) {
                          _dateSortAscending = false;
                          _priceSortAscending = null;
                        } else if (_dateSortAscending == false) {
                          _dateSortAscending = true;
                        } else {
                          _dateSortAscending = null;
                        }
                      });
                      _applySearchAndFilters();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                _buildSimpleViewButton(
                  isGridView: _isGridView,
                  onTap: () {
                    setState(() {
                      _isGridView = !_isGridView;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// Sticky header delegate for filter bar
class _StickyFilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _StickyFilterHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;
  
  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(
      child: Container(
        color: Colors.white,
        child: child,
      ),
    );
  }

  @override
  bool shouldRebuild(_StickyFilterHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}