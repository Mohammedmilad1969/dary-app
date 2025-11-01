import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' if (dart.library.html) '../utils/file_stub.dart' show File;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../models/property.dart';
import '../services/language_service.dart';
import '../widgets/language_toggle_button.dart';
import '../providers/auth_provider.dart';
import '../services/property_service.dart' as property_service;
import '../services/persistence_service.dart';
import '../services/image_upload_service.dart';
import '../services/theme_service.dart';
import '../widgets/property_limit_modal.dart';
import '../services/wallet_service.dart';

// Libya timezone (GMT+2) and current date
const libyaTimeZone = Duration(hours: 2);
final baseDate = DateTime(2025, 10, 28); // October 28, 2025

DateTime getCurrentLibyaTime() {
  return baseDate.add(libyaTimeZone);
}

class AddPropertyScreen extends StatefulWidget {
  final Property? propertyToEdit; // Optional property to edit
  
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
    _titleController.text = property.title;
    _descriptionController.text = property.description;
    _priceController.text = property.price.toStringAsFixed(0);
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
      final availableNeighborhoods = _cityNeighborhoods[cityValue] ?? [];
      
      if (neighborhoodValue != null && neighborhoodValue.isNotEmpty) {
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
      _yearBuiltController.text = property.yearBuilt.toString();
    }
    
    // Set rent fields if applicable
    if (property.status == PropertyStatus.forRent) {
      if (property.monthlyRent > 0) {
        _monthlyRentController.text = property.monthlyRent.toStringAsFixed(0);
        _selectedRentType = 'monthly';
      } else if (property.dailyRent > 0) {
        _dailyRentController.text = property.dailyRent.toStringAsFixed(0);
        _selectedRentType = 'daily';
      }
    }
    
    if (property.deposit > 0) {
      _depositController.text = property.deposit.toStringAsFixed(0);
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
    final propertyLimit = (userDoc.data()?['propertyLimit'] as num?)?.toInt() ?? 5;

    if (kDebugMode) {
      debugPrint('🔍 Checking property limit on screen open:');
      debugPrint('   Actual Total Listings: $actualPropertyCount');
      debugPrint('   Property Limit from Firestore: $propertyLimit');
      debugPrint('   Can Add Property: ${actualPropertyCount < propertyLimit}');
    }

    if (actualPropertyCount >= propertyLimit) {
      if (kDebugMode) {
        debugPrint('⚠️ User has reached property limit! Showing modal...');
      }
    
      if (!mounted) return;
    
      // Show property limit modal
      final purchaseMade = await showDialog<bool>(
        context: context,
        builder: (context) => PropertyLimitModal(
          currentLimit: propertyLimit,
          currentProperties: actualPropertyCount,
          maxLimit: 20,
        ),
      );

      // After modal closes, re-check from Firestore
      final newActualCount = await propertyService.getUserPropertyCount(currentUser.id);
      final newUserDoc = await firestore.collection('users').doc(currentUser.id).get();
      final newPropertyLimit = (newUserDoc.data()?['propertyLimit'] as num?)?.toInt() ?? 5;
    
      // If user canceled and still can't add, go back
      if (purchaseMade != true && newActualCount >= newPropertyLimit) {
        if (mounted) {
          context.go('/');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('You have reached your property limit. Please purchase more slots to add properties.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 4),
              ),
            );
          }
        }
        return; // Exit without adding property
      } else if (purchaseMade == true) {
        // Purchase was made, allow user to continue (don't check limit again)
        if (kDebugMode) {
          debugPrint('✅ Slot purchase successful, allowing property creation');
        }
        _shouldCheckLimit = false;
      }
    }
  }

  // Map of cities to their neighborhoods
