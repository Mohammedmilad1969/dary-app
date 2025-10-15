import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../models/property.dart';
import '../providers/auth_provider.dart';
import '../services/saved_search_service.dart';

class PropertySearchFilter extends StatefulWidget {
  final Function(List<Property>) onFilterChanged;
  final List<Property> allProperties;
  final VoidCallback? onCombinedFilter;
  final String? currentRentSellFilter;
  final VoidCallback? onClearAllFilters;

  const PropertySearchFilter({
    super.key,
    required this.onFilterChanged,
    required this.allProperties,
    this.onCombinedFilter,
    this.currentRentSellFilter,
    this.onClearAllFilters,
  });

  @override
  State<PropertySearchFilter> createState() => _PropertySearchFilterState();
}

class _PropertySearchFilterState extends State<PropertySearchFilter> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  PropertyType? _selectedType;
  PropertyStatus? _selectedStatus;
  String? _selectedCity;
  RangeValues _priceRange = const RangeValues(0, 10000000); // Increased to 10M LYD
  bool _showFeaturedOnly = false;
  
  // Property Features
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
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyFilters();
    });
  }

  void _onSearchChanged() {
    // Cancel previous timer
    _debounceTimer?.cancel();
    
    // If search is empty, apply filters immediately
    if (_searchController.text.isEmpty) {
      _applyFilters();
    } else {
      // Debounce search for 300ms
      _debounceTimer = Timer(const Duration(milliseconds: 300), () {
        _applyFilters();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _applyFilters() {
    List<Property> filteredProperties = widget.allProperties;

    // Apply Rent/Sell filter first if active
    if (widget.currentRentSellFilter != null) {
      switch (widget.currentRentSellFilter!.toLowerCase()) {
        case 'rent':
          filteredProperties = filteredProperties.where((p) => p.status == PropertyStatus.forRent).toList();
          break;
        case 'sell':
          filteredProperties = filteredProperties.where((p) => p.status == PropertyStatus.forSale).toList();
          break;
      }
    }

    // Apply search filter - more flexible matching with boosted property prioritization
    if (_searchController.text.isNotEmpty) {
      final searchTerm = _searchController.text.toLowerCase().trim();
      
      // Split search term into words for better matching
      final searchWords = searchTerm.split(' ').where((word) => word.isNotEmpty).toList();
      
      // Create a list with relevance scores for boosted properties
      final List<MapEntry<Property, int>> propertyScores = [];
      
      for (final property in filteredProperties) {
        // Create a comprehensive searchable text that includes all relevant fields
        final searchableText = '${property.title} ${property.description} ${property.city} ${property.neighborhood} ${property.type.name} ${property.status.name} ${property.type.typeDisplayName}'.toLowerCase();
        
        // Calculate relevance score
        int score = 0;
        bool matchesAllWords = true;
        
        for (final word in searchWords) {
          bool wordMatched = false;
          
          // Direct match
          if (searchableText.contains(word)) {
            score += 10;
            wordMatched = true;
          }
          
          // Partial match for longer words (minimum 3 characters)
          if (word.length >= 3) {
            final partialMatch = searchableText.split(' ').any((textWord) => 
              textWord.startsWith(word) || word.startsWith(textWord)
            );
            if (partialMatch) {
              score += 5;
              wordMatched = true;
            }
          }
          
          if (!wordMatched) {
            matchesAllWords = false;
            break;
          }
        }
        
        // Boost score for boosted properties (significant boost for visibility)
        if (property.isBoosted) {
          score += 100; // High priority boost
        }
        
        // Only include properties that match all search words
        if (matchesAllWords) {
          propertyScores.add(MapEntry(property, score));
        }
      }
      
      // Sort by relevance score (highest first) - boosted properties will be at top
      propertyScores.sort((a, b) => b.value.compareTo(a.value));
      
      // Extract properties in sorted order
      filteredProperties = propertyScores.map((entry) => entry.key).toList();
    } else {
      // If search is empty, show all properties (no additional filtering needed)
    }

    // Apply type filter
    if (_selectedType != null) {
      filteredProperties = filteredProperties.where((p) => p.type == _selectedType).toList();
    }

    // Apply status filter
    if (_selectedStatus != null) {
      filteredProperties = filteredProperties.where((p) => p.status == _selectedStatus).toList();
    }

    // Apply city filter
    if (_selectedCity != null && _selectedCity!.isNotEmpty) {
      filteredProperties = filteredProperties.where((p) => p.city == _selectedCity).toList();
    }

    // Apply price range filter
    filteredProperties = filteredProperties.where((p) {
      double price = p.status == PropertyStatus.forRent ? p.monthlyRent : p.price;
      return price >= _priceRange.start && price <= _priceRange.end;
    }).toList();

    // Apply featured filter
    if (_showFeaturedOnly) {
      filteredProperties = filteredProperties.where((p) => p.isFeatured).toList();
    }

    // Apply feature filters
    if (_hasBalcony) {
      filteredProperties = filteredProperties.where((p) => p.hasBalcony).toList();
    }
    if (_hasGarden) {
      filteredProperties = filteredProperties.where((p) => p.hasGarden).toList();
    }
    if (_hasParking) {
      filteredProperties = filteredProperties.where((p) => p.hasParking).toList();
    }
    if (_hasPool) {
      filteredProperties = filteredProperties.where((p) => p.hasPool).toList();
    }
    if (_hasGym) {
      filteredProperties = filteredProperties.where((p) => p.hasGym).toList();
    }
    if (_hasSecurity) {
      filteredProperties = filteredProperties.where((p) => p.hasSecurity).toList();
    }
    if (_hasElevator) {
      filteredProperties = filteredProperties.where((p) => p.hasElevator).toList();
    }
    if (_hasAC) {
      filteredProperties = filteredProperties.where((p) => p.hasAC).toList();
    }
    if (_hasHeating) {
      filteredProperties = filteredProperties.where((p) => p.hasHeating).toList();
    }
    if (_hasFurnished) {
      filteredProperties = filteredProperties.where((p) => p.hasFurnished).toList();
    }

    // Sort properties with boosted ones at the top (final sort to ensure boosted properties always appear first)
    final mutableList = List<Property>.from(filteredProperties);
    mutableList.sort((a, b) {
      // Boosted properties always come first
      if (a.isBoosted && !b.isBoosted) return -1;
      if (!a.isBoosted && b.isBoosted) return 1;
      
      // If both are boosted or both are not boosted, maintain original order
      return 0;
    });

    widget.onFilterChanged(mutableList);
  }


  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedType = null;
      _selectedStatus = null;
      _selectedCity = null;
      _priceRange = const RangeValues(0, 2000000);
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
    
    // Don't call _applyFilters() here because _clearAllFilters() handles the property update
  }

  Future<void> _saveCurrentSearch() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to save searches'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show dialog to get search name
    final nameController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Search'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter a name for this search:'),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                hintText: 'e.g., "Apartments in Tripoli"',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                Navigator.of(context).pop(true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed == true && nameController.text.trim().isNotEmpty) {
      final savedSearchService = SavedSearchService();
      
      // Create filters map
      final filters = <String, dynamic>{
        'searchQuery': _searchController.text.trim(),
        'priceRange': {
          'min': _priceRange.start,
          'max': _priceRange.end,
        },
        'features': <String>[],
      };

      // Add type filter
      if (_selectedType != null) {
        filters['type'] = _selectedType!.typeDisplayName.toLowerCase();
      }

      // Add status filter
      if (_selectedStatus != null) {
        filters['status'] = _selectedStatus.toString().split('.').last;
      }

      // Add city filter
      if (_selectedCity != null && _selectedCity!.isNotEmpty) {
        filters['city'] = _selectedCity!;
      }

      // Add feature filters
      final features = <String>[];
      if (_hasBalcony) features.add('hasBalcony');
      if (_hasGarden) features.add('hasGarden');
      if (_hasParking) features.add('hasParking');
      if (_hasPool) features.add('hasPool');
      if (_hasGym) features.add('hasGym');
      if (_hasSecurity) features.add('hasSecurity');
      if (_hasElevator) features.add('hasElevator');
      if (_hasAC) features.add('hasAC');
      if (_hasHeating) features.add('hasHeating');
      if (_hasFurnished) features.add('hasFurnished');
      filters['features'] = features;

      // Save the search
      final success = await savedSearchService.saveSearch(
        userId: currentUser.id,
        name: nameController.text.trim(),
        filters: filters,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success 
                  ? 'Search saved successfully!'
                  : 'Failed to save search',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[50]!, Colors.green[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.15),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                hintText: l10n?.searchProperties ?? 'Search properties...',
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 16,
                ),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[600],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.search,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.clear,
                            color: Colors.grey,
                            size: 16,
                          ),
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _applyFilters();
                        },
                      ),
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        if (!authProvider.isAuthenticated) return const SizedBox.shrink();
                        
                        return IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.green[600],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.bookmark_add,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          onPressed: _saveCurrentSearch,
                          tooltip: 'Save Search',
                        );
                      },
                    ),
                  ],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.green[400]!, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Compact Action Buttons Row
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: TextButton.icon(
                    onPressed: _clearFilters,
                    icon: Icon(Icons.clear_all, size: 18, color: Colors.green[600]),
                    label: Text(
                      l10n?.clearFilters ?? 'Clear Filters',
                      style: TextStyle(
                        color: Colors.green[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green[600]!, Colors.green[700]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextButton.icon(
                    onPressed: () {
                      _showAdvancedFilters();
                    },
                    icon: const Icon(Icons.tune, size: 18, color: Colors.white),
                    label: Text(
                      l10n?.advancedFilters ?? 'Advanced',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAdvancedFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Text(
                AppLocalizations.of(context)?.advancedFilters ?? 'Advanced Filters',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              
              // Property Type Selection
              Text(
                AppLocalizations.of(context)?.propertyType ?? 'Property Type',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<PropertyType>(
                value: _selectedType,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Select property type',
                ),
                items: PropertyType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.typeDisplayName),
                  );
                }).toList(),
                onChanged: (value) {
                  setModalState(() {
                    _selectedType = value;
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              // Status Selection
              Text(
                AppLocalizations.of(context)?.propertyStatus ?? 'Property Status',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<PropertyStatus>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Select status',
                ),
                items: PropertyStatus.values.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status.statusDisplayName),
                  );
                }).toList(),
                onChanged: (value) {
                  setModalState(() {
                    _selectedStatus = value;
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              // Price Range
              Text(
                AppLocalizations.of(context)?.priceRange ?? 'Price Range',
                style: TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.w600,
                  color: Colors.green[700],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  children: [
                    RangeSlider(
                      values: _priceRange,
                      min: 0,
                      max: 2000000,
                      divisions: 20,
                      labels: RangeLabels(
                        '\$${(_priceRange.start / 1000).round()}K',
                        '\$${(_priceRange.end / 1000).round()}K',
                      ),
                      activeColor: Colors.green,
                      inactiveColor: Colors.green[200],
                      onChanged: (values) {
                        setModalState(() {
                          _priceRange = values;
                        });
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$${(_priceRange.start / 1000).round()}K',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '\$${(_priceRange.end / 1000).round()}K',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Property Features
              Text(
                'Property Features',
                style: TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.w600,
                  color: Colors.green[700],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  children: [
                    _buildFeatureSwitch('Balcony', Icons.balcony, _hasBalcony, (value) {
                      setModalState(() {
                        _hasBalcony = value;
                      });
                    }),
                    _buildFeatureSwitch('Garden', Icons.yard, _hasGarden, (value) {
                      setModalState(() {
                        _hasGarden = value;
                      });
                    }),
                    _buildFeatureSwitch('Parking', Icons.local_parking, _hasParking, (value) {
                      setModalState(() {
                        _hasParking = value;
                      });
                    }),
                    _buildFeatureSwitch('Pool', Icons.pool, _hasPool, (value) {
                      setModalState(() {
                        _hasPool = value;
                      });
                    }),
                    _buildFeatureSwitch('Gym', Icons.fitness_center, _hasGym, (value) {
                      setModalState(() {
                        _hasGym = value;
                      });
                    }),
                    _buildFeatureSwitch('Security', Icons.security, _hasSecurity, (value) {
                      setModalState(() {
                        _hasSecurity = value;
                      });
                    }),
                    _buildFeatureSwitch('Elevator', Icons.elevator, _hasElevator, (value) {
                      setModalState(() {
                        _hasElevator = value;
                      });
                    }),
                    _buildFeatureSwitch('AC', Icons.ac_unit, _hasAC, (value) {
                      setModalState(() {
                        _hasAC = value;
                      });
                    }),
                    _buildFeatureSwitch('Heating', Icons.thermostat, _hasHeating, (value) {
                      setModalState(() {
                        _hasHeating = value;
                      });
                    }),
                    _buildFeatureSwitch('Furnished', Icons.chair, _hasFurnished, (value) {
                      setModalState(() {
                        _hasFurnished = value;
                      });
                    }),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Apply Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      // Update the main state with modal state
                    });
                    _applyFilters();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(AppLocalizations.of(context)?.applyFilters ?? 'Apply Filters'),
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureSwitch(String title, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(
        title,
        style: TextStyle(
          color: Colors.green[700],
          fontWeight: FontWeight.w500,
        ),
      ),
      secondary: Icon(
        icon, 
        size: 20,
        color: Colors.green[600],
      ),
      value: value,
      onChanged: onChanged,
      activeColor: Colors.green,
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }
}
