import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/property.dart';

/// Chatbot response with text and optional property results
class ChatbotResponse {
  final String text;
  final List<Property>? properties;

  ChatbotResponse({required this.text, this.properties});
}

/// Service for handling chatbot interactions with Google Gemini API
class ChatbotService {
  static const String _apiKeyCacheKey = 'gemini_api_key_cache';
  static const String _modelName = 'gemini-2.0-flash';
  
  GenerativeModel? _model;
  String? _cachedApiKey;
  bool _isInitializing = false;
  
  ChatbotService() {
    // Initialize model asynchronously with a small delay
    // to ensure Firebase is fully initialized
    Future.delayed(const Duration(milliseconds: 500), () {
      _initializeModel();
    });
  }

  /// Initialize the model with API key from Firestore
  Future<void> _initializeModel() async {
    if (_isInitializing) return; // Prevent multiple initializations
    _isInitializing = true;
    
    try {
      final apiKey = await _getApiKey();
      _model = GenerativeModel(
        model: _modelName,
        apiKey: apiKey,
      );
      if (kDebugMode) {
        debugPrint('✅ Chatbot model initialized with API key from Firestore');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error initializing chatbot model: $e');
        debugPrint('💡 Please ensure config/gemini_api_key document exists in Firestore');
      }
      // Don't create model if API key can't be fetched - fail gracefully
      _model = null;
    } finally {
      _isInitializing = false;
    }
  }

  /// Get API key from Firestore (with caching)
  Future<String> _getApiKey() async {
    // Check memory cache first
    if (_cachedApiKey != null && _cachedApiKey!.isNotEmpty) {
      return _cachedApiKey!;
    }

    // Check local storage cache
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedKey = prefs.getString(_apiKeyCacheKey);
      if (cachedKey != null && cachedKey.isNotEmpty) {
        _cachedApiKey = cachedKey;
        return cachedKey;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error reading cached API key: $e');
      }
    }

    // Fetch from Firestore
    try {
      final firestore = FirebaseFirestore.instance;
      
      if (kDebugMode) {
        debugPrint('🔍 Fetching API key from Firestore: config/gemini_api_key');
        debugPrint('🔍 Firestore instance: ${firestore.app.name}');
        debugPrint('🔍 Firestore database ID: ${firestore.databaseId}');
        debugPrint('🔍 Firebase project ID: ${firestore.app.options.projectId}');
        
        // Try to list all documents in config collection to debug
        try {
          final configDocs = await firestore.collection('config').limit(10).get();
          debugPrint('🔍 Config collection has ${configDocs.docs.length} document(s)');
          if (configDocs.docs.isEmpty) {
            debugPrint('⚠️ Config collection is EMPTY! The document does not exist.');
            debugPrint('💡 Verify in Firebase Console:');
            debugPrint('   - Project: ${firestore.app.options.projectId}');
            debugPrint('   - Database: ${firestore.databaseId}');
            debugPrint('   - URL: https://console.firebase.google.com/project/${firestore.app.options.projectId}/firestore/data/~2Fconfig~2Fgemini_api_key');
          }
          for (final doc in configDocs.docs) {
            debugPrint('🔍 Found document in config: ${doc.id}');
          }
        } catch (e) {
          debugPrint('⚠️ Error listing config collection: $e');
        }
      }
      
      // Retry mechanism - Firestore on web sometimes needs time to initialize
      DocumentSnapshot? doc;
      int retries = 3;
      int attempt = 0;
      
      while (attempt < retries && (doc == null || !doc.exists)) {
        attempt++;
        
        if (kDebugMode && attempt > 1) {
          debugPrint('🔄 Retry attempt $attempt of $retries');
        }
        
        // Wait a moment to ensure Firestore is ready (especially on web)
        await Future.delayed(Duration(milliseconds: 300 * attempt));
        
        // Try to get the document - use serverAndCache to try server first, then cache
        doc = await firestore
            .collection('config')
            .doc('gemini_api_key')
            .get(const GetOptions(source: Source.serverAndCache)); // Try server first, fallback to cache
        
        if (doc.exists) {
          break; // Found it, exit retry loop
        }
        
        if (kDebugMode && attempt < retries) {
          debugPrint('⚠️ Document not found on attempt $attempt, retrying...');
        }
      }
      
      // Check if we have a document after all retries
      if (doc == null) {
        throw Exception('Failed to fetch document after $retries attempts');
      }
      
      if (kDebugMode) {
        debugPrint('🔍 Document exists: ${doc.exists}');
        debugPrint('🔍 Document ID: ${doc.id}');
        debugPrint('🔍 Document reference path: ${doc.reference.path}');
        debugPrint('🔍 Document data: ${doc.data()}');
        debugPrint('🔍 Document metadata: ${doc.metadata}');
      }
      
      if (!doc.exists) {
        if (kDebugMode) {
          debugPrint('❌ Document does not exist. Config collection has 0 documents.');
          debugPrint('💡 The document needs to be created in Firebase Console:');
          
          // Document doesn't exist - provide detailed instructions
          debugPrint('💡 Please create the document manually in Firebase Console:');
          debugPrint('   1. Go to: https://console.firebase.google.com/project/dary-a74c8/firestore/data');
          debugPrint('   2. Make sure you see the (default) database (not a named database)');
          debugPrint('   3. Click "Start collection" if config collection doesn\'t exist');
          debugPrint('   4. Collection ID: config');
          debugPrint('   5. Document ID: gemini_api_key');
          debugPrint('   6. Click "Add field"');
          debugPrint('   7. Field name: apiKey (exactly, case-sensitive)');
          debugPrint('   8. Field type: string');
          debugPrint('   9. Field value: Your Gemini API key');
          debugPrint('   10. Click "Save"');
          debugPrint('');
          debugPrint('🔍 Verification steps:');
          debugPrint('   - After creating, refresh the page');
          debugPrint('   - Verify the document appears in the config collection');
          debugPrint('   - Verify the apiKey field is visible');
          debugPrint('   - Make sure you\'re logged into the correct Firebase account');
        } else {
          throw Exception('API key document not found in Firestore at path: config/gemini_api_key');
        }
      }
      
      // After creation/retry, check again
      if (!doc.exists) {
        throw Exception('API key document still not found after creation attempt');
      }
      
      final data = doc.data() as Map<String, dynamic>?;
      if (kDebugMode) {
        debugPrint('🔍 Document data keys: ${data?.keys.toList()}');
      }
      
      final apiKey = data?['apiKey'] as String?;
      
      if (kDebugMode) {
        debugPrint('🔍 API key found: ${apiKey != null && apiKey.isNotEmpty}');
      }
      
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('API key field is null or empty in Firestore document. Document contains: ${data?.keys.toList()}');
      }

