import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:dary/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../models/property.dart';
import '../providers/auth_provider.dart';
import '../services/saved_search_service.dart';
import '../services/theme_service.dart';
import '../utils/text_input_formatters.dart';

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
  final int? initialBedrooms;
  final int? initialBathrooms;
  final int? initialKitchens;
  final String? initialMinPrice;
  final String? initialMaxPrice;
  final String? initialMinSize;
  final String? initialMaxSize;

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
    this.initialBedrooms,
    this.initialBathrooms,
    this.initialKitchens,
    this.initialMinPrice,
    this.initialMaxPrice,
    this.initialMinSize,
    this.initialMaxSize,
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
  int? _selectedBedrooms;
  int? _selectedBathrooms;
  int? _selectedKitchens;
  bool _showFeaturedOnly = false;

  static const List<String> _libyanCities = [
    'Tripoli',
    'Benghazi',
    'Misrata',
    'Zawiya',
    'Sirte',
    'Sabha',
    'Tobruk',
    'Derna',
    'Al Bayda',
    'Al Marj',
    'Gharyan',
    'Zliten',
    'Khoms',
    'Tarhuna',
    'Ajdabiya',
    'Murzuq',
    'Ghat',
    'Ubari',
    'Al Kufra',
    'Al Jufra',
  ];

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

  @override
  void initState() {
    super.initState();
    // Initialize with provided initial values to preserve state
    _searchController.text = widget.initialSearchText ?? '';
    _selectedType = widget.initialType;
    _selectedStatus = widget.initialStatus;
    _selectedCity = widget.initialCity;
    _selectedBedrooms = widget.initialBedrooms;
    _selectedBathrooms = widget.initialBathrooms;
    _selectedKitchens = widget.initialKitchens;
    _minPriceController.text = widget.initialMinPrice ?? '';
    _maxPriceController.text = widget.initialMaxPrice ?? '';
    _minSizeController.text = widget.initialMinSize ?? '';
    _maxSizeController.text = widget.initialMaxSize ?? '';
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
      widget.onFilterValuesChanged!({
        'searchText': _searchController.text,
        'type': _selectedType,
        'status': _selectedStatus,
        'city': _selectedCity,
        'bedrooms': _selectedBedrooms,
        'bathrooms': _selectedBathrooms,
        'kitchens': _selectedKitchens,
        'minPrice': _minPriceController.text,
        'maxPrice': _maxPriceController.text,
        'minSize': _minSizeController.text,
        'maxSize': _maxSizeController.text,
      });
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

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedType = null;
      _selectedStatus = null;
      _selectedCity = null;
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
    });
    
    // Notify parent to clear Rent/Sell filter as well
    widget.onClearAllFilters?.call();
    
    // Apply filters to show all properties
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    // Return the full advanced filters interface directly
    return StatefulBuilder(
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
              const Text('Advanced Filters',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 24),
              _buildAdvancedFiltersContent(context, setModalState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdvancedFiltersContent(BuildContext context, StateSetter setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Property Type
        const Text('Property Type',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 8),
        DropdownButtonFormField<PropertyType>(
          value: _selectedType,
          dropdownColor: Colors.white,
          style: const TextStyle(color: Colors.black87),
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Select property type',
            hintStyle: TextStyle(color: Colors.grey[600]),
          ),
          items: PropertyType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(type.typeDisplayName, style: const TextStyle(color: Colors.black87)),
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
        const Text('Property Status',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 8),
        DropdownButtonFormField<PropertyStatus>(
          value: _selectedStatus,
          dropdownColor: Colors.white,
          style: const TextStyle(color: Colors.black87),
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Select status',
            hintStyle: TextStyle(color: Colors.grey[600]),
          ),
          items: PropertyStatus.values.map((status) {
            return DropdownMenuItem(
              value: status,
              child: Text(status.statusDisplayName, style: const TextStyle(color: Colors.black87)),
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
        const Text('Price Range (LYD)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
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
                  labelText: 'Min Price (LYD)',
                  labelStyle: ThemeService.getBodyStyle(context),
                  hintText: '0',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  border: OutlineInputBorder(),
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
                  labelText: 'Max Price (LYD)',
                  labelStyle: ThemeService.getBodyStyle(context),
                  hintText: '10000000',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {},
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // City
        const Text('City',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedCity,
          dropdownColor: Colors.white,
          style: const TextStyle(color: Colors.black87),
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Select city',
            hintStyle: TextStyle(color: Colors.grey[600]),
          ),
          items: _libyanCities.map((city) {
            return DropdownMenuItem(
              value: city,
              child: Text(city, style: const TextStyle(color: Colors.black87)),
            );
          }).toList(),
          onChanged: (value) {
            setModalState(() {
              _selectedCity = value;
              _notifyFilterValuesChanged();
            });
          },
        ),

        const SizedBox(height: 16),

        // Bedrooms
        const Text('Bedrooms',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: _selectedBedrooms,
          dropdownColor: Colors.white,
          style: const TextStyle(color: Colors.black87),
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Select bedrooms',
            hintStyle: TextStyle(color: Colors.grey[600]),
          ),
          items: [1, 2, 3, 4, 5, 6, 7, 8, 9].map((bedrooms) {
            return DropdownMenuItem(
              value: bedrooms,
              child: Text('$bedrooms', style: const TextStyle(color: Colors.black87)),
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
        const Text('Bathrooms',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: _selectedBathrooms,
          dropdownColor: Colors.white,
          style: const TextStyle(color: Colors.black87),
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Select bathrooms',
            hintStyle: TextStyle(color: Colors.grey[600]),
          ),
          items: [1, 2, 3, 4, 5, 6, 7, 8, 9].map((bathrooms) {
            return DropdownMenuItem(
              value: bathrooms,
              child: Text('$bathrooms', style: const TextStyle(color: Colors.black87)),
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
        const Text('Kitchens',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: _selectedKitchens,
          dropdownColor: Colors.white,
          style: const TextStyle(color: Colors.black87),
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Select kitchens',
            hintStyle: TextStyle(color: Colors.grey[600]),
          ),
          items: [1, 2, 3, 4, 5, 6].map((kitchens) {
            return DropdownMenuItem(
              value: kitchens,
              child: Text('$kitchens', style: const TextStyle(color: Colors.black87)),
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
        const Text('Size Range (m²)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
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
                  labelText: 'Min Size (m²)',
                  labelStyle: ThemeService.getBodyStyle(context),
                  hintText: '0',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  border: OutlineInputBorder(),
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
                  labelText: 'Max Size (m²)',
                  labelStyle: ThemeService.getBodyStyle(context),
                  hintText: '10000',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  border: OutlineInputBorder(),
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
                  foregroundColor: Colors.green[700],
                  side: BorderSide(color: Colors.green[700]!),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Clear Filters'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  await _applyFilters();
                  if (mounted && Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Apply Filters'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showAdvancedFilters() {
    // This method opens the full advanced filters directly
    Navigator.pop(context); // Close the simple search modal
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Advanced Filters',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 24),

                // Property Type
                const Text('Property Type',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                const SizedBox(height: 8),
                 DropdownButtonFormField<PropertyType>(
                   value: _selectedType,
                   dropdownColor: Colors.white,
                   style: const TextStyle(color: Colors.black87),
                   decoration: InputDecoration(
                     border: OutlineInputBorder(),
                     hintText: 'Select property type',
                     hintStyle: TextStyle(color: Colors.grey[600]),
                   ),
                   items: PropertyType.values.map((type) {
                     return DropdownMenuItem(
                       value: type,
                       child: Text(type.typeDisplayName, style: const TextStyle(color: Colors.black87)),
                     );
                   }).toList(),
                   onChanged: (value) {
                     setModalState(() => _selectedType = value);
                     _applyFilters();
                   },
                 ),

                const SizedBox(height: 16),

                // Status
                const Text('Property Status',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                const SizedBox(height: 8),
                 DropdownButtonFormField<PropertyStatus>(
                   value: _selectedStatus,
                   dropdownColor: Colors.white,
                   style: const TextStyle(color: Colors.black87),
                   decoration: InputDecoration(
                     border: OutlineInputBorder(),
                     hintText: 'Select status',
                     hintStyle: TextStyle(color: Colors.grey[600]),
                   ),
                   items: PropertyStatus.values.map((status) {
                     return DropdownMenuItem(
                       value: status,
                       child: Text(status.statusDisplayName, style: const TextStyle(color: Colors.black87)),
                     );
                   }).toList(),
                   onChanged: (value) {
                     setModalState(() => _selectedStatus = value);
                     _applyFilters();
                   },
                 ),

                const SizedBox(height: 16),

                // Price Range
                const Text('Price Range (LYD)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
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
                          labelText: 'Min Price (LYD)',
                          labelStyle: ThemeService.getBodyStyle(context),
                          hintText: '0',
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          border: OutlineInputBorder(),
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
                          labelText: 'Max Price (LYD)',
                          labelStyle: ThemeService.getBodyStyle(context),
                          hintText: '10000000',
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {},
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // City
                const Text('City',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                const SizedBox(height: 8),
                 DropdownButtonFormField<String>(
                   value: _selectedCity,
                   dropdownColor: Colors.white,
                   style: const TextStyle(color: Colors.black87),
                   decoration: InputDecoration(
                     border: OutlineInputBorder(),
                     hintText: 'Select city',
                     hintStyle: TextStyle(color: Colors.grey[600]),
                   ),
                   items: _libyanCities.map((city) {
                     return DropdownMenuItem(
                       value: city,
                       child: Text(city, style: const TextStyle(color: Colors.black87)),
                     );
                   }).toList(),
                   onChanged: (value) {
                     setModalState(() => _selectedCity = value);
                     _applyFilters();
                   },
                ),

                const SizedBox(height: 16),

                // Bedrooms
                const Text('Bedrooms',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: _selectedBedrooms,
                  dropdownColor: Colors.white,
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Select bedrooms',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                  ),
                  items: [1, 2, 3, 4, 5, 6, 7, 8, 9].map((bedrooms) {
                    return DropdownMenuItem(
                      value: bedrooms,
                      child: Text('$bedrooms', style: const TextStyle(color: Colors.black87)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setModalState(() => _selectedBedrooms = value);
                    _applyFilters();
                  },
                ),

                const SizedBox(height: 16),

                // Bathrooms
                const Text('Bathrooms',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: _selectedBathrooms,
                  dropdownColor: Colors.white,
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Select bathrooms',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                  ),
                  items: [1, 2, 3, 4, 5, 6, 7, 8, 9].map((bathrooms) {
                    return DropdownMenuItem(
                      value: bathrooms,
                      child: Text('$bathrooms', style: const TextStyle(color: Colors.black87)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setModalState(() => _selectedBathrooms = value);
                    _applyFilters();
                  },
                ),

                const SizedBox(height: 16),

                // Kitchens
                const Text('Kitchens',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: _selectedKitchens,
                  dropdownColor: Colors.white,
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Select kitchens',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                  ),
                  items: [1, 2, 3, 4, 5, 6].map((kitchens) {
                    return DropdownMenuItem(
                      value: kitchens,
                      child: Text('$kitchens', style: const TextStyle(color: Colors.black87)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setModalState(() => _selectedKitchens = value);
                    _applyFilters();
                  },
                ),

                const SizedBox(height: 16),

                // Size Range
                const Text('Size Range (m²)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
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
                          labelText: 'Min Size (m²)',
                          labelStyle: ThemeService.getBodyStyle(context),
                          hintText: '0',
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          border: OutlineInputBorder(),
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
                          labelText: 'Max Size (m²)',
                          labelStyle: ThemeService.getBodyStyle(context),
                          hintText: '10000',
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          border: OutlineInputBorder(),
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
                          foregroundColor: Colors.green[700],
                          side: BorderSide(color: Colors.green[700]!),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Clear Filters'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          setState(() {});
                          await _applyFilters();
                          if (mounted && Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Apply Filters'),
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
