import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for handling chatbot interactions with Google Gemini API
class ChatbotService {
  static const String _apiKeyCacheKey = 'gemini_api_key_cache';
  static const String _modelName = 'gemini-2.0-flash';
  
  GenerativeModel? _model;
  String? _cachedApiKey;
  bool _isInitializing = false;
  
  ChatbotService() {
    // Initialize model asynchronously
    _initializeModel();
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
      }
      // Fallback: try to initialize with cached key or throw
      if (_cachedApiKey != null && _cachedApiKey!.isNotEmpty) {
        _model = GenerativeModel(
          model: _modelName,
          apiKey: _cachedApiKey!,
        );
      } else {
        rethrow;
      }
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
      final doc = await firestore
          .collection('config')
          .doc('gemini_api_key')
          .get();
      
      if (!doc.exists) {
        throw Exception('API key document not found in Firestore');
      }
      
      final apiKey = doc.data()?['apiKey'] as String?;
      
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('API key not configured in Firestore');
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
        debugPrint('💡 Make sure Firestore document exists at config/gemini_api_key');
      }
      // Fallback: use the key temporarily until Firestore is set up
      // TODO: Remove this fallback after Firestore document is created
      return 'AIzaSyCRjEnjwf210P1Vu_j8HKhXwC9Yh2AErxo';
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

  /// Send a message to the chatbot and get a response
  Future<String> sendMessage(String message, {String? conversationContext}) async {
    try {
      // Ensure model is initialized
      await _ensureModelInitialized();
      
      if (_model == null) {
        throw Exception('Chatbot model not initialized');
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
        if (response.candidates != null && response.candidates!.isNotEmpty) {
          final candidate = response.candidates!.first;
          if (candidate.content != null && candidate.content!.parts.isNotEmpty) {
            // Extract text from TextPart objects in the parts list
            final textParts = candidate.content!.parts
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
        return responseText;
      } else {
        return isArabic 
          ? 'عذرًا، لم أتمكن من إنشاء رد. يرجى المحاولة مرة أخرى.'
          : 'I apologize, but I couldn\'t generate a response. Please try again.';
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
        return isArabic 
          ? 'عذرًا، هناك مشكلة في إعدادات API. يرجى الاتصال بالدعم.'
          : 'Sorry, there\'s an issue with the API configuration. Please contact support.';
      } else if (errorString.contains('quota') || errorString.contains('limit') || errorString.contains('rate limit')) {
        return isArabic
          ? 'عذرًا، الخدمة غير متاحة مؤقتًا بسبب حدود المعدل. يرجى المحاولة مرة أخرى لاحقًا.'
          : 'Sorry, the service is temporarily unavailable due to rate limits. Please try again later.';
      } else if (errorString.contains('network') || errorString.contains('connection')) {
        return isArabic
          ? 'عذرًا، لم أتمكن من الاتصال بالخدمة. يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى.'
          : 'Sorry, I couldn\'t connect to the service. Please check your internet connection and try again.';
      } else if (errorString.contains('safety') || errorString.contains('blocked')) {
        return isArabic
          ? 'عذرًا، تم حظر رسالتك بواسطة فلاتر الأمان. يرجى إعادة صياغة سؤالك.'
          : 'Sorry, your message was blocked by safety filters. Please try rephrasing your question.';
      }
      
      return isArabic
        ? 'عذرًا، واجهت خطأ. يرجى المحاولة مرة أخرى. إذا استمرت المشكلة، اتصل بالدعم.'
        : 'Sorry, I encountered an error. Please try again. If the problem persists, contact support.';
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