final Map<String, List<String>> _cityNeighborhoods = {
  'Tripoli': [
    'Abu Salim (أبو سليم)',
    'Ain Zara (عين زارة)',
    'Airport Road (طريق المطار)',
    'Al Falah (الفلاح)',
    'Al Hadba (الهضبة)',
    'Al Hamrouniya (الحمروانية)',
    'Al Jazeera (الجزيرة)',
    'Al Krimiya (الكريمية)',
    'Al Mashroa (المشروع)',
    'Al Najma (النجمة)',
    'Al Rasheed (الرشيد)',
    'Al Zawya (الزاوية)',
    'Bab Ben Ghashir (باب بن غشير)',
    'Ben Ashour (بن عاشور)',
    'Dahra (الظهرة)',
    'Fornaj (الفورنجي)',
    'Gargharesh (قرقارش)',
    'Gargaresh West (قرقارش الغربية)',
    'Ghout Al Shaal (غوط الشعال)',
    'Hay Al Moharrar (حي المحرر)',
    'Hay Andalus (حي الأندلس)',
    'Hai Shariq (حي الشرق)',
    'Janzour (جنزور)',
    'Melliha (المليحة)',
    'Old City (المدينة القديمة)',
    'Qasr Bin Ghashir (قصر بن غشير)',
    'Ras Hassan (رأس حسن)',
    'Sarraj (السراج)',
    'Sidi Al Masri (سيدي المصري)',
    'Sidi Khalifa (سيدي خليفة)',
    'Siyahiya (السياحية)',
    'Souq Al Juma (سوق الجمعة)',
    'Tajoura (تاجوراء)',
    'Zawiyat Al Dahmani (زاوية الدهماني)',
  ],
  'Benghazi': [
    'Al Alaili (العليلي)',
    'Al Berka (البركة)',
    'Al Bersa (البركة الجديدة)',
    'Al Fataeh (الفتائح)',
    'Al Fwayhat (الفويهات)',
    'Al Hawari (الهواري)',
    'Al Khaleej (الخليج)',
    'Al Kish (الكويش)',
    'Al Leithy (الليثي)',
    'Al Majouri (المجوري)',
    'Al Manar (المنار)',
    'Al Qish (القش)',
    'Al Quraysh (القريش)',
    'Al Sabri (الصابري)',
    'Al Suq Al Arabi (السوق العربي)',
    'Benina (بنينة)',
    'Bouhdima (بوهديمة)',
    'Bu Atni (بوعطني)',
    'El Salmani (السلماني)',
    'Gwarsha (قوراشة)',
    'Sidi Hussein (سيدي حسين)',
    'Sidi Khalifa (سيدي خليفة)',
    'Souq Al Jreed (سوق الجريد)',
  ],
  'Mişrātah': [
    'Airport Road (طريق المطار)',
    'Al Ahrar (الأحرار)',
    'Al Diriya (الدرية)',
    'Al Fatah (الفتح)',
    'Al Ghanimah (الغنيمة)',
    'Al Jazeera (الجزيرة)',
    'Al Kararim (الكراريم)',
    'Al Khums Road (طريق الخمس)',
    'Al Mashroa (المشروع)',
    'Al Skikdar (السكيكدار)',
    'Al Souq Al Qadim (السوق القديم)',
    'Al Thahra (الظهرة)',
    'Al Zaweya (الزاوية)',
    'City Center (وسط المدينة)',
    'Dafniyah (دفنية)',
    'Industrial Area (المنطقة الصناعية)',
    'North Misrata (مصراتة الشمالية)',
    'Qasr Ahmad Port (ميناء قصر أحمد)',
    'Zerouq (زروق)',
  ],
  'Al Bayḑā\'': [
    'Al Abraq (الأبرق)',
    'Al Bayda (البيضاء)',
    'Al Fassuqa (الفاسوقة)',
    'Al Haniya (الهنية)',
    'Al Jazeera (الجزيرة)',
    'Al Manara (المنارة)',
    'Al Masakin (المساكن)',
    'Al Qasr (القصر)',
    'Al Sahel (الساحل)',
    'Bab Al Bahr (باب البحر)',
    'City Center (وسط المدينة)',
    'Masah (مسّه)',
    'Shahat (شحات)',
    'Zawiyat Al Baida (زاوية البيضاء)',
  ],
  'Tobruk': [
    'Al Gharbya (المنطقة الغربية)',
    'Al Mahatta (المحطة)',
    'Al Manshiya (المنشية)',
    'Al Mashreq (المشرق)',
    'Al Qawarish (القوارش)',
    'Al Rawda (الروضة)',
    'Al Sahel (الساحل)',
    'City Center (وسط المدينة)',
    'Hariga (هريقة)',
    'Martuba (مرتوبة)',
    'Port Area (منطقة الميناء)',
    'Umm Al-Rizam (أم الرزم)',
  ],
  'Sabratha': [
    'Al Garah (القارة)',
    'Al Harsha (الحرشة)',
    'Al Jazeera (الجزيرة)',
    'Al Maamoura (المعمورة)',
    'Beach Area (المنطقة الساحلية)',
    'City Center (وسط المدينة)',
    'Coastal Road (الطريق الساحلي)',
    'Ruins Area (منطقة الآثار)',
    'Sidi Bilal (سيدي بلال)',
    'Sorman Road (طريق صرمان)',
  ],
  'Surt': [
    'Al Fatah (الفتح)',
    'Al Thalatheen (الثلاثين)',
    'Bin Jawad Road (طريق بن جواد)',
    'Bou Grain (بو قرين)',
    'City Center (وسط المدينة)',
    'Gardabiya (القرضابية)',
    'Harbor Area (منطقة الميناء)',
    'Noofliya (النوفلية)',
    'Sawawa (سواوة)',
    'Tagreft (تغريف)',
    'Wadi Jarif (وادي جارف)',
    'West Sirt (سرت الغربية)',
    'Zaafran (الزعفران)',
  ],
  'Zawiya': [
    'Abu Issa (أبو عيسى)',
    'Al Jamail (الجميل)',
    'Al Maya (المعاية)',
    'Al Qarara (القرارة)',
    'Bir Al Ghanam (بئر الغنم)',
    'City Center (وسط المدينة)',
    'Harsha (الحرشة)',
    'Industrial Zone (المنطقة الصناعية)',
    'Janzur Road (طريق جنزور)',
    'Sabratha Road (طريق صبراتة)',
    'Zawiya West (الزاوية الغربية)',
  ],
  'Sabha': [
    'Airport District (حي المطار)',
    'Al Gadadfa (القذاذفة)',
    'Al Hajara (الحجرة)',
    'Al Jadid (الجديد)',
    'Al Jazeera (الجزيرة)',
    'Al Mahdia (المهدية)',
    'Al Nasiriya (الناصرية)',
    'Al Sukra (السكّرة)',
    'Al Tayouri (الطيوري)',
    'City Center (وسط المدينة)',
    'Hajara South (الحجرة الجنوبية)',
    'Manshiya (المنشية)',
    'Qarda (قاردة)',
  ],
  'Derna': [
    'Al Fataeh (الفتائح)',
    'Al Sahel (الساحل)',
    'Al Sahari (السهاري)',
    'Bab Sheha (باب شيحا)',
    'Bab Shha North (باب شيحا الشمالية)',
    'Bab Tobruk (باب طبرق)',
    'City Center (وسط المدينة)',
    'Old Port (الميناء القديم)',
    'Ras Al Hilal Road (طريق رأس الهلال)',
    'Sahaba Street (شارع الصحابة)',
    'Wadi Derna (وادي درنة)',
  ],
  'Zliten': [
    'Al Fakhriya (الفخرية)',
    'Al Hara Al Gharbiya (الحارة الغربية)',
    'Al Hara Al Sharqiya (الحارة الشرقية)',
    'Al Jazeera (الجزيرة)',
    'Al Khoms Road (طريق الخمس)',
    'Al Mahdia (المهدية)',
    'Al Mansoura (المنصورة)',
    'Al Qasr (القصر)',
    'City Center (وسط المدينة)',
    'Souq Al Thulatha (سوق الثلاثاء)',
    'Wadi Kaam (وادي كام)',
  ],
  'Khoms': [
    'Al Fursiya (الفروسية)',
    'Al Jawhara (الجوهرة)',
    'Al Qasr (القصر)',
    'Al Sabaa (السباع)',
    'Al Sokkah (السكة)',
    'Al Zahra (الزهرة)',
    'City Center (وسط المدينة)',
    'Industrial Zone (المنطقة الصناعية)',
    'Leptis Area (منطقة لبدة)',
    'Leptis Port (ميناء لبدة)',
  ],
  'Ajdabiya': [
    'Al Hadaiq (الحدائق)',
    'Al Manar (المنار)',
    'Al Quds (القدس)',
    'Al Salam (السلام)',
    'Brega Road (طريق البريقة)',
    'City Center (وسط المدينة)',
    'Gate Area (منطقة البوابة)',
    'Industrial Zone (المنطقة الصناعية)',
    'North Ajdabiya (أجدابيا الشمالية)',
    'South Ajdabiya (جنوب أجدابيا)',
  ],
  'Ghadames': [
    'Airport Area (منطقة المطار)',
    'Al Garah (القارة)',
    'Al Saha (الساحة)',
    'New Town (المدينة الجديدة)',
    'North Ghadames (غدامس الشمالية)',
    'Old Town (المدينة القديمة)',
    'Tourist Quarter (المنطقة السياحية)',
  ],
  'Ghat': [
    'Airport Area (منطقة المطار)',
    'Al Awinat (العوينات)',
    'Al Barkat (البركت)',
    'City Center (وسط المدينة)',
    'Desert Camp (المخيم الصحراوي)',
    'Old Ghat (غات القديمة)',
  ],
  'Nalut': [
    'Al Garah (القارة)',
    'Al Haraba (الحرابة)',
    'City Center (وسط المدينة)',
    'Mountain Area (المنطقة الجبلية)',
    'Old Nalut (نالوت القديمة)',
    'Western Nalut (نالوت الغربية)',
  ],
  'Al Marj': [
    'Abyar Road (طريق الأبيار)',
    'Al Hijaz (الحجاز)',
    'Al Shajara (الشجرة)',
    'City Center (وسط المدينة)',
    'Eastern Marj (المرج الشرقية)',
    'Green Belt (الحزام الأخضر)',
  ],
  'Al Kufra': [
    'Al Jawf (الجوف)',
    'City Center (وسط المدينة)',
    'Industrial Area (المنطقة الصناعية)',
    'Rebiana (ربيانة)',
    'South Kufra (الكفرة الجنوبية)',
    'Tazirbu (تازربو)',
  ],
  'Murzuq': [
    'Airport Area (منطقة المطار)',
    'Al Qadisiya (القادسية)',
    'Al Salam (السلام)',
    'City Center (وسط المدينة)',
    'Murzuq South (مرزق الجنوبية)',
    'Old Murzuq (مرزق القديمة)',
    'Qatrun Road (طريق القطرون)',
  ],
};


  // Libyan cities list
  final List<String> _libyanCities = [
    'Tripoli',
    'Benghazi',
    'Ajdābiyā',
    'Mişrātah',
    'Al Bayḑā\'',
    'Al Khums',
    'Az Zāwīyah',
    'Gharyān',
    'Al Marj',
    'Tobruk',
    'Şabrātah',
    'Al Jumayl',
    'Darnah',
    'Janzūr',
    'Zuwārah',
    'Masallātah',
    'Surt',
    'Yafran',
    'Nālūt',
    'Banī Walīd',
    'Tājūrā\'',
    'Birāk',
    'Shaḩḩāt',
    'Murzuq',
    'Awbārī',
    'Qaşr al Qarabūllī',
    'Waddān',
    'Al Qubbah',
    'Al \'Azīzīyah',
    'Mizdah',
    'Tūkrah',
    'Ghāt',
    'Az Zuwaytīnah',
    'Hūn',
    'Qaryat al Qī\'ān',
    'Al Jawf',
    'Zalţan',
    'Az Zintān',
    'Qaryat Sulūq',
    'Tarhūnah',
    'Umm ar Rizam',
    'Qamīnis',
    'Kiklah',
    'Ghadāmis',
    'Sūknah',
    'As Sidrah',
    'Al Bardīyah',
    'Al Abraq',
    'Bin Jawwād',
    'Sūsah',
    'Martūbah',
    'Al Qayqab',
    'Musā\'id',
    'Tāknis',
    'Al Burayqah',
    'Awjilah',
    'Farzūghah',
    'Qaryat \'Umar al Mukhtār',
    'Bi\'r al Ashhab',
    'Qaryat al Fā\'idīyah',
    'Jardas al \'Abīd',
    'Qandūlah',
    'Kambūt',
    'Daryānah',
    'Marāwah',
    'Jikharrah',
    'Zawīlah',
    'Wāzin',
    'Qirnādah',
    'Bi\'r al Ghanam',
    'Ar Rajmah',
    'Al Jaghbūb',
    'Sabhā',
    'Idrī',
  ];
  final _bedroomsController = TextEditingController();
  final _bathroomsController = TextEditingController();
  final _floorsController = TextEditingController();
  final _yearBuiltController = TextEditingController();
  final _monthlyRentController = TextEditingController();
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
  bool _hasNearbySchools = false;
  bool _hasNearbyHospitals = false;
  bool _hasNearbyShopping = false;
  bool _hasPublicTransport = false;
  
  List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;
  bool _isUploadingImages = false;

  // Get neighborhoods for selected city
  List<String> get _availableNeighborhoods {
    if (_selectedCity == null) return [];
    return _cityNeighborhoods[_selectedCity!] ?? ['Other'];
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
    _yearBuiltController.dispose();
    _monthlyRentController.dispose();
    _dailyRentController.dispose();
    _depositController.dispose();
    _landSizeController.dispose();
    _buildingSizeController.dispose();
    super.dispose();
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
          color: isSelected ? Colors.green : Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey[600]!,
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
          color: isSelected ? Colors.green : Colors.grey[800],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey[600]!,
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
        await showDialog(
          context: context,
          builder: (context) => PropertyLimitModal(
            currentLimit: currentUser.propertyLimit,
            currentProperties: currentUser.totalListings,
            maxLimit: 20,
          ),
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
          await propertyService.syncUserPropertyCount(currentUser.id);
          await authProvider.refreshUser();
          
          final finalCheckUser = authProvider.currentUser;
          if (finalCheckUser == null || !finalCheckUser.canAddProperty) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('You have reached your property limit. Please purchase more slots.'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 3),
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
              ? (double.tryParse(_priceController.text) ?? 0.0)
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
          yearBuilt: int.tryParse(_yearBuiltController.text) ?? 0,
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
          hasNearbySchools: _hasNearbySchools,
          hasNearbyHospitals: _hasNearbyHospitals,
          hasNearbyShopping: _hasNearbyShopping,
          hasPublicTransport: _hasPublicTransport,
          monthlyRent: (_selectedStatus == PropertyStatus.forRent && _selectedRentType == 'monthly')
              ? (double.tryParse(_monthlyRentController.text) ?? 0.0)
              : 0.0,
          dailyRent: (_selectedStatus == PropertyStatus.forRent && _selectedRentType == 'daily')
              ? (double.tryParse(_dailyRentController.text) ?? 0.0)
              : 0.0,
          deposit: double.tryParse(_depositController.text) ?? 0.0,
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
              content: Text('Uploading ${_selectedImages.length} images...'),
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
          imageUrls: isEditing && imageUrls.isEmpty 
              ? widget.propertyToEdit!.imageUrls // Keep existing images if no new ones uploaded
              : imageUrls.isNotEmpty ? imageUrls : (isEditing ? widget.propertyToEdit!.imageUrls : []), // Use uploaded images or existing
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
              throw Exception('Insufficient wallet balance. Please add funds to your wallet.');
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
              throw Exception('Payment failed. Please try again.');
            }
            
            if (kDebugMode) {
              debugPrint('✅ Wallet charged ${_selectedPackagePrice} LYD for boost package: $_selectedPackageName');
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
                content: const Text('Property updated successfully!'),
                backgroundColor: Colors.green,
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
                  ? '${l10n?.propertyAddedSuccessfully ?? 'Property added successfully!'} Boost package activated!'
                  : l10n?.propertyAddedSuccessfully ?? 'Property added successfully!'),
                backgroundColor: Colors.green,
              ),
            );

            _clearForm();
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
    _yearBuiltController.clear();
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
      return _buildLoginRequiredScreen(context, l10n);
    }

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.green.shade600,
                Colors.green.shade700,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: AppBar(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add_home, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  widget.propertyToEdit != null 
                    ? 'Edit Property'
                    : (l10n?.addPropertyTitle ?? 'Add Property'),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              LanguageToggleButton(languageService: languageService),
            ],
          ),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.grey.shade50,
                  Colors.white,
                  Colors.grey.shade50,
                ],
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Theme(
                data: Theme.of(context).copyWith(
                  inputDecorationTheme: InputDecorationTheme(
                    filled: true,
                    fillColor: Colors.white,
                    labelStyle: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                      borderSide: BorderSide(color: Colors.green.shade600, width: 2.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.red, width: 1.5),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.red, width: 2.5),
                    ),
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      // Basic Information Section
                      _buildSectionTitle(l10n?.basicInformation ?? 'Basic Information'),
                      
                      _buildAnimatedCard(
                        delay: 0,
                        child: Column(
                          children: [
                            // Title Field
                            TextFormField(
                              controller: _titleController,
                              style: ThemeService.getBodyStyle(
                                context,
                                color: Colors.black87,
                              ),
                              decoration: InputDecoration(
                                labelText: l10n?.propertyTitle ?? 'Property Title',
                                labelStyle: ThemeService.getBodyStyle(context),
                                hintText: l10n?.enterPropertyTitle ?? 'Enter property title',
                                hintStyle: ThemeService.getBodyStyle(context),
                                prefixIcon: const Icon(Icons.title),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return l10n?.pleaseEnterTitle ?? 'Please enter a title';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Description Field
                            TextFormField(
                              controller: _descriptionController,
                              style: ThemeService.getBodyStyle(
                                context,
                                color: Colors.black87,
                              ),
                              decoration: InputDecoration(
                                labelText: l10n?.description ?? 'Description',
                                labelStyle: ThemeService.getBodyStyle(context),
                                hintText: l10n?.describeYourProperty ?? 'Describe your property',
                                hintStyle: ThemeService.getBodyStyle(context),
                                prefixIcon: const Icon(Icons.description),
                              ),
                              maxLines: 4,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return l10n?.pleaseEnterDescription ?? 'Please enter a description';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Property Type and Status
                      _buildAnimatedCard(
                        delay: 100,
                        child: Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<PropertyType>(
                                value: _selectedType,
                                style: ThemeService.getBodyStyle(
                                  context,
                                  color: Colors.black87,
                                ),
                                decoration: InputDecoration(
                                  labelText: l10n?.propertyType ?? 'Property Type',
                                  labelStyle: ThemeService.getBodyStyle(context),
                                  prefixIcon: const Icon(Icons.home),
                                ),
                                items: PropertyType.values.map((type) {
                                  return DropdownMenuItem(
                                    value: type,
                                    child: Text(
                                      type.typeDisplayName,
                                      style: ThemeService.getBodyStyle(context),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedType = value!;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<PropertyStatus>(
                                value: _selectedStatus,
                                style: ThemeService.getBodyStyle(
                                  context,
                                  color: Colors.black87,
                                ),
                                decoration: InputDecoration(
                                  labelText: l10n?.propertyStatus ?? 'Property Status',
                                  labelStyle: ThemeService.getBodyStyle(context),
                                  prefixIcon: const Icon(Icons.sell),
                                ),
                                items: PropertyStatus.values.map((status) {
                                  return DropdownMenuItem(
                                    value: status,
                                    child: Text(status.statusDisplayName),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedStatus = value!;
                                    // Reset rent type when status changes
                                    if (value != PropertyStatus.forRent) {
                                      _selectedRentType = null;
                                      _monthlyRentController.clear();
                                      _dailyRentController.clear();
                                    }
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Price Field (LYD) - only show for sale properties
                      if (_selectedStatus != PropertyStatus.forRent) ...[
                        _buildAnimatedCard(
                          delay: 200,
                          child: TextFormField(
                            controller: _priceController,
                            style: ThemeService.getBodyStyle(
                              context,
                              color: Colors.black87,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Price (LYD)',
                              labelStyle: ThemeService.getBodyStyle(context),
                              hintText: 'Enter price in Libyan Dinar',
                              hintStyle: ThemeService.getBodyStyle(context),
                              prefixIcon: const Icon(Icons.attach_money),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter the price';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Please enter a valid price';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],

                      // Rent Pricing (for rent properties) - Radio buttons for monthly/daily
                      if (_selectedStatus == PropertyStatus.forRent) ...[
                        _buildAnimatedCard(
                          delay: 200,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Rent Pricing',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Rent Type Radio Buttons with better styling
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedRentType = 'monthly';
                                            _dailyRentController.clear();
                                          });
                                        },
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          curve: Curves.easeInOut,
                                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                          decoration: BoxDecoration(
                                            color: _selectedRentType == 'monthly' 
                                                ? Colors.green.shade600 
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: _selectedRentType == 'monthly'
                                                ? [
                                                    BoxShadow(
                                                      color: Colors.green.withOpacity(0.3),
                                                      blurRadius: 8,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ]
                                                : [],
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.calendar_month,
                                                color: _selectedRentType == 'monthly' 
                                                    ? Colors.white 
                                                    : Colors.grey[600],
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Monthly Rent',
                                                style: TextStyle(
                                                  color: _selectedRentType == 'monthly' 
                                                      ? Colors.white 
                                                      : Colors.grey[700],
                                                  fontWeight: _selectedRentType == 'monthly' 
                                                      ? FontWeight.bold 
                                                      : FontWeight.normal,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedRentType = 'daily';
                                            _monthlyRentController.clear();
                                          });
                                        },
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          curve: Curves.easeInOut,
                                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                          decoration: BoxDecoration(
                                            color: _selectedRentType == 'daily' 
                                                ? Colors.green.shade600 
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: _selectedRentType == 'daily'
                                                ? [
                                                    BoxShadow(
                                                      color: Colors.green.withOpacity(0.3),
                                                      blurRadius: 8,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ]
                                                : [],
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.today,
                                                color: _selectedRentType == 'daily' 
                                                    ? Colors.white 
                                                    : Colors.grey[600],
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Daily Rent',
                                                style: TextStyle(
                                                  color: _selectedRentType == 'daily' 
                                                      ? Colors.white 
                                                      : Colors.grey[700],
                                                  fontWeight: _selectedRentType == 'daily' 
                                                      ? FontWeight.bold 
                                                      : FontWeight.normal,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Show only the selected rent type field
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (child, animation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0, -0.1),
                                        end: Offset.zero,
                                      ).animate(CurvedAnimation(
                                        parent: animation,
                                        curve: Curves.easeOut,
                                      )),
                                      child: child,
                                    ),
                                  );
                                },
                                child: _selectedRentType == 'monthly'
                                    ? TextFormField(
                                        key: const ValueKey('monthly'),
                                        controller: _monthlyRentController,
                                        style: ThemeService.getBodyStyle(
                                          context,
                                          color: Colors.black87,
                                        ),
                                        decoration: InputDecoration(
                                          labelText: 'Monthly Rent (LYD)',
                                          labelStyle: ThemeService.getBodyStyle(context),
                                          hintText: 'Enter monthly rent',
                                          hintStyle: ThemeService.getBodyStyle(context),
                                          prefixIcon: const Icon(Icons.calendar_month),
                                        ),
                                        keyboardType: TextInputType.number,
                                        validator: (value) {
                                          if (_selectedRentType != 'monthly') return null;
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter monthly rent';
                                          }
                                          if (double.tryParse(value) == null) {
                                            return 'Please enter a valid rent amount';
                                          }
                                          return null;
                                        },
                                      )
                                    : _selectedRentType == 'daily'
                                        ? TextFormField(
                                            key: const ValueKey('daily'),
                                            controller: _dailyRentController,
                                            style: ThemeService.getBodyStyle(
                                              context,
                                              color: Colors.black87,
                                            ),
                                            decoration: InputDecoration(
                                              labelText: 'Daily Rent (LYD)',
                                              labelStyle: ThemeService.getBodyStyle(context),
                                              hintText: 'Enter daily rent',
                                              hintStyle: ThemeService.getBodyStyle(context),
                                              prefixIcon: const Icon(Icons.today),
                                            ),
                                            keyboardType: TextInputType.number,
                                            validator: (value) {
                                              if (_selectedRentType != 'daily') return null;
                                              if (value == null || value.isEmpty) {
                                                return 'Please enter daily rent';
                                              }
                                              if (double.tryParse(value) == null) {
                                                return 'Please enter a valid rent amount';
                                              }
                                              return null;
                                            },
                                          )
                                        : SizedBox.shrink(key: const ValueKey('empty')),
                              ),
                              
                              // Rent type validation
                              if (_selectedStatus == PropertyStatus.forRent && _selectedRentType == null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Row(
                                    children: [
                                      Icon(Icons.info_outline, color: Colors.orange.shade700, size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Please select monthly or daily rent',
                                        style: TextStyle(
                                          color: Colors.orange.shade700,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _depositController,
                                style: ThemeService.getBodyStyle(
                                  context,
                                  color: Colors.black87,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Security Deposit (LYD)',
                                  labelStyle: ThemeService.getBodyStyle(context),
                                  hintText: 'Enter deposit amount',
                                  hintStyle: ThemeService.getBodyStyle(context),
                                  prefixIcon: const Icon(Icons.security),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter deposit amount';
                                  }
                                  if (double.tryParse(value) == null) {
                                    return 'Please enter a valid deposit amount';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Location Information Section
                      _buildSectionTitle(l10n?.locationInformation ?? 'Location Information'),
                      
                      _buildAnimatedCard(
                        delay: 300,
                        child: Column(
                          children: [
                            // Address Field
                            TextFormField(
                              controller: _addressController,
                              style: ThemeService.getBodyStyle(
                                context,
                                color: Colors.black87,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Address',
                                labelStyle: ThemeService.getBodyStyle(context),
                                hintText: 'Enter full address',
                                hintStyle: ThemeService.getBodyStyle(context),
                                prefixIcon: const Icon(Icons.location_on),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter the address';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Neighborhood and City Row
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedCity,
                                    style: ThemeService.getBodyStyle(
                                      context,
                                      color: Colors.black87,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'City',
                                      labelStyle: ThemeService.getBodyStyle(context),
                                      hintText: 'Select city',
                                      hintStyle: ThemeService.getBodyStyle(context),
                                      prefixIcon: const Icon(Icons.location_city),
                                    ),
                                    items: _libyanCities.map((city) {
                                      return DropdownMenuItem(
                                        value: city,
                                        child: Text(city),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedCity = value;
                                        _selectedNeighborhood = null; // Reset neighborhood when city changes
                                      });
                                    },
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please select a city';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedNeighborhood,
                                    style: ThemeService.getBodyStyle(
                                      context,
                                      color: Colors.black87,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Neighborhood',
                                      labelStyle: ThemeService.getBodyStyle(context),
                                      hintText: _selectedCity == null ? 'Select city first' : 'Select neighborhood',
                                      hintStyle: ThemeService.getBodyStyle(context),
                                      prefixIcon: const Icon(Icons.location_city),
                                    ),
                                    items: _availableNeighborhoods.map((neighborhood) {
                                      return DropdownMenuItem(
                                        value: neighborhood,
                                        child: Text(neighborhood),
                                      );
                                    }).toList(),
                                    onChanged: _selectedCity == null ? null : (value) {
                                      setState(() {
                                        _selectedNeighborhood = value;
                                      });
                                    },
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please select a neighborhood';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Property Details Section - Hide for land type
                      if (_selectedType != PropertyType.land) ...[
                        _buildSectionTitle(l10n?.propertyDetails ?? 'Property Details'),
                        
                        _buildAnimatedCard(
                          delay: 400,
                          child: Column(
                            children: [
                              // Bedrooms, Bathrooms and Kitchens Selection
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<int>(
                                      value: _selectedBedrooms,
                                      style: ThemeService.getBodyStyle(
                                        context,
                                        color: Colors.black87,
                                      ),
                                      decoration: InputDecoration(
                                        labelText: 'Bedrooms',
                                        labelStyle: ThemeService.getBodyStyle(context),
                                        hintText: 'Select bedrooms',
                                        hintStyle: ThemeService.getBodyStyle(context),
                                        prefixIcon: const Icon(Icons.bed),
                                      ),
                                      items: List.generate(10, (index) => index + 1).map((number) {
                                        return DropdownMenuItem(
                                          value: number,
                                          child: Text(number.toString()),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedBedrooms = value!;
                                        });
                                      },
                                      validator: (value) {
                                        if (value == null) {
                                          return 'Please select number of bedrooms';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: DropdownButtonFormField<int>(
                                      value: _selectedBathrooms,
                                      style: ThemeService.getBodyStyle(
                                        context,
                                        color: Colors.black87,
                                      ),
                                      decoration: InputDecoration(
                                        labelText: 'Bathrooms',
                                        labelStyle: ThemeService.getBodyStyle(context),
                                        hintText: 'Select bathrooms',
                                        hintStyle: ThemeService.getBodyStyle(context),
                                        prefixIcon: const Icon(Icons.bathtub),
                                      ),
                                      items: List.generate(10, (index) => index + 1).map((number) {
                                        return DropdownMenuItem(
                                          value: number,
                                          child: Text(number.toString()),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedBathrooms = value!;
                                        });
                                      },
                                      validator: (value) {
                                        if (value == null) {
                                          return 'Please select number of bathrooms';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: DropdownButtonFormField<int>(
                                      value: _selectedKitchens,
                                      style: ThemeService.getBodyStyle(
                                        context,
                                        color: Colors.black87,
                                      ),
                                      decoration: InputDecoration(
                                        labelText: 'Kitchens',
                                        labelStyle: ThemeService.getBodyStyle(context),
                                        hintText: 'Select kitchens',
                                        hintStyle: ThemeService.getBodyStyle(context),
                                        prefixIcon: const Icon(Icons.kitchen),
                                      ),
                                      items: List.generate(5, (index) => index + 1).map((number) {
                                        return DropdownMenuItem(
                                          value: number,
                                          child: Text(number.toString()),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedKitchens = value!;
                                        });
                                      },
                                      validator: (value) {
                                        if (value == null) {
                                          return 'Please select number of kitchens';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              
                              // Floors Row - Hide for apartment and land types
                              if (_selectedType != PropertyType.apartment && _selectedType != PropertyType.land) ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _floorsController,
                                        style: ThemeService.getBodyStyle(
                                          context,
                                          color: Colors.black87,
                                        ),
                                        decoration: InputDecoration(
                                          labelText: 'Floors',
                                          labelStyle: ThemeService.getBodyStyle(context),
                                          hintText: 'Number of floors',
                                          hintStyle: ThemeService.getBodyStyle(context),
                                          prefixIcon: const Icon(Icons.layers),
                                        ),
                                        keyboardType: TextInputType.number,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter number of floors';
                                          }
                                          if (int.tryParse(value) == null) {
                                            return 'Please enter a valid number';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                              ],
                            ],
                          ),
                        ),
                      ],
                      
                      // Property Size Section
                      _buildSectionTitle('Property Size'),
                      
                      _buildAnimatedCard(
                        delay: 500,
                        child: Row(
                          children: [
                            // Land Size - Hide for apartment type
                            if (_selectedType != PropertyType.apartment) ...[
                              Expanded(
                                child: TextFormField(
                                  controller: _landSizeController,
                                  style: ThemeService.getBodyStyle(
                                    context,
                                    color: Colors.black87,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Land Size (m²)',
                                    labelStyle: ThemeService.getBodyStyle(context),
                                    hintText: 'e.g., 500',
                                    hintStyle: ThemeService.getBodyStyle(context),
                                    prefixIcon: const Icon(Icons.landscape),
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter land size';
                                    }
                                    if (int.tryParse(value) == null) {
                                      return 'Please enter a valid number';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              if (_selectedType != PropertyType.land) const SizedBox(width: 16),
                            ],
                            // Building Size - Hide for land type
                            if (_selectedType != PropertyType.land)
                              Expanded(
                                child: TextFormField(
                                  controller: _buildingSizeController,
                                  style: ThemeService.getBodyStyle(
                                    context,
                                    color: Colors.black87,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Building Size (m²)',
                                    labelStyle: ThemeService.getBodyStyle(context),
                                    hintText: 'e.g., 200',
                                    hintStyle: ThemeService.getBodyStyle(context),
                                    prefixIcon: const Icon(Icons.home),
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter building size';
                                    }
                                    if (int.tryParse(value) == null) {
                                      return 'Please enter a valid number';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Year Built and Condition
                      _buildAnimatedCard(
                        delay: 600,
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _yearBuiltController,
                                style: ThemeService.getBodyStyle(
                                  context,
                                  color: Colors.black87,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Year Built',
                                  labelStyle: ThemeService.getBodyStyle(context),
                                  hintText: 'e.g., 2020',
                                  hintStyle: ThemeService.getBodyStyle(context),
                                  prefixIcon: const Icon(Icons.calendar_today),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter year built';
                                  }
                                  if (int.tryParse(value) == null) {
                                    return 'Please enter a valid year';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<PropertyCondition>(
                                value: _selectedCondition,
                                style: ThemeService.getBodyStyle(
                                  context,
                                  color: Colors.black87,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Condition',
                                  labelStyle: ThemeService.getBodyStyle(context),
                                  prefixIcon: const Icon(Icons.build),
                                ),
                                items: PropertyCondition.values.map((condition) {
                                  return DropdownMenuItem(
                                    value: condition,
                                    child: Text(condition.conditionDisplayName),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedCondition = value!;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Features Section - Hide for land type
                      if (_selectedType != PropertyType.land) ...[
                        _buildSectionTitle(l10n?.features ?? 'Features'),
                        
                        // Property Features Grid
                        _buildFeaturesGrid(),
                        const SizedBox(height: 24),
                      ],

                      // Contact Information Section
                      _buildSectionTitle('Your Contact Information'),
                      
                      // Display user's contact info (read-only)
                      _buildAnimatedCard(
                        delay: 650,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.green.shade50,
                                Colors.green.shade100,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.green.shade200, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Contact information will be taken from your profile:',
                                style: ThemeService.getBodyStyle(
                                  context,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green[700],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(Icons.person, color: Colors.green[600]),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Name: ${authProvider.currentUser?.name ?? 'Not available'}',
                                    style: ThemeService.getBodyStyle(
                                      context,
                                      fontSize: 14,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.phone, color: Colors.green[600]),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Phone: ${authProvider.currentUser?.phone ?? 'Not available'}',
                                    style: ThemeService.getBodyStyle(
                                      context,
                                      fontSize: 14,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.email, color: Colors.green[600]),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Email: ${authProvider.currentUser?.email ?? 'Not available'}',
                                    style: ThemeService.getBodyStyle(
                                      context,
                                      fontSize: 14,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Image Upload Section
                      _buildSectionTitle(l10n?.images ?? 'Images'),
                      
                      _buildAnimatedCard(
                        delay: 680,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.camera_alt,
                                    color: Colors.green.shade700,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '${l10n?.uploadImages ?? 'Upload Images'} (${_selectedImages.length}/10)',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.green.shade600,
                                    Colors.green.shade700,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: _pickImages,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.add_photo_alternate, color: Colors.white, size: 28),
                                        const SizedBox(width: 12),
                                        Text(
                                          l10n?.selectImages ?? 'Select Images',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            if (_selectedImages.isNotEmpty)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                height: 120,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _selectedImages.length,
                                  itemBuilder: (context, index) {
                                    return TweenAnimationBuilder<double>(
                                      duration: Duration(milliseconds: 300 + (index * 50)),
                                      tween: Tween(begin: 0.0, end: 1.0),
                                      curve: Curves.easeOut,
                                      builder: (context, value, child) {
                                        return Opacity(
                                          opacity: value,
                                          child: Transform.scale(
                                            scale: 0.8 + (0.2 * value),
                                            child: Container(
                                              margin: const EdgeInsets.only(right: 12),
                                              width: 120,
                                              height: 120,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(16),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.1 * value),
                                                    blurRadius: 10,
                                                    offset: Offset(0, 4 * value),
                                                  ),
                                                ],
                                              ),
                                              child: Stack(
                                                children: [
                                                  ClipRRect(
                                                    borderRadius: BorderRadius.circular(16),
                                                    child: kIsWeb
                                                        ? Image.network(
                                                            _selectedImages[index].path,
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
                                                          )
                                                        : _buildPlatformImage(_selectedImages[index].path),
                                                  ),
                                                  Positioned(
                                                    top: 8,
                                                    right: 8,
                                                    child: GestureDetector(
                                                      onTap: () => _removeImage(index),
                                                      child: Container(
                                                        padding: const EdgeInsets.all(6),
                                                        decoration: BoxDecoration(
                                                          color: Colors.red.shade600,
                                                          shape: BoxShape.circle,
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: Colors.red.withOpacity(0.4),
                                                              blurRadius: 8,
                                                              offset: const Offset(0, 2),
                                                            ),
                                                          ],
                                                        ),
                                                        child: const Icon(
                                                          Icons.close,
                                                          color: Colors.white,
                                                          size: 18,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Upgrade Ad Section
                      _buildUpgradeAdSection(),
                      const SizedBox(height: 24),

                      // Submit Button
                      _buildAnimatedCard(
                        delay: 700,
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: [
                                Colors.green.shade600,
                                Colors.green.shade700,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: (_isSubmitting || _isUploadingImages) ? null : _submitForm,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (_isSubmitting || _isUploadingImages)
                                      const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    else
                                      const Icon(Icons.check_circle, color: Colors.white, size: 24),
                                    const SizedBox(width: 12),
                                    Text(
                                      _isUploadingImages 
                                        ? 'Uploading Images...' 
                                        : _isSubmitting 
                                          ? (l10n?.addingProperty ?? 'Adding Property...') 
                                          : (l10n?.addPropertyButton ?? 'Add Property'),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
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
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.green.shade400,
                          Colors.green.shade700,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: ThemeService.getHeadingStyle(
                      context,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
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
                        color: Colors.black.withOpacity(0.05 * value),
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

  Widget _buildFeaturesGrid() {
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
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(20),
              elevation: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.green.shade50,
                      Colors.green.shade100,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.shade200, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.1 * value),
                      blurRadius: 15,
                      offset: Offset(0, 4 * value),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                  // Property Features Section
                  Text(
                    'Property Features',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    children: [
                      _buildSwitchTile('Balcony', Icons.balcony, _hasBalcony, (value) => setState(() => _hasBalcony = value)),
                      _buildSwitchTile('Garden', Icons.yard, _hasGarden, (value) => setState(() => _hasGarden = value)),
                      _buildSwitchTile('Parking', Icons.local_parking, _hasParking, (value) => setState(() => _hasParking = value)),
                      _buildSwitchTile('Pool', Icons.pool, _hasPool, (value) => setState(() => _hasPool = value)),
                      _buildSwitchTile('Gym', Icons.fitness_center, _hasGym, (value) => setState(() => _hasGym = value)),
                      _buildSwitchTile('Security', Icons.security, _hasSecurity, (value) => setState(() => _hasSecurity = value)),
                      _buildSwitchTile('Elevator', Icons.elevator, _hasElevator, (value) => setState(() => _hasElevator = value)),
                      _buildSwitchTile('AC', Icons.ac_unit, _hasAC, (value) => setState(() => _hasAC = value)),
                      _buildSwitchTile('Heating', Icons.thermostat, _hasHeating, (value) => setState(() => _hasHeating = value)),
                      _buildSwitchTile('Furnished', Icons.chair, _hasFurnished, (value) => setState(() => _hasFurnished = value)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Lifestyle Features Section
                  Text(
                    'Lifestyle Features',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    children: [
                      _buildSwitchTile('Pet Friendly', Icons.pets, _hasPetFriendly, (value) => setState(() => _hasPetFriendly = value)),
                      _buildSwitchTile('Nearby Schools', Icons.school, _hasNearbySchools, (value) => setState(() => _hasNearbySchools = value)),
                      _buildSwitchTile('Nearby Hospitals', Icons.local_hospital, _hasNearbyHospitals, (value) => setState(() => _hasNearbyHospitals = value)),
                      _buildSwitchTile('Nearby Shopping', Icons.shopping_cart, _hasNearbyShopping, (value) => setState(() => _hasNearbyShopping = value)),
                      _buildSwitchTile('Public Transport', Icons.directions_transit, _hasPublicTransport, (value) => setState(() => _hasPublicTransport = value)),
                    ],
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
    return File(path);
  }

  Widget _buildSwitchTile(String title, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return Material(
      color: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: value ? Colors.green.shade50 : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value ? Colors.green.shade300 : Colors.grey.shade300,
            width: value ? 1.5 : 1,
          ),
        ),
        child: SwitchListTile(
        title: Text(
          title,
          style: TextStyle(
            color: value ? Colors.green.shade700 : Colors.grey[700],
            fontWeight: value ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        secondary: Icon(
          icon,
          color: value ? Colors.green.shade600 : Colors.grey[600],
        ),
        value: value,
        onChanged: onChanged,
        activeColor: Colors.green.shade600,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        dense: true,
      ),
      ),
    );
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
              color: Colors.amber.withOpacity(0.3),
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
                Icon(
                  Icons.star,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Upgrade Your Ad',
                    style: TextStyle(
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
              'Make your property stand out with premium features!',
              style: TextStyle(
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
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green, width: 2),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade300, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Package Selected: $_selectedPackageName (${_selectedPackagePrice!.toInt()} LYD)',
                        style: TextStyle(
                          color: Colors.green.shade300,
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
                  _selectedPackageId != null ? 'Change Package' : 'Select Package',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.white, width: 2),
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
          'Select Package for Your Property',
          style: TextStyle(color: Colors.black87, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choose a package to boost your property listing:',
              style: TextStyle(color: Colors.grey[700], fontSize: 16),
            ),
            const SizedBox(height: 20),
            _buildUpgradePackage(
              title: 'Basic Boost',
              price: '20 LYD',
              duration: '1 Day',
              features: ['Top listing position', 'Increased visibility'],
              color: Colors.brown,
              packageId: 'basic_boost',
              packagePrice: 20.0,
              isSelected: _selectedPackageId == 'basic_boost',
              onTap: () {
                setState(() {
                  _selectedPackageId = 'basic_boost';
                  _selectedPackageName = 'Basic Boost';
                  _selectedPackagePrice = 20.0;
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Basic Boost package selected for your property'),
                    backgroundColor: Colors.brown,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildUpgradePackage(
              title: 'Premium Boost',
              price: '100 LYD',
              duration: '7 Days',
              features: ['Top listing position', 'Increased visibility', 'Priority support'],
              color: Colors.grey.shade700,
              packageId: 'premium_boost',
              packagePrice: 100.0,
              isSelected: _selectedPackageId == 'premium_boost',
              onTap: () {
                setState(() {
                  _selectedPackageId = 'premium_boost';
                  _selectedPackageName = 'Premium Boost';
                  _selectedPackagePrice = 100.0;
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Premium Boost package selected for your property'),
                    backgroundColor: Colors.grey.shade600,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildUpgradePackage(
              title: 'Ultimate Boost',
              price: '300 LYD',
              duration: '30 Days',
              features: ['Top listing position', 'Maximum visibility', 'Priority support', 'Featured badge'],
              color: Colors.amber.shade700,
              packageId: 'ultimate_boost',
              packagePrice: 300.0,
              isSelected: _selectedPackageId == 'ultimate_boost',
              onTap: () {
                setState(() {
                  _selectedPackageId = 'ultimate_boost';
                  _selectedPackageName = 'Ultimate Boost';
                  _selectedPackagePrice = 300.0;
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Ultimate Boost package selected for your property'),
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
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Selected: $_selectedPackageName (${_selectedPackagePrice!.toInt()} LYD)',
                        style: TextStyle(
                          color: Colors.green.shade700,
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
                    content: Text('Package selection cleared'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              child: Text(
                'Clear Selection',
                style: TextStyle(color: Colors.orange.shade700, fontSize: 16),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: TextStyle(color: Colors.green.shade700, fontSize: 16),
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
            ? color.withOpacity(0.3)
            : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.5), 
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
              color: Colors.black87,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.green,
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
                    'Login Required',
                    style: ThemeService.getHeadingStyle(
                      context,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Please login to add properties to the platform',
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
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    child: Text(
                      'Login',
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
                      'Back to Home',
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