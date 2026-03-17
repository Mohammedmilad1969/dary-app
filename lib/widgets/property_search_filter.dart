import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../l10n/app_localizations.dart';
import '../models/property.dart';
import '../services/theme_service.dart';
import '../utils/text_input_formatters.dart';
import '../utils/city_localizer.dart';

class PropertySearchFilter extends StatefulWidget {
  final Function(List<Property>) onFilterChanged;
  final List<Property> allProperties;
  final VoidCallback? onCombinedFilter;
  final String? currentRentSellFilter;
  final VoidCallback? onClearAllFilters;
  final Function(Map<String, dynamic>)? onFilterValuesChanged;
  
  // Initial filter values for state preservation
  final String? initialSearchText;
  final PropertyType? initialType;
  final PropertyStatus? initialStatus;
  final String? initialCity;
  final String? initialNeighborhood;
  final int? initialBedrooms;
  final int? initialBathrooms;
  final int? initialKitchens;
  final String? initialMinPrice;
  final String? initialMaxPrice;
  final String? initialMinSize;
  final String? initialMaxSize;
  final bool? initialFeaturedOnly;
  final bool? initialHasParking;
  final bool? initialHasPool;
  final bool? initialHasGarden;
  final bool? initialHasElevator;
  final bool? initialHasFurnished;
  final bool? initialHasAC;

  const PropertySearchFilter({
    super.key,
    required this.onFilterChanged,
    required this.allProperties,
    this.onCombinedFilter,
    this.currentRentSellFilter,
    this.onClearAllFilters,
    this.onFilterValuesChanged,
    this.initialSearchText,
    this.initialType,
    this.initialStatus,
    this.initialCity,
    this.initialNeighborhood,
    this.initialBedrooms,
    this.initialBathrooms,
    this.initialKitchens,
    this.initialMinPrice,
    this.initialMaxPrice,
    this.initialMinSize,
    this.initialMaxSize,
    this.initialFeaturedOnly,
    this.initialHasParking,
    this.initialHasPool,
    this.initialHasGarden,
    this.initialHasElevator,
    this.initialHasFurnished,
    this.initialHasAC,
  });

  @override
  State<PropertySearchFilter> createState() => _PropertySearchFilterState();
}

