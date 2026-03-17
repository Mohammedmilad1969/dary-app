import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' as io show File;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/property.dart';
import '../services/language_service.dart';
import '../providers/auth_provider.dart';
import '../services/property_service.dart' as property_service;
import '../services/persistence_service.dart';
import '../services/image_upload_service.dart';
import '../services/theme_service.dart';
import '../features/paywall/paywall_screens.dart';
import '../services/wallet_service.dart';
import '../utils/text_input_formatters.dart';
import '../utils/city_localizer.dart';
import '../models/user_profile.dart';
import '../widgets/dary_loading_indicator.dart';

// Libya timezone (GMT+2)
const libyaTimeZone = Duration(hours: 2);

DateTime getCurrentLibyaTime() {
  // Get current UTC time and add Libya timezone offset
  return DateTime.now().toUtc().add(libyaTimeZone);
}

class AddPropertyScreen extends StatefulWidget {
  final Property? propertyToEdit; //  property to edit
  
  const AddPropertyScreen({super.key, this.propertyToEdit});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _addressController = TextEditingController();
  String? _selectedCity;
  String? _selectedNeighborhood;
  bool _shouldCheckLimit = true; // Track if we should check the limit
  AppLocalizations? get l10n => AppLocalizations.of(context);

  bool get _isFieldLocked {
    return widget.propertyToEdit != null && widget.propertyToEdit!.slotConsumed;
  }