      // Cache the key locally
      _cachedApiKey = apiKey;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_apiKeyCacheKey, apiKey);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ Error caching API key: $e');
        }
      }
      
      if (kDebugMode) {
        debugPrint('✅ API key retrieved from Firestore and cached');
      }
      
      return apiKey;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching API key from Firestore: $e');
        debugPrint('💡 Make sure Firestore document exists at config/gemini_api_key with apiKey field');
      }
      // REMOVED: No fallback API key for security reasons
      // The document should exist in Firestore
      rethrow; // Re-throw the error so the caller knows it failed
    }
  }

  /// Ensure model is initialized before use
  Future<void> _ensureModelInitialized() async {
    if (_model == null || _isInitializing) {
      await _initializeModel();
    }
  }

  /// Detect if the message contains Arabic characters
  bool _isArabicMessage(String message) {
    final arabicPattern = RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]');
    return arabicPattern.hasMatch(message);
  }

  /// Search properties based on user query
  Future<List<Property>> _searchProperties(String userQuery) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final isArabic = _isArabicMessage(userQuery);
      
      // Normalize query to lowercase
      final normalizedQuery = userQuery.toLowerCase().trim();
      
      // Check if user wants to see ALL properties (including unpublished)
      // Detect "show all" patterns even when combined with property types
      final showAllKeywords = ['show all', 'show me all', 'list all', 'جميع', 'كل', 'عرض جميع'];
      final hasShowAllKeyword = showAllKeywords.any((keyword) => normalizedQuery.contains(keyword));
      // Also check for property-related words (apartments, villas, etc. count too)
      final hasPropertyKeyword = normalizedQuery.contains('propert') || 
                                 normalizedQuery.contains('عقار') ||
                                 normalizedQuery.contains('apartment') ||
                                 normalizedQuery.contains('villa') ||
                                 normalizedQuery.contains('house') ||
                                 normalizedQuery.contains('land') ||
                                 normalizedQuery.contains('شقة') ||
                                 normalizedQuery.contains('فيلا');
      
      // If user says "show all" or "show me all" + any property type, show all properties
      final showAllProperties = hasShowAllKeyword && hasPropertyKeyword;
      
      if (kDebugMode) {
        debugPrint('🔍 Query analysis:');
        debugPrint('   Has "show all" keyword: $hasShowAllKeyword');
        debugPrint('   Has property keyword: $hasPropertyKeyword');
        debugPrint('   Show ALL properties: $showAllProperties');
      }
      
      // Extract all search parameters
      String? city;
      String? neighborhood;
      PropertyType? propertyType;
      double? minPrice;
      double? maxPrice;
      int? minBedrooms;
      int? maxBedrooms;
      int? minBathrooms;
      PropertyStatus? status;
      int? minSizeSqm;
      int? maxSizeSqm;
      List<String> requiredFeatures = [];
      
      // Map Arabic city names to English
      final cityMap = {
        'طرابلس': 'Tripoli',
        'بنغازي': 'Benghazi',
        'مصراتة': 'Misrata',
        'سبها': 'Sebha',
        'طبرق': 'Tobruk',
      };
      
      // Map property types (order matters - more specific first)
      final typeMap = {
        // English - plural and singular
        'apartments': PropertyType.apartment,
        'apartment': PropertyType.apartment,
        'villas': PropertyType.villa,
        'villa': PropertyType.villa,
        'houses': PropertyType.house,
        'house': PropertyType.house,
        'lands': PropertyType.land,
        'land': PropertyType.land,
        'commercial': PropertyType.commercial,
        // Arabic
        'شقة': PropertyType.apartment,
        'شقق': PropertyType.apartment,
        'بيت': PropertyType.house,
        'بيوت': PropertyType.house,
        'منزل': PropertyType.house,
        'منازل': PropertyType.house,
        'دار': PropertyType.house,
        'دور': PropertyType.house,
        'أرض': PropertyType.land,
        'أراضي': PropertyType.land,
        'عمارة': PropertyType.apartment,
        'عمارات': PropertyType.apartment,
        'فيلا': PropertyType.villa,
        'فيلات': PropertyType.villa,
      };
      
      // Try to extract city
      for (final entry in cityMap.entries) {
        if (normalizedQuery.contains(entry.key.toLowerCase()) || 
            normalizedQuery.contains(entry.value.toLowerCase())) {
          city = entry.value;
          break;
        }
      }
      
      // Try to extract property type (check exact word matches first for accuracy)
      // Split query into words and remove common stop words
      final stopWords = {'i', 'want', 'need', 'looking', 'for', 'a', 'an', 'the', 'in', 'at', 'ب', 'في', 'أريد', 'أحتاج', 'أبحث'};
      final queryWords = normalizedQuery
          .split(RegExp(r'[\s,\-\.]+'))
          .map((w) => w.trim().toLowerCase())
          .where((w) => w.isNotEmpty && !stopWords.contains(w))
          .toList();
      
      if (kDebugMode) {
        debugPrint('🔍 Query words (filtered): $queryWords');
      }
      
      // First, try exact word matches (more accurate) - prioritize longer/more specific matches
      final sortedTypeMap = typeMap.entries.toList()
        ..sort((a, b) => b.key.length.compareTo(a.key.length)); // Longer keys first
      
      // Check each query word against type map
      for (final word in queryWords) {
        if (word.isEmpty) continue;
        
        // Check exact match first (most accurate)
        for (final entry in sortedTypeMap) {
          final keyLower = entry.key.toLowerCase();
          if (word == keyLower) {
            propertyType = entry.value;
            if (kDebugMode) {
              debugPrint('✅ Found exact word match: "$word" -> ${propertyType.name}');
            }
            break;
          }
        }
        if (propertyType != null) break;
        
        // Check if word starts with or ends with type key (handles plurals like "apartments" -> "apartment")
        for (final entry in sortedTypeMap) {
          final keyLower = entry.key.toLowerCase();
          // Remove 's' suffix for plurals (apartments -> apartment)
          final wordWithoutS = word.endsWith('s') && word.length > 1 ? word.substring(0, word.length - 1) : word;
          if (wordWithoutS == keyLower || word == keyLower || 
              word.startsWith(keyLower) || keyLower.startsWith(word) ||
              wordWithoutS.startsWith(keyLower) || keyLower.startsWith(wordWithoutS)) {
            propertyType = entry.value;
            if (kDebugMode) {
              debugPrint('✅ Found word match: "$word" -> ${propertyType.name}');
            }
            break;
          }
        }
        if (propertyType != null) break;
      }
      
      // If no exact match found, try contains on full query (less accurate but catches more)
      if (propertyType == null) {
        for (final entry in sortedTypeMap) {
          if (normalizedQuery.contains(entry.key.toLowerCase())) {
            propertyType = entry.value;
            if (kDebugMode) {
              debugPrint('🔍 Found contains match: "${entry.key}" -> ${propertyType.name}');
            }
            break;
          }
        }
      }
      
      if (kDebugMode && propertyType != null) {
        debugPrint('✅ Extracted property type: ${propertyType.name}');
      } else if (kDebugMode) {
        debugPrint('⚠️ Could not extract property type from query');
      }
      
      // Extract neighborhood keywords (common neighborhoods - expanded list)
      final neighborhoods = {
        'siraj': 'siraj',
        'صراج': 'siraj',
        'ain zara': 'Ain Zara',
        'عين زارة': 'Ain Zara',
        'hay andalous': 'Hay Andalous',
        'حي الأندلس': 'Hay Andalous',
        'gargharesh': 'Gargharesh',
        'قرقارش': 'Gargharesh',
        'ben ashur': 'Ben Ashur',
        'بن عاشور': 'Ben Ashur',
        'swani': 'Swani',
        'صواني': 'Swani',
        'hadaek': 'Hadaek',
        'حدائق': 'Hadaek',
      };
      
      for (final entry in neighborhoods.entries) {
        if (normalizedQuery.contains(entry.key.toLowerCase())) {
          neighborhood = entry.value;
          if (kDebugMode) {
            debugPrint('✅ Extracted neighborhood: $neighborhood');
          }
          break;
        }
      }
      
      // Extract price range
      // Patterns: "under 50000", "over 100000", "between 30000 and 80000", "less than 50000", "more than 80000"
      // Arabic: "أقل من", "أكثر من", "بين", "تحت", "فوق"
      final pricePatterns = [
        // English patterns
        RegExp(r'(?:under|below|less than|max|maximum|max price)\s*(\d+(?:[,\s]\d{3})*)', caseSensitive: false),
        RegExp(r'(?:over|above|more than|min|minimum|min price)\s*(\d+(?:[,\s]\d{3})*)', caseSensitive: false),
        RegExp(r'(?:between|from)\s*(\d+(?:[,\s]\d{3})*)\s*(?:and|to|-)\s*(\d+(?:[,\s]\d{3})*)', caseSensitive: false),
        // Arabic patterns
        RegExp(r'(?:أقل من|تحت|حد أقصى|أقصى سعر)\s*(\d+(?:[,\s]\d{3})*)', caseSensitive: false),
        RegExp(r'(?:أكثر من|فوق|حد أدنى|أدنى سعر)\s*(\d+(?:[,\s]\d{3})*)', caseSensitive: false),
        RegExp(r'(?:بين|من)\s*(\d+(?:[,\s]\d{3})*)\s*(?:و|إلى|-)\s*(\d+(?:[,\s]\d{3})*)', caseSensitive: false),
        // Simple number patterns (assume max price if mentioned as single number)
        RegExp(r'(\d+(?:[,\s]\d{3})*)\s*(?:lyd|dinar|دينار|ليرة)', caseSensitive: false),
      ];
      
      for (final pattern in pricePatterns) {
        final match = pattern.firstMatch(normalizedQuery);
        if (match != null) {
          try {
            // Remove commas and spaces from numbers
            String parseNumber(String numStr) => numStr.replaceAll(RegExp(r'[,\s]'), '');
            
            if (match.groupCount >= 2 && match.group(2) != null) {
              // Range pattern (between X and Y)
              final minStr = parseNumber(match.group(1)!);
              final maxStr = parseNumber(match.group(2)!);
              minPrice = double.tryParse(minStr);
              maxPrice = double.tryParse(maxStr);
              if (kDebugMode && minPrice != null && maxPrice != null) {
                debugPrint('✅ Extracted price range: ${minPrice.toInt()} - ${maxPrice.toInt()} LYD');
              }
            } else if (pattern.pattern.contains('under|below|less|max|أقل|تحت')) {
              // Max price pattern
              final maxStr = parseNumber(match.group(1)!);
              maxPrice = double.tryParse(maxStr);
              if (kDebugMode && maxPrice != null) {
                debugPrint('✅ Extracted max price: ${maxPrice.toInt()} LYD');
              }
            } else if (pattern.pattern.contains('over|above|more|min|أكثر|فوق')) {
              // Min price pattern
              final minStr = parseNumber(match.group(1)!);
              minPrice = double.tryParse(minStr);
              if (kDebugMode && minPrice != null) {
                debugPrint('✅ Extracted min price: ${minPrice.toInt()} LYD');
              }
            } else if (match.groupCount >= 1 && match.group(1) != null) {
              // Simple number pattern - assume max price
              final maxStr = parseNumber(match.group(1)!);
              maxPrice = double.tryParse(maxStr);
              if (kDebugMode && maxPrice != null) {
                debugPrint('✅ Extracted price (assumed max): ${maxPrice.toInt()} LYD');
              }
            }
            
            if (minPrice != null || maxPrice != null) break;
          } catch (e) {
            if (kDebugMode) {
              debugPrint('⚠️ Error parsing price: $e');
            }
          }
        }
      }
      
      // Extract bedrooms count
      // Patterns: "2 bedrooms", "3+ bedrooms", "2-4 bedrooms", "at least 2 bedrooms"
      final bedroomPatterns = [
        RegExp(r'(\d+)\s*(?:\+|\+)?\s*(?:bedroom|bed|br|غرفة|غرف)', caseSensitive: false),
        RegExp(r'(?:at least|minimum|min)\s*(\d+)\s*(?:bedroom|bed|br|غرفة|غرف)', caseSensitive: false),
        RegExp(r'(\d+)\s*(?:to|-)\s*(\d+)\s*(?:bedroom|bed|br|غرفة|غرف)', caseSensitive: false),
        RegExp(r'(?:up to|max|maximum)\s*(\d+)\s*(?:bedroom|bed|br|غرفة|غرف)', caseSensitive: false),
      ];
      
      for (final pattern in bedroomPatterns) {
        final match = pattern.firstMatch(normalizedQuery);
        if (match != null) {
          try {
            if (match.groupCount >= 2 && match.group(2) != null) {
              // Range pattern
              minBedrooms = int.tryParse(match.group(1)!);
              maxBedrooms = int.tryParse(match.group(2)!);
              if (kDebugMode && minBedrooms != null && maxBedrooms != null) {
                debugPrint('✅ Extracted bedrooms range: $minBedrooms - $maxBedrooms');
              }
            } else if (pattern.pattern.contains('\\+')) {
              // "3+ bedrooms" pattern
              final countStr = match.group(1)!;
              minBedrooms = int.tryParse(countStr);
              if (kDebugMode && minBedrooms != null) {
                debugPrint('✅ Extracted min bedrooms: $minBedrooms+');
              }
            } else if (pattern.pattern.contains('up to|max')) {
              // Max bedrooms pattern
              maxBedrooms = int.tryParse(match.group(1)!);
              if (kDebugMode && maxBedrooms != null) {
                debugPrint('✅ Extracted max bedrooms: $maxBedrooms');
              }
            } else if (match.groupCount >= 1) {
              // Simple count pattern
              minBedrooms = int.tryParse(match.group(1)!);
              if (kDebugMode && minBedrooms != null) {
                debugPrint('✅ Extracted bedrooms: $minBedrooms');
              }
            }
            
            if (minBedrooms != null || maxBedrooms != null) break;
          } catch (e) {
            if (kDebugMode) {
              debugPrint('⚠️ Error parsing bedrooms: $e');
            }
          }
        }
      }
      
      // Extract bathrooms count
      final bathroomPatterns = [
        RegExp(r'(\d+)\s*(?:bathroom|bath|wc|حمام)', caseSensitive: false),
      ];
      
      for (final pattern in bathroomPatterns) {
        final match = pattern.firstMatch(normalizedQuery);
        if (match != null) {
          try {
            minBathrooms = int.tryParse(match.group(1)!);
            if (kDebugMode && minBathrooms != null) {
              debugPrint('✅ Extracted bathrooms: $minBathrooms');
            }
            break;
          } catch (e) {
            if (kDebugMode) {
              debugPrint('⚠️ Error parsing bathrooms: $e');
            }
          }
        }
      }
      
      // Extract property status (for sale, for rent)
      if (normalizedQuery.contains(RegExp(r'(?:for sale|sale|buy|شراء|للبيع)', caseSensitive: false))) {
        status = PropertyStatus.forSale;
        if (kDebugMode) {
          debugPrint('✅ Extracted status: for sale');
        }
      } else if (normalizedQuery.contains(RegExp(r'(?:for rent|rent|rental|إيجار|للايجار)', caseSensitive: false))) {
        status = PropertyStatus.forRent;
        if (kDebugMode) {
          debugPrint('✅ Extracted status: for rent');
        }
      }
      
      // Extract features
      final featureMap = {
        'parking': 'hasParking',
        'موقف سيارات': 'hasParking',
        'pool': 'hasPool',
        'مسبح': 'hasPool',
        'garden': 'hasGarden',
        'حديقة': 'hasGarden',
        'balcony': 'hasBalcony',
        'شرفة': 'hasBalcony',
        'elevator': 'hasElevator',
        'مصعد': 'hasElevator',
        'furnished': 'hasFurnished',
        'مفروش': 'hasFurnished',
        'ac|air conditioning': 'hasAC',
        'تكييف': 'hasAC',
        'gym': 'hasGym',
        'صالة رياضية': 'hasGym',
        'security': 'hasSecurity',
        'أمن': 'hasSecurity',
      };
      
      for (final entry in featureMap.entries) {
        if (normalizedQuery.contains(entry.key.toLowerCase())) {
          requiredFeatures.add(entry.value);
          if (kDebugMode) {
            debugPrint('✅ Extracted feature: ${entry.value}');
          }
        }
      }
      
      // Extract size/area (in sqm)
      final sizePatterns = [
        RegExp(r'(\d+)\s*(?:sqm|m²|square meter|متر مربع)', caseSensitive: false),
        RegExp(r'(?:at least|minimum|min)\s*(\d+)\s*(?:sqm|m²|square meter|متر مربع)', caseSensitive: false),
      ];
      
      for (final pattern in sizePatterns) {
        final match = pattern.firstMatch(normalizedQuery);
        if (match != null) {
          try {
            minSizeSqm = int.tryParse(match.group(1)!);
            if (kDebugMode && minSizeSqm != null) {
              debugPrint('✅ Extracted min size: $minSizeSqm sqm');
            }
            break;
          } catch (e) {
            if (kDebugMode) {
              debugPrint('⚠️ Error parsing size: $e');
            }
          }
        }
      }
      
      // Build Firestore query
      Query firestoreQuery = firestore.collection('properties');
      
      // Only filter by isPublished if user didn't explicitly ask for "all properties"
      // For "show all properties", we include both published and unpublished
      if (!showAllProperties) {
        // Only show published properties (default behavior)
        firestoreQuery = firestoreQuery.where('isPublished', isEqualTo: true);
        if (kDebugMode) {
          debugPrint('🔍 Filtering by isPublished: true (default)');
        }
      } else {
        if (kDebugMode) {
          debugPrint('🔍 Showing ALL properties (including unpublished)');
        }
      }
      
      // Filter by city if found (only when user specifies a city)
      if (city != null) {
        firestoreQuery = firestoreQuery.where('city', isEqualTo: city);
        if (kDebugMode) {
          debugPrint('🔍 Filtering by city: $city');
        }
      } else {
        if (kDebugMode) {
          debugPrint('🔍 No city filter (getting all cities)');
        }
      }
      
      // Filter by status if specified (for sale/rent)
      if (status != null) {
        firestoreQuery = firestoreQuery.where('status', isEqualTo: status.name);
        if (kDebugMode) {
          debugPrint('🔍 Filtering by status: ${status.name}');
        }
      }
      
      // Filter by price range (min/max) if specified
      // Note: Firestore can only filter on one range per query, so we'll use the most restrictive
      if (minPrice != null) {
        firestoreQuery = firestoreQuery.where('price', isGreaterThanOrEqualTo: minPrice);
        if (kDebugMode) {
          debugPrint('🔍 Filtering by min price: ${minPrice.toInt()} LYD');
        }
      }
      if (maxPrice != null && minPrice == null) {
        // Only add maxPrice if minPrice wasn't used (Firestore limitation)
        // Otherwise we'll filter in memory
        firestoreQuery = firestoreQuery.where('price', isLessThanOrEqualTo: maxPrice);
        if (kDebugMode) {
          debugPrint('🔍 Filtering by max price: ${maxPrice.toInt()} LYD');
        }
      }
      
      // Add orderBy - Firestore requires orderBy when using limit() for consistent results
      // Order by createdAt descending (most recent first)
      // If price filtering, we might want to order by price instead, but createdAt is safer for now
      firestoreQuery = firestoreQuery.orderBy('createdAt', descending: true);
      
      // Get ALL properties (Firestore max limit is 1000, but we'll use 500 for performance)
      // We filter by type in memory anyway, so getting more is safe
      firestoreQuery = firestoreQuery.limit(500);
      
      if (kDebugMode) {
        debugPrint('🔍 Firestore query: orderBy(createdAt DESC), limit: 500');
      }
      
      final snapshot = await firestoreQuery.get();
      
      if (kDebugMode) {
        debugPrint('📥 Retrieved ${snapshot.docs.length} documents from Firestore (limit: 500)');
        if (snapshot.docs.length >= 500) {
          debugPrint('⚠️ Warning: Hit Firestore limit of 500! There may be more properties.');
        }
      }
      
      // Filter in memory (type, neighborhood - ensures exact matches)
      var filteredDocs = snapshot.docs;
      
      // First filter by property type if specified (ensure exact match)
      if (propertyType != null && filteredDocs.isNotEmpty) {
        // Property types in Firestore are stored as enum.name (e.g., "apartment", "villa")
        final expectedTypeString = propertyType.name.toLowerCase();
        
        if (kDebugMode) {
          debugPrint('🔍 Filtering by property type: $expectedTypeString');
          debugPrint('🔍 Total docs from Firestore before type filtering: ${filteredDocs.length}');
          debugPrint('🔍 Show all properties mode: $showAllProperties');
        }
        
        var index = 0;
        var matchedCount = 0;
        filteredDocs = filteredDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final docType = (data['type']?.toString() ?? '').toLowerCase().trim();
          
          if (kDebugMode && index < 5) {
            debugPrint('🔍 Doc[$index] type: "$docType" vs expected: "$expectedTypeString"');
          }
          index++;
          
          // Match exact type (e.g., "apartment" or "villa")
          final matches = docType == expectedTypeString;
          if (matches) matchedCount++;
          
          if (kDebugMode && !matches && index <= 5) {
            debugPrint('❌ Doc[$index] type mismatch: "$docType" != "$expectedTypeString"');
          }
          
          return matches;
        }).toList();
        
        if (kDebugMode) {
          debugPrint('✅ Total docs after type filtering: ${filteredDocs.length} (matched: $matchedCount)');
        }
      }
      
      // Then filter by neighborhood if found
      if (neighborhood != null && filteredDocs.isNotEmpty) {
        final neighborhoodLower = neighborhood.toLowerCase();
        filteredDocs = filteredDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final docNeighborhood = (data['neighborhood'] ?? '').toString().toLowerCase();
          return docNeighborhood.contains(neighborhoodLower) || 
                 neighborhoodLower.contains(docNeighborhood);
        }).toList();
        
        if (kDebugMode) {
          debugPrint('🔍 Filtered by neighborhood "$neighborhood": ${filteredDocs.length} docs');
        }
      }
      
      // Filter by price range (if not already filtered in Firestore)
      if (maxPrice != null && minPrice != null && filteredDocs.isNotEmpty) {
        // Both min and max specified - filter in memory (Firestore limitation)
        filteredDocs = filteredDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final price = (data['price'] ?? 0).toDouble();
          return price >= minPrice! && price <= maxPrice!;
        }).toList();
        
        if (kDebugMode) {
          debugPrint('🔍 Filtered by price range ${minPrice.toInt()}-${maxPrice.toInt()}: ${filteredDocs.length} docs');
        }
      } else if (maxPrice != null && minPrice == null && filteredDocs.isNotEmpty) {
        // Only maxPrice specified but wasn't in Firestore query - filter in memory
        filteredDocs = filteredDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final price = (data['price'] ?? 0).toDouble();
          return price <= maxPrice!;
        }).toList();
        
        if (kDebugMode) {
          debugPrint('🔍 Filtered by max price ${maxPrice.toInt()}: ${filteredDocs.length} docs');
        }
      }
      
      if (filteredDocs.isEmpty) {
        if (kDebugMode) {
          debugPrint('❌ No properties found after filtering');
        }
        return [];
      }
      
      final properties = <Property>[];
      var processedCount = 0;
      var skippedCount = 0;
      var addedCount = 0;
      
      for (final doc in filteredDocs) {
        try {
          processedCount++;
          final data = doc.data() as Map<String, dynamic>;
            final property = Property.fromFirestore(doc.id, data);
            
            // Filter out effectively expired properties
            if (property.isEffectivelyExpired) {
              skippedCount++;
              continue;
            }
            
            // Double-check property type matches (extra validation)
            if (propertyType != null && property.type != propertyType) {
            skippedCount++;
            if (kDebugMode && skippedCount <= 3) {
              debugPrint('⚠️ Skipped property ${doc.id}: type is ${property.type.name} but expected ${propertyType.name}');
            }
            continue; // Skip if type doesn't match
          }
          
          // Filter by bedrooms range
          if (minBedrooms != null && property.bedrooms < minBedrooms) {
            skippedCount++;
            if (kDebugMode && skippedCount <= 3) {
              debugPrint('⚠️ Skipped property ${doc.id}: bedrooms ${property.bedrooms} < min $minBedrooms');
            }
            continue;
          }
          if (maxBedrooms != null && property.bedrooms > maxBedrooms) {
            skippedCount++;
            if (kDebugMode && skippedCount <= 3) {
              debugPrint('⚠️ Skipped property ${doc.id}: bedrooms ${property.bedrooms} > max $maxBedrooms');
            }
            continue;
          }
          
          // Filter by bathrooms
          if (minBathrooms != null && property.bathrooms < minBathrooms) {
            skippedCount++;
            if (kDebugMode && skippedCount <= 3) {
              debugPrint('⚠️ Skipped property ${doc.id}: bathrooms ${property.bathrooms} < min $minBathrooms');
            }
            continue;
          }
          
          // Filter by size
          if (minSizeSqm != null && property.sizeSqm < minSizeSqm) {
            skippedCount++;
            if (kDebugMode && skippedCount <= 3) {
              debugPrint('⚠️ Skipped property ${doc.id}: size ${property.sizeSqm} < min $minSizeSqm');
            }
            continue;
          }
          if (maxSizeSqm != null && property.sizeSqm > maxSizeSqm) {
            skippedCount++;
            if (kDebugMode && skippedCount <= 3) {
              debugPrint('⚠️ Skipped property ${doc.id}: size ${property.sizeSqm} > max $maxSizeSqm');
            }
            continue;
          }
          
          // Filter by required features
          if (requiredFeatures.isNotEmpty) {
            bool hasAllFeatures = true;
            for (final feature in requiredFeatures) {
              bool hasFeature = false;
              switch (feature) {
                case 'hasParking':
                  hasFeature = property.hasParking;
                  break;
                case 'hasPool':
                  hasFeature = property.hasPool;
                  break;
                case 'hasGarden':
                  hasFeature = property.hasGarden;
                  break;
                case 'hasBalcony':
                  hasFeature = property.hasBalcony;
                  break;
                case 'hasElevator':
                  hasFeature = property.hasElevator;
                  break;
                case 'hasFurnished':
                  hasFeature = property.hasFurnished;
                  break;
                case 'hasAC':
                  hasFeature = property.hasAC;
                  break;
                case 'hasGym':
                  hasFeature = property.hasGym;
                  break;
                case 'hasSecurity':
                  hasFeature = property.hasSecurity;
                  break;
              }
              
              if (!hasFeature) {
                hasAllFeatures = false;
                break;
              }
            }
            
            if (!hasAllFeatures) {
              skippedCount++;
              if (kDebugMode && skippedCount <= 3) {
                debugPrint('⚠️ Skipped property ${doc.id}: missing required features');
              }
              continue;
            }
          }
          
          properties.add(property);
          addedCount++;
          
          if (kDebugMode && addedCount <= 5) {
            debugPrint('✅ Added property $addedCount: ${property.title} (${property.city}, type: ${property.type.name}, price: ${property.price.toInt()})');
          }
          
          // Don't limit - return all matching properties
        } catch (e) {
          skippedCount++;
          if (kDebugMode && skippedCount <= 3) {
            debugPrint('⚠️ Error parsing property ${doc.id}: $e');
          }
        }
      }
      
      if (kDebugMode) {
        debugPrint('📊 Search Summary:');
        debugPrint('   Total docs from Firestore: ${snapshot.docs.length}');
        debugPrint('   Processed docs: $processedCount');
        debugPrint('   Skipped docs: $skippedCount');
        debugPrint('   Final properties: ${properties.length}');
      }
      
      return properties;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error searching properties: $e');
      }
      return [];
    }
  }

  /// Detect if message is asking about properties/search
  bool _isPropertySearchQuery(String message) {
    final normalizedQuery = message.toLowerCase();
    
    // Keywords that indicate property search
    final searchKeywords = [
      'find', 'search', 'look for', 'show me', 'want', 'need', 'أبحث عن', 'أريد', 'أحتاج', 
      'أرغب في', 'find me', 'looking for', 'properties', 'property', 'عقار', 'عقارات',
      'villa', 'house', 'apartment', 'land', 'شقة', 'بيت', 'منزل', 'دار', 'أرض', 'أراضي',
      'tripoli', 'benghazi', 'طرابلس', 'بنغازي', 'siraj', 'siraj', 'siraj', 'عين زارة'
    ];
    
    return searchKeywords.any((keyword) => normalizedQuery.contains(keyword));
  }

  /// Send a message to the chatbot and get a response
  Future<ChatbotResponse> sendMessage(String message, {String? conversationContext}) async {
    try {
      // Ensure model is initialized
      await _ensureModelInitialized();
      
      if (_model == null) {
        final isArabic = _isArabicMessage(message);
        return ChatbotResponse(
          text: isArabic 
            ? 'عذرًا، خدمة الدردشة غير متاحة حاليًا. يرجى التحقق من إعدادات Firebase.'
            : 'Sorry, the chatbot service is currently unavailable. Please check Firebase configuration.',
        );
      }
      
      // Check if user is asking about properties/search
      final isPropertySearch = _isPropertySearchQuery(message);
      List<Property>? foundProperties;
      
      if (isPropertySearch) {
        // Search properties first
        foundProperties = await _searchProperties(message);
        
        if (foundProperties.isNotEmpty) {
          final isArabic = _isArabicMessage(message);
          final propertyCount = foundProperties.length;
          final responseText = isArabic
            ? 'وجدت $propertyCount عقاراً يتطابق مع بحثك:\n\n'
            : 'I found $propertyCount property(ies) matching your search:\n\n';
          
          return ChatbotResponse(
            text: responseText,
            properties: foundProperties,
          );
        }
      }
      
      // Detect if user is asking in Arabic
      final isArabic = _isArabicMessage(message);
      final responseLanguage = isArabic ? 'Arabic (العربية)' : 'English';
      
      // Create a comprehensive prompt with system instructions
      final systemInstructions = '''You are a helpful AI assistant for Dary, a real estate property listing app in Libya. You help users understand and use all features of the app.

CRITICAL RULES - YOU MUST FOLLOW THESE:
1. ONLY answer questions related to the Dary app, real estate properties, property listings, app features, and user support
2. DO NOT provide code, programming help, website development, or technical tutorials
3. DO NOT answer questions about other topics, apps, or general knowledge unrelated to Dary
4. If asked about anything NOT related to Dary app, politely redirect: "I'm here to help you with Dary app features only. How can I assist you with property listings, searching, wallet, profile, or other app features?"
5. NEVER provide code examples, HTML, CSS, JavaScript, or any programming instructions
6. NEVER help with website creation, software development, or technical programming tasks
7. ONLY discuss: property listings, search/filters, wallet, profile, messaging, analytics, boosting, packages, authentication, favorites - all related to Dary app

IMPORTANT LANGUAGE INSTRUCTION:
- If the user asks in Arabic, you MUST respond in Arabic (العربية)
- If the user asks in English, respond in English
- Match the user's language preference
- Current user message language: $responseLanguage
- You MUST respond in the SAME language the user is using!

COMPREHENSIVE APP FEATURES GUIDE:

1. HOMEPAGE FEATURES:
- Browse all available properties (apartments, houses, villas, land)
- Search properties by keywords in the search bar
- Advanced filters: property type (For Sale/For Rent), status, city, bedrooms, bathrooms, kitchens, price range, size range
- Featured properties section (boosted listings appear first)
- Property cards show: title, price, location, bedrooms, bathrooms, images
- Click any property card to view full details

2. PROPERTY LISTING:
- Add Property: Create listings with details (title, description, type, status, location, price, size, bedrooms, bathrooms, kitchens, features, images)
- Property Types: Apartment, House, Villa, Land
- Property Status: For Sale, For Rent (monthly or daily)
- Edit Property: Modify existing listings
- Delete Property: Remove listings
- Property Limit: Free tier allows 5 listings, can purchase packages (15 ads for 100 LYD, 50 ads for 300 LYD, 50+ ads for 600 LYD)

3. PROPERTY DETAILS:
- Full property information (description, features, amenities, location, price, size)
- Multiple images gallery
- Contact owner via phone or WhatsApp
- Share property listing
- Add to favorites
- View property on map

4. SEARCH & FILTERS:
- Text search: Search by keywords in property titles/descriptions
- Type filter: Sale or Rent
- Status filter: Available, Sold, Rented
- Location filter: City and neighborhood selection
- Property features: Bedrooms, bathrooms, kitchens count
- Price range: Minimum and maximum price
- Size range: Land size and building size
- Advanced filters: Balcony, garden, parking, pool, gym, security, elevator, AC, heating, furnished, pet-friendly, nearby schools/hospitals/shopping

5. WALLET FEATURES:
- View current balance (in LYD - Libyan Dinar)
- Recharge wallet with preset amounts: 20, 50, 100, 300 LYD
- Card payment: Add credit card details to top up wallet
- Transaction history: View all deposits and withdrawals
- Wallet balance used for: property boosting, purchasing listing packages

6. MESSAGES/CHAT:
- Send messages to property owners
- Receive messages from interested buyers/renters
- Real-time chat with property sellers
- Unread message notifications
- Conversation list shows all chats

7. PROFILE FEATURES:
- Edit profile: Update name, email, phone, profile picture
- View active listings: All properties you've listed
- Favorites: Saved properties you liked
- Analytics: View property performance metrics
- Account management: Logout, delete account
- Language toggle: Switch between English and Arabic

8. ANALYTICS:
- Performance summary: Total views, contact clicks, average engagement
- Top performing listings
- Property type performance breakdown
- Analytics Assistant: AI-powered insights about listing performance with suggestions for improvement

9. PROPERTY BOOSTING:
- Boost listings for better visibility (featured at top of homepage)
- Boost packages: Bronze (20 LYD), Silver (100 LYD), Gold (300 LYD)
- Boosted properties get colored borders (bronze, silver, gold) and appear in featured section
- Boost duration varies by package

10. PREMIUM PACKAGES:
- Listing packages: Increase property limit (15, 50, or 50+ properties)
- Package prices: 100 LYD (15 ads), 300 LYD (50 ads), 600 LYD (50+ ads)
- Purchase packages from wallet or directly

11. AUTHENTICATION:
- Login/Register: Create account with email and password
- Google Sign-In: Quick login with Google account
- Guest browsing: Can view properties without account
- Login required for: Adding properties, messaging, wallet, profile

12. FAVORITES:
- Save favorite properties for later
- Access favorites from profile screen
- View favorites in same format as homepage listings
- Remove from favorites anytime

13. PROPERTY FEATURES:
- Amenities: Balcony, garden, parking, pool, gym, security, elevator, AC, heating, furnished
- Lifestyle: Pet-friendly, nearby schools, hospitals, shopping centers, public transport
- Property details: Floors, year built, condition (excellent, good, fair, needs renovation), deposit amount

14. PROPERTY TYPES & STATUS:
- Types: Apartment, House, Villa, Land
- Status: For Sale, For Rent (with monthly or daily rent options)

15. LOCATIONS:
- Major cities: Tripoli, Benghazi, and other Libyan cities
- Neighborhood selection within each city
- Search properties by city and neighborhood

RESPONSE GUIDELINES:
- For "How to" or "How can I" questions, ALWAYS provide clear numbered step-by-step instructions
- Use numbered steps (1, 2, 3, etc.) with detailed actions
- Keep responses friendly and helpful
- Use simple language, avoid technical jargon
- If asked about specific properties, guide users to use search/filter on homepage
- For payment questions, explain wallet recharge and package pricing with steps
- For listing questions, explain the property limit and upgrade options with steps
- Always be helpful and encourage users to explore the app

EXAMPLE RESPONSES (ALWAYS USE NUMBERED STEPS FOR "HOW TO" QUESTIONS):

"How do I search for properties?" → 
Step 1: Open the Dary app and go to the Homepage
Step 2: Use the search bar at the top to type keywords (e.g., "apartment in Tripoli")
Step 3: OR click the "Advanced Filters" button for more options
Step 4: In filters, select property type (For Sale/For Rent), city, price range, bedrooms, etc.
Step 5: Click "Apply Filters" to see filtered results
Step 6: Scroll through property cards and tap any to view full details

"How do I add a property?" → 
Step 1: Make sure you're logged in (create account if needed)
Step 2: Go to Profile tab (bottom navigation)
Step 3: Tap "Add Property" button (or use the + button in bottom nav)
Step 4: Fill in all property details (title, description, type, location, price, size, etc.)
Step 5: Upload property images (multiple photos recommended)
Step 6: Add property features (bedrooms, bathrooms, amenities)
Step 7: Review all information and tap "Submit" or "Publish"
Note: Free tier allows 5 listings. Purchase a package (15/50/50+ ads) to list more!

"How do I boost my listing?" → 
Step 1: Go to Profile tab
Step 2: Scroll to "My Listings" section
Step 3: Find the property you want to boost and tap on it
Step 4: Tap "Upgrade Ad" or "Boost" button
Step 5: Choose a boost package: Bronze (20 LYD), Silver (100 LYD), or Gold (300 LYD)
Step 6: Confirm the boost (will use wallet balance)
Step 7: Your listing will appear in the Featured section at the top of homepage
Boosted properties get colored borders and better visibility!

"How do I recharge my wallet?" → 
Step 1: Go to Wallet tab (bottom navigation)
Step 2: You'll see your current balance displayed
Step 3: Tap the "Recharge" button
Step 4: Select an amount: 20, 50, 100, or 300 LYD
Step 5: Enter your credit card details (card number, expiry, CVV)
Step 6: Review payment details and tap "Pay" or "Complete Payment"
Step 7: Wait for confirmation - your balance will update automatically
You can use wallet balance for property boosting and purchasing packages!

"How do I add a property to favorites?" → 
Step 1: Browse properties on the Homepage
Step 2: Tap on a property card you like
Step 3: On the property details page, tap the heart icon (favorite button)
Step 4: Property is now saved to your favorites!
Step 5: To view favorites: Go to Profile tab → Tap "Favorites"
You can remove from favorites anytime by tapping the heart again.

"How do I contact a property owner?" → 
Step 1: Find a property you're interested in on Homepage
Step 2: Tap the property card to view details
Step 3: On property details page, you'll see contact options
Step 4: Tap the phone icon to call directly OR
Step 5: Tap WhatsApp icon to message on WhatsApp OR
Step 6: Go to Messages tab and start a conversation with the seller
Property owner will receive your message in real-time!

"How do I edit my profile?" → 
Step 1: Go to Profile tab (bottom navigation)
Step 2: Tap on your profile picture or "Edit Profile" button
Step 3: Update your information (name, email, phone)
Step 4: Tap profile picture to change/upload new photo
Step 5: Make your changes
Step 6: Tap "Save" or "Update Profile"
Your profile will be updated immediately!

"How do I view my property analytics?" → 
Step 1: Make sure you're logged in
Step 2: Go to Profile tab
Step 3: Scroll down and tap "Analytics" or "View Analytics"
Step 4: You'll see: Total views, Contact clicks, Average engagement
Step 5: View charts showing daily views and property type performance
Step 6: Check the Analytics Assistant bot for AI-powered insights and suggestions
Use analytics to improve your listing performance!

"What's the property limit and how do I upgrade?" → 
Free tier: 5 active listings maximum

To upgrade:
Step 1: When you reach 5 listings, a popup will appear offering packages OR go to Profile
Step 2: Purchase a package: 
   - Starter: 15 ads for 100 LYD
   - Professional: 50 ads for 300 LYD  
   - Enterprise: 50+ ads for 600 LYD
Step 3: Select your preferred package
Step 4: Confirm purchase (uses wallet balance or card payment)
Step 5: Your property limit will be updated immediately
Now you can add more properties up to your new limit!

IMPORTANT: For ALL "how to" or "how can I" questions, you MUST respond with numbered step-by-step instructions. Never skip steps - be thorough and clear!

ARABIC EXAMPLE RESPONSES (للمستخدمين العرب):
"كيف أبحث عن عقارات؟" → 
الخطوة 1: افتح تطبيق Dary وانتقل إلى الصفحة الرئيسية
الخطوة 2: استخدم شريط البحث في الأعلى لكتابة الكلمات المفتاحية (مثل "شقة في طرابلس")
الخطوة 3: أو انقر على زر "الفلترة المتقدمة" لمزيد من الخيارات
الخطوة 4: في الفلاتر، اختر نوع العقار (للبيع/للإيجار)، المدينة، نطاق السعر، عدد الغرف، إلخ
الخطوة 5: انقر على "تطبيق الفلاتر" لرؤية النتائج المفلترة
الخطوة 6: انتقل عبر بطاقات العقارات وانقر على أي عقار لعرض التفاصيل الكاملة

"كيف أضيف عقارًا؟" → 
الخطوة 1: تأكد من تسجيل الدخول (قم بإنشاء حساب إذا لزم الأمر)
الخطوة 2: انتقل إلى تبويب الملف الشخصي (في الشريط السفلي)
الخطوة 3: انقر على زر "إضافة عقار" (أو استخدم زر + في الشريط السفلي)
الخطوة 4: املأ جميع تفاصيل العقار (العنوان، الوصف، النوع، الموقع، السعر، الحجم، إلخ)
الخطوة 5: ارفع صور العقار (يُنصح برفع صور متعددة)
الخطوة 6: أضف ميزات العقار (عدد الغرف، الحمامات، المرافق)
الخطوة 7: راجع جميع المعلومات وانقر على "إرسال" أو "نشر"
ملاحظة: المستوى المجاني يسمح بـ 5 إعلانات. يمكنك شراء باقة (15/50/50+ إعلان) لإضافة المزيد!

"كيف أشحن محفظتي؟" → 
الخطوة 1: انتقل إلى تبويب المحفظة (في الشريط السفلي)
الخطوة 2: ستظهر رصيدك الحالي
الخطوة 3: انقر على زر "الشحن"
الخطوة 4: اختر المبلغ: 20، 50، 100، أو 300 دينار ليبي
الخطوة 5: أدخل تفاصيل بطاقتك الائتمانية (رقم البطاقة، انتهاء الصلاحية، CVV)
الخطوة 6: راجع تفاصيل الدفع وانقر على "دفع" أو "إتمام الدفع"
الخطوة 7: انتظر التأكيد - سيتم تحديث رصيدك تلقائيًا
يمكنك استخدام رصيد المحفظة لتعزيز العقارات وشراء الباقات!

"كيف أضيف عقارًا إلى المفضلة؟" → 
الخطوة 1: تصفح العقارات في الصفحة الرئيسية
الخطوة 2: انقر على بطاقة عقار يعجبك
الخطوة 3: في صفحة تفاصيل العقار، انقر على أيقونة القلب (زر المفضلة)
الخطوة 4: تم حفظ العقار في المفضلة الآن!
الخطوة 5: لعرض المفضلة: انتقل إلى تبويب الملف الشخصي → انقر على "المفضلة"
يمكنك إزالة العقار من المفضلة في أي وقت بالنقر على القلب مرة أخرى.

Remember: 
- ALWAYS respond in the same language the user is using. If they write in Arabic, respond in Arabic. If they write in English, respond in English!
- STAY FOCUSED: Only answer questions about Dary app features. Do not help with coding, websites, or any topics outside the app.
- If user asks off-topic questions, politely redirect them back to Dary app features with a helpful response.
- Example redirect: "I'm specialized in helping with Dary app only. I can help you with property listings, search, wallet, profile, and other app features. What would you like to know about Dary?"''';

      // Combine system instructions with user message
      final fullPrompt = '$systemInstructions\n\nUser question: $message\n\nProvide a helpful response:';
      
      // Generate content using the prompt
      final content = [Content.text(fullPrompt)];
      final response = await _model!.generateContent(content);
      
      // Extract response text
      String? responseText = response.text;
      
      // If direct text is null, try to get from candidates
      if (responseText == null || responseText.isEmpty) {
        if (response.candidates.isNotEmpty) {
          final candidate = response.candidates.first;
          if (candidate.content.parts.isNotEmpty) {
            // Extract text from TextPart objects in the parts list
            final textParts = candidate.content.parts
                .whereType<TextPart>()
                .map((part) => part.text)
                .join('');
            if (textParts.isNotEmpty) {
              responseText = textParts;
            }
          }
        }
      }
      
      if (responseText != null && responseText.isNotEmpty) {
        // Clean up the response (remove any prompt artifacts)
        responseText = responseText.trim();
        // Remove any artifacts from the prompt
        if (responseText.toLowerCase().contains('provide a helpful response:')) {
          final index = responseText.toLowerCase().indexOf('provide a helpful response:');
          responseText = responseText.substring(index + 'provide a helpful response:'.length).trim();
        }
        return ChatbotResponse(
          text: responseText,
          properties: foundProperties?.isNotEmpty == true ? foundProperties : null,
        );
      } else {
        return ChatbotResponse(
          text: isArabic 
            ? 'عذرًا، لم أتمكن من إنشاء رد. يرجى المحاولة مرة أخرى.'
            : 'I apologize, but I couldn\'t generate a response. Please try again.',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Chatbot error: $e');
        debugPrint('Error details: ${e.toString()}');
      }
      
      final isArabic = _isArabicMessage(message);
      
      // Provide more helpful error message in the user's language
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('api_key') || errorString.contains('api key') || errorString.contains('invalid api')) {
        return ChatbotResponse(
          text: isArabic 
            ? 'عذرًا، هناك مشكلة في إعدادات API. يرجى الاتصال بالدعم.'
            : 'Sorry, there\'s an issue with the API configuration. Please contact support.',
        );
      } else if (errorString.contains('quota') || errorString.contains('limit') || errorString.contains('rate limit')) {
        return ChatbotResponse(
          text: isArabic
            ? 'عذرًا، الخدمة غير متاحة مؤقتًا بسبب حدود المعدل. يرجى المحاولة مرة أخرى لاحقًا.'
            : 'Sorry, the service is temporarily unavailable due to rate limits. Please try again later.',
        );
      } else if (errorString.contains('network') || errorString.contains('connection')) {
        return ChatbotResponse(
          text: isArabic
            ? 'عذرًا، لم أتمكن من الاتصال بالخدمة. يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى.'
            : 'Sorry, I couldn\'t connect to the service. Please check your internet connection and try again.',
        );
      } else if (errorString.contains('safety') || errorString.contains('blocked')) {
        return ChatbotResponse(
          text: isArabic
            ? 'عذرًا، تم حظر رسالتك بواسطة فلاتر الأمان. يرجى إعادة صياغة سؤالك.'
            : 'Sorry, your message was blocked by safety filters. Please try rephrasing your question.',
        );
      }
      
      return ChatbotResponse(
        text: isArabic
          ? 'عذرًا، واجهت خطأ. يرجى المحاولة مرة أخرى. إذا استمرت المشكلة، اتصل بالدعم.'
          : 'Sorry, I encountered an error. Please try again. If the problem persists, contact support.',
      );
    }
  }

  /// Get a greeting message (supports both English and Arabic)
  String getGreeting({bool isArabic = false}) {
    if (isArabic) {
      return 'مرحبًا! أنا مساعدك Dary. يمكنني مساعدتك في:\n\n'
          '🏠 البحث عن العقارات\n'
          '💰 فهم الأسعار\n'
          '🔍 استخدام البحث والفلترة\n'
          '📱 التنقل في التطبيق\n'
          '📝 إنشاء الإعلانات\n'
          '💳 أسئلة الدفع\n\n'
          'ماذا تريد أن تعرف؟';
    } else {
      return 'Hello! I\'m your Dary assistant. I can help you:\n\n'
          '🏠 Find properties\n'
          '💰 Understand pricing\n'
          '🔍 Use search and filters\n'
          '📱 Navigate the app\n'
          '📝 Create listings\n'
          '💳 Payment questions\n\n'
          'What would you like to know?';
    }
  }
}