class _PropertySearchFilterState extends State<PropertySearchFilter> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _minSizeController = TextEditingController();
  final TextEditingController _maxSizeController = TextEditingController();
  Timer? _debounceTimer;
  PropertyType? _selectedType;
  PropertyStatus? _selectedStatus;
  String? _selectedCity;
  String? _selectedNeighborhood;
  int? _selectedBedrooms;
  int? _selectedBathrooms;
  int? _selectedKitchens;
  bool _showFeaturedOnly = false;

  // Libyan cities list - now handled by CityLocalizer
  final List<String> _libyanCities = CityLocalizer.getAllEnglishCities();


  // Map of cities to their neighborhoods - using CityLocalizer
  List<String> getNeighborhoods(String city) => CityLocalizer.getNeighborhoods(city);

  bool _hasBalcony = false;
  bool _hasGarden = false;
  bool _hasParking = false;
  bool _hasPool = false;
  bool _hasGym = false;
  bool _hasSecurity = false;
  bool _hasElevator = false;
  bool _hasAC = false;
  bool _hasHeating = false;
  bool _hasFurnished = false;
  bool _hasWaterWell = false;

  @override
  void initState() {
    super.initState();
    // Initialize with provided initial values to preserve state
    _searchController.text = widget.initialSearchText ?? '';
    _selectedType = widget.initialType;
    _selectedStatus = widget.initialStatus;
    _selectedCity = widget.initialCity;
    _selectedNeighborhood = widget.initialNeighborhood;
    _selectedBedrooms = widget.initialBedrooms;
    _selectedBathrooms = widget.initialBathrooms;
    _selectedKitchens = widget.initialKitchens;
    _minPriceController.text = widget.initialMinPrice ?? '';
    _maxPriceController.text = widget.initialMaxPrice ?? '';
    _minSizeController.text = widget.initialMinSize ?? '';
    _maxSizeController.text = widget.initialMaxSize ?? '';
    _showFeaturedOnly = widget.initialFeaturedOnly ?? false;
    _hasParking = widget.initialHasParking ?? false;
    _hasPool = widget.initialHasPool ?? false;
    _hasGarden = widget.initialHasGarden ?? false;
    _hasElevator = widget.initialHasElevator ?? false;
    _hasFurnished = widget.initialHasFurnished ?? false;
    _hasAC = widget.initialHasAC ?? false;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _maxPriceController.dispose();
    _minPriceController.dispose();
    _minSizeController.dispose();
    _maxSizeController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _notifyFilterValuesChanged() {
    if (widget.onFilterValuesChanged != null) {
      final values = {
        'searchText': _searchController.text,
        'type': _selectedType,
        'status': _selectedStatus,
        'city': _selectedCity,
        'neighborhood': _selectedNeighborhood,
        'bedrooms': _selectedBedrooms,
        'bathrooms': _selectedBathrooms,
        'kitchens': _selectedKitchens,
        'minPrice': _minPriceController.text,
        'maxPrice': _maxPriceController.text,
        'minSize': _minSizeController.text,
        'maxSize': _maxSizeController.text,
        'featuredOnly': _showFeaturedOnly,
        'hasParking': _hasParking,
        'hasPool': _hasPool,
        'hasGarden': _hasGarden,
        'hasElevator': _hasElevator,
        'hasFurnished': _hasFurnished,
        'hasAC': _hasAC,
      };
      print('📤 Notifying filter values changed: $values');
      widget.onFilterValuesChanged!(values);
    } else {
      print('⚠️ onFilterValuesChanged callback is null!');
    }
  }

  Future<void> _applyFilters() async {
    try {
      if (kDebugMode) {
        debugPrint('🔍 Applying filters...');
        debugPrint('📊 Total properties: ${widget.allProperties.length}');
        debugPrint('🔎 Search term: "${_searchController.text}"');
        debugPrint('🏠 Selected type: $_selectedType');
        debugPrint('💰 Selected status: $_selectedStatus');
        debugPrint('🏙️ Selected city: $_selectedCity');
        debugPrint('🛏️ Selected bedrooms: $_selectedBedrooms');
        debugPrint('🚿 Selected bathrooms: $_selectedBathrooms');
        debugPrint('🍳 Selected kitchens: $_selectedKitchens');
        debugPrint('📏 Size range: ${_minSizeController.text} - ${_maxSizeController.text} m²');
        debugPrint('💰 Price range: ${_minPriceController.text} - ${_maxPriceController.text} LYD');
      }

      List<Property> propertiesToFilter = widget.allProperties;
      
      if (propertiesToFilter.isEmpty) {
        if (kDebugMode) {
          debugPrint('⚠️ No properties available in cache');
        }
        widget.onFilterChanged([]);
        return;
      }

      List<Property> filtered = List<Property>.from(propertiesToFilter);

    // Apply Rent/Sell filter first if active
    if (widget.currentRentSellFilter != null) {
      switch (widget.currentRentSellFilter!.toLowerCase()) {
        case 'rent':
          filtered = filtered.where((p) => p.status == PropertyStatus.forRent).toList();
          break;
        case 'sell':
          filtered = filtered.where((p) => p.status == PropertyStatus.forSale).toList();
          break;
      }
      if (kDebugMode) {
        debugPrint('🏠 After Rent/Sell filter: ${filtered.length} properties');
      }
    }

    // Apply search filter with comprehensive matching
    if (_searchController.text.isNotEmpty) {
      final searchTerm = _searchController.text.toLowerCase().trim();
      final searchWords = searchTerm.split(' ').where((word) => word.isNotEmpty).toList();
      
      filtered = filtered.where((property) {
        // Create comprehensive searchable text
        final searchableText = '${property.title} ${property.description} ${property.city} ${property.neighborhood} ${property.type.name} ${property.status.name} ${property.type.typeDisplayName}'.toLowerCase();
        
        // Check if all search words are found
        return searchWords.every((word) => searchableText.contains(word));
      }).toList();
      
      if (kDebugMode) {
        debugPrint('🔎 After search filter: ${filtered.length} properties');
      }
    }

    // Apply type filter
    if (_selectedType != null) {
      filtered = filtered.where((p) => p.type == _selectedType).toList();
      if (kDebugMode) {
        debugPrint('🏠 After type filter: ${filtered.length} properties');
      }
    }

    // Apply status filter
    if (_selectedStatus != null) {
      filtered = filtered.where((p) => p.status == _selectedStatus).toList();
      if (kDebugMode) {
        debugPrint('💰 After status filter: ${filtered.length} properties');
      }
    }

    // Apply city filter
    if (_selectedCity != null && _selectedCity!.isNotEmpty) {
      filtered = filtered.where((p) => p.city == _selectedCity).toList();
      if (kDebugMode) {
        debugPrint('🏙️ After city filter: ${filtered.length} properties');
      }
    }

    // Apply neighborhood filter
    if (_selectedNeighborhood != null && _selectedNeighborhood!.isNotEmpty) {
      filtered = filtered.where((p) => p.neighborhood == _selectedNeighborhood).toList();
      if (kDebugMode) {
        debugPrint('📍 After neighborhood filter: ${filtered.length} properties');
      }
    }

    // Apply bedroom filter
    if (_selectedBedrooms != null) {
      filtered = filtered.where((p) => p.bedrooms == _selectedBedrooms).toList();
      if (kDebugMode) {
        debugPrint('🛏️ After bedroom filter: ${filtered.length} properties');
      }
    }

    // Apply bathroom filter
    if (_selectedBathrooms != null) {
      filtered = filtered.where((p) => p.bathrooms == _selectedBathrooms).toList();
      if (kDebugMode) {
        debugPrint('🚿 After bathroom filter: ${filtered.length} properties');
      }
    }

    // Apply kitchen filter
    if (_selectedKitchens != null) {
      filtered = filtered.where((p) => p.kitchens == _selectedKitchens).toList();
      if (kDebugMode) {
        debugPrint('🍳 After kitchen filter: ${filtered.length} properties');
      }
    }

    // Apply size range filter
    double minSize = double.tryParse(_minSizeController.text) ?? 0;
    double maxSize = double.tryParse(_maxSizeController.text) ?? 10000;
    
    filtered = filtered.where((p) {
      return p.sizeSqm >= minSize && p.sizeSqm <= maxSize;
    }).toList();

    if (kDebugMode) {
      debugPrint('📏 After size filter: ${filtered.length} properties');
    }

    // Apply price range filter
    double minPrice = double.tryParse(_minPriceController.text.replaceAll(',', '')) ?? 0;
    double maxPrice = double.tryParse(_maxPriceController.text.replaceAll(',', '')) ?? 10000000;

    filtered = filtered.where((p) {
      double price = p.status == PropertyStatus.forRent ? p.monthlyRent : p.price;
      return price >= minPrice && price <= maxPrice;
    }).toList();

    if (kDebugMode) {
      debugPrint('💰 After price filter: ${filtered.length} properties');
    }

    // Apply featured filter
    if (_showFeaturedOnly) {
      filtered = filtered.where((p) => p.isFeatured).toList();
      if (kDebugMode) {
        debugPrint('⭐ After featured filter: ${filtered.length} properties');
      }
    }

    // Sort with boosted properties at the top
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

      if (kDebugMode) {
        debugPrint('✅ Final filtered properties: ${filtered.length}');
      }

      if (kDebugMode) {
        debugPrint('📤 Calling onFilterChanged with ${filtered.length} properties');
      }
      widget.onFilterChanged(filtered);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error in _applyFilters: $e');
      }
      // Return empty list on error - don't show all properties as fallback
      widget.onFilterChanged([]);
    }
  }

  List<String> _getAvailableNeighborhoods() {
    if (_selectedCity == null) {
      return [];
    }
    
    // Get neighborhoods from CityLocalizer
    final neighborhoods = CityLocalizer.getNeighborhoods(_selectedCity!);
    
    // Also include any neighborhoods from existing properties (in case there are new ones)
    final propertiesInCity = widget.allProperties
        .where((p) {
          final pCity = p.city.trim() ?? '';
          return (pCity == _selectedCity) && 
                 p.neighborhood.isNotEmpty;
        })
        .toList();
    
    final propertyNeighborhoods = propertiesInCity
        .map((p) => p.neighborhood.trim())
        .where((n) => n.isNotEmpty)
        .toSet()
        .toList();
    
    // Combine both lists, remove duplicates, and sort
    final allNeighborhoods = <String>{...neighborhoods, ...propertyNeighborhoods};
    final sortedNeighborhoods = allNeighborhoods.toList()..sort();
    
    return sortedNeighborhoods;
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedType = null;
      _selectedStatus = null;
      _selectedCity = null;
      _selectedNeighborhood = null;
      _selectedBedrooms = null;
      _selectedBathrooms = null;
      _selectedKitchens = null;
      _minPriceController.clear();
      _maxPriceController.clear();
      _minSizeController.clear();
      _maxSizeController.clear();
      _showFeaturedOnly = false;
      
      // Reset feature filters
      _hasBalcony = false;
      _hasGarden = false;
      _hasParking = false;
      _hasPool = false;
      _hasGym = false;
      _hasSecurity = false;
      _hasElevator = false;
      _hasAC = false;
      _hasHeating = false;
      _hasFurnished = false;
      _hasWaterWell = false;
    });
    
    // Notify parent to clear Rent/Sell filter as well
    widget.onClearAllFilters?.call();
    
    // Apply filters to show all properties
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Return the full advanced filters interface directly
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.black54),
                onPressed: () => Navigator.pop(context),
              ),
              Text(
                l10n?.advancedFilters ?? 'Advanced Filters',
                style: ThemeService.getDynamicStyle(
                  context,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF01352D),
                ),
              ),
              TextButton(
                onPressed: () {
                  if (widget.onClearAllFilters != null) {
                    widget.onClearAllFilters!();
                  }
                  // Also clear local state
                  setState(() {
                    _searchController.clear();
                    _maxPriceController.clear();
                    _minPriceController.clear();
                    _minSizeController.clear();
                    _maxSizeController.clear();
                    _selectedType = null;
                    _selectedStatus = null;
                    _selectedCity = null;
                    _selectedNeighborhood = null;
                    _selectedBedrooms = null;
                    _selectedBathrooms = null;
                    _selectedKitchens = null;
                    _showFeaturedOnly = false;
                  });
                },
                child: Text(
                  l10n?.clearAllNotifications ?? 'Clear All', // Reusing clearAll
                  style: ThemeService.getDynamicStyle(
                    context,
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          // Content
          Flexible(
            child: SingleChildScrollView(
              child: _buildAdvancedFiltersContent(context, setState),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedFiltersContent(BuildContext context, StateSetter setModalState) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Property Type
        Text(l10n?.propertyType ?? 'Property Type',
            style: ThemeService.getDynamicStyle(context, fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 8),
        DropdownButtonFormField<PropertyType>(
          initialValue: _selectedType,
          dropdownColor: Colors.white,
          style: ThemeService.getDynamicStyle(context, color: Colors.black87),
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: l10n?.propertyType,
            hintStyle: ThemeService.getDynamicStyle(context, color: Colors.grey[600]),
          ),
          items: PropertyType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(type.getLocalizedName(context), style: ThemeService.getDynamicStyle(context, color: Colors.black87)),
            );
          }).toList(),
          onChanged: (value) {
            setModalState(() {
              _selectedType = value;
              _notifyFilterValuesChanged();
            });
          },
        ),

        const SizedBox(height: 16),

        // Status
        Text(l10n?.propertyStatus ?? 'Property Status',
            style: ThemeService.getDynamicStyle(context, fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 8),
        DropdownButtonFormField<PropertyStatus>(
          initialValue: _selectedStatus,
          dropdownColor: Colors.white,
          style: ThemeService.getDynamicStyle(context, color: Colors.black87),
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: l10n?.propertyStatus,
            hintStyle: ThemeService.getDynamicStyle(context, color: Colors.grey[600]),
          ),
          items: PropertyStatus.values.map((status) {
            return DropdownMenuItem(
              value: status,
              child: Text(status.getLocalizedName(context), style: ThemeService.getDynamicStyle(context, color: Colors.black87)),
            );
          }).toList(),
          onChanged: (value) {
            setModalState(() {
              _selectedStatus = value;
              _notifyFilterValuesChanged();
            });
          },
        ),

        const SizedBox(height: 16),

        // Price Range
        Text(l10n?.priceRangeLyd ?? 'Price Range (LYD)',
            style: ThemeService.getDynamicStyle(context, fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _minPriceController,
                keyboardType: TextInputType.number,
                style: ThemeService.getBodyStyle(
                  context,
                  color: Colors.black87,
                ),
                inputFormatters: [PriceFormatter()],
                decoration: InputDecoration(
                  labelText: '${(l10n?.priceRangeLyd ?? 'Price (LYD)').split('(').first}(Min)',
                  labelStyle: ThemeService.getBodyStyle(context),
                  hintText: '0',
                  hintStyle: ThemeService.getDynamicStyle(context, color: Colors.grey[600]),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) {},
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _maxPriceController,
                keyboardType: TextInputType.number,
                style: ThemeService.getBodyStyle(
                  context,
                  color: Colors.black87,
                ),
                inputFormatters: [PriceFormatter()],
                decoration: InputDecoration(
                  labelText: '${(l10n?.priceRangeLyd ?? 'Price (LYD)').split('(').first}(Max)',
                  labelStyle: ThemeService.getBodyStyle(context),
                  hintText: '10,000,000',
                  hintStyle: ThemeService.getDynamicStyle(context, color: Colors.grey[600]),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) {},
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // City
        Text(l10n?.city ?? 'City',
            style: ThemeService.getDynamicStyle(context, fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedCity,
          dropdownColor: Colors.white,
          style: ThemeService.getDynamicStyle(context, color: Colors.black87),
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: l10n?.city,
            hintStyle: ThemeService.getDynamicStyle(context, color: Colors.grey[600]),
          ),
          items: _libyanCities.map((city) {
            return DropdownMenuItem(
              value: city,
              child: Text(
                CityLocalizer.getBilingualCityName(city),
                style: ThemeService.getDynamicStyle(context, color: Colors.black87),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setModalState(() {
              _selectedCity = value;
              _selectedNeighborhood = null; // Reset neighborhood when city changes
              _notifyFilterValuesChanged();
            });
          },
        ),

        const SizedBox(height: 16),

        // Neighborhood
        Text(l10n?.neighborhood ?? 'Neighborhood',
            style: ThemeService.getDynamicStyle(context, fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedNeighborhood,
          dropdownColor: Colors.white,
          style: ThemeService.getDynamicStyle(context, color: Colors.black87),
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: _selectedCity == null ? l10n?.city : l10n?.neighborhood,
            hintStyle: ThemeService.getDynamicStyle(context, color: Colors.grey[600]),
          ),
          items: _getAvailableNeighborhoods().map((neighborhood) {
            return DropdownMenuItem(
              value: neighborhood,
              child: Text(neighborhood, style: ThemeService.getDynamicStyle(context, color: Colors.black87)),
            );
          }).toList(),
          onChanged: _selectedCity == null ? null : (value) {
            setModalState(() {
              _selectedNeighborhood = value;
              _notifyFilterValuesChanged();
            });
          },
        ),

        const SizedBox(height: 16),

        // Bedrooms
        Text(l10n?.bedrooms ?? 'Bedrooms',
            style: ThemeService.getDynamicStyle(context, fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          initialValue: _selectedBedrooms,
          dropdownColor: Colors.white,
          style: ThemeService.getDynamicStyle(context, color: Colors.black87),
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: l10n?.bedrooms,
            hintStyle: ThemeService.getDynamicStyle(context, color: Colors.grey[600]),
          ),
          items: [1, 2, 3, 4, 5, 6, 7, 8, 9].map((bedrooms) {
            return DropdownMenuItem(
              value: bedrooms,
              child: Text('${l10n?.bedroomsCount(bedrooms)}', style: ThemeService.getDynamicStyle(context, color: Colors.black87)),
            );
          }).toList(),
          onChanged: (value) {
            setModalState(() {
              _selectedBedrooms = value;
              _notifyFilterValuesChanged();
            });
          },
        ),

        const SizedBox(height: 16),

        // Bathrooms
        Text(l10n?.bathrooms ?? 'Bathrooms',
            style: ThemeService.getDynamicStyle(context, fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          initialValue: _selectedBathrooms,
          dropdownColor: Colors.white,
          style: ThemeService.getDynamicStyle(context, color: Colors.black87),
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: l10n?.bathrooms,
            hintStyle: ThemeService.getDynamicStyle(context, color: Colors.grey[600]),
          ),
          items: [1, 2, 3, 4, 5, 6, 7, 8, 9].map((bathrooms) {
            return DropdownMenuItem(
              value: bathrooms,
              child: Text('${l10n?.bathroomsCount(bathrooms)}', style: ThemeService.getDynamicStyle(context, color: Colors.black87)),
            );
          }).toList(),
          onChanged: (value) {
            setModalState(() {
              _selectedBathrooms = value;
              _notifyFilterValuesChanged();
            });
          },
        ),

        const SizedBox(height: 16),

        // Kitchens
        Text(l10n?.kitchens ?? 'Kitchens',
            style: ThemeService.getDynamicStyle(context, fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          initialValue: _selectedKitchens,
          dropdownColor: Colors.white,
          style: ThemeService.getDynamicStyle(context, color: Colors.black87),
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: l10n?.kitchens,
            hintStyle: ThemeService.getDynamicStyle(context, color: Colors.grey[600]),
          ),
          items: [1, 2, 3, 4, 5, 6].map((kitchens) {
            return DropdownMenuItem(
              value: kitchens,
              child: Text('$kitchens', style: ThemeService.getDynamicStyle(context, color: Colors.black87)),
            );
          }).toList(),
          onChanged: (value) {
            setModalState(() {
              _selectedKitchens = value;
              _notifyFilterValuesChanged();
            });
          },
        ),

        const SizedBox(height: 16),

        // Size Range
        Text(l10n?.sizeRange ?? 'Size Range (m²)',
            style: ThemeService.getDynamicStyle(context, fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _minSizeController,
                keyboardType: TextInputType.number,
                style: ThemeService.getBodyStyle(
                  context,
                  color: Colors.black87,
                ),
                inputFormatters: [PriceFormatter()],
                decoration: InputDecoration(
                  labelText: '${(l10n?.sizeRange ?? 'Size (m²)').split('(').first}(Min)',
                  labelStyle: ThemeService.getBodyStyle(context),
                  hintText: '0',
                   hintStyle: ThemeService.getDynamicStyle(context, color: Colors.grey[600]),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) {},
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _maxSizeController,
                keyboardType: TextInputType.number,
                style: ThemeService.getBodyStyle(
                  context,
                  color: Colors.black87,
                ),
                inputFormatters: [PriceFormatter()],
                decoration: InputDecoration(
                  labelText: '${(l10n?.sizeRange ?? 'Size (m²)').split('(').first}(Max)',
                  labelStyle: ThemeService.getBodyStyle(context),
                  hintText: '10,000',
                  hintStyle: ThemeService.getDynamicStyle(context, color: Colors.grey[600]),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) {},
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Action buttons row
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  _clearFilters();
                  if (mounted && Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF01352D),
                  side: const BorderSide(color: Color(0xFF01352D)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(l10n?.clearFilters ?? 'Clear Filters'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  _notifyFilterValuesChanged();
                  await _applyFilters();
                  if (mounted && Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF01352D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(l10n?.applyFilters ?? 'Apply Filters'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showAdvancedFilters() {
    final l10n = AppLocalizations.of(context);
    // This method opens the full advanced filters directly
    Navigator.pop(context); // Close the simple search modal
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n?.advancedFilters ?? 'Advanced Filters',
                    style: ThemeService.getHeadingStyle(context, fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 24),

                // Property Type
                Text(l10n?.propertyType ?? 'Property Type',
                    style: ThemeService.getDynamicStyle(context, fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                const SizedBox(height: 8),
                 DropdownButtonFormField<PropertyType>(
                   initialValue: _selectedType,
                   dropdownColor: Colors.white,
                   style: ThemeService.getDynamicStyle(context, color: Colors.black87),
                   decoration: InputDecoration(
                     border: const OutlineInputBorder(),
                     hintText: l10n?.propertyType,
                     hintStyle: ThemeService.getDynamicStyle(context, color: Colors.grey[600]),
                   ),
                   items: PropertyType.values.map((type) {
                     return DropdownMenuItem(
                       value: type,
                       child: Text(type.getLocalizedName(context), style: ThemeService.getDynamicStyle(context, color: Colors.black87)),
                     );
                   }).toList(),
                   onChanged: (value) {
                     setModalState(() => _selectedType = value);
                     _applyFilters();
                   },
                 ),

                const SizedBox(height: 16),

                // Status
                Text(l10n?.propertyStatus ?? 'Property Status',
                    style: ThemeService.getDynamicStyle(context, fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                const SizedBox(height: 8),
                 DropdownButtonFormField<PropertyStatus>(
                   initialValue: _selectedStatus,
                   dropdownColor: Colors.white,
                   style: ThemeService.getDynamicStyle(context, color: Colors.black87),
                   decoration: InputDecoration(
                     border: const OutlineInputBorder(),
                     hintText: l10n?.propertyStatus,
                     hintStyle: ThemeService.getDynamicStyle(context, color: Colors.grey[600]),
                   ),
                   items: PropertyStatus.values.map((status) {
                     return DropdownMenuItem(
                       value: status,
                       child: Text(status.getLocalizedName(context), style: ThemeService.getDynamicStyle(context, color: Colors.black87)),
                     );
                   }).toList(),
                   onChanged: (value) {
                     setModalState(() => _selectedStatus = value);
                     _applyFilters();
                   },
                 ),

                const SizedBox(height: 16),

                // Price Range
                Text(l10n?.priceRangeLyd ?? 'Price Range (LYD)',
                    style: ThemeService.getDynamicStyle(context, fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _minPriceController,
                        keyboardType: TextInputType.number,
                        style: ThemeService.getBodyStyle(
                          context,
                          color: Colors.black87,
                        ),
                        decoration: InputDecoration(
                          labelText: '${(l10n?.priceRangeLyd ?? 'Price (LYD)').split('(').first}(Min)',
                          labelStyle: ThemeService.getBodyStyle(context),
                          hintText: '0',
                          hintStyle: ThemeService.getDynamicStyle(context, color: Colors.grey[600]),
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (value) {},
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _maxPriceController,
                        keyboardType: TextInputType.number,
                        style: ThemeService.getBodyStyle(
                          context,
                          color: Colors.black87,
                        ),
                        decoration: InputDecoration(
                          labelText: '${(l10n?.priceRangeLyd ?? 'Price (LYD)').split('(').first}(Max)',
                          labelStyle: ThemeService.getBodyStyle(context),
                          hintText: '10,000,000',
                           hintStyle: ThemeService.getDynamicStyle(context, color: Colors.grey[600]),
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (value) {},
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // City
                Text(l10n?.city ?? 'City',
                    style: ThemeService.getDynamicStyle(context, fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                const SizedBox(height: 8),
                 DropdownButtonFormField<String>(
                   initialValue: _selectedCity,
                   dropdownColor: Colors.white,
                   style: ThemeService.getDynamicStyle(context, color: Colors.black87),
                   decoration: InputDecoration(
                     border: const OutlineInputBorder(),
                     hintText: l10n?.city,
                     hintStyle: ThemeService.getDynamicStyle(context, color: Colors.grey[600]),
                   ),
                   items: _libyanCities.map((city) {
                     return DropdownMenuItem(
                       value: city,
                       child: Text(
                         CityLocalizer.getBilingualCityName(city),
                         style: ThemeService.getDynamicStyle(context, color: Colors.black87),
                       ),
                     );
                   }).toList(),
                   onChanged: (value) {
                     setModalState(() {
                       _selectedCity = value;
                       _selectedNeighborhood = null; // Reset neighborhood when city changes
                     });
                     _applyFilters();
                   },
                ),

                const SizedBox(height: 16),

                // Neighborhood
                Text(l10n?.neighborhood ?? 'Neighborhood',
                    style: ThemeService.getDynamicStyle(context, fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedNeighborhood,
                  dropdownColor: Colors.white,
                  style: ThemeService.getDynamicStyle(context, color: Colors.black87),
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: _selectedCity == null ? l10n?.city : l10n?.neighborhood,
                    hintStyle: ThemeService.getDynamicStyle(context, color: Colors.grey[600]),
                  ),
                  items: _getAvailableNeighborhoods().map((neighborhood) {
                    return DropdownMenuItem(
                      value: neighborhood,
                      child: Text(neighborhood, style: ThemeService.getDynamicStyle(context, color: Colors.black87)),
                    );
                  }).toList(),
                  onChanged: _selectedCity == null ? null : (value) {
                    setModalState(() => _selectedNeighborhood = value);
                     _applyFilters();
                   },
                ),

                const SizedBox(height: 16),

                // Bedrooms
                Text(l10n?.bedrooms ?? 'Bedrooms',
                    style: ThemeService.getDynamicStyle(context, fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  initialValue: _selectedBedrooms,
                  dropdownColor: Colors.white,
                  style: ThemeService.getDynamicStyle(context, color: Colors.black87),
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: l10n?.bedrooms,
                    hintStyle: ThemeService.getDynamicStyle(context, color: Colors.grey[600]),
                  ),
                  items: [1, 2, 3, 4, 5, 6, 7, 8, 9].map((bedrooms) {
                    return DropdownMenuItem(
                      value: bedrooms,
                      child: Text(l10n?.bedroomsCount(bedrooms) ?? '$bedrooms Bedrooms', style: ThemeService.getDynamicStyle(context, color: Colors.black87)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setModalState(() => _selectedBedrooms = value);
                    _applyFilters();
                  },
                ),

                const SizedBox(height: 16),

                // Bathrooms
                Text(l10n?.bathrooms ?? 'Bathrooms',
                    style: ThemeService.getDynamicStyle(context, fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  initialValue: _selectedBathrooms,
                  dropdownColor: Colors.white,
                  style: ThemeService.getDynamicStyle(context, color: Colors.black87),
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: l10n?.bathrooms,
                    hintStyle: ThemeService.getDynamicStyle(context, color: Colors.grey[600]),
                  ),
                  items: [1, 2, 3, 4, 5, 6, 7, 8, 9].map((bathrooms) {
                    return DropdownMenuItem(
                      value: bathrooms,
                      child: Text(l10n?.bathroomsCount(bathrooms) ?? '$bathrooms Bathrooms', style: ThemeService.getDynamicStyle(context, color: Colors.black87)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setModalState(() => _selectedBathrooms = value);
                    _applyFilters();
                  },
                ),

                const SizedBox(height: 16),

                // Kitchens
                Text(l10n?.kitchens ?? 'Kitchens',
                    style: ThemeService.getDynamicStyle(context, fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  initialValue: _selectedKitchens,
                  dropdownColor: Colors.white,
                  style: ThemeService.getDynamicStyle(context, color: Colors.black87),
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: l10n?.kitchens,
                    hintStyle: ThemeService.getDynamicStyle(context, color: Colors.grey[600]),
                  ),
                  items: [1, 2, 3, 4, 5, 6].map((kitchens) {
                    return DropdownMenuItem(
                      value: kitchens,
                      child: Text('$kitchens', style: ThemeService.getDynamicStyle(context, color: Colors.black87)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setModalState(() => _selectedKitchens = value);
                    _applyFilters();
                  },
                ),

                const SizedBox(height: 16),

                // Size Range
                Text(l10n?.sizeRange ?? 'Size Range (m²)',
                    style: ThemeService.getDynamicStyle(context, fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _minSizeController,
                        keyboardType: TextInputType.number,
                        style: ThemeService.getBodyStyle(
                          context,
                          color: Colors.black87,
                        ),
                        decoration: InputDecoration(
                          labelText: '${(l10n?.sizeRange ?? 'Size (m²)').split('(').first}(Min)',
                          labelStyle: ThemeService.getBodyStyle(context),
                          hintText: '0',
                          hintStyle: ThemeService.getDynamicStyle(context, color: Colors.grey[600]),
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (value) {},
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _maxSizeController,
                        keyboardType: TextInputType.number,
                        style: ThemeService.getBodyStyle(
                          context,
                          color: Colors.black87,
                        ),
                        decoration: InputDecoration(
                          labelText: '${(l10n?.sizeRange ?? 'Size (m²)').split('(').first}(Max)',
                          labelStyle: ThemeService.getBodyStyle(context),
                          hintText: '10,000',
                          hintStyle: ThemeService.getDynamicStyle(context, color: Colors.grey[600]),
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (value) {},
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Action buttons row
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _clearFilters();
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF01352D),
                          side: const BorderSide(color: Color(0xFF01352D)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(l10n?.clearFilters ?? 'Clear Filters'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          // Save filter values first
                          _notifyFilterValuesChanged();
                          // Apply filters
                          await _applyFilters();
                          // Small delay to ensure state updates complete
                          await Future.delayed(const Duration(milliseconds: 50));
                          if (mounted && Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                        },


                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF01352D),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(l10n?.applyFilters ?? 'Apply Filters'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