  @override
  void initState() {
    super.initState();
    // If editing, pre-fill the form with existing property data
    if (widget.propertyToEdit != null) {
      _loadPropertyData(widget.propertyToEdit!);
      // Skip limit check when editing
      _shouldCheckLimit = false;
    }
    
    // Check property limit when screen opens (only for new properties)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_shouldCheckLimit) {
        _checkPropertyLimit();
      }
    });
  }

  void _loadPropertyData(Property property) {
    final formatter = NumberFormat.decimalPattern();
    _titleController.text = property.title;
    _descriptionController.text = property.description;
    _priceController.text = formatter.format(property.price);
    _addressController.text = property.address;
    
    // Normalize city value to match dropdown items
    String? cityValue = property.city;
    
    // Map common Arabic city names to English names in dropdown list
    final cityMapping = {
      'طرابلس': 'Tripoli',
      'بنغازي': 'Benghazi',
      // Add more mappings as needed for other Arabic city names
    };
    
    // Check if we need to map the city name
    if (cityMapping.containsKey(cityValue)) {
      cityValue = cityMapping[cityValue];
    }
    
    // Verify the city exists in the dropdown list
    if (cityValue != null && !_libyanCities.contains(cityValue)) {
      // City doesn't exist in dropdown list, set to null to avoid assertion error
      if (kDebugMode) {
        debugPrint('⚠️ City "$cityValue" not found in dropdown list. Setting to null.');
      }
      cityValue = null;
    }
    
    _selectedCity = cityValue;
    
    // Normalize neighborhood value to match dropdown items
    String? neighborhoodValue = property.neighborhood;
    
    // Get available neighborhoods for the selected city
    if (cityValue != null) {
      final availableNeighborhoods = CityLocalizer.getNeighborhoods(cityValue);
      
      if (neighborhoodValue.isNotEmpty) {
        // Try to find exact match first (case-insensitive)
        String? matchedNeighborhood;
        try {
          matchedNeighborhood = availableNeighborhoods.firstWhere(
            (neighborhood) => neighborhood.toLowerCase() == neighborhoodValue!.toLowerCase(),
          );
        } catch (e) {
          // No exact match found, try fuzzy matching
          matchedNeighborhood = null;
        }
        
        // If no exact match, try matching by extracting English part (before parentheses)
        if (matchedNeighborhood == null) {
          final normalizedValue = neighborhoodValue.toLowerCase().trim();
          for (final neighborhood in availableNeighborhoods) {
            // Extract English part before parentheses
            final englishPart = neighborhood.split('(').first.trim().toLowerCase();
            if (englishPart == normalizedValue || neighborhood.toLowerCase() == normalizedValue) {
              matchedNeighborhood = neighborhood;
              break;
            }
          }
        }
        
        // Set matched neighborhood or null if not found
        if (matchedNeighborhood != null && matchedNeighborhood.isNotEmpty) {
          neighborhoodValue = matchedNeighborhood;
        } else {
          if (kDebugMode) {
            debugPrint('⚠️ Neighborhood "$neighborhoodValue" not found in dropdown list for city "$cityValue". Setting to null.');
          }
          neighborhoodValue = null;
        }
      } else {
        neighborhoodValue = null;
      }
    } else {
      // If city is null, neighborhood should also be null
      neighborhoodValue = null;
    }
    
    _selectedNeighborhood = neighborhoodValue;
    _selectedType = property.type;
    _selectedStatus = property.status;
    _selectedCondition = property.condition;
    _selectedBedrooms = property.bedrooms;
    _selectedBathrooms = property.bathrooms;
    _selectedKitchens = property.kitchens;
    
    if (property.floors > 0) {
      _floorsController.text = property.floors.toString();
    }
    if (property.yearBuilt > 0) {
      _selectedYearBuilt = property.yearBuilt;
    }
    
    // Set rent fields if applicable
    if (property.status == PropertyStatus.forRent) {
      if (property.monthlyRent > 0) {
        _monthlyRentController.text = formatter.format(property.monthlyRent);
        _selectedRentType = 'monthly';
      } else if (property.dailyRent > 0) {
        _dailyRentController.text = formatter.format(property.dailyRent);
        _selectedRentType = 'daily';
      }
    }
    
    if (property.deposit > 0) {
      _depositController.text = formatter.format(property.deposit);
    }
    
    // Set size fields
    if (property.type == PropertyType.land) {
      _landSizeController.text = property.sizeSqm.toString();
    } else if (property.sizeSqm > 0) {
      _buildingSizeController.text = property.sizeSqm.toString();
    }
    
    // Set feature flags
    _hasBalcony = property.hasBalcony;
    _hasGarden = property.hasGarden;
    _hasParking = property.hasParking;
    _hasPool = property.hasPool;
    _hasGym = property.hasGym;
    _hasSecurity = property.hasSecurity;
    _hasElevator = property.hasElevator;
    _hasAC = property.hasAC;
    _hasHeating = property.hasHeating;
    _hasFurnished = property.hasFurnished;
    _hasPetFriendly = property.hasPetFriendly;
    _hasWaterWell = property.hasWaterWell;
    _hasNearbySchools = property.hasNearbySchools;
    _hasNearbyHospitals = property.hasNearbyHospitals;
    _hasNearbyShopping = property.hasNearbyShopping;
    _hasPublicTransport = property.hasPublicTransport;
    
    // Set boost package if exists
    if (property.isBoosted && property.boostPackageName != null) {
      // Try to match the package
      if (property.boostPackageName!.toLowerCase().contains('basic')) {
        _selectedPackageId = 'basic_boost';
        _selectedPackageName = 'Basic Boost';
        _selectedPackagePrice = property.boostPrice ?? 20.0;
      } else if (property.boostPackageName!.toLowerCase().contains('premium')) {
        _selectedPackageId = 'premium_boost';
        _selectedPackageName = 'Premium Boost';
        _selectedPackagePrice = property.boostPrice ?? 100.0;
      } else if (property.boostPackageName!.toLowerCase().contains('ultimate')) {
        _selectedPackageId = 'ultimate_boost';
        _selectedPackageName = 'Ultimate Boost';
        _selectedPackagePrice = property.boostPrice ?? 300.0;
      }
    }
  }

  Future<void> _checkPropertyLimit() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      return;
    }

    // Get actual counts directly from Firestore
    final propertyService = Provider.of<property_service.PropertyService>(context, listen: false);
    final actualPropertyCount = await propertyService.getUserPropertyCount(currentUser.id);
    
    // Get property limit directly from Firestore
    final firestore = FirebaseFirestore.instance;
    final userDoc = await firestore.collection('users').doc(currentUser.id).get();
    final propertyLimit = (userDoc.data()?['propertyLimit'] as num?)?.toInt() ?? 3;

    if (kDebugMode) {
      debugPrint('🔍 Checking Posting Credits on screen open:');
      debugPrint('   Current Credits: ${currentUser.postingCredits}');
      debugPrint('   Can Add Property: ${currentUser.postingCredits > 0}');
    }

    if (currentUser.postingCredits <= 0) {
      if (kDebugMode) {
        debugPrint('⚠️ User has no posting credits! Showing modal...');
      }
    
      if (!mounted) return;
    
      // Show property limit modal (now for credits)
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const PaywallScreen(),
      );

      // After modal closes, refresh user
      await authProvider.refreshUser();

      // If still no credits, go back
      if (authProvider.currentUser!.postingCredits <= 0) {
        if (mounted) {
          context.go('/');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n?.noCreditsMessage ?? 'No posting points remaining. Please purchase a points package to list your property.'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return; // Exit without adding property
      } else {
        // Credits available, allow user to continue
        _shouldCheckLimit = false;
      }
    }
  }

  // No longer needed, using CityLocalizer instead



  // Libyan cities list
  final List<String> _libyanCities = CityLocalizer.getAllEnglishCities();
  
  // Available neighborhoods based on selected city
  List<String> get _availableNeighborhoods {
    if (_selectedCity == null) return [];
    return CityLocalizer.getNeighborhoods(_selectedCity!);
  }

  final _bedroomsController = TextEditingController();
  final _bathroomsController = TextEditingController();
  final _floorsController = TextEditingController();
  final _monthlyRentController = TextEditingController();
  
  // Year built selection (1950-2050)
  int? _selectedYearBuilt;
  final _dailyRentController = TextEditingController();
  final _depositController = TextEditingController();
  final _landSizeController = TextEditingController();
  final _buildingSizeController = TextEditingController();
  
  // Room, bathroom and kitchen selection
  int _selectedBedrooms = 1;
  int _selectedBathrooms = 1;
  int _selectedKitchens = 1;
  
  // Package selection for the property being added
  String? _selectedPackageId;
  String? _selectedPackageName;
  double? _selectedPackagePrice;

  PropertyType _selectedType = PropertyType.apartment;
  PropertyStatus _selectedStatus = PropertyStatus.forSale;
  PropertyCondition _selectedCondition = PropertyCondition.good;
  
  // Rent type selection (monthly or daily) - only one can be selected
  String? _selectedRentType; // 'monthly' or 'daily'
  
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
  bool _hasPetFriendly = false;
  bool _hasWaterWell = false;
  bool _hasNearbySchools = false;
  bool _hasNearbyHospitals = false;
  bool _hasNearbyShopping = false;
  bool _hasPublicTransport = false;
  
  List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;
  bool _isUploadingImages = false;
  
  // Step wizard state
  int _currentStep = 0;
  final int _totalSteps = 6;
  final PageController _pageController = PageController();
  
  // Step definitions
  List<Map<String, dynamic>> get _steps {
    final l10n = AppLocalizations.of(context);
    return [
      {'title': l10n?.propertyType ?? 'Property Type', 'icon': Icons.home_work_rounded, 'subtitle': l10n?.whatTypeProperty ?? 'What are you listing?'},
      {'title': l10n?.basicInfo ?? 'Basic Info', 'icon': Icons.edit_note_rounded, 'subtitle': l10n?.addCompellingDescription ?? 'Title & Description'},
      {'title': l10n?.location ?? 'Location', 'icon': Icons.location_on_rounded, 'subtitle': l10n?.whereIsProperty ?? 'Where is it?'},
      {'title': l10n?.details ?? 'Details', 'icon': Icons.meeting_room_rounded, 'subtitle': l10n?.roomsSizePricing ?? 'Rooms & Size'},
      {'title': l10n?.features ?? 'Features', 'icon': Icons.star_rounded, 'subtitle': l10n?.amenities ?? 'Amenities'},
      {'title': l10n?.photos ?? 'Photos', 'icon': Icons.photo_library_rounded, 'subtitle': l10n?.showItOff ?? 'Show it off'},
    ];
  }


  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _addressController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _floorsController.dispose();
    _monthlyRentController.dispose();
    _dailyRentController.dispose();
    _depositController.dispose();
    _landSizeController.dispose();
    _buildingSizeController.dispose();
    _pageController.dispose();
    super.dispose();
  }
  
  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      // Validate current step before moving
      if (_validateCurrentStep()) {
        setState(() {
          _currentStep++;
        });
        _pageController.animateToPage(
          _currentStep,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    }
  }
  
  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }
  
  bool _validateCurrentStep() {
    final l10n = AppLocalizations.of(context);
    switch (_currentStep) {
      case 0: // Property Type - always valid
        return true;
      case 1: // Basic Info
        if (_titleController.text.isEmpty) {
          _showValidationError(l10n?.pleaseEnterTitle ?? 'Please enter a property title');
          return false;
        }
        if (_descriptionController.text.isEmpty) {
          _showValidationError(l10n?.pleaseEnterDescription ?? 'Please enter a description');
          return false;
        }
        return true;
      case 2: // Location
        if (_selectedCity == null) {
          _showValidationError(l10n?.pleaseSelectCity ?? 'Please select a city');
          return false;
        }
        if (_selectedNeighborhood == null) {
          _showValidationError(l10n?.pleaseSelectNeighborhood ?? 'Please select a neighborhood');
          return false;
        }
        if (_addressController.text.trim().isEmpty) {
          _showValidationError(l10n?.pleaseEnterAddress ?? 'Please enter an address');
          return false;
        }
        return true;
      case 3: // Details
        // Check price/rent
        if (_selectedStatus == PropertyStatus.forSale) {
          if (_priceController.text.isEmpty) {
            _showValidationError(l10n?.pleaseEnterPrice ?? 'Please enter a price');
            return false;
          }
          final price = double.tryParse(_priceController.text.replaceAll(',', '')) ?? 0.0;
          if (price < 50000) {
            _showValidationError('Minimum sale price is 50,000 LYD');
            return false;
          }
          if (price > 30000000) {
            _showValidationError('Maximum sale price is 30,000,000 LYD');
            return false;
          }
        }
        if (_selectedStatus == PropertyStatus.forRent) {
          if (_selectedRentType == 'monthly') {
            if (_monthlyRentController.text.isEmpty) {
              _showValidationError(l10n?.pleaseEnterMonthlyRent ?? 'Please enter monthly rent');
              return false;
            }
            final rent = double.tryParse(_monthlyRentController.text.replaceAll(',', '')) ?? 0.0;
            if (rent < 100) {
              _showValidationError('Minimum monthly rent is 100 LYD');
              return false;
            }
            if (rent > 200000) {
              _showValidationError('Maximum monthly rent is 200,000 LYD');
              return false;
            }
          }
          if (_selectedRentType == 'daily') {
            if (_dailyRentController.text.isEmpty) {
              _showValidationError(l10n?.pleaseEnterDailyRent ?? 'Please enter daily rent');
              return false;
            }
            final rent = double.tryParse(_dailyRentController.text.replaceAll(',', '')) ?? 0.0;
            if (rent < 100) {
              _showValidationError('Minimum daily rent is 100 LYD');
              return false;
            }
            if (rent > 200000) {
              _showValidationError('Maximum daily rent is 200,000 LYD');
              return false;
            }
          }
        }
        
        // Check size
        if (_selectedType == PropertyType.land) {
          if (_landSizeController.text.trim().isEmpty) {
             _showValidationError(l10n?.pleaseEnterLandSize ?? 'Please enter land size');
             return false;
          }
        } else {
          if (_buildingSizeController.text.trim().isEmpty) {
             _showValidationError(l10n?.pleaseEnterBuildingSize ?? 'Please enter building size');
             return false;
          }
        }
        return true;
      case 4: // Features - always valid
        return true;
      case 5: // Photos
        if (_selectedImages.isEmpty && widget.propertyToEdit == null) {
          _showValidationError(l10n?.pleaseAddPhoto ?? 'Please add at least one photo');
          return false;
        }
        return true;
      default:
        return true;
    }
  }
  
  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
  
  Future<void> _submitProperty() async {
    // Validate final step
    if (!_validateCurrentStep()) return;
    
    // Call the existing submit form logic
    await _submitForm();
  }

  Future<void> _pickImages() async {
    final l10n = AppLocalizations.of(context);
    if (_selectedImages.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n?.maxImages ?? 'You can upload a maximum of 10 images.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images.take(10 - _selectedImages.length));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n?.failedToPickImages ?? 'Failed to pick images: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Widget _buildNumberSelector({
    required String label,
    required int selectedValue,
    required Function(int) onChanged,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: ThemeService.getBodyStyle(context, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (int i = 1; i <= 6; i++)
              _buildNumberButton(
                number: i,
                isSelected: selectedValue == i,
                onTap: () => onChanged(i),
              ),
            _buildNumberButton(
              number: 9,
              isSelected: selectedValue >= 9,
              onTap: () => onChanged(9),
              label: '+9',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNumberButton({
    required int number,
    required bool isSelected,
    required VoidCallback onTap,
    String? label,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF01352D) : Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF01352D) : Colors.grey[600]!,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            label ?? number.toString(),
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[300],
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusToggle({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF01352D) : Colors.grey[800],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF01352D) : Colors.grey[600]!,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[300],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[300],
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    final l10n = AppLocalizations.of(context);
    
    // Task 7: Comprehensive validation before form submission
    // Validate all required fields and show specific error messages
    List<String> missingFields = [];
    
    // Validate title
    if (_titleController.text.trim().isEmpty) {
      missingFields.add('Property Title');
    }
    
    // Validate description
    if (_descriptionController.text.trim().isEmpty) {
      missingFields.add('Description');
    }
    
    // Validate price based on status
    if (_selectedStatus == PropertyStatus.forSale) {
      if (_priceController.text.trim().isEmpty) {
        missingFields.add('Price');
      }
    } else if (_selectedStatus == PropertyStatus.forRent) {
      if (_selectedRentType == null) {
        missingFields.add('Rent Type (Monthly or Daily)');
      } else if (_selectedRentType == 'monthly' && _monthlyRentController.text.trim().isEmpty) {
        missingFields.add('Monthly Rent');
      } else if (_selectedRentType == 'daily' && _dailyRentController.text.trim().isEmpty) {
        missingFields.add('Daily Rent');
      }
    }
    
    // Validate location
    if (_selectedCity == null || _selectedCity!.isEmpty) {
      missingFields.add('City');
    }
    
    if (_selectedNeighborhood == null || _selectedNeighborhood!.isEmpty) {
      missingFields.add('Neighborhood');
    }
    
    if (_addressController.text.trim().isEmpty) {
      missingFields.add('Address');
    }
    
    // Validate size
    if (_selectedType == PropertyType.land) {
      if (_landSizeController.text.trim().isEmpty) {
        missingFields.add('Land Size');
      }
    } else {
      if (_buildingSizeController.text.trim().isEmpty) {
        missingFields.add('Building Size');
      }
    }
    
    // Show comprehensive error message if any fields are missing
    if (missingFields.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fill in the following required fields:\n${missingFields.join(', ')}',
            style: const TextStyle(fontSize: 14),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
      return;
    }
    
    // Validate rent type selection for rent properties
    if (_selectedStatus == PropertyStatus.forRent && _selectedRentType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select monthly or daily rent'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_formKey.currentState!.validate()) {
      // Get current user
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final propertyService = Provider.of<property_service.PropertyService>(context, listen: false);
      final currentUser = authProvider.currentUser;
      
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Check property limit
      if (kDebugMode) {
        debugPrint('🔍 Add Property - Checking limits:');
        debugPrint('   User ID: ${currentUser.id}');
        debugPrint('   Total Listings: ${currentUser.totalListings}');
        debugPrint('   Property Limit: ${currentUser.propertyLimit}');
        debugPrint('   Can Add Property: ${currentUser.canAddProperty}');
      }

      if (!currentUser.canAddProperty) {
        if (kDebugMode) {
          debugPrint('⚠️ User has reached property limit!');
        }
        // Show property limit modal
        await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const PaywallScreen(),
          );
        
        // Refresh user data after modal closes
        await authProvider.refreshUser();
        
        // Re-check after refresh
        final refreshedUser = authProvider.currentUser;
        if (refreshedUser == null || !refreshedUser.canAddProperty) {
          return; // User still can't add properties
        }
      } else if (kDebugMode) {
        debugPrint('✅ User can add property, proceeding...');
      }

      setState(() {
        _isSubmitting = true;
      });

      try {
        // Final check: Ensure user still hasn't exceeded limit
        // (accounting for properties added by other devices/sessions)
        // But skip this check if user just purchased slots (_shouldCheckLimit == false)
        if (_shouldCheckLimit) {
          await authProvider.refreshUser();
          
          final finalCheckUser = authProvider.currentUser;
          if (finalCheckUser == null || !finalCheckUser.canAddProperty) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n?.propertyLimitReachedGeneral ?? 'You have reached your property limit. Please purchase more slots.'),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
            setState(() {
              _isSubmitting = false;
            });
            return;
          }
        }

        // Check if editing or creating
        final isEditing = widget.propertyToEdit != null;
        
        // Create property object
        final refreshedUser = authProvider.currentUser!;
        final property = Property(
          id: isEditing ? widget.propertyToEdit!.id : '', // Use existing ID when editing
          userId: refreshedUser.id, // Associate with current user
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          price: _selectedStatus != PropertyStatus.forRent 
              ? (double.tryParse(_priceController.text.replaceAll(',', '')) ?? 0.0)
              : 0.0,
          sizeSqm: _selectedType == PropertyType.land
              ? (int.tryParse(_landSizeController.text) ?? 0)
              : (int.tryParse(_buildingSizeController.text) ?? 0),
          city: _selectedCity ?? '',
          neighborhood: _selectedNeighborhood ?? '',
          address: _addressController.text.trim(),
          bedrooms: _selectedType != PropertyType.land ? _selectedBedrooms : 0,
          bathrooms: _selectedType != PropertyType.land ? _selectedBathrooms : 0,
          kitchens: _selectedType != PropertyType.land ? _selectedKitchens : 1,
          floors: (_selectedType != PropertyType.apartment && _selectedType != PropertyType.land)
              ? (int.tryParse(_floorsController.text) ?? 1)
              : 1,
          yearBuilt: _selectedYearBuilt ?? 0,
          type: _selectedType,
          status: _selectedStatus,
          condition: _selectedCondition,
          hasBalcony: _hasBalcony,
          hasGarden: _hasGarden,
          hasParking: _hasParking,
          hasPool: _hasPool,
          hasGym: _hasGym,
          hasSecurity: _hasSecurity,
          hasElevator: _hasElevator,
          hasAC: _hasAC,
          hasHeating: _hasHeating,
          hasFurnished: _hasFurnished,
          hasPetFriendly: _hasPetFriendly,
          hasWaterWell: _hasWaterWell,
          hasNearbySchools: _hasNearbySchools,
          hasNearbyHospitals: _hasNearbyHospitals,
          hasNearbyShopping: _hasNearbyShopping,
          hasPublicTransport: _hasPublicTransport,
          monthlyRent: (_selectedStatus == PropertyStatus.forRent && _selectedRentType == 'monthly')
              ? (double.tryParse(_monthlyRentController.text.replaceAll(',', '')) ?? 0.0)
              : 0.0,
          dailyRent: (_selectedStatus == PropertyStatus.forRent && _selectedRentType == 'daily')
              ? (double.tryParse(_dailyRentController.text.replaceAll(',', '')) ?? 0.0)
              : 0.0,
          deposit: double.tryParse(_depositController.text.replaceAll(',', '')) ?? 0.0,
          contactPhone: currentUser.phone ?? '',
          contactEmail: currentUser.email ?? '',
          agentName: currentUser.name ?? '',
          imageUrls: [], // TODO: Upload images to Firebase Storage
          createdAt: getCurrentLibyaTime(),
          updatedAt: getCurrentLibyaTime(),
          views: 0,
          isFeatured: false,
          isVerified: false,
          isBoosted: _selectedPackageId != null,
          boostPackageName: _selectedPackageName,
          boostExpiresAt: _selectedPackageId != null 
            ? getCurrentLibyaTime().add(Duration(
                days: _selectedPackageId == 'basic_boost' ? 1 :
                      _selectedPackageId == 'premium_boost' ? 7 : 30
              ))
            : null,
          boostPrice: _selectedPackagePrice,
        );

        // Validate minimum images requirement (Task 5: Minimum 4 photos)
        final existingImagesCount = isEditing ? (widget.propertyToEdit!.imageUrls.length) : 0;
        final totalImagesCount = _selectedImages.length + existingImagesCount;
        
        // Check if we have enough images (minimum 4 for new properties, or if editing without existing images)
        if (!isEditing && _selectedImages.length < 4) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n?.minImagesError(_selectedImages.length) ?? 'Please upload at least 4 photos. You have uploaded ${_selectedImages.length} photo(s).'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
          setState(() {
            _isSubmitting = false;
          });
          return;
        }
        
        // If editing and no new images, check existing images count
        if (isEditing && _selectedImages.isEmpty && existingImagesCount < 4) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n?.minImagesError(existingImagesCount) ?? 'Please upload at least 4 photos. Property currently has $existingImagesCount photo(s).'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
          setState(() {
            _isSubmitting = false;
          });
          return;
        }

        // Upload images first
        List<String> imageUrls = [];
        if (_selectedImages.isNotEmpty) {
          setState(() {
            _isUploadingImages = true;
          });
          
          // Create a temporary property ID for image uploads
          final tempPropertyId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n?.uploadingImages(_selectedImages.length) ?? 'Uploading ${_selectedImages.length} images...'),
              backgroundColor: Colors.blue,
              duration: const Duration(seconds: 2),
            ),
          );
          
          try {
            imageUrls = await ImageUploadService.uploadImages(_selectedImages, tempPropertyId);
            
            if (imageUrls.isEmpty) {
              throw Exception('Failed to upload images');
            }
          } finally {
            setState(() {
              _isUploadingImages = false;
            });
          }
        }

        // Create property with uploaded image URLs
        final propertyWithImages = Property(
          id: property.id,
          userId: property.userId,
          title: property.title,
          description: property.description,
          price: property.price,
          sizeSqm: property.sizeSqm,
          city: property.city,
          neighborhood: property.neighborhood,
          address: property.address,
          bedrooms: property.bedrooms,
          bathrooms: property.bathrooms,
          kitchens: property.kitchens,
          floors: property.floors,
          yearBuilt: property.yearBuilt,
          type: property.type,
          status: property.status,
          condition: property.condition,
          hasBalcony: property.hasBalcony,
          hasGarden: property.hasGarden,
          hasParking: property.hasParking,
          hasPool: property.hasPool,
          hasGym: property.hasGym,
          hasSecurity: property.hasSecurity,
          hasElevator: property.hasElevator,
          hasAC: property.hasAC,
          hasHeating: property.hasHeating,
          hasFurnished: property.hasFurnished,
          hasPetFriendly: property.hasPetFriendly,
          hasNearbySchools: property.hasNearbySchools,
          hasNearbyHospitals: property.hasNearbyHospitals,
          hasNearbyShopping: property.hasNearbyShopping,
          hasPublicTransport: property.hasPublicTransport,
          monthlyRent: property.monthlyRent,
          dailyRent: property.dailyRent,
          deposit: property.deposit,
          contactPhone: property.contactPhone,
          contactEmail: property.contactEmail,
          agentName: property.agentName,
          // Task 8: Preserve image order when editing - combine existing with new images
          imageUrls: isEditing 
              ? (imageUrls.isNotEmpty 
                  ? [...widget.propertyToEdit!.imageUrls, ...imageUrls] // Append new images to existing ones, preserving order
                  : widget.propertyToEdit!.imageUrls) // Keep existing images if no new ones
              : imageUrls, // For new properties, use only uploaded images
          createdAt: isEditing ? widget.propertyToEdit!.createdAt : property.createdAt,
          updatedAt: DateTime.now(),
          views: isEditing ? widget.propertyToEdit!.views : 0,
          isFeatured: isEditing ? widget.propertyToEdit!.isFeatured : false,
          isVerified: isEditing ? widget.propertyToEdit!.isVerified : false,
          isBoosted: isEditing ? widget.propertyToEdit!.isBoosted : (_selectedPackageId != null),
          boostPackageName: isEditing ? widget.propertyToEdit!.boostPackageName : _selectedPackageName,
          boostExpiresAt: isEditing ? widget.propertyToEdit!.boostExpiresAt : (_selectedPackageId != null 
            ? DateTime.now().add(Duration(
                days: _selectedPackageId == 'basic_boost' ? 1 :
                      _selectedPackageId == 'premium_boost' ? 7 : 30
              ))
            : null),
          boostPrice: isEditing ? widget.propertyToEdit!.boostPrice : _selectedPackagePrice,
          isPublished: isEditing ? widget.propertyToEdit!.isPublished : true,
        );

        // If editing, skip wallet charging
        final persistenceService = Provider.of<PersistenceService>(context, listen: false);
        
        // If creating (not editing) and a boost package is selected, charge wallet first
        if (!isEditing && _selectedPackageId != null && _selectedPackagePrice != null && propertyWithImages.isBoosted) {
          try {
            // Get wallet service
            final walletService = Provider.of<WalletService>(context, listen: false);
            
            // Check wallet balance
            final currentBalance = walletService.getCurrentBalance();
            if (currentBalance < _selectedPackagePrice!) {
              throw Exception(l10n?.insufficientBalance ?? 'Insufficient wallet balance. Please add funds to your wallet.');
            }
            
            // Deduct amount from wallet
            final deductSuccess = await walletService.deductAmount(
              userId: currentUser.id,
              amount: _selectedPackagePrice!,
              description: 'Top Listing Purchase - ${_selectedPackageName ?? 'Boost Package'}',
              metadata: {
                'packageId': _selectedPackageId,
                'packageName': _selectedPackageName,
                'durationDays': _selectedPackageId == 'basic_boost' ? 1 :
                                _selectedPackageId == 'premium_boost' ? 7 : 30,
              },
            );
            
            if (!deductSuccess) {
              throw Exception(l10n?.paymentFailed ?? 'Payment failed. Please try again.');
            }
            
            if (kDebugMode) {
              debugPrint('✅ Wallet charged $_selectedPackagePrice LYD for boost package: $_selectedPackageName');
            }
          } catch (e) {
            // If payment fails, throw error
            if (kDebugMode) {
              debugPrint('❌ Payment failed for boost: $e');
            }
            throw Exception('Failed to process boost payment: ${e.toString()}');
          }
        }

        // Update or create property based on editing mode
        if (isEditing) {
          // Update existing property
          final success = await propertyService.updateProperty(widget.propertyToEdit!.id, propertyWithImages);
          
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n?.propertyUpdatedSuccessfully ?? 'Property updated successfully!'),
                backgroundColor: const Color(0xFF01352D),
              ),
            );
            
            _clearForm();
            context.go('/'); // Navigate back to home
          } else {
            throw Exception('Failed to update property');
          }
        } else {
          // Create new property
          final propertyId = await propertyService.createProperty(propertyWithImages);
          
          if (propertyId != null) {
            // If boost was selected, ensure it's properly applied after creation
            if (_selectedPackageId != null && propertyWithImages.isBoosted) {
              // Explicitly apply boost using PropertyService to ensure it's saved correctly
              final durationDays = _selectedPackageId == 'basic_boost' ? 1 :
                                  _selectedPackageId == 'premium_boost' ? 7 : 30;
              
              final boostApplied = await propertyService.boostProperty(
                propertyId,
                _selectedPackageName ?? 'Boost Package',
                _selectedPackagePrice ?? 0.0,
                durationDays,
                persistenceService: persistenceService,
              );
              
              if (kDebugMode) {
                debugPrint('✅ Boost applied to property $propertyId: $boostApplied (package: $_selectedPackageName)');
              }
            }
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_selectedPackageId != null 
                  ? '${l10n?.propertyPublishedSuccessfully ?? l10n?.propertyAddedSuccessfully ?? 'Property added successfully!'} ${l10n?.boostActivated ?? 'Boost package activated!'}'
                  : l10n?.propertyPublishedSuccessfully ?? l10n?.propertyAddedSuccessfully ?? 'Property added successfully!'),
                backgroundColor: const Color(0xFF01352D),
              ),
            );

            _clearForm();
            await authProvider.refreshUser(); // Refresh limits
            await ProfileService.loadUserProperties(currentUser.id); // Refresh properties
            context.go('/'); // Navigate back to home
          } else {
            throw Exception('Failed to create property');
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _clearForm() {
    _titleController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _addressController.clear();
    _selectedCity = null;
    _selectedNeighborhood = null;
    _bedroomsController.clear();
    _bathroomsController.clear();
    _floorsController.clear();
    _selectedYearBuilt = null;
    _monthlyRentController.clear();
    _dailyRentController.clear();
    _depositController.clear();
    
    _selectedType = PropertyType.apartment;
    _selectedStatus = PropertyStatus.forSale;
    _selectedCondition = PropertyCondition.good;
    
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
    _hasPetFriendly = false;
    _hasNearbySchools = false;
    _hasNearbyHospitals = false;
    _hasNearbyShopping = false;
    _hasPublicTransport = false;
    
    _selectedImages = [];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageService = Provider.of<LanguageService>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    // Check authentication
    if (!authProvider.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/login');
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar with Step Indicator
            _buildWizardHeader(l10n),
            
            // Step Content
            Expanded(
              child: Form(
                key: _formKey,
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() => _currentStep = index);
                  },
                  children: [
                    _buildStep0PropertyType(l10n),
                    _buildStep1BasicInfo(l10n),
                    _buildStep2Location(l10n),
                    _buildStep3Details(l10n),
                    _buildStep4Features(l10n),
                    _buildStep5Photos(l10n),
                  ],
                ),
              ),
            ),
            
            // Navigation Buttons
            _buildNavigationButtons(l10n),
          ],
        ),
      ),
    );
  }
  
  Widget _buildWizardHeader(AppLocalizations? l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF01352D),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF01352D).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Title Row
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: Text(l10n?.discardChangesTitle ?? 'Discard Changes?'),
                      content: Text(l10n?.discardChangesMessage ?? 'Are you sure you want to leave? Your progress will be lost.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(l10n?.cancel ?? 'Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            context.go('/');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[400],
                          ),
                          child: Text(l10n?.discard ?? 'Discard', style: const TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                },
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      widget.propertyToEdit != null ? (l10n?.editProperty ?? 'Edit Property') : (l10n?.addPropertyTitle ?? 'Add Property'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n?.stepProgress(_currentStep + 1, _totalSteps) ?? 'Step ${_currentStep + 1} of $_totalSteps',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 48), // Balance the close button
            ],
          ),
          const SizedBox(height: 20),
          
          // Step Indicator
          Row(
            children: List.generate(_totalSteps, (index) {
              final isActive = index == _currentStep;
              final isCompleted = index < _currentStep;
              
              return Expanded(
                child: GestureDetector(
                  onTap: isCompleted ? () {
                    setState(() => _currentStep = index);
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    );
                  } : null,
                  child: Column(
                    children: [
                      // Step Icon
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: isActive ? 48 : 36,
                        height: isActive ? 48 : 36,
                        decoration: BoxDecoration(
                          color: isActive 
                              ? Colors.white 
                              : isCompleted 
                                  ? Colors.green[400] 
                                  : Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          boxShadow: isActive ? [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.3),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ] : [],
                        ),
                        child: Icon(
                          isCompleted ? Icons.check_rounded : _steps[index]['icon'],
                          color: isActive 
                              ? const Color(0xFF01352D) 
                              : isCompleted 
                                  ? Colors.white 
                                  : Colors.white.withValues(alpha: 0.5),
                          size: isActive ? 24 : 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Step Title (only show for active)
                      if (isActive)
                        Text(
                          _steps[index]['title'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              );
            }),
          ),
          
          // Progress Bar
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / _totalSteps,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNavigationButtons(AppLocalizations? l10n) {
    final isLastStep = _currentStep == _totalSteps - 1;
    
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back Button
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _previousStep,
                icon: const Icon(Icons.arrow_back_rounded),
                label: Text(l10n?.back ?? 'Back'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF01352D),
                  side: const BorderSide(color: Color(0xFF01352D), width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            )
          else
            const Spacer(),
          
          const SizedBox(width: 16),
          
          // Next/Submit Button
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting 
                  ? null 
                  : isLastStep 
                      ? _submitProperty 
                      : _nextStep,
              icon: _isSubmitting 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: DaryLoadingIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(isLastStep ? Icons.check_rounded : Icons.arrow_forward_rounded),
              label: Text(
                _isSubmitting 
                    ? (l10n?.saving ?? 'Saving...')
                    : isLastStep 
                        ? (widget.propertyToEdit != null ? (l10n?.updateProperty ?? 'Update Property') : (l10n?.publishProperty ?? 'Publish Property'))
                        : (l10n?.continueButton ?? 'Continue'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isLastStep ? Colors.green[600] : const Color(0xFF01352D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Step 0: Property Type Selection
  Widget _buildStep0PropertyType(AppLocalizations? l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            icon: Icons.home_work_rounded,
            title: l10n?.whatTypeProperty ?? 'What type of property?',
            subtitle: l10n?.selectCategoryDescription ?? 'Select the category that best describes your property',
          ),
          const SizedBox(height: 24),
          
          // Property Type Selection
          Text(
            l10n?.propertyType ?? 'Property Type',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          AbsorbPointer(
            absorbing: _isFieldLocked,
            child: Opacity(
              opacity: _isFieldLocked ? 0.6 : 1.0,
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: PropertyType.values.map((type) {
                  final isSelected = _selectedType == type;
                  final icon = _getPropertyTypeIcon(type);
                  return GestureDetector(
                    onTap: () => setState(() => _selectedType = type),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF01352D) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF01352D) : Colors.grey[300]!,
                          width: 2,
                        ),
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: const Color(0xFF01352D).withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ] : [],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            icon,
                            size: 32,
                            color: isSelected ? Colors.white : Colors.grey[600],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            type.getLocalizedName(context),
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey[800],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          if (_isFieldLocked)
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text(
                'Property type cannot be changed for active listings.',
                style: TextStyle(color: Color(0xFFE65100), fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          
          const SizedBox(height: 32),
          
          // Listing Type (Sale/Rent)
          Text(
            l10n?.listingType ?? 'Listing Type',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          AbsorbPointer(
            absorbing: _isFieldLocked,
            child: Opacity(
              opacity: _isFieldLocked ? 0.6 : 1.0,
              child: Row(
                children: [
                  Expanded(
                    child: _buildListingTypeCard(
                      icon: Icons.sell_rounded,
                      title: l10n?.statusForSale ?? 'For Sale',
                      isSelected: _selectedStatus == PropertyStatus.forSale,
                      onTap: () => setState(() => _selectedStatus = PropertyStatus.forSale),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildListingTypeCard(
                      icon: Icons.key_rounded,
                      title: l10n?.statusForRent ?? 'For Rent',
                      isSelected: _selectedStatus == PropertyStatus.forRent,
                      onTap: () => setState(() => _selectedStatus = PropertyStatus.forRent),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Property Condition
          Text(
            l10n?.condition ?? 'Property Condition',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: PropertyCondition.values.map((condition) {
              final isSelected = _selectedCondition == condition;
              return ChoiceChip(
                label: Text(condition.getLocalizedName(context)),
                selected: isSelected,
                onSelected: (_) => setState(() => _selectedCondition = condition),
                selectedColor: const Color(0xFF01352D),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildListingTypeCard({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF01352D) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF01352D) : Colors.grey[300]!,
            width: 2,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFF01352D).withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ] : [],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 48,
              color: isSelected ? Colors.white : const Color(0xFF01352D),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  IconData _getPropertyTypeIcon(PropertyType type) {
    switch (type) {
      case PropertyType.house:
        return Icons.house_rounded;
      case PropertyType.apartment:
        return Icons.apartment_rounded;
      case PropertyType.villa:
        return Icons.villa_rounded;
      case PropertyType.land:
        return Icons.landscape_rounded;
      case PropertyType.commercial:
        return Icons.storefront_rounded;
      default:
        return Icons.home_rounded;
    }
  }
  
  // Step 1: Basic Info
  Widget _buildStep1BasicInfo(AppLocalizations? l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            icon: Icons.edit_note_rounded,
            title: l10n?.tellUsAboutProperty ?? 'Tell us about your property',
            subtitle: l10n?.addCompellingDescription ?? 'Add a compelling title and description',
          ),
          const SizedBox(height: 24),
          
          // Title Field
          _buildInputLabel(l10n?.propertyTitle ?? 'Property Title'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _titleController,
            style: const TextStyle(color: Colors.black87, fontSize: 16),
            inputFormatters: [BasicTextFormatter()],
            decoration: _buildInputDecoration(
              hint: l10n?.titleHint ?? 'e.g., Beautiful 3BR Apartment in City Center',
              icon: Icons.title_rounded,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Description Field
          _buildInputLabel(l10n?.description ?? 'Description'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _descriptionController,
            style: const TextStyle(color: Colors.black87, fontSize: 16),
            inputFormatters: [BasicTextFormatter()],
            maxLines: 5,
            decoration: _buildInputDecoration(
              hint: l10n?.descriptionHint ?? 'Describe your property features, neighborhood, and what makes it special...',
              icon: Icons.description_rounded,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Tips Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_rounded, color: Colors.blue[600], size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.proTip ?? 'Pro Tip',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n?.detailedDescriptionTip ?? 'Properties with detailed descriptions get 40% more views!',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Step 2: Location
  Widget _buildStep2Location(AppLocalizations? l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            icon: Icons.location_on_rounded,
            title: l10n?.whereIsProperty ?? 'Where is your property?',
            subtitle: l10n?.helpBuyersFind ?? 'Help buyers find your property easily',
          ),
          const SizedBox(height: 24),
          
          // City Dropdown
          _buildInputLabel(l10n?.city ?? 'City'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedCity,
            decoration: _buildInputDecoration(
              hint: l10n?.selectCity ?? 'Select a city',
              icon: Icons.location_city_rounded,
            ).copyWith(
              fillColor: _isFieldLocked ? Colors.grey[100] : null,
              filled: _isFieldLocked,
            ),
            items: _libyanCities.map((city) {
              return DropdownMenuItem(value: city, child: Text(CityLocalizer.getBilingualCityName(city)));
            }).toList(),
            onChanged: _isFieldLocked ? null : (value) {
              setState(() {
                _selectedCity = value;
                _selectedNeighborhood = null;
              });
            },
            style: const TextStyle(color: Colors.black87, fontSize: 16),
            dropdownColor: Colors.white,
          ),
          
          const SizedBox(height: 24),
          
          // Neighborhood Dropdown
          _buildInputLabel(l10n?.neighborhood ?? 'Neighborhood'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedNeighborhood,
            decoration: _buildInputDecoration(
              hint: _selectedCity == null ? (l10n?.selectCityFirst ?? 'Select a city first') : (l10n?.selectNeighborhood ?? 'Select a neighborhood'),
              icon: Icons.map_rounded,
            ).copyWith(
              fillColor: (_isFieldLocked || _selectedCity == null) ? Colors.grey[100] : null,
              filled: _isFieldLocked || _selectedCity == null,
            ),
            items: _availableNeighborhoods.map((neighborhood) {
              return DropdownMenuItem(value: neighborhood, child: Text(neighborhood));
            }).toList(),
            onChanged: (_isFieldLocked || _selectedCity == null) ? null : (value) {
              setState(() => _selectedNeighborhood = value);
            },
            style: const TextStyle(color: Colors.black87, fontSize: 16),
            dropdownColor: Colors.white,
          ),
          if (_isFieldLocked)
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text(
                'Location cannot be changed for active listings.',
                style: TextStyle(color: Color(0xFFE65100), fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          
          const SizedBox(height: 24),
          
          // Address Field
          _buildInputLabel(l10n?.streetAddress ?? 'Street Address'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _addressController,
            style: const TextStyle(color: Colors.black87, fontSize: 16),
            inputFormatters: [BasicTextFormatter()],
            decoration: _buildInputDecoration(
              hint: l10n?.addressHint ?? 'e.g., 123 Main Street',
              icon: Icons.home_rounded,
            ),
          ),
        ],
      ),
    );
  }
  
  // Step 3: Property Details
  Widget _buildStep3Details(AppLocalizations? l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            icon: Icons.meeting_room_rounded,
            title: l10n?.roomsSizePricing ?? 'Rooms, size, and pricing',
            subtitle: l10n?.details ?? 'Property Details',
          ),
          const SizedBox(height: 24),
          
          // Price Section
          if (_selectedStatus == PropertyStatus.forSale) ...[
            _buildInputLabel(l10n?.salePriceLyd ?? 'Sale Price (LYD)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _priceController,
              style: const TextStyle(color: Colors.black87, fontSize: 16),
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsSeparatorInputFormatter()],
              decoration: _buildInputDecoration(
                hint: l10n?.enterPrice ?? 'Enter price',
                icon: Icons.attach_money_rounded,
              ),
            ),
          ] else ...[
            // Rent Type Selection
            _buildInputLabel(l10n?.listingType ?? 'Rent Type'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildRentTypeChip('monthly', l10n?.monthlyRent ?? 'Monthly Rent'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildRentTypeChip('daily', l10n?.dailyRent ?? 'Daily Rent'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_selectedRentType == 'monthly') ...[
              _buildInputLabel(l10n?.monthlyRent ?? 'Monthly Rent (LYD)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _monthlyRentController,
                style: const TextStyle(color: Colors.black87, fontSize: 16),
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsSeparatorInputFormatter()],
                decoration: _buildInputDecoration(
                  hint: l10n?.enterMonthlyRent ?? 'Enter monthly rent',
                  icon: Icons.calendar_month_rounded,
                ),
              ),
            ] else if (_selectedRentType == 'daily') ...[
              _buildInputLabel(l10n?.dailyRent ?? 'Daily Rent (LYD)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _dailyRentController,
                style: const TextStyle(color: Colors.black87, fontSize: 16),
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsSeparatorInputFormatter()],
                decoration: _buildInputDecoration(
                  hint: l10n?.enterDailyRent ?? 'Enter daily rent',
                  icon: Icons.today_rounded,
                ),
              ),
            ],
          ],
          
          const SizedBox(height: 24),
          
          // Rooms Section (hide for land)
          if (_selectedType != PropertyType.land) ...[
            _buildInputLabel(l10n?.rooms ?? 'Rooms'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildCounterField(l10n?.beds ?? 'Beds', _selectedBedrooms, (v) => setState(() => _selectedBedrooms = v), Icons.bed_rounded)),
                const SizedBox(width: 12),
                Expanded(child: _buildCounterField(l10n?.baths ?? 'Baths', _selectedBathrooms, (v) => setState(() => _selectedBathrooms = v), Icons.bathtub_rounded)),
                const SizedBox(width: 12),
                Expanded(child: _buildCounterField(l10n?.kitchens ?? 'Kitchens', _selectedKitchens, (v) => setState(() => _selectedKitchens = v), Icons.kitchen_rounded)),
              ],
            ),
            const SizedBox(height: 24),
          ],
          
          // Size Section
          _buildInputLabel(_selectedType == PropertyType.land ? (l10n?.landSizeM2 ?? 'Land Size (m²)') : (l10n?.buildingSizeM2 ?? 'Size (m²)')),
          const SizedBox(height: 8),
          TextFormField(
            controller: _selectedType == PropertyType.land ? _landSizeController : _buildingSizeController,
            style: const TextStyle(color: Colors.black87, fontSize: 16),
            readOnly: _isFieldLocked,
            keyboardType: TextInputType.number,
            decoration: _buildInputDecoration(
              hint: l10n?.enterSizeM2 ?? 'Enter size in square meters',
              icon: Icons.square_foot_rounded,
            ).copyWith(
              fillColor: _isFieldLocked ? Colors.grey[100] : null,
              filled: _isFieldLocked,
            ),
          ),
          if (_isFieldLocked)
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text(
                'Property size cannot be changed for active listings.',
                style: TextStyle(color: Color(0xFFE65100), fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          
          const SizedBox(height: 24),
          
          // Floors and Year Built (hide for land)
          if (_selectedType != PropertyType.land) ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInputLabel(l10n?.floors ?? 'Floors'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _floorsController,
                        style: const TextStyle(color: Colors.black87, fontSize: 16),
                        keyboardType: TextInputType.number,
                        decoration: _buildInputDecoration(
                          hint: '1',
                          icon: Icons.layers_rounded,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInputLabel(l10n?.yearBuilt ?? 'Year Built'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        initialValue: _selectedYearBuilt,
                        decoration: _buildInputDecoration(
                          hint: l10n?.select ?? 'Select',
                          icon: Icons.calendar_today_rounded,
                        ),
                        items: List.generate(75, (index) {
                          final year = 2025 - index;
                          return DropdownMenuItem(value: year, child: Text('$year'));
                        }),
                        onChanged: (value) => setState(() => _selectedYearBuilt = value),
                        style: const TextStyle(color: Colors.black87, fontSize: 16),
                        dropdownColor: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildRentTypeChip(String value, String label) {
    final isSelected = _selectedRentType == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedRentType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF01352D) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF01352D) : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildCounterField(String label, int value, Function(int) onChanged, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF01352D), size: 24),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: value > 0 ? () => onChanged(value - 1) : null,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.remove, size: 18, color: Colors.grey[700]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '$value',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => onChanged(value + 1),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFF01352D),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, size: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // Step 4: Features
  Widget _buildStep4Features(AppLocalizations? l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            icon: Icons.star_rounded,
            title: l10n?.features ?? 'Amenities & Features',
            subtitle: l10n?.selectCategoryDescription ?? 'What does your property offer?',
          ),
          const SizedBox(height: 24),
          
          // Indoor Features
          _buildFeatureSection(l10n?.indoorFeatures ?? 'Indoor Features', [
            _buildFeatureToggle(l10n?.ac ?? 'Air Conditioning', Icons.ac_unit_rounded, _hasAC, (v) => setState(() => _hasAC = v)),
            _buildFeatureToggle(l10n?.heating ?? 'Heating', Icons.whatshot_rounded, _hasHeating, (v) => setState(() => _hasHeating = v)),
            _buildFeatureToggle(l10n?.furnished ?? 'Furnished', Icons.chair_rounded, _hasFurnished, (v) => setState(() => _hasFurnished = v)),
            _buildFeatureToggle(l10n?.elevator ?? 'Elevator', Icons.elevator_rounded, _hasElevator, (v) => setState(() => _hasElevator = v)),
          ]),
          
          const SizedBox(height: 24),
          
          // Outdoor Features
          _buildFeatureSection(l10n?.outdoorFeatures ?? 'Outdoor Features', [
            _buildFeatureToggle(l10n?.balcony ?? 'Balcony', Icons.balcony_rounded, _hasBalcony, (v) => setState(() => _hasBalcony = v)),
            _buildFeatureToggle(l10n?.garden ?? 'Garden', Icons.yard_rounded, _hasGarden, (v) => setState(() => _hasGarden = v)),
            _buildFeatureToggle(l10n?.parking ?? 'Parking', Icons.local_parking_rounded, _hasParking, (v) => setState(() => _hasParking = v)),
            _buildFeatureToggle(l10n?.pool ?? 'Pool', Icons.pool_rounded, _hasPool, (v) => setState(() => _hasPool = v)),
          ]),
          
          const SizedBox(height: 24),
          
          // Building Features
          _buildFeatureSection(l10n?.buildingFeatures ?? 'Building Features', [
            _buildFeatureToggle(l10n?.security ?? 'Security', Icons.security_rounded, _hasSecurity, (v) => setState(() => _hasSecurity = v)),
            _buildFeatureToggle(l10n?.gym ?? 'Gym', Icons.fitness_center_rounded, _hasGym, (v) => setState(() => _hasGym = v)),
            _buildFeatureToggle(l10n?.waterWell ?? 'Water Well', Icons.water_drop_rounded, _hasWaterWell, (v) => setState(() => _hasWaterWell = v)),
            _buildFeatureToggle(l10n?.petFriendly ?? 'Pet Friendly', Icons.pets_rounded, _hasPetFriendly, (v) => setState(() => _hasPetFriendly = v)),
          ]),
          
          const SizedBox(height: 24),
          
          // Nearby
          _buildFeatureSection(l10n?.nearby ?? 'Nearby', [
            _buildFeatureToggle(l10n?.nearbySchools ?? 'Schools', Icons.school_rounded, _hasNearbySchools, (v) => setState(() => _hasNearbySchools = v)),
            _buildFeatureToggle(l10n?.nearbyHospitals ?? 'Hospitals', Icons.local_hospital_rounded, _hasNearbyHospitals, (v) => setState(() => _hasNearbyHospitals = v)),
            _buildFeatureToggle(l10n?.nearbyShopping ?? 'Shopping', Icons.shopping_cart_rounded, _hasNearbyShopping, (v) => setState(() => _hasNearbyShopping = v)),
            _buildFeatureToggle(l10n?.publicTransport ?? 'Public Transport', Icons.directions_bus_rounded, _hasPublicTransport, (v) => setState(() => _hasPublicTransport = v)),
          ]),
        ],
      ),
    );
  }
  
  Widget _buildFeatureSection(String title, List<Widget> features) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: features,
        ),
      ],
    );
  }
  
  Widget _buildFeatureToggle(String label, IconData icon, bool value, Function(bool) onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: value ? const Color(0xFF01352D) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value ? const Color(0xFF01352D) : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: value ? Colors.white : Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: value ? Colors.white : Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Step 5: Photos
  Widget _buildStep5Photos(AppLocalizations? l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            icon: Icons.photo_library_rounded,
            title: l10n?.photos ?? 'Add Photos',
            subtitle: l10n?.showItOff ?? 'Show off your property with great photos',
          ),
          const SizedBox(height: 24),
          
          // Upload Area
          GestureDetector(
            onTap: _pickImages,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF01352D).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_photo_alternate_rounded,
                      size: 48,
                      color: Color(0xFF01352D),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n?.selectImages ?? 'Tap to add photos',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n?.maxImages ?? 'You can add up to 10 photos',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Photo Count
          Text(
            '${_selectedImages.length}/10 ${l10n?.photosAdded ?? 'photos added'}',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Selected Images Grid
          if (_selectedImages.isNotEmpty)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: kIsWeb
                          ? Image.network(
                              _selectedImages[index].path,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            )
                          : Image.file(
                              io.File(_selectedImages[index].path),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedImages.removeAt(index);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    if (index == 0)
                      Positioned(
                        bottom: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF01352D),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            l10n?.featured ?? 'Cover',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          
          const SizedBox(height: 20),
          
          // Tips
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.tips_and_updates_rounded, color: Colors.amber[700], size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.proTip ?? 'Photo Tips',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[900],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n?.photoTipsDescription ?? '• Use good lighting\n• Show all rooms\n• Include exterior photos',
                        style: TextStyle(
                          color: Colors.amber[800],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper Widgets
  Widget _buildStepHeader({required IconData icon, required String title, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF01352D).withValues(alpha: 0.1),
            const Color(0xFF01352D).withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF01352D),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.grey[700],
      ),
    );
  }
  
  InputDecoration _buildInputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400]),
      prefixIcon: Icon(icon, color: const Color(0xFF01352D)),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF01352D), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
  
  // Keep the old build method content below for the actual form submission logic
  // This is a compatibility bridge - the actual form fields are now in step widgets
  Widget _buildOldFormContent(AppLocalizations? l10n) {
    // Original form code moved to step widgets above
    return const SizedBox.shrink();
  }
  
  // Original Section Title Widget (kept for compatibility)
  Widget _buildSectionTitleOriginal(String title) {
    return _buildSectionTitle(title);
  }
  

  Widget _buildSectionTitle(String title) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 400),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20, top: 8),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 24,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF01352D),
                          Color(0xFF01352D),
                        ],
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(2)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: ThemeService.getHeadingStyle(
                      context,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF01352D),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedCard({required int delay, required Widget child}) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 500 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: Transform.scale(
              scale: 0.95 + (0.05 * value),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                elevation: 0,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05 * value),
                        blurRadius: 20,
                        offset: Offset(0, 4 * value),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildFeaturesGrid(AppLocalizations? l10n) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              elevation: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF01352D),
                      Color(0xFF01352D),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF01352D).withValues(alpha: 0.3), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF01352D).withValues(alpha: 0.15 * value),
                      blurRadius: 15,
                      offset: Offset(0, 4 * value),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final chipWidth = (constraints.maxWidth - 12) / 2;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                    children: [
                           _buildFeatureChip(l10n?.balcony ?? 'Balcony', Icons.balcony, _hasBalcony, (value) => setState(() => _hasBalcony = value), width: chipWidth),
                           _buildFeatureChip(l10n?.garden ?? 'Garden', Icons.yard, _hasGarden, (value) => setState(() => _hasGarden = value), width: chipWidth),
                           _buildFeatureChip(l10n?.parking ?? 'Parking', Icons.local_parking, _hasParking, (value) => setState(() => _hasParking = value), width: chipWidth),
                           _buildFeatureChip(l10n?.pool ?? 'Pool', Icons.pool, _hasPool, (value) => setState(() => _hasPool = value), width: chipWidth),
                           _buildFeatureChip(l10n?.gym ?? 'Gym', Icons.fitness_center, _hasGym, (value) => setState(() => _hasGym = value), width: chipWidth),
                           _buildFeatureChip(l10n?.security ?? 'Security', Icons.security, _hasSecurity, (value) => setState(() => _hasSecurity = value), width: chipWidth),
                           _buildFeatureChip(l10n?.elevator ?? 'Elevator', Icons.elevator, _hasElevator, (value) => setState(() => _hasElevator = value), width: chipWidth),
                           _buildFeatureChip(l10n?.ac ?? 'Air Conditioning', Icons.ac_unit, _hasAC, (value) => setState(() => _hasAC = value), width: chipWidth),
                           _buildFeatureChip(l10n?.heating ?? 'Heating', Icons.thermostat, _hasHeating, (value) => setState(() => _hasHeating = value), width: chipWidth),
                           _buildFeatureChip(l10n?.waterWell ?? 'Water Well', Icons.water_drop, _hasWaterWell, (value) => setState(() => _hasWaterWell = value), width: chipWidth),
                           _buildFeatureChip(l10n?.furnished ?? 'Furnished', Icons.chair, _hasFurnished, (value) => setState(() => _hasFurnished = value), width: chipWidth),
                           _buildFeatureChip(l10n?.petFriendly ?? 'Pet Friendly', Icons.pets, _hasPetFriendly, (value) => setState(() => _hasPetFriendly = value), width: chipWidth),
                           _buildFeatureChip(l10n?.nearbySchools ?? 'Nearby Schools', Icons.school, _hasNearbySchools, (value) => setState(() => _hasNearbySchools = value), width: chipWidth),
                           _buildFeatureChip(l10n?.nearbyHospitals ?? 'Nearby Hospitals', Icons.local_hospital, _hasNearbyHospitals, (value) => setState(() => _hasNearbyHospitals = value), width: chipWidth),
                           _buildFeatureChip(l10n?.nearbyShopping ?? 'Nearby Shopping', Icons.shopping_cart, _hasNearbyShopping, (value) => setState(() => _hasNearbyShopping = value), width: chipWidth),
                           _buildFeatureChip(l10n?.publicTransport ?? 'Public Transport', Icons.directions_transit, _hasPublicTransport, (value) => setState(() => _hasPublicTransport = value), width: chipWidth),
                    ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        );
      },
      child: null,
    );
  }

  Widget _buildPlatformImage(String path) {
    // This method is only called when !kIsWeb, so File is available
    // On web, Image.network is used directly in the widget tree
    return Image.file(
      _createFileFromPath(path),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[300],
          child: const Icon(
            Icons.image,
            color: Colors.grey,
            size: 40,
          ),
        );
      },
    );
  }

  dynamic _createFileFromPath(String path) {
    // This will only be called when !kIsWeb due to kIsWeb check above
    if (kIsWeb) {
      // This branch should never execute, but needed for type checking
      return path;
    }
    return io.File(path);
  }

  Widget _buildFeatureChip(String title, IconData icon, bool value, ValueChanged<bool> onChanged, {double? width}) {
    final chip = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
            color: value 
                ? Colors.white.withValues(alpha: 0.25) 
                : Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: value ? Colors.white : Colors.white.withValues(alpha: 0.5),
              width: value ? 2 : 1.5,
            ),
            boxShadow: value
                ? [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
          ),
                  ]
                : null,
        ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
          title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
          ),
                  maxLines: 2,
                  overflow: TextOverflow.visible,
                  softWrap: true,
                ),
              ),
            ],
          ),
      ),
      ),
    );

    if (width != null) {
      return SizedBox(width: width, child: chip);
    }
    return chip;
  }

  Widget _buildUpgradeAdSection() {
    return _buildAnimatedCard(
      delay: 690,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.amber.shade600, Colors.orange.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(
                  Icons.star,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n?.upgradeBoost ?? 'Upgrade Your Ad',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l10n?.boostDescription ?? 'Make your property stand out with premium features!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            if (_selectedPackageId != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF01352D).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF01352D), width: 2),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: const Color(0xFF01352D).withValues(alpha: 0.7), size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n?.packageSelectedWithPrice(_selectedPackageName ?? '', _selectedPackagePrice?.toInt().toString() ?? '0') ?? 'Package Selected: $_selectedPackageName (${_selectedPackagePrice?.toInt()} LYD)',
                        style: const TextStyle(
                          color: Color(0xFF01352D),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showUpgradeModal,
                icon: const Icon(Icons.upgrade, color: Colors.white),
                label: Text(
                  _selectedPackageId != null ? (l10n?.changePackage ?? 'Change Package') : (l10n?.selectPackage ?? 'Select Package'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpgradeModal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          l10n?.selectPackage ?? 'Select Package for Your Property',
          style: const TextStyle(color: Colors.black87, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n?.chooseBoostPackage ?? 'Choose a package to boost your property listing:',
              style: TextStyle(color: Colors.grey[700], fontSize: 16),
            ),
            const SizedBox(height: 20),
            _buildUpgradePackage(
              title: l10n?.plusBoost ?? 'Plus Boost',
              price: '20 LYD',
              duration: l10n?.durationOneDay ?? '1 Day',
              features: [l10n?.priorityPlacement ?? 'Top listing position', l10n?.increasedVisibility ?? 'Increased visibility'],
              color: Colors.brown,
              packageId: 'plus',
              packagePrice: 20.0,
              isSelected: _selectedPackageId == 'plus',
              onTap: () {
                setState(() {
                  _selectedPackageId = 'plus';
                  _selectedPackageName = l10n?.plusBoost ?? 'Plus Boost';
                  _selectedPackagePrice = 20.0;
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${l10n?.plusBoost ?? 'Plus Boost'} ${l10n?.packageSelected ?? 'package selected for your property'}'),
                    backgroundColor: Colors.brown,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildUpgradePackage(
              title: l10n?.emeraldBoost ?? 'Emerald Boost',
              price: '50 LYD',
              duration: l10n?.durationThreeDays ?? '3 Days',
              features: [l10n?.priorityPlacement ?? 'Priority position', l10n?.increasedVisibility ?? '3x more views', l10n?.featuredBadge ?? 'Emerald badge'],
              color: const Color(0xFF10B981),
              packageId: 'emerald',
              packagePrice: 50.0,
              isSelected: _selectedPackageId == 'emerald',
              onTap: () {
                setState(() {
                  _selectedPackageId = 'emerald';
                  _selectedPackageName = l10n?.emeraldBoost ?? 'Emerald Boost';
                  _selectedPackagePrice = 50.0;
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(
                    content: Text('${l10n?.emeraldBoost ?? 'Emerald Boost'} ${l10n?.packageSelected ?? 'package selected for your property'}'),
                    backgroundColor: const Color(0xFF10B981),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildUpgradePackage(
              title: l10n?.premiumBoost ?? 'Premium Boost',
              price: '100 LYD',
              duration: l10n?.durationSevenDays ?? '7 Days',
              features: [l10n?.increasedVisibility ?? 'Maximum visibility', l10n?.featuredBadge ?? 'Featured everywhere', l10n?.premiumSupport ?? 'Priority support'],
              color: Colors.grey.shade700,
              packageId: 'premium',
              packagePrice: 100.0,
              isSelected: _selectedPackageId == 'premium',
              onTap: () {
                setState(() {
                  _selectedPackageId = 'premium';
                  _selectedPackageName = l10n?.premiumBoost ?? 'Premium Boost';
                  _selectedPackagePrice = 100.0;
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${l10n?.premiumBoost ?? 'Premium Boost'} ${l10n?.packageSelected ?? 'package selected for your property'}'),
                    backgroundColor: Colors.grey.shade600,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildUpgradePackage(
              title: l10n?.eliteBoost ?? 'Elite Boost',
              price: '300 LYD',
              duration: l10n?.durationThirtyDays ?? '30 Days',
              features: [l10n?.priorityPlacement ?? 'Permanent top spot', l10n?.eliteBranding ?? 'Elite branding', l10n?.dedicatedSupport ?? 'Dedicated support', l10n?.featuredBadge ?? 'Featured badge'],
              color: Colors.amber.shade700,
              packageId: 'elite',
              packagePrice: 300.0,
              isSelected: _selectedPackageId == 'elite',
              onTap: () {
                setState(() {
                  _selectedPackageId = 'elite';
                  _selectedPackageName = l10n?.eliteBoost ?? 'Elite Boost';
                  _selectedPackagePrice = 300.0;
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${l10n?.eliteBoost ?? 'Elite Boost'} ${l10n?.packageSelected ?? 'package selected for your property'}'),
                    backgroundColor: Colors.amber.shade700,
                  ),
                );
              },
            ),
            if (_selectedPackageId != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF01352D).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF01352D)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Color(0xFF01352D)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n?.selectedWithPrice(_selectedPackageName ?? '', _selectedPackagePrice?.toInt().toString() ?? '0') ?? 'Selected: $_selectedPackageName (${_selectedPackagePrice?.toInt()} LYD)',
                        style: const TextStyle(
                          color: Color(0xFF01352D),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (_selectedPackageId != null)
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedPackageId = null;
                  _selectedPackageName = null;
                  _selectedPackagePrice = null;
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n?.packageCleared ?? 'Package selection cleared'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              child: Text(
                l10n?.clearSelection ?? 'Clear Selection',
                style: TextStyle(color: Colors.orange.shade700, fontSize: 16),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              l10n?.close ?? 'Close',
              style: const TextStyle(color: Color(0xFF01352D), fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradePackage({
    required String title,
    required String price,
    required String duration,
    required List<String> features,
    required Color color,
    required String packageId,
    required double packagePrice,
    required bool isSelected,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
            ? color.withValues(alpha: 0.3)
            : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.5), 
            width: isSelected ? 3 : 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: _getColorValue(color),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      price,
                      style: TextStyle(
                        color: _getColorValue(color),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.check_circle,
                        color: _getColorValue(color),
                        size: 20,
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              duration,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            ...features.map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.check,
                    color: _getColorValue(color),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    feature,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Color _getColorValue(Color color) {
    if (color is MaterialColor) {
      return color.shade700;
    }
    return color;
  }

  Widget _buildLoginRequiredScreen(BuildContext context, AppLocalizations? l10n) {
    return Column(
      children: [
        AppBar(
          title: Text(
            l10n?.addPropertyTitle ?? 'Add Property',
            style: ThemeService.getHeadingStyle(
              context,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFF01352D),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n?.loginRequired ?? 'Login Required',
                    style: ThemeService.getHeadingStyle(
                      context,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n?.pleaseLoginToAddProperty ?? 'Please login to add properties to the platform',
                    textAlign: TextAlign.center,
                    style: ThemeService.getBodyStyle(
                      context,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => context.go('/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF01352D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    child: Text(
                      l10n?.login ?? 'Login',
                      style: ThemeService.getBodyStyle(
                        context,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.go('/'),
                    child: Text(
                      l10n?.backToHome ?? 'Back to Home',
                      style: ThemeService.getBodyStyle(
                        context,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}