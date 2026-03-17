// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get noInternetConnection => 'لا يوجد اتصال بالإنترنت';

  @override
  String get pleaseCheckConnection => 'يرجى التحقق من إعدادات الشبكة';

  @override
  String get propertyLegalNote =>
      'Please verify all property paperwork. Dary is not responsible for any legal discrepancies or issues.';

  @override
  String get propertyLegalNoteAr =>
      'يرجى التحقق من جميع أوراق العقار. داري ليست مسؤولة عن أي خلافات أو مشاكل قانونية.';

  @override
  String get paymentSuccessful => 'تمت عملية الدفع بنجاح!';

  @override
  String get paymentFailed =>
      'فشلت عملية الدفع. يرجى التحقق من بيانات البطاقة والمحاولة مرة أخرى.';

  @override
  String get changePhoneNumber => 'تغيير رقم الهاتف';

  @override
  String get processing => 'جاري المعالجة...';

  @override
  String get payNow => 'ادفع الآن';

  @override
  String get cardDetails => 'تفاصيل البطاقة';

  @override
  String get cardNumber => 'رقم البطاقة';

  @override
  String get expiryDate => 'تاريخ الانتهاء';

  @override
  String get cvv => 'رمز الأمان';

  @override
  String get cardholderName => 'اسم صاحب البطاقة';

  @override
  String get errorOccurred => 'حدث خطأ ما. يرجى المحاولة مرة أخرى.';

  @override
  String get appTitle => 'عقارات داري';

  @override
  String get home => 'الرئيسية';

  @override
  String get addProperty => 'إضافة عقار';

  @override
  String get wallet => 'المحفظة';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get welcomeMessage => 'مرحباً بك في داري!';

  @override
  String get subtitleMessage => 'تطبيق Flutter البسيط مع Material 3';

  @override
  String get navigationHint => 'استخدم التنقل السفلي لاستكشاف الميزات';

  @override
  String get currentBalance => 'الرصيد الحالي';

  @override
  String get recharge => 'تعبئة الرصيد';

  @override
  String get transactionHistory => 'تاريخ المعاملات';

  @override
  String get export => 'تصدير';

  @override
  String get myProfile => 'ملفي الشخصي';

  @override
  String get manageAccountSettings => 'إدارة إعدادات حسابك';

  @override
  String get activeListings => 'القوائم النشطة';

  @override
  String get viewAll => 'عرض الكل';

  @override
  String get accountManagement => 'إدارة الحساب';

  @override
  String get editProfile => 'تعديل الملف الشخصي';

  @override
  String get upgradeToPremium => 'ترقية إلى المميز';

  @override
  String get deleteAccount => 'حذف الحساب';

  @override
  String get upgradeToPremiumTitle => 'شراء نقاط';

  @override
  String get boostYourListings => 'عزز عقاراتك';

  @override
  String get getMoreVisibility => 'اشترِ نقاط نشر لإدراج عقاراتك';

  @override
  String get limitedTimeOffer => '✨ عرض لفترة محدودة';

  @override
  String get chooseYourPackage => 'اختر باقة النقاط';

  @override
  String get selectPerfectDuration => 'النقاط دائمة ولا تنتهي أبداً';

  @override
  String get topListing => 'أفضل عرض';

  @override
  String get oneDay => 'يوم واحد';

  @override
  String get oneWeek => 'أسبوع واحد';

  @override
  String get oneMonth => 'شهر واحد';

  @override
  String get popular => 'شائع';

  @override
  String get perfectForQuickPromotion => 'مثالي للترويج السريع';

  @override
  String get greatForTestingWaters => 'رائع لاختبار السوق';

  @override
  String get bestValueForSeriousSellers => 'أفضل قيمة للبائعين الجديين';

  @override
  String get priorityPlacement => 'أولوية الظهور في نتائج البحث';

  @override
  String get featuredBadge => 'شارة مميزة على إعلانك';

  @override
  String get increasedVisibility => 'زيادة المشاهدات';

  @override
  String get dayBoost => 'تعزيز لمدة 24 ساعة';

  @override
  String get weekBoost => 'تعزيز لمدة 7 أيام';

  @override
  String get monthBoost => 'تعزيز لمدة 30 يوماً';

  @override
  String get analyticsDashboard => 'لوحة تحليل البيانات';

  @override
  String get premiumSupport => 'دعم متميز';

  @override
  String get multipleListingPromotion => 'ترويج عدة عقارات';

  @override
  String get customListingDesign => 'تصميم مخصص للعقار';

  @override
  String get buyOneDay => 'شراء يوم واحد';

  @override
  String get buyOneWeek => 'شراء أسبوع واحد';

  @override
  String get buyOneMonth => 'شراء شهر واحد';

  @override
  String get whyChooseTopListing => 'لماذا تميز إعلانك؟';

  @override
  String get increasedVisibilityDescription =>
      'يظهر إعلانك في أعلى نتائج البحث';

  @override
  String get featuredBadgeDescription =>
      'تميّز بشارة مميزة واحتل موقعاً بارزاً';

  @override
  String get analyticsDashboardDescription =>
      'تتبع المشاهدات والنقرات ومعدلات التفاعل';

  @override
  String get premiumSupportDescription => 'احصل على دعم عملاء ذو أولوية';

  @override
  String successfullyPurchased(String packageName) {
    return 'تم شراء $packageName بنجاح!';
  }

  @override
  String get viewDetails => 'عرض التفاصيل';

  @override
  String get purchaseFailed => 'فشل الشراء. يرجى المحاولة مرة أخرى.';

  @override
  String errorProcessingPurchase(String error) {
    return 'خطأ في معالجة الشراء: $error';
  }

  @override
  String get addPropertyTitle => 'إضافة عقار';

  @override
  String get propertyTitle => 'العقار';

  @override
  String get enterPropertyTitle => 'أدخل عنوان العقار';

  @override
  String get description => 'الوصف';

  @override
  String get describeYourProperty => 'اوصف عقارك';

  @override
  String get price => 'السعر';

  @override
  String get enterPrice => 'أدخل السعر';

  @override
  String get size => 'المساحة (م²)';

  @override
  String get enterSize => 'أدخل المساحة بالمتر المربع';

  @override
  String get features => 'المميزات';

  @override
  String get balcony => 'شرفة';

  @override
  String get propertyHasBalcony => 'العقار يحتوي على شرفة';

  @override
  String get garden => 'حديقة';

  @override
  String get propertyHasGarden => 'العقار يحتوي على حديقة';

  @override
  String get parking => 'موقف سيارات';

  @override
  String get propertyHasParking => 'العقار يحتوي على موقف سيارات';

  @override
  String get images => 'الصور';

  @override
  String get uploadImages => 'رفع الصور (حتى 10)';

  @override
  String imagesSelected(int count) {
    return 'تم اختيار $count صورة';
  }

  @override
  String get selectedImages => 'الصور المختارة:';

  @override
  String get addPropertyButton => 'إضافة عقار';

  @override
  String get addingProperty => 'جاري إضافة العقار...';

  @override
  String get propertyAddedSuccessfully => 'تم إضافة العقار بنجاح!';

  @override
  String get languageToggle => 'اللغة';

  @override
  String get noTransactionsYet => 'لا توجد معاملات بعد';

  @override
  String get exportTransactions => 'تصدير المعاملات';

  @override
  String get searchProperties => 'البحث في العقارات...';

  @override
  String get featured => 'صورة الغلاف';

  @override
  String get verified => 'معتمد';

  @override
  String get priceRange => 'نطاق السعر';

  @override
  String get clearFilters => 'مسح الفلاتر';

  @override
  String get advancedFilters => 'متقدم';

  @override
  String get propertyType => 'نوع العقار';

  @override
  String get propertyStatus => 'حالة العقار';

  @override
  String get applyFilters => 'تطبيق الفلاتر';

  @override
  String get forSale => 'للبيع';

  @override
  String get forRent => 'للإيجار';

  @override
  String get sold => 'مباع';

  @override
  String get rented => 'مؤجر';

  @override
  String get apartment => 'شقة';

  @override
  String get house => 'منزل';

  @override
  String get villa => 'فيلا';

  @override
  String get townhouse => 'منزل متلاصق';

  @override
  String get studio => 'استوديو';

  @override
  String get penthouse => 'بنتهاوس';

  @override
  String get commercial => 'تجاري';

  @override
  String get land => 'أرض';

  @override
  String get noPropertiesFound => 'لم يتم العثور على عقارات';

  @override
  String get tryAdjustingFilters => 'حاول تعديل الفلاتر';

  @override
  String get basicInformation => 'المعلومات الأساسية';

  @override
  String get locationInformation => 'معلومات الموقع';

  @override
  String get propertyDetails => 'تفاصيل العقار';

  @override
  String get contactInformation => 'معلومات الاتصال';

  @override
  String get pleaseEnterTitle => 'الرجاء إدخال العنوان';

  @override
  String get pleaseEnterDescription => 'الرجاء إدخال الوصف';

  @override
  String get pleaseEnterPrice => 'الرجاء إدخال السعر';

  @override
  String get pleaseEnterValidPrice => 'الرجاء إدخال سعر صالح';

  @override
  String get pleaseEnterSize => 'الرجاء إدخال المساحة';

  @override
  String get pleaseEnterValidSize => 'الرجاء إدخال مساحة صالحة';

  @override
  String get maxImages => 'يمكنك تحميل 10 صور كحد أقصى.';

  @override
  String get failedToPickImages => 'فشل في اختيار الصور:';

  @override
  String get selectImages => 'اختر الصور';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get register => 'إنشاء حساب';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get phoneNumber => 'رقم الهاتف';

  @override
  String get loginTitle => 'مرحباً بعودتك';

  @override
  String get loginSubtitle => 'سجل دخولك إلى حسابك';

  @override
  String get registerTitle => 'إنشاء حساب';

  @override
  String get registerSubtitle => 'انضم إلى داري العقارية اليوم';

  @override
  String get loginButton => 'تسجيل الدخول';

  @override
  String get registerButton => 'إنشاء حساب';

  @override
  String get alreadyHaveAccount => 'لديك حساب بالفعل؟';

  @override
  String get dontHaveAccount => 'ليس لديك حساب؟';

  @override
  String get signInHere => 'سجل دخولك هنا';

  @override
  String get signUpHere => 'سجل هنا';

  @override
  String get enterEmail => 'أدخل بريدك الإلكتروني';

  @override
  String get enterPassword => 'أدخل كلمة المرور';

  @override
  String get enterConfirmPassword => 'أكد كلمة المرور';

  @override
  String get enterFullName => 'أدخل اسمك الكامل';

  @override
  String get enterPhoneNumber => 'أدخل رقم هاتفك';

  @override
  String get emailRequired => 'البريد الإلكتروني مطلوب';

  @override
  String get passwordRequired => 'كلمة المرور مطلوبة';

  @override
  String get nameRequired => 'الاسم الكامل مطلوب';

  @override
  String get phoneRequired => 'رقم الهاتف مطلوب';

  @override
  String get confirmPasswordRequired => 'الرجاء تأكيد كلمة المرور';

  @override
  String get invalidEmail => 'بريد إلكتروني غير صالح';

  @override
  String get passwordTooShort => 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';

  @override
  String get passwordsDoNotMatch => 'كلمات المرور غير متطابقة';

  @override
  String get loginSuccess => 'تم تسجيل الدخول بنجاح! مرحباً بعودتك';

  @override
  String get registerSuccess => 'تم إنشاء الحساب بنجاح! مرحباً بك في داري';

  @override
  String get loginFailed => 'فشل تسجيل الدخول. يرجى التحقق من بيانات الاعتماد';

  @override
  String get registerFailed => 'فشل التسجيل. يرجى المحاولة مرة أخرى';

  @override
  String get firebaseWrongPassword =>
      'كلمة المرور غير صحيحة. يرجى المحاولة مرة أخرى.';

  @override
  String get firebaseUserNotFound =>
      'لم يتم العثور على حساب بهذا البريد الإلكتروني أو رقم الهاتف.';

  @override
  String get firebaseEmailAlreadyInUse =>
      'هذا البريد الإلكتروني مسجل بالفعل. يرجى تسجيل الدخول.';

  @override
  String get firebasePhoneAlreadyInUse => 'رقم الهاتف هذا مسجل بالفعل.';

  @override
  String get firebaseWeakPassword =>
      'كلمة المرور ضعيفة جداً. يرجى اختيار كلمة مرور أقوى.';

  @override
  String get firebaseTooManyRequests =>
      'محاولات كثيرة جداً. يرجى الانتظار قليلاً والمحاولة مرة أخرى.';

  @override
  String get firebaseNetworkError =>
      'خطأ في الشبكة. يرجى التحقق من اتصالك بالإنترنت.';

  @override
  String get firebaseInvalidCredential =>
      'بيانات الاعتماد غير صالحة. يرجى التحقق من بريدك الإلكتروني وكلمة المرور.';

  @override
  String get firebaseUserDisabled =>
      'تم تعطيل هذا الحساب. يرجى التواصل مع الدعم.';

  @override
  String get firebaseOperationNotAllowed =>
      'هذه العملية غير مسموح بها. يرجى التواصل مع الدعم.';

  @override
  String get firebaseInvalidEmail => 'صيغة البريد الإلكتروني غير صالحة.';

  @override
  String get firebaseAccountExistsWithDifferentCredential =>
      'يوجد حساب بالفعل بنفس البريد الإلكتروني ولكن ببيانات اعتماد مختلفة.';

  @override
  String get firebaseRequiresRecentLogin =>
      'هذه العملية حساسة وتتطلب تسجيل دخول حديث. يرجى تسجيل الدخول مرة أخرى.';

  @override
  String get firebaseGenericError => 'حدث خطأ. يرجى المحاولة مرة أخرى.';

  @override
  String get loggingIn => 'جاري تسجيل الدخول...';

  @override
  String get registering => 'جاري إنشاء الحساب...';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get forgotPasswordTitle => 'نسيت كلمة المرور؟';

  @override
  String get forgotPasswordDescription =>
      'لا تقلق! أدخل بريدك الإلكتروني أدناه لتلقي تعليمات إعادة تعيين كلمة المرور.';

  @override
  String get sendInstructions => 'إرسال التعليمات';

  @override
  String get rememberPassword => 'تذكرت كلمة المرور؟';

  @override
  String get backToLogin => 'العودة لتسجيل الدخول';

  @override
  String get enterValidEmail => 'يرجى إدخال بريد إلكتروني صحيح';

  @override
  String get resetInstructionsSent =>
      'تم إرسال تعليمات إعادة تعيين كلمة المرور إلى بريدك الإلكتروني.';

  @override
  String get checkEmail => 'تحقق من بريدك الإلكتروني';

  @override
  String get pleaseVerifyEmail => 'يرجى تفعيل البريد الإلكتروني';

  @override
  String get verificationEmailSentDesc =>
      'تم إرسال رابط التفعيل إلى بريدك الإلكتروني. يرجى التفعيل للوصول إلى كافة الميزات.';

  @override
  String get resend => 'إعادة إرسال';

  @override
  String get verificationEmailSent => 'تم إرسال بريد التفعيل!';

  @override
  String get verifiedAccount => 'حساب موثق';

  @override
  String get unverifiedAccount => 'حساب غير موثق';

  @override
  String get rememberMe => 'تذكرني';

  @override
  String get tooManyAttempts =>
      'محاولات كثيرة جداً. يرجى المحاولة مرة أخرى لاحقاً.';

  @override
  String get emailNotVerifiedTitle => 'البريد الإلكتروني غير مفعل';

  @override
  String get emailNotVerifiedMessage =>
      'يرجى تفعيل بريدك الإلكتروني للوصول إلى كافة الميزات. تحقق من بريدك الوارد لرابط التفعيل.';

  @override
  String get becomeRealEstateOffice => 'ترقية حسابي لمكتب عقاري';

  @override
  String realEstateOfficeRequestMessage(String name, String id) {
    return 'مرحباً، أود ترقية حسابي إلى مكتب عقاري.\nالاسم: $name\nرقم الحساب: $id';
  }

  @override
  String get propertyExpiringSoonTitle => 'تنتهي صلاحية العقار قريباً!';

  @override
  String propertyExpiringSoonMessage(String title, int days) {
    return 'تنتهي صلاحية عقارك \"$title\" خلال $days أيام. قم بتجديده الآن لإبقائه نشطاً!';
  }

  @override
  String get termsAndConditions => 'الشروط والأحكام';

  @override
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String get logoutSuccess => 'تم تسجيل الخروج بنجاح';

  @override
  String get messages => 'الرسائل';

  @override
  String get chat => 'المحادثة';

  @override
  String get typeMessage => 'أكتب رسالة...';

  @override
  String get noMessagesYet => 'لا توجد رسائل بعد';

  @override
  String get startConversation => 'ابدأ المحادثة!';

  @override
  String get noConversationsYet => 'لا توجد محادثات بعد';

  @override
  String get startConversationWithSeller =>
      'ابدأ محادثة مع البائع لمناقشة العقارات!';

  @override
  String get browseProperties => 'تصفح العقارات';

  @override
  String get conversationNotFound => 'المحادثة غير موجودة';

  @override
  String get errorLoadingMessages => 'خطأ في تحميل الرسائل';

  @override
  String get errorSendingMessage => 'خطأ في إرسال الرسالة';

  @override
  String get errorLoadingConversations => 'خطأ في تحميل المحادثات';

  @override
  String get pleaseLoginFirst => 'يرجى تسجيل الدخول أولاً';

  @override
  String get cannotContactYourself => 'لا يمكنك التواصل مع نفسك';

  @override
  String get errorCreatingConversation => 'خطأ في إنشاء المحادثة';

  @override
  String get errorContactingSeller => 'خطأ في التواصل مع البائع';

  @override
  String get contactSeller => 'تواصل مع البائع';

  @override
  String get creatingConversation => 'جاري إنشاء المحادثة...';

  @override
  String get agentInfo => 'معلومات الوكيل';

  @override
  String get realEstateAgent => 'وكيل عقاري';

  @override
  String get views => 'المشاهدات';

  @override
  String get listedOn => 'مدرج في';

  @override
  String get bedrooms => 'غرف النوم';

  @override
  String get bathrooms => 'دورات المياه';

  @override
  String get sqm => 'متر مربع';

  @override
  String get pool => 'مسبح';

  @override
  String get gym => 'صالة رياضية';

  @override
  String get security => 'أمان';

  @override
  String get elevator => 'مصعد';

  @override
  String get ac => 'تكييف';

  @override
  String get furnished => 'مفروش';

  @override
  String get newConversationStarted => 'تم بدء محادثة جديدة';

  @override
  String get about => 'حول';

  @override
  String get view => 'عرض';

  @override
  String get testNotification => 'اختبار الإشعارات';

  @override
  String get verification => 'التحقق';

  @override
  String get verificationInfo => 'معلومات التحقق';

  @override
  String get verificationDescription =>
      'لتصبح بائعاً معتمداً، يرجى رفع بطاقة الهوية ورخصة العمل. هذا يساعدنا في التحقق من هويتك وبناء الثقة مع المشترين المحتملين.';

  @override
  String get uploadIdCard => 'رفع بطاقة الهوية';

  @override
  String get uploadBusinessLicense => 'رفع رخصة العمل';

  @override
  String get tapToUploadIdCard => 'اضغط لرفع بطاقة الهوية';

  @override
  String get tapToUploadLicense => 'اضغط لرفع رخصة العمل';

  @override
  String get submitVerification => 'إرسال للتحقق';

  @override
  String get verificationSuccess => 'أنت الآن بائع معتمد!';

  @override
  String get verificationSuccessMessage =>
      'تم التحقق من وثائقك. يمكنك الآن الاستمتاع بجميع فوائد كونك بائعاً معتمداً.';

  @override
  String get continueText => 'متابعة';

  @override
  String get alreadyVerified => 'أنت معتمد بالفعل!';

  @override
  String get alreadyVerifiedMessage =>
      'تم التحقق من حسابك. يمكنك الاستمتاع بجميع فوائد كونك بائعاً معتمداً.';

  @override
  String get backToProfile => 'العودة إلى الملف الشخصي';

  @override
  String get getVerified => 'توثيق الحساب';

  @override
  String get privacyNotice =>
      'وثائقك مشفرة ومخزنة بأمان. نستخدمها فقط لأغراض التحقق.';

  @override
  String get pleaseUploadBothDocuments => 'يرجى رفع كلا الوثيقتين';

  @override
  String get verificationError => 'فشل التحقق. يرجى المحاولة مرة أخرى.';

  @override
  String errorPickingImage(Object error) {
    return 'خطأ في اختيار الصورة: $error';
  }

  @override
  String get camera => 'الكاميرا';

  @override
  String get gallery => 'المعرض';

  @override
  String get analytics => 'التحليلات';

  @override
  String get viewAnalytics => 'عرض التحليلات';

  @override
  String get performanceOverview => 'نظرة عامة على الأداء';

  @override
  String get topPerformingListing => 'أفضل إعلان أداءً';

  @override
  String get averageEngagement => 'متوسط التفاعل';

  @override
  String get totalViews => 'إجمالي المشاهدات';

  @override
  String get totalContacts => 'إجمالي جهات الاتصال';

  @override
  String get dailyViews => 'المشاهدات اليومية (آخر 7 أيام)';

  @override
  String get propertyTypePerformance => 'أداء أنواع العقارات';

  @override
  String get detailedMetrics => 'المقاييس التفصيلية';

  @override
  String get totalListings => 'إجمالي القوائم';

  @override
  String get averageViewsPerListing => 'متوسط المشاهدات لكل إعلان';

  @override
  String get contactConversionRate => 'معدل تحويل جهات الاتصال';

  @override
  String get errorLoadingAnalytics => 'خطأ في تحميل بيانات التحليلات';

  @override
  String get adminDashboard => 'لوحة تحكم المسؤول';

  @override
  String get users => 'المستخدمون';

  @override
  String get properties => 'العقارات';

  @override
  String get payments => 'المدفوعات';

  @override
  String get totalUsers => 'إجمالي المستخدمين';

  @override
  String get totalProperties => 'إجمالي العقارات';

  @override
  String get totalPayments => 'إجمالي المدفوعات';

  @override
  String get totalRevenue => 'إجمالي الإيرادات';

  @override
  String get name => 'الاسم';

  @override
  String get phone => 'الهاتف';

  @override
  String get active => 'نشط';

  @override
  String get listings => 'الإعلانات';

  @override
  String get actions => 'الإجراءات';

  @override
  String get title => 'العنوان';

  @override
  String get owner => 'المالك';

  @override
  String get city => 'المدينة';

  @override
  String get status => 'الحالة';

  @override
  String get user => 'المستخدم';

  @override
  String get type => 'النوع';

  @override
  String get amount => 'المبلغ';

  @override
  String get date => 'التاريخ';

  @override
  String get errorLoadingAdminData => 'خطأ في تحميل بيانات الإدارة';

  @override
  String get premiumListings => 'الإعلانات المميزة';

  @override
  String get sortBy => 'ترتيب حسب';

  @override
  String get purchaseDate => 'تاريخ الشراء';

  @override
  String get packagePrice => 'سعر الحزمة';

  @override
  String get package => 'الحزمة';

  @override
  String get expiry => 'الانتهاء';

  @override
  String get boostedProperties => 'العقارات المعززة';

  @override
  String get featuredProperties => 'العقارات المميزة';

  @override
  String get allProperties => 'جميع العقارات';

  @override
  String get rent => 'إيجار';

  @override
  String get savedSearches => 'البحث المحفوظ';

  @override
  String get noSavedSearches => 'لا توجد عمليات بحث محفوظة';

  @override
  String get noSavedSearchesDescription =>
      'احفظ عمليات البحث عن العقارات لتلقي إشعارات عند إضافة عقارات جديدة مطابقة';

  @override
  String get startSearching => 'ابدأ البحث';

  @override
  String get runSearch => 'تشغيل البحث';

  @override
  String get checkNewMatches => 'فحص الجديد';

  @override
  String get saveSearch => 'حفظ البحث';

  @override
  String get enterSearchName => 'أدخل اسمًا لهذا البحث:';

  @override
  String get searchSavedSuccessfully => 'تم حفظ البحث بنجاح!';

  @override
  String get failedToSaveSearch => 'فشل في حفظ البحث';

  @override
  String get pleaseLoginToSaveSearches => 'يرجى تسجيل الدخول لحفظ عمليات البحث';

  @override
  String get searchDeletedSuccessfully => 'تم حذف البحث بنجاح';

  @override
  String get failedToDeleteSearch => 'فشل في حذف البحث';

  @override
  String get deleteSavedSearch => 'حذف البحث المحفوظ';

  @override
  String areYouSureDeleteSearch(Object searchName) {
    return 'هل أنت متأكد من أنك تريد حذف \"$searchName\"؟';
  }

  @override
  String foundNewProperties(Object count, Object searchName) {
    return 'تم العثور على $count عقار جديد مطابق لـ \"$searchName\"';
  }

  @override
  String get delete => 'حذف';

  @override
  String get sell => 'بيع';

  @override
  String get notificationSettings => 'إعدادات الإشعارات';

  @override
  String get notificationStatus => 'حالة الإشعارات';

  @override
  String get notificationsEnabled => 'الإشعارات مفعلة';

  @override
  String get notificationsDisabled => 'الإشعارات معطلة';

  @override
  String get enableNotifications => 'تفعيل الإشعارات';

  @override
  String get enableNotificationsSubtitle =>
      'تلقي إشعارات للعقارات الجديدة والرسائل';

  @override
  String get firebaseCloudMessaging => 'رسائل Firebase السحابية';

  @override
  String get fcmEnabled => 'رسائل Firebase مفعلة وتعمل';

  @override
  String get fcmDisabled => 'رسائل Firebase معطلة أو غير متاحة';

  @override
  String get fcmToken => 'رمز Firebase';

  @override
  String get fcmTokenDescription =>
      'يستخدم هذا الرمز لإرسال إشعارات الدفع إلى جهازك';

  @override
  String get fcmTokenNotAvailable => 'رمز Firebase غير متاح';

  @override
  String get notificationTypes => 'أنواع الإشعارات';

  @override
  String get newListingsNotifications => 'العقارات الجديدة';

  @override
  String get newListingsNotificationsSubtitle =>
      'تلقي إشعارات عند مطابقة عقارات جديدة لعمليات البحث المحفوظة';

  @override
  String get chatNotifications => 'رسائل الدردشة';

  @override
  String get chatNotificationsSubtitle => 'تلقي إشعارات عند استلام رسائل جديدة';

  @override
  String get priceDropNotifications => 'انخفاض الأسعار';

  @override
  String get priceDropNotificationsSubtitle =>
      'تلقي إشعارات عند انخفاض أسعار العقارات التي تتابعها';

  @override
  String get testNotifications => 'اختبار الإشعارات';

  @override
  String get testNotificationsDescription =>
      'اختبر إعداد الإشعارات بإرسال إشعار تجريبي';

  @override
  String get sendTestNotification => 'إرسال اختبار';

  @override
  String get testNotificationSent => 'تم إرسال الإشعار التجريبي!';

  @override
  String get clearAllNotifications => 'مسح الكل';

  @override
  String get markAllAsRead => 'تمييز الكل كمقروء';

  @override
  String get noNotificationsYet => 'لا توجد إشعارات بعد';

  @override
  String get notificationsDiscoverySubtitle => 'سنقوم بإخطارك عند حدوث شيء مهم';

  @override
  String get notificationsCleared => 'تم مسح جميع الإشعارات';

  @override
  String get lastCheckTime => 'وقت آخر فحص';

  @override
  String get lastCheckTimeDescription =>
      'آخر مرة فحص فيها التطبيق عن عقارات جديدة مطابقة';

  @override
  String get editDetails => 'تعديل التفاصيل';

  @override
  String get unpublish => 'إلغاء النشر';

  @override
  String get publishNow => 'انشر الآن';

  @override
  String get publish => 'نشر';

  @override
  String get renewListing => 'تجديد الإعلان';

  @override
  String get deleteForever => 'حذف نهائي';

  @override
  String viewsCount(int count) {
    return '$count مشاهدة';
  }

  @override
  String get publishedStatus => 'منشور';

  @override
  String get unpublishedStatus => 'غير منشور';

  @override
  String get boostedStatus => 'معزز';

  @override
  String get expiredStatus => 'منتهي';

  @override
  String daysLeftCount(int count) {
    return '$count يوماً متبقية';
  }

  @override
  String get edit => 'تعديل';

  @override
  String get renew => 'تجديد';

  @override
  String get cancel => 'إلغاء';

  @override
  String get confirm => 'تأكيد';

  @override
  String get unpublishSuccess => 'تم إلغاء نشر العقار بنجاح';

  @override
  String get unpublishFailed => 'فشل في إلغاء نشر العقار';

  @override
  String get publishSuccess => 'تم نشر العقار بنجاح';

  @override
  String get publishFailed => 'فشل في نشر العقار';

  @override
  String get renewSuccess => 'تم تجديد العقار بنجاح';

  @override
  String get renewFailed => 'فشل في تجديد العقار';

  @override
  String get deleteSuccess => 'تم حذف العقار بنجاح';

  @override
  String get deleteFailed => 'فشل في حذف العقار';

  @override
  String get deletePropertyTitle => 'حذف العقار';

  @override
  String get deletePropertyConfirm =>
      'هل أنت متأكد من أنك تريد حذف هذا العقار؟ لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get neighborhood => 'الحي';

  @override
  String get kitchens => 'المطابخ';

  @override
  String get sizeRange => 'نطاق المساحة';

  @override
  String get priceRangeLyd => 'نطاق السعر (د.ل)';

  @override
  String bedroomsCount(int count) {
    return '$count غرف نوم';
  }

  @override
  String bathroomsCount(int count) {
    return '$count حمامات';
  }

  @override
  String get typeApartment => 'شقة';

  @override
  String get typeHouse => 'منزل';

  @override
  String get typeVilla => 'فيلا';

  @override
  String get typeVacationHome => 'منزل عطلات';

  @override
  String get typeTownhouse => 'تاون هاوس';

  @override
  String get typeStudio => 'استوديو';

  @override
  String get typePenthouse => 'بنتهاوس';

  @override
  String get typeCommercial => 'تجاري';

  @override
  String get typeLand => 'أرض';

  @override
  String get statusForSale => 'للبيع';

  @override
  String get statusForRent => 'للايجار';

  @override
  String get statusSold => 'تم البيع';

  @override
  String get statusRented => 'تم التأجير';

  @override
  String get condNewConstruction => 'بناء جديد';

  @override
  String get condExcellent => 'ممتاز';

  @override
  String get condGood => 'جيد';

  @override
  String get condFair => 'مقبول';

  @override
  String get condNeedsRenovation => 'يحتاج ترميم';

  @override
  String get whatTypeProperty => 'ما هو نوع العقار؟';

  @override
  String get selectCategoryDescription => 'اختر الفئة التي تصف عقارك بشكل أفضل';

  @override
  String get listingType => 'نوع الإعلان';

  @override
  String get tellUsAboutProperty => 'أخبرنا عن عقارك';

  @override
  String get addCompellingDescription => 'أضف عنواناً ووصفاً جذاباً';

  @override
  String get titleHint => 'مثال: شقة جميلة 3 غرف في وسط المدينة';

  @override
  String get descriptionHint => 'صف ميزات عقارك، والحي، وما يجعله مميزاً...';

  @override
  String get proTip => 'نصيحة احترافية';

  @override
  String get detailedDescriptionTip =>
      'العقارات ذات الأوصاف التفصيلية تحصل على مشاهدات أكثر بنسبة 40%!';

  @override
  String get whereIsProperty => 'أين يقع عقارك؟';

  @override
  String get helpBuyersFind => 'ساعد المشترين في العثور على عقارك بسهولة';

  @override
  String get streetAddress => 'عنوان الشارع';

  @override
  String get addressHint => 'مثال: شارع 123 الرئيسي';

  @override
  String get roomsSizePricing => 'الغرف، المساحة والتسعير';

  @override
  String get salePriceLyd => 'سعر البيع (د.ل)';

  @override
  String get monthlyRent => 'إيجار شهري';

  @override
  String get dailyRent => 'إيجار يومي';

  @override
  String get enterMonthlyRent => 'أدخل الإيجار الشهري';

  @override
  String get enterDailyRent => 'أدخل الإيجار اليومي';

  @override
  String get beds => 'أسرة';

  @override
  String get baths => 'حمامات';

  @override
  String get landSizeM2 => 'مساحة الأرض (م²)';

  @override
  String get buildingSizeM2 => 'مساحة البناء (م²)';

  @override
  String get enterSizeM2 => 'أدخل المساحة بالمتر المربع';

  @override
  String get floors => 'الطوابق';

  @override
  String get yearBuilt => 'سنة البناء';

  @override
  String get discardChangesTitle => 'تجاهل التغييرات؟';

  @override
  String get discardChangesMessage =>
      'هل أنت متأكد من أنك تريد المغادرة؟ سيتم فقدان تقدمك.';

  @override
  String get discard => 'تجاهل';

  @override
  String get continueButton => 'استمرار';

  @override
  String stepProgress(int current, int total) {
    return 'الخطوة $current من $total';
  }

  @override
  String get editProperty => 'تعديل العقار';

  @override
  String get saving => 'جاري الحفظ...';

  @override
  String get updateProperty => 'تحديث العقار';

  @override
  String get publishProperty => 'نشر العقار';

  @override
  String get back => 'رجوع';

  @override
  String get photosAdded => 'صور مضافة';

  @override
  String get photoTipsDescription =>
      '• استخدم إضاءة جيدة\n• أظهر جميع الغرف\n• أضف صوراً خارجية';

  @override
  String get indoorFeatures => 'الميزات الداخلية';

  @override
  String get outdoorFeatures => 'الميزات الخارجية';

  @override
  String get buildingFeatures => 'ميزات المبنى';

  @override
  String get nearby => 'بالقرب من';

  @override
  String minImagesError(int count) {
    return 'يرجى تحميل 4 صور على الأقل. لقد قمت بتحميل $count صورة.';
  }

  @override
  String uploadingImages(int count) {
    return 'جاري تحميل $count صور...';
  }

  @override
  String insufficientBalance(
      String amount, Object balance, Object currency, Object price) {
    return 'رصيد غير كاف. تحتاج إلى $price $currency ولكن لديك فقط $balance $currency';
  }

  @override
  String get propertyUpdatedSuccessfully => 'تم تحديث العقار بنجاح!';

  @override
  String get propertyPublishedSuccessfully => 'تم نشر العقار بنجاح!';

  @override
  String get boostActivated => 'تم تفعيل الترويج!';

  @override
  String get selectPackage => 'اختر الباقة';

  @override
  String get chooseBoostPackage => 'اختر باقة لتمييز إعلان عقارك:';

  @override
  String get plusBoost => 'تمييز بلس';

  @override
  String get emeraldBoost => 'تمييز الزمرد';

  @override
  String get eliteBoost => 'تمييز النخبة';

  @override
  String get premiumBoost => 'تمييز بريميوم';

  @override
  String get durationOneDay => 'يوم واحد';

  @override
  String get durationThreeDays => '3 أيام';

  @override
  String get durationSevenDays => '7 أيام';

  @override
  String get durationThirtyDays => '30 يوماً';

  @override
  String get rooms => 'الغرف';

  @override
  String get location => 'الموقع';

  @override
  String get select => 'اختيار';

  @override
  String get packageSelected => 'تم اختيار هذه الحزمة لعقارك';

  @override
  String get changePackage => 'تغيير الحزمة';

  @override
  String get upgradeBoost => 'ميز إعلانك';

  @override
  String get boostDescription => 'اجعل عقارك مميزاً بميزات حصرية!';

  @override
  String get eliteBranding => 'علامة تجارية للنخبة';

  @override
  String get dedicatedSupport => 'دعم مخصص';

  @override
  String get packageCleared => 'تم إلغاء اختيار الحزمة';

  @override
  String get loginRequired => 'تسجيل الدخول مطلوب';

  @override
  String get pleaseLoginToAddProperty =>
      'يرجى تسجيل الدخول لإضافة عقارات إلى المنصة';

  @override
  String get backToHome => 'العودة للصفحة الرئيسية';

  @override
  String get close => 'إغلاق';

  @override
  String packageSelectedWithPrice(Object package, Object price) {
    return 'تم اختيار الباقة: $package ($price د.ل)';
  }

  @override
  String get clearSelection => 'إلغاء الاختيار';

  @override
  String selectedWithPrice(Object package, Object price) {
    return 'تم الاختيار: $package ($price د.ل)';
  }

  @override
  String get basicInfo => 'معلومات أساسية';

  @override
  String get details => 'التفاصيل';

  @override
  String get amenities => 'المرافق';

  @override
  String get photos => 'الصور';

  @override
  String get showItOff => 'اعرض عقارك';

  @override
  String get condition => 'الحالة';

  @override
  String get selectCity => 'اختر المدينة';

  @override
  String get selectCityFirst => 'اختر المدينة أولاً';

  @override
  String get selectNeighborhood => 'اختر الحي';

  @override
  String get pleaseSelectCity => 'يرجى اختيار مدينة';

  @override
  String get pleaseSelectNeighborhood => 'يرجى اختيار حي';

  @override
  String get pleaseEnterAddress => 'يرجى إدخال العنوان';

  @override
  String get pleaseEnterMonthlyRent => 'يرجى إدخال الإيجار الشهري';

  @override
  String get pleaseEnterDailyRent => 'يرجى إدخال الإيجار اليومي';

  @override
  String get pleaseEnterLandSize => 'يرجى إدخال مساحة الأرض';

  @override
  String get pleaseEnterBuildingSize => 'يرجى إدخال مساحة البناء';

  @override
  String get pleaseAddPhoto => 'يرجى إضافة صورة واحدة على الأقل';

  @override
  String get heating => 'تدفئة';

  @override
  String get waterWell => 'بئر ماء';

  @override
  String get petFriendly => 'صديق للحيوانات الأليفة';

  @override
  String get nearbySchools => 'مدارس قريبة';

  @override
  String get nearbyHospitals => 'مستشفيات قريبة';

  @override
  String get nearbyShopping => 'تسوق قريب';

  @override
  String get publicTransport => 'مواصلات عامة';

  @override
  String get listingExpiry => 'انتهاء الإعلان';

  @override
  String get expiresToday => 'ينتهي اليوم';

  @override
  String listingWillExpireIn(Object time) {
    return 'سينتهي الإعلان خلال $time';
  }

  @override
  String get openInGoogleMaps => 'الفتح في خرائط جوجل';

  @override
  String get daysSuffix => 'أيام';

  @override
  String get hoursSuffix => 'ساعة';

  @override
  String get minutesSuffix => 'دقيقة';

  @override
  String get now => 'الآن';

  @override
  String get call => 'اتصال';

  @override
  String get whatsApp => 'واتساب';

  @override
  String get sqmSuffix => 'م²';

  @override
  String get propertyRenewedSuccessfully => 'تم تجديد العقار بنجاح';

  @override
  String interestedInProperty(Object title) {
    return 'أنا مهتم بهذا العقار: $title';
  }

  @override
  String get phoneNumberNotAvailable => 'رقم الهاتف غير متاح';

  @override
  String get whatsAppNotAvailable => 'واتساب غير متاح';

  @override
  String get starter => 'مبتدئ';

  @override
  String get starterDesc => 'مثالية للبدء (60 يومًا)';

  @override
  String get professional => 'محترف';

  @override
  String get professionalDesc => 'مثالية للأعمال المتنامية (60 يومًا)';

  @override
  String get enterprise => 'باقة الشركات';

  @override
  String get enterpriseDesc => 'للعمليات واسعة النطاق (60 يومًا)';

  @override
  String get elite => 'نخبة';

  @override
  String get eliteDesc => 'إمكانيات غير محدودة (60 يومًا)';

  @override
  String get premiumSlots => 'الخانات المميزة';

  @override
  String get scaleYourBusiness => 'وسع أعمالك العقارية';

  @override
  String get currentLimitLabel => 'الحد الحالي';

  @override
  String get usedSlotsLabel => 'الفتحات المستخدمة';

  @override
  String get currentActivePackages => 'الباقات النشطة حالياً';

  @override
  String get chooseNewPackage => 'اختر باقة جديدة';

  @override
  String get mostPopular => 'الأكثر رواجاً';

  @override
  String get orderTotal => 'إجمالي الطلب';

  @override
  String get billedOnce => 'يتم الدفع مرة واحدة';

  @override
  String get pleaseSelectPackage => 'يرجى اختيار باقة';

  @override
  String amountAddedToWallet(Object amount) {
    return 'تم إضافة $amount د.ل إلى محفظتك.';
  }

  @override
  String get testCards => 'بطاقات الاختبار';

  @override
  String get boosted => 'معزز';

  @override
  String get boostExpired => 'انتهى التعزيز';

  @override
  String get unlimited => 'غير محدود';

  @override
  String get unknownUser => 'مستخدم غير معروف';

  @override
  String get propertyOwner => 'صاحب العقار';

  @override
  String get listingExpired => 'انتهى وقت الإعلان';

  @override
  String get listingExpiredDesc => 'هذا العقار لم يعد مرئياً للجمهور.';

  @override
  String get renewNow => 'تجديد الآن';

  @override
  String get area => 'المنطقة';

  @override
  String get securityDeposit => 'التأمين';

  @override
  String sharePropertyText(Object city, Object title) {
    return 'شاهد هذا العقار: $title في $city!';
  }

  @override
  String shareProfileText(Object name) {
    return 'شاهد هذا الملف الشخصي على داري: $name';
  }

  @override
  String get viewProfile => 'عرض الملف الشخصي';

  @override
  String get listed => 'مدرج';

  @override
  String get messageSeller => 'مراسلة البائع';

  @override
  String get manageBoost => 'إدارة التمييز';

  @override
  String get failedToCreateConversation =>
      'فشل في إنشاء المحادثة. يرجى المحاولة مرة أخرى.';

  @override
  String failedToStartConversation(Object error) {
    return 'فشل في بدء المحادثة: $error';
  }

  @override
  String get starterPackage => 'باقة المبتدئين';

  @override
  String get professionalPackage => 'الباقة الاحترافية';

  @override
  String get enterprisePackage => 'باقة الشركات';

  @override
  String get elitePackage => 'باقة النخبة';

  @override
  String get scaleBusiness => 'طوّر نشاطك العقاري';

  @override
  String get currentLimit => 'الحد الحالي';

  @override
  String get usedSlots => 'المساحات المستخدمة';

  @override
  String expiresInDays(String days) {
    return 'ينتهي خلال $days يوم';
  }

  @override
  String get slots => 'مساحة';

  @override
  String get sixtyDays => '60 يوم';

  @override
  String get newLimit => 'الحد الجديد';

  @override
  String get packagesExpiryWarning =>
      'تنتهي الباقات بعد 60 يومًا. سيتم إلغاء نشر العقارات (وليس حذفها) عند انتهاء صلاحية الباقة حتى يتم شراء مساحات جديدة.';

  @override
  String get completePurchase => 'إتمام الشراء';

  @override
  String durationDays(String days) {
    return '$days أيام';
  }

  @override
  String get shortTermPromo => 'مثالي للترويج قصير المدى';

  @override
  String get quickPromo => 'مثالي للترويج السريع';

  @override
  String get testingWaters => 'رائع لتجربة السوق';

  @override
  String get bestValueSerious => 'أفضل قيمة للبائعين الجادين';

  @override
  String buyPackage(String duration) {
    return 'شراء $duration';
  }

  @override
  String get perDay => '/يوم';

  @override
  String get perMonth => '/شهر';

  @override
  String boostedWithTime(String time) {
    return 'مميّز (متبقي $time)';
  }

  @override
  String get hoursShort => 'س';

  @override
  String get minutesShort => 'د';

  @override
  String addedToWallet(Object amount) {
    return 'تمت إضافة $amount إلى محفظتك.';
  }

  @override
  String get payWithCard => 'الدفع بالبطاقة';

  @override
  String amountLabel(Object amount) {
    return 'المبلغ: $amount';
  }

  @override
  String get enterCardNumber => 'يرجى إدخال رقم البطاقة';

  @override
  String get cardTooShort => 'يجب أن يتكون رقم البطاقة من 13 رقمًا على الأقل';

  @override
  String get requiredField => 'مطلوب';

  @override
  String get invalidFormat => 'تنسيق غير صالح';

  @override
  String get tooShort => 'قصير جداً';

  @override
  String get enterCardholderName => 'يرجى إدخال اسم صاحب البطاقة';

  @override
  String get testCardsInfo =>
      'النجاح: 4242 4242 4242 4242\nالرفض: 4000 0000 0000 0002\nالانتهاء: 4000 0000 0000 0069';

  @override
  String get loginToContactSeller => 'يرجى تسجيل الدخول للاتصال بالبائع.';

  @override
  String get viewMoreDetails => 'عرض المزيد من التفاصيل';

  @override
  String get noPhoneNumberAvailable => 'رقم الهاتف غير متاح';

  @override
  String get whatsappMessageIntro => 'مرحباً! أنا مهتم بهذا العقار:';

  @override
  String get addedToFavorites => 'تمت الإضافة إلى المفضلة';

  @override
  String get removedFromFavorites => 'تمت الإزالة من المفضلة';

  @override
  String get cannotMakePhoneCall => 'لا يمكن إجراء مكالمة هاتفية من هذا الجهاز';

  @override
  String get share => 'مشاركة';

  @override
  String get save => 'حفظ';

  @override
  String get boostProperty => 'تمييز العقار';

  @override
  String get boostPropertyDescription => 'اختر باقة تمييز لزيادة ظهور عقارك.';

  @override
  String get viewPackages => 'عرض الباقات';

  @override
  String get airConditioning => 'تكييف هواء';

  @override
  String get currencyLYD => 'د.ل';

  @override
  String get daysShort => 'ي';

  @override
  String get whatsAppShort => 'واتساب';

  @override
  String timeAgoYears(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count سنوات',
      two: 'منذ سنتين',
      one: 'منذ سنة',
    );
    return '$_temp0';
  }

  @override
  String timeAgoMonths(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count أشهر',
      two: 'منذ شهرين',
      one: 'منذ شهر',
    );
    return '$_temp0';
  }

  @override
  String timeAgoDays(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count أيام',
      two: 'منذ يومين',
      one: 'منذ يوم',
    );
    return '$_temp0';
  }

  @override
  String timeAgoHours(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count ساعات',
      two: 'منذ ساعتين',
      one: 'منذ ساعة',
    );
    return '$_temp0';
  }

  @override
  String timeAgoMinutes(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count دقائق',
      two: 'منذ دقيقتين',
      one: 'منذ دقيقة',
    );
    return '$_temp0';
  }

  @override
  String timeAgoSeconds(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count ثوانٍ',
      two: 'منذ ثانيتين',
      one: 'الآن',
    );
    return '$_temp0';
  }

  @override
  String get welcomeToDary => 'مرحباً بك في داري';

  @override
  String get yourSmartPropertyCompanion => 'رفيقك الذكي في عالم العقارات';

  @override
  String get emailOrPhone => 'البريد الإلكتروني أو الهاتف';

  @override
  String get enterEmailOrPhone => 'أدخل بريدك الإلكتروني أو رقم هاتفك';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get orContinueWith => 'أو تابع باستخدام';

  @override
  String get google => 'جوجل';

  @override
  String get signUp => 'إنشاء حساب';

  @override
  String get signingInWithGoogle => 'جارٍ تسجيل الدخول باستخدام جوجل...';

  @override
  String get createAccount => 'إنشاء حساب';

  @override
  String get joinDaryFindDreamHome => 'انضم إلى داري واعثر على منزل أحلامك';

  @override
  String get emailAddress => 'البريد الإلكتروني';

  @override
  String get confirmYourPassword => 'أكد كلمة المرور';

  @override
  String get enterPasswordValidation => 'أدخل كلمة المرور';

  @override
  String get passwordMinLength =>
      'يجب أن تتكون كلمة المرور من 8 أحرف على الأقل';

  @override
  String get passwordNeedsCapital => 'يجب أن تحتوي على حرف كبير واحد على الأقل';

  @override
  String get passwordNeedsNumber => 'يجب أن تحتوي على رقم واحد على الأقل';

  @override
  String get passwordNeedsSymbol => 'يجب أن تحتوي على رمز واحد على الأقل';

  @override
  String get agreeToTermsPrivacy => 'أوافق على الشروط وسياسة الخصوصية';

  @override
  String get orSignUpWith => 'أو سجل باستخدام';

  @override
  String get googleAccount => 'حساب جوجل';

  @override
  String get activeListingsLabel => 'الإعلانات النشطة';

  @override
  String get upgradeAd => 'ترقية الإعلان';

  @override
  String get moreSlots => 'المزيد من الخانات';

  @override
  String get boostAd => 'تعزيز الإعلان';

  @override
  String get myFavorites => 'المفضلة';

  @override
  String get officeDashboard => 'لوحة تحكم المكتب';

  @override
  String get allCaughtUp => 'لا توجد رسائل جديدة!';

  @override
  String get localCreditCard => 'بطاقة ائتمان محلية';

  @override
  String feePercentage(Object fee) {
    return 'نسبة الرسوم $fee';
  }

  @override
  String get transactionFeePercentage => 'نسبة الرسوم';

  @override
  String get topUp => 'شحن';

  @override
  String get pleaseEnterValidAmount => 'يرجى إدخال مبلغ صحيح';

  @override
  String get daryVouchers => 'قسائم داري';

  @override
  String get enter13DigitCode => 'أدخل الرمز المكون من 13 رقماً';

  @override
  String get whereToBuyVouchers =>
      'أين يتم شراء القسائم / Where to buy vouchers?';

  @override
  String get purchaseFromStore =>
      '• يمكنك الشراء من أي محل تتوفر لديه ماكينة دفع (المظلة) أو (أنيس).';

  @override
  String get purchaseFromStoreAr =>
      '• Purchase from any store with Umbrella or Anis POS terminals.';

  @override
  String get directSupport => 'الدعم الفني / Direct Support';

  @override
  String get customerSupport => 'الدعم الفني / Customer Support';

  @override
  String get ibanCopied => 'تم نسخ رقم الحساب';

  @override
  String get copy => 'نسخ';

  @override
  String get selectChargeMethod => 'اختر طريقة الشحن';

  @override
  String get pleaseEnterValid13DigitCode =>
      'يرجى إدخال رمز صحيح مكون من 13 رقماً';

  @override
  String get pleaseLoginToRecharge => 'يرجى تسجيل الدخول لشحن محفظتك';

  @override
  String walletRechargedSuccessfully(Object balance, Object currency) {
    return 'تم شحن المحفظة بنجاح! الرصيد الجديد: $balance $currency';
  }

  @override
  String get invalidRechargeCode =>
      'رمز الشحن غير صحيح. يرجى المحاولة مرة أخرى.';

  @override
  String errorProcessingRecharge(Object error) {
    return 'خطأ في معالجة الشحن: $error';
  }

  @override
  String get couldNotLaunchWhatsApp => 'تعذر فتح واتساب';

  @override
  String get balance => 'الرصيد';

  @override
  String get transactions => 'المعاملات';

  @override
  String get recentTransactions => 'المعاملات الأخيرة';

  @override
  String get transactionRecharge => 'شحن';

  @override
  String get transactionPurchase => 'شراء';

  @override
  String transactionBoost(String name) {
    return 'تعزيز: $name';
  }

  @override
  String transactionRefund(Object reason) {
    return 'استرجاع - $reason';
  }

  @override
  String get transactionFee => 'رسوم';

  @override
  String get add => 'إضافة';

  @override
  String get search => 'بحث';

  @override
  String get filters => 'تصفية';

  @override
  String get sortByDate => 'التاريخ';

  @override
  String get sortByPrice => 'السعر';

  @override
  String get sortByPriceLowToHigh => 'السعر: من الأقل إلى الأعلى';

  @override
  String get sortByPriceHighToLow => 'السعر: من الأعلى إلى الأقل';

  @override
  String get sortByNewest => 'الأحدث أولاً';

  @override
  String get sortByOldest => 'الأقدم أولاً';

  @override
  String get minPrice => 'أقل سعر';

  @override
  String get maxPrice => 'أعلى سعر';

  @override
  String get minSize => 'أقل مساحة';

  @override
  String get maxSize => 'أعلى مساحة';

  @override
  String get featuredOnly => 'المميزة فقط';

  @override
  String get hasParking => 'يوجد موقف سيارات';

  @override
  String get hasPool => 'يوجد مسبح';

  @override
  String get hasGarden => 'يوجد حديقة';

  @override
  String get hasElevator => 'يوجد مصعد';

  @override
  String get hasFurnished => 'مفروش';

  @override
  String get hasAC => 'يوجد تكييف';

  @override
  String slotsUsed(Object used, Object total) {
    return '$used / $total خانة مستخدمة';
  }

  @override
  String get buyMoreSlots => 'شراء المزيد من الخانات';

  @override
  String get boostYourAd => 'عزز إعلانك';

  @override
  String selectListingToBoost(Object packageName) {
    return 'اختر الإعلان الذي تريد ترويجه باستخدام $packageName:';
  }

  @override
  String get noActiveListingsFound =>
      'لم يتم العثور على إعلانات نشطة. يرجى إنشاء إعلان أولاً.';

  @override
  String get allListingsBoosted =>
      'جميع إعلاناتك النشطة مفعلة حاليًا. انتظر انتهاء الترويج قبل الترويج مرة أخرى.';

  @override
  String get information => 'معلومات';

  @override
  String get settings => 'الإعدادات';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get myListings => 'عقاراتي';

  @override
  String get savedProperties => 'العقارات المحفوظة';

  @override
  String get accountSettings => 'إعدادات الحساب';

  @override
  String get language => 'اللغة';

  @override
  String get theme => 'المظهر';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get termsOfService => 'شروط الخدمة';

  @override
  String get aboutUs => 'من نحن';

  @override
  String get contactUs => 'اتصل بنا';

  @override
  String get version => 'الإصدار';

  @override
  String get boostElite => 'النخبة';

  @override
  String get boostPremium => 'مميز';

  @override
  String get boostEmerald => 'زمردي';

  @override
  String get boostPlus => 'بلس';

  @override
  String get packageEmerald => 'زمردي';

  @override
  String get packageBronze => 'Bronze';

  @override
  String get packageSilver => 'Silver';

  @override
  String get packageGold => 'Gold';

  @override
  String get packageBasic => 'أساسي';

  @override
  String get packageStandard => 'قياسي';

  @override
  String get packagePremium => 'مميز';

  @override
  String get packageEnterprise => 'باقة مؤسسة';

  @override
  String get packageMonth => 'شهر';

  @override
  String get packageMonths => 'أشهر';

  @override
  String get packageYear => 'سنة';

  @override
  String get packagePerMonth => 'شهرياً';

  @override
  String get packagePerYear => 'سنوياً';

  @override
  String packageSlots(Object count) {
    return '$count خانة';
  }

  @override
  String packageBoosts(Object count) {
    return '$count تعزيز';
  }

  @override
  String get packagePriority => 'دعم ذو أولوية';

  @override
  String get packageAnalytics => 'تحليلات متقدمة';

  @override
  String get packageVerified => 'شارة التحقق';

  @override
  String get currentPlan => 'الباقة الحالية';

  @override
  String get upgradePlan => 'ترقية الباقة';

  @override
  String get downgradePlan => 'تخفيض الخطة';

  @override
  String get freePlan => 'الخطة المجانية';

  @override
  String get searchPropertiesCities => 'ابحث عن عقارات، مدن...';

  @override
  String get rentalProperties => 'عقارات للإيجار';

  @override
  String get propertiesForSale => 'عقارات للبيع';

  @override
  String get advanced => 'متقدم';

  @override
  String get set => 'محدد';

  @override
  String get more => 'المزيد';

  @override
  String pleaseLoginToAccess(Object feature) {
    return 'يرجى تسجيل الدخول للوصول إلى $feature';
  }

  @override
  String get manageBalanceTransactions => 'إدارة رصيدك ومعاملاتك';

  @override
  String get transactionCompleted => 'مكتمل';

  @override
  String get transactionPending => 'قيد الانتظار';

  @override
  String get transactionFailed => 'فشل';

  @override
  String get verifiedSeller => 'بائع موثوق';

  @override
  String memberSince(Object date) {
    return 'عضو منذ $date';
  }

  @override
  String get increasePropertyLimit => 'زيادة حد العقارات';

  @override
  String get areYouSureLogout => 'هل أنت متأكد من تسجيل الخروج؟';

  @override
  String get hourBoost24 => 'تمييز لمدة 24 ساعة';

  @override
  String get apply => 'تطبيق';

  @override
  String get reset => 'إعادة ضبط';

  @override
  String get increasedVisibilityTitle => 'زيادة المشاهدات';

  @override
  String get increasedVisibilityDesc => 'يظهر إعلانك في أعلى نتائج البحث';

  @override
  String get featuredBadgeTitle => 'شارة مميزة';

  @override
  String get featuredBadgeDesc => 'تميّز بشارة مميزة واحتل موقعاً بارزاً';

  @override
  String get analyticsDashboardTitle => 'لوحة التحليلات';

  @override
  String get analyticsDashboardDesc =>
      'تتبع المشاهدات والنقرات ومعدلات التفاعل';

  @override
  String get premiumSupportTitle => 'دعم متميز';

  @override
  String get premiumSupportDesc => 'احصل على دعم عملاء ذو أولوية';

  @override
  String get moreFilters => 'مزيد من الفلاتر';

  @override
  String get updatePersonalInfo => 'تحديث معلوماتك الشخصية';

  @override
  String get tapToAddCover => 'اضغط لإضافة صورة غلاف';

  @override
  String get slotsValidity =>
      'العقارات التي تستخدم الخانات صالحة لمدة 60 يومًا إجمالاً';

  @override
  String get profileUpdatedSuccess => 'تم تحديث الملف الشخصي بنجاح!';

  @override
  String get profileUpdateFail =>
      'فشل تحديث الملف الشخصي. يرجى المحاولة مرة أخرى.';

  @override
  String get errorRemovingFavorite => 'خطأ في إزالة المفضل';

  @override
  String get errorLoadingFavorites => 'خطأ في تحميل المفضلات';

  @override
  String get realEstateOffice => 'مكتب عقارات';

  @override
  String get propertyLimit => 'حد العقارات';

  @override
  String get overview => 'نظرة عامة';

  @override
  String get contactClicks => 'نقرات التواصل';

  @override
  String get phoneCalls => 'مكالمات هاتفية';

  @override
  String get whatsapp => 'واتساب';

  @override
  String get walletBalance => 'رصيد المحفظة';

  @override
  String get soldRented => 'باع / أجر';

  @override
  String get buySlots => 'شراء خانات';

  @override
  String get boost => 'تمييز';

  @override
  String get viewsOverTime => 'المشاهدات مع مرور الوقت';

  @override
  String get noData => 'لا توجد بيانات';

  @override
  String get byType => 'حسب النوع';

  @override
  String get byStatus => 'حسب الحالة';

  @override
  String get engagementMetrics => 'مقاييس التفاعل';

  @override
  String get avgViewsPerProperty => 'متوسط المشاهدات لكل عقار';

  @override
  String get conversionRate => 'معدل التحويل';

  @override
  String get all => 'الكل';

  @override
  String get expired => 'منتهي';

  @override
  String get changeCover => 'تغيير الغلاف';

  @override
  String get premiumSlotsStatus => 'حالة الخانات المميزة';

  @override
  String get statTotalListings => 'إجمالي القوائم';

  @override
  String get statActiveListings => 'القوائم النشطة';

  @override
  String get statTotalProperties => 'إجمالي العقارات';

  @override
  String get statAvailableProperties => 'العقارات المتاحة';

  @override
  String get unlimitedCapacity => 'سعة غير محدودة';

  @override
  String totalSlotsCount(int count) {
    return 'إجمالي $count خانة';
  }

  @override
  String hoursLeftCount(int count) {
    return 'متبقي $count ساعة';
  }

  @override
  String get unlimitedPackage => 'الباقة غير المحدودة';

  @override
  String get scaleWithoutLimits => 'طور عملك بدون حدود';

  @override
  String moreSlotsCount(int count) {
    return '+ $count خانة إضافية';
  }

  @override
  String get upgrade => 'ترقية';

  @override
  String get editCover => 'تعديل الغلاف';

  @override
  String get whoWeAreTitle => 'من نحن';

  @override
  String get whoWeAreContent =>
      'داري هو رفيقك العقاري الرقمي الليبي الأمثل. لقد بنينا أكثر من مجرد تطبيق؛ لقد أنشأنا سوقاً سلساً حيث تصبح أحلام العقارات حقيقة. من الفلل الراقية إلى الشقق المريحة، نحن نجسّر الفجوة بين أصحاب العقارات الليبيين والباحثين عنها.';

  @override
  String get ourMissionTitle => 'مهمتنا';

  @override
  String get ourMissionContent =>
      'إحداث ثورة في سوق العقارات الليبي من خلال الشفافية والتكنولوجيا والثقة. نحن نمكن المستخدمين من الحصول على رؤى مفصلة ووسائط عالية الجودة وقنوات اتصال مباشرة.';

  @override
  String get whyDaryTitle => 'لماذا داري؟';

  @override
  String get whyDaryContent =>
      '• قوائم موثقة\n• اتصال مباشر آمن\n• تصفية متقدمة\n• تحليلات في الوقت الفعلي\n• لوحات تحكم متخصصة للمكاتب';

  @override
  String get userAgreementTitle => '1. اتفاقية المستخدم';

  @override
  String get userAgreementContent =>
      'من خلال الوصول إلى داري، فإنك توافق على تقديم معلومات صحيحة. المستخدمون مسؤولون عن جميع الأنشطة التي تتم بموجب حساباتهم.';

  @override
  String get listingAuthenticityTitle => '2. أصالة القائمة';

  @override
  String get listingAuthenticityContent =>
      'يجب أن تكون جميع العقارات حقيقية. يُحظر تماماً الإعلان الكاذب أو الأسعار المضللة أو تكرار الإعلانات وسيؤدي ذلك إلى تعليق الحساب.';

  @override
  String get communicationTitle => '3. التواصل';

  @override
  String get communicationContent =>
      'داري يسهل الاتصال ولكنه ليس مسؤولاً عن الاتفاقيات الخارجية بين المستخدمين. توخ دائماً الحذر وتحقق من تفاصيل العقار شخصياً.';

  @override
  String get paymentServicesTitle => '4. خدمات الدفع';

  @override
  String get paymentServicesContent =>
      'ميزات التمييز وشحن المحفظة نهائية. يتم التعامل مع المدفوعات عبر تكامل طرف ثالث آمن (معاملات).';

  @override
  String get getInTouch => 'تواصل معنا';

  @override
  String get reachOutHelp => 'نحن هنا لمساعدتك في أي استفسارات';

  @override
  String get emailSupport => 'الدعم عبر البريد الإلكتروني';

  @override
  String get response24h => 'الرد خلال 24 ساعة';

  @override
  String get callUs => 'اتصل بنا';

  @override
  String lineCount(int count) {
    return 'الخط $count';
  }

  @override
  String get whatsAppChat => 'دردشة واتساب';

  @override
  String supportDeskCount(int count) {
    return 'مكتب الدعم $count';
  }

  @override
  String showMoreCount(int count) {
    return 'عرض المزيد ($count إضافي)';
  }

  @override
  String get showLess => 'عرض أقل';

  @override
  String selectedCount(int count) {
    return 'تم اختيار $count';
  }

  @override
  String get selectAll => 'اختيار الكل';

  @override
  String get deselectAll => 'إلغاء اختيار الكل';

  @override
  String get deleteSelected => 'حذف المختارة';

  @override
  String get noListingsYet => 'لا توجد قوائم بعد';

  @override
  String propertiesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عقارات',
      two: 'عقاران',
      one: 'عقار واحد',
    );
    return '$_temp0';
  }

  @override
  String get listingsExpiringSoon => 'إعلانات تنتهي قريبًا!';

  @override
  String get listingsExpiryWarning =>
      'العقارات التالية على وشك الانتهاء. يرجى تجديدها للحفاظ على ظهورها للعموم.';

  @override
  String andMoreCount(int count) {
    return '...و$count أكثر';
  }

  @override
  String get later => 'لاحقًا';

  @override
  String get gotIt => 'فهمت';

  @override
  String renewAll(int count) {
    return 'تجديد الكل ($count)';
  }

  @override
  String renewedSuccessfully(int count) {
    return 'تم تجديد $count عقار بنجاح!';
  }

  @override
  String notEnoughPointsToRenew(int available, int required) {
    return 'نقاط غير كافية. لديك $available نقطة وتحتاج $required نقطة.';
  }

  @override
  String get renewingProperties => 'تجديد العقارات...';

  @override
  String get office => 'مكتب';

  @override
  String get userNotFound => 'المستخدم غير موجود';

  @override
  String get goBack => 'رجوع';

  @override
  String totalCount(int count) {
    return 'إجمالي $count';
  }

  @override
  String get deleteAccountTitle => 'حذف الحساب';

  @override
  String get deleteAccountConfirmation =>
      'هل أنت متأكد من رغبتك في حذف حسابك؟ لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get googleReauthDeletion =>
      'بما أنك قمت بتسجيل الدخول عبر جوجل، سيُطلب منك إعادة المصادقة مع جوجل لتأكيد الحذف.';

  @override
  String get enterPasswordToConfirm => 'يرجى إدخال كلمة المرور للتأكيد:';

  @override
  String get passwordHint => 'كلمة المرور';

  @override
  String get pleaseEnterPassword => 'يرجى إدخال كلمة المرور';

  @override
  String get accountDeletedSuccessfully => 'تم حذف حسابك بنجاح.';

  @override
  String get deleteAccountComingSoon => 'ميزة حذف الحساب ستتوفر قريباً!';

  @override
  String deletePropertiesCountTitle(int count) {
    return 'حذف $count عقار؟';
  }

  @override
  String deletePropertiesConfirmation(int count) {
    return 'هل أنت متأكد من رغبتك في حذف $count عقار مختار؟ لا يمكن التراجع عن هذا الإجراء وستبقى هذه الخانات مستهلكة.';
  }

  @override
  String get deleteAll => 'حذف الكل';

  @override
  String deletePropertiesSuccessCount(int successCount, int totalCount) {
    return 'تم حذف $successCount من أصل $totalCount عقار بنجاح';
  }

  @override
  String errorUpdatingProfile(Object error) {
    return 'خطأ في تحديث الملف الشخصي: $error';
  }

  @override
  String get noUserFound => 'لم يتم العثور على مستخدم';

  @override
  String get emailChangeInfo =>
      'هذا البريد الإلكتروني مرتبط بحسابك ولا يمكن تغييره.';

  @override
  String get saveChanges => 'حفظ التغييرات';

  @override
  String get customizeExperience => 'خصص تجربتك';

  @override
  String get pleaseEnterName => 'يرجى إدخال اسمك';

  @override
  String get nameTooShort => 'يجب أن يكون الاسم حرفين على الأقل';

  @override
  String get phoneTooShort => 'رقم الهاتف قصير جداً';

  @override
  String daysCount(Object count) {
    return '$count أيام';
  }

  @override
  String get allTime => 'كل الوقت';

  @override
  String get performance => 'الأداء';

  @override
  String get topPerformingProperties => 'العقارات الأعلى أداءً';

  @override
  String get noPerformanceData => 'لا تتوفر بيانات أداء';

  @override
  String get totalSpent => 'إجمالي الإنفاق';

  @override
  String get totalRecharged => 'إجمالي الشحن';

  @override
  String get spendingBreakdown => 'توزيع الإنفاق';

  @override
  String get boostPackages => 'باقات التمييز';

  @override
  String get propertySlots => 'خانات العقارات';

  @override
  String get manageWallet => 'إدارة المحفظة';

  @override
  String get activeBoosts => 'التمييزات النشطة';

  @override
  String engagementRate(Object rate) {
    return 'معدل التفاعل: $rate%';
  }

  @override
  String get calls => 'مكالمات';

  @override
  String get saves => 'حفظ';

  @override
  String get expiring => 'تنهي';

  @override
  String get comingSoon => 'قريباً';

  @override
  String get boostActive => 'التمييز نشط';

  @override
  String get noActiveBoosts => 'لا توجد تمييزات نشطة';

  @override
  String get expires => 'تنتهي في';

  @override
  String avgViews(Object count) {
    return 'متوسط $count';
  }

  @override
  String leadsPercentage(Object count) {
    return '$count% من العملاء المتوقعين';
  }

  @override
  String get available => 'متاح';

  @override
  String ratePercentage(Object rate) {
    return 'معدل $rate%';
  }

  @override
  String get transactionRechargeMoamalat => 'شحن عبر بطاقة معاملات';

  @override
  String transactionPurchaseSlots(Object count, Object name) {
    return 'شراء $name - إضافة $count خانة عقار';
  }

  @override
  String transactionTopListing(Object name) {
    return 'شراء تمييز - $name';
  }

  @override
  String get transactionBoostPlus => 'تمييز إعلان: بلس';

  @override
  String get transactionVoucherRecharge => 'شحن عبر قسيمة';

  @override
  String get transactionAdminCredit => 'رصيد يدوي من الإدارة';

  @override
  String get packageStarter => 'Starter';

  @override
  String get packageProfessional => 'Professional';

  @override
  String get packageElite => 'النخبه';

  @override
  String get packageTopListing => 'Top Listing';

  @override
  String get package1Day => '1 Day';

  @override
  String get package3Days => '3 Days';

  @override
  String get package1Week => '1 Week';

  @override
  String get package1Month => '1 Month';

  @override
  String todayAt(Object time) {
    return 'Today $time';
  }

  @override
  String yesterdayAt(Object time) {
    return 'Yesterday $time';
  }

  @override
  String daysAgo(Object count) {
    return '$count days ago';
  }

  @override
  String get referenceId => 'Reference ID';

  @override
  String get tipsFindProperty => 'Find your dream property';

  @override
  String get tipsContactSeller => 'Contact seller directly';

  @override
  String get tipsNegotiateDeal => 'Negotiate and close deal';

  @override
  String get deleteConversation => 'Delete Conversation';

  @override
  String get deleteConversationConfirmation =>
      'Are you sure you want to delete this conversation? This action cannot be undone.';

  @override
  String get conversationDeleted => 'Conversation deleted';

  @override
  String errorDeletingConversation(Object error) {
    return 'Error deleting conversation: $error';
  }

  @override
  String get online => 'Online';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get propertyNotFound => 'Property not found';

  @override
  String errorLoadingProperty(Object error) {
    return 'Error loading property: $error';
  }

  @override
  String get generalPreferences => 'General Preferences';

  @override
  String get maintenance => 'Maintenance';

  @override
  String get notificationsActive => 'Notifications Active';

  @override
  String get notificationsPaused => 'Notifications Paused';

  @override
  String get notificationsActiveDesc =>
      'You will receive updates about your listings and chats';

  @override
  String get notificationsPausedDesc =>
      'Turn on notifications to stay updated on opportunities';

  @override
  String get troubleshooting => 'Troubleshooting';

  @override
  String get test => 'Test';

  @override
  String get clear => 'Clear';

  @override
  String get lastSync => 'Last Sync:';

  @override
  String newMessageFrom(Object senderName) {
    return 'رسالة جديدة من $senderName';
  }

  @override
  String aboutProperty(Object propertyTitle) {
    return 'عن $propertyTitle';
  }

  @override
  String get property => 'عقار';

  @override
  String get loading => 'جار التحميل...';

  @override
  String get pleaseLoginToPurchase => 'يرجى تسجيل الدخول لشراء الحزم';

  @override
  String get noActiveListingsToBoost =>
      'لم يتم العثور على إعلانات نشطة. يرجى إنشاء إعلان أولاً.';

  @override
  String get chooseListingToBoost => 'اختر الإعلان للترويج';

  @override
  String get boostListing => 'ترويج الإعلان';

  @override
  String weeksAgo(Object count) {
    return 'منذ $count أسابيع';
  }

  @override
  String monthsAgo(Object count) {
    return 'منذ $count أشهر';
  }

  @override
  String boostSuccessMessage(
      Object balance, Object listingTitle, Object packageName) {
    return 'تم تفعيل الترويج لإعلان $listingTitle باستخدام $packageName!\nالرصيد المتبقي: $balance دل';
  }

  @override
  String get bulkBoostActivated => 'تم تفعيل الترويج المتعدد!';

  @override
  String bulkBoostSuccessMessage(
      Object balance, Object count, Object packageName) {
    return 'تم تفعيل الترويج لعدد $count من إعلاناتك باستخدام $packageName!\nالرصيد المتبقي: $balance دل';
  }

  @override
  String get awesome => 'رائع!';

  @override
  String get insufficientBalanceAction => 'شحن الرصيد';

  @override
  String get oneWeekAgo => 'منذ أسبوع';

  @override
  String get oneMonthAgo => 'منذ شهر';

  @override
  String get voucherPurchaseInstruction1 =>
      '• Purchase from any store with Umbrella or Anis POS terminals.';

  @override
  String get voucherPurchaseInstruction2 =>
      '• يمكنك الشراء من أي محل تتوفر لديه ماكينة دفع (المظلة) أو (أنيس).';

  @override
  String get securePayment => 'دفع آمن';

  @override
  String get invalidVoucherCode =>
      'رمز قسيمة غير صالح. يرجى التحقق والمحاولة مرة أخرى.';

  @override
  String get voucherAlreadyRedeemed => 'تم استخدام هذه القسيمة مسبقًا.';

  @override
  String voucherRechargeSuccess(Object balance, Object currency) {
    return 'تم شحن المحفظة بنجاح! الرصيد الجديد: $balance $currency';
  }

  @override
  String get processingVoucher => 'جاري معالجة القسيمة...';

  @override
  String get done => 'تم';

  @override
  String get rechargeSuccessful => 'تم الشحن بنجاح';

  @override
  String get analyticsAssistant => 'مساعد التحليلات';

  @override
  String get aiPoweredInsights => 'رؤى الأداء المدعومة بالذكاء الاصطناعي';

  @override
  String get lowVisibility => 'رؤية منخفضة';

  @override
  String get greatEngagement => 'تفاعل رائع!';

  @override
  String get goodContactConversion => 'تحويل تواصل جيد';

  @override
  String get quickActions => 'إجراءات سريعة';

  @override
  String get boostProperties => 'تمييز العقارات';

  @override
  String get rechargeWallet => 'تعبئة المحفظة';

  @override
  String get propertySaved => 'عقار محفوظ';

  @override
  String get suggestions => 'المقترحات:';

  @override
  String propertiesSavedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عقارات محفوظة',
      two: 'عقاران محفوظان',
      one: 'عقار واحد محفوظ',
    );
    return '$_temp0';
  }

  @override
  String get noFavoritesYet => 'لا توجد مفضلات بعد';

  @override
  String get startAddingToFavorites => 'ابدأ في إضافة عقارات إلى مفضلتك';

  @override
  String get idLabel => 'المعرف';

  @override
  String get boostedStatusBadge => 'مميّز';

  @override
  String get helpSupport => 'المساعدة والدعم';

  @override
  String get onboardingTitle1 => 'ابحث عن منزل أحلامك';

  @override
  String get onboardingDesc1 =>
      'استكشف آلاف العقارات المميزة في أفضل المواقع في جميع أنحاء ليبيا.';

  @override
  String get onboardingTitle2 => 'بحث ذكي وفلاتر';

  @override
  String get onboardingDesc2 =>
      'استخدم محرك البحث المتقدم لدينا للعثور على ما تحتاجه بالضبط ببضع نقرات فقط.';

  @override
  String get onboardingTitle3 => 'اتصال آمن ومباشر';

  @override
  String get onboardingDesc3 =>
      'تواصل مباشرة مع البائعين والوكلاء من خلال نظام المراسلة الآمن الخاص بنا.';

  @override
  String get skip => 'تخطي';

  @override
  String get start => 'ابدأ';

  @override
  String get next => 'التالي';

  @override
  String get pageNotFound => 'الصفحة غير موجودة';

  @override
  String get goHome => 'الذهاب للرئيسية';

  @override
  String get loadingProperty => 'جاري تحميل العقار...';

  @override
  String get error => 'خطأ';

  @override
  String get splashTagline => 'منزل أحلامك يبدأ من هنا...';

  @override
  String get noViewsTitle => 'لم يتم اكتشاف مشاهدات';

  @override
  String get noViewsMessage =>
      'لم تتلق عقاراتك أي مشاهدات. قد يكون هذا بسبب:\n• العقارات غير منشورة\n• صور منخفضة الجودة أو مفقودة\n• عناوين غير واضحة أو غير جذابة\n• قد تكون العقارات مخفية أو غير نشطة';

  @override
  String get checkPublished => 'تحقق مما إذا كانت جميع العقارات منشورة';

  @override
  String get addHighQualityPhotos => 'أضف صور عالية الجودة لجميع العقارات';

  @override
  String get writeClearTitles => 'اكتب عناوين واضحة ووصفية';

  @override
  String get considerBoosting => 'فكر في تعزيز عقاراتك لزيادة الرؤية';

  @override
  String get lowVisibilityTitle => 'انخفاض في الرؤية';

  @override
  String lowVisibilityMessage(String average) {
    return 'تحصل عقاراتك على مشاهدات قليلة جدًا (بمتوسط $average لكل إعلان).\nهذا يشير إلى أن قوائمك بحاجة إلى تحسين أفضل.';
  }

  @override
  String get improvePhotos => 'تحسين جودة صور العقارات';

  @override
  String get detailedDescriptions => 'اكتب وصفًا أكثر تفصيلاً وجاذبية';

  @override
  String get addMorePhotos => 'أضف المزيد من الصور (على الأقل 5-10 لكل عقار)';

  @override
  String get verifyPricing => 'تأكد من أن تسعيرك تنافسي';

  @override
  String get lowEngagementTitle => 'معدل تفاعل منخفض';

  @override
  String lowEngagementMessage(String rate) {
    return 'معدل تفاعلك هو $rate%، وهو أقل من المتوسط.\nهذا يعني أن الناس يشاهدون عقاراتك لكنهم لا يتخذون إجراء.';
  }

  @override
  String get compellingDescriptions => 'أضف وصفًا أكثر إقناعًا للعقار';

  @override
  String get includeAmenities => 'قم بتضمين جميع وسائل الراحة والميزات';

  @override
  String get verifyContactInfo => 'تحقق من صحة معلومات الاتصال';

  @override
  String get adjustPricing => 'فكر في تعديل الأسعار لتكون أكثر تنافسية';

  @override
  String get addLocationDetails =>
      'أضف تفاصيل موقع العقار (الحي، المرافق القريبة)';

  @override
  String get veryLowContactTitle => 'معدل اتصال منخفض جدًا';

  @override
  String veryLowContactMessage(String rate) {
    return 'فقط $rate% من المشاهدين يتصلون بك.\nهذا يشير إلى أن العقارات قد تكون باهظة الثمن أو تفتقر إلى معلومات مهمة.';
  }

  @override
  String get reviewPricing => 'مراجعة وتعديل الأسعار حسب أسعار السوق';

  @override
  String get completeInfo => 'أضف معلومات كاملة عن العقار';

  @override
  String get highlightPoints => 'سلط الضوء على نقاط البيع الفريدة';

  @override
  String get visiblePhoneNumber => 'تأكد من أن رقم هاتف الاتصال مرئي';

  @override
  String get respondQuickly => 'رد بسرعة على الاستفسارات عند ورودها';

  @override
  String get noListingsTitle => 'لا توجد قوائم حتى الآن';

  @override
  String get noListingsMessage =>
      'ليس لديك أي قوائم نشطة. ابدأ بإضافة عقارك الأول!';

  @override
  String get addFirstProperty => 'انقر على \"إضافة عقار\" لإنشاء قائمتك الأولى';

  @override
  String get fillDetails => 'املأ جميع تفاصيل العقار بالكامل';

  @override
  String get publishVisible => 'انشر عقارك لجعله مرئيًا';

  @override
  String get increaseExposureTitle => 'زيادة تعرضك';

  @override
  String get increaseExposureMessage =>
      'امتلاك قائمة واحدة فقط يحد من رؤيتك. فكر في إضافة المزيد من العقارات.';

  @override
  String get addMoreProperties => 'أضف المزيد من العقارات لزيادة محفظتك';

  @override
  String get eachPropertyVisibility => 'كل عقار يزيد من رؤيتك العامة';

  @override
  String get diversify => 'نوع أنواع العقارات والمواقع';

  @override
  String get greatEngagementTitle => 'تفاعل رائع!';

  @override
  String greatEngagementMessage(String rate) {
    return 'معدل تفاعلك البالغ $rate% ممتاز!\nواصل العمل الجيد من خلال الحفاظ على جودة القوائم.';
  }

  @override
  String get maintainQuality => 'استمر في الحفاظ على قوائم عالية الجودة';

  @override
  String get keepUpdated => 'حافظ على تحديث معلومات العقار';

  @override
  String get addRegularly => 'أضف عقارات جديدة بانتظام';

  @override
  String get goodContactTitle => 'تحويل اتصال جيد';

  @override
  String goodContactMessage(String rate) {
    return 'معدل الاتصال الخاص بك البالغ $rate% يظهر تحويلاً جيدًا.\nتأكد من الرد بسرعة على جميع الاستفسارات.';
  }

  @override
  String get respond24h => 'الرد على الاستفسارات في غضون 24 ساعة';

  @override
  String get keepContactUpdated => 'حافظ على تحديث معلومات الاتصال';

  @override
  String get beProfessional => 'كن محترفًا ومساعدًا في التواصل';

  @override
  String get doingGreatTitle => 'أنت تقوم بعمل رائع!';

  @override
  String get doingGreatMessage =>
      'عقاراتك تؤدي بشكل جيد. لم يتم اكتشاف مشاكل رئيسية.';

  @override
  String get monitorMetrics => 'استمر في مراقبة مقاييسك';

  @override
  String get refreshListings => 'تحديث القوائم بشكل دوري لإبقائها في القمة';

  @override
  String get keepDescriptionsFresh => 'حافظ على الوصف جديداً ومفصلاً';

  @override
  String get monitorWeekly => 'راقب التحليلات أسبوعياً';

  @override
  String get boostPeakTimes => 'فكر في تعزيز العقارات خلال أوقات الذروة';

  @override
  String get gatherFeedback => 'استقبل ورد على ملاحظات المستخدمين';

  @override
  String get verifyPhoneNumber => 'تأكيد رقم الهاتف';

  @override
  String get otpSentTo => 'لقد أرسلنا رمز تأكيد مكون من 6 أرقام إلى';

  @override
  String get verify => 'تأكيد';

  @override
  String get resendCode => 'إعادة إرسال الرمز';

  @override
  String get unpublishAll => 'إلغاء نشر الكل';

  @override
  String get publishAll => 'نشر الكل';

  @override
  String unpublishPropertiesTitle(int count) {
    return 'إلغاء نشر $count عقار؟';
  }

  @override
  String get unpublishConfirmMessage =>
      'هل أنت متأكد من رغبتك في إلغاء نشر العقارات المختارة؟ ستختفي من البحث العام.';

  @override
  String publishPropertiesTitle(int count) {
    return 'نشر $count عقار؟';
  }

  @override
  String get publishReuseSlotsMessage =>
      'ستعيد هذه العقارات استخدام خاناتك الحالية. لن يتم استهلاك خانات جديدة. استمرار؟';

  @override
  String publishUseSomeSlotsMessage(int count) {
    return 'سيستخدم هذا $count من خاناتك المتاحة. الباقي يعيد استخدام الخانات الحالية. استمرار؟';
  }

  @override
  String get slotLimitReached => 'تم الوصول إلى حد الخانات';

  @override
  String notEnoughSlotsMessage(int needed, int available) {
    return 'ليس لديك خانات كافية لنشر هذه العقارات. تحتاج إلى $needed خانات جديدة ولكن لديك فقط $available متاحة.';
  }

  @override
  String get mockPropertySuccess => 'تم إنشاء عقار تجريبي بنجاح!';

  @override
  String get propertyLimitReachedAdd =>
      'لقد وصلت إلى حد العقارات المسموح به. يرجى شراء المزيد من الخانات لإضافة العقارات.';

  @override
  String get propertyLimitReachedGeneral =>
      'لقد وصلت إلى حد العقارات المسموح به. يرجى شراء المزيد من الخانات.';

  @override
  String get purchaseSuccessfulLabel => 'تمت عملية الشراء بنجاح!';

  @override
  String addedSlotsNewLimit(int slots, int limit) {
    return 'تمت إضافة $slots خانة عقار.\nالحد الجديد: $limit عقار';
  }

  @override
  String get moreCredits => 'شراء المزيد من النقاط';

  @override
  String get buyMoreCredits => 'شراء المزيد من النقاط';

  @override
  String packageCredits(int count) {
    return '$count نقطة';
  }

  @override
  String get buyCredits => 'شراء نقاط';

  @override
  String get buyNow => 'اشتري الآن';

  @override
  String get purchaseSuccess => 'تمت عملية الشراء بنجاح!';

  @override
  String get totalBalance => 'إجمالي النقاط';

  @override
  String get creditsLabel => 'نقطة';

  @override
  String get postingCreditFooter => 'كل إدراج عقاري يستهلك نقطة نشر واحدة.';

  @override
  String get postingCreditsTitle => 'نقاط النشر';

  @override
  String get oneTimePurchase => 'شراء لمرة واحدة';

  @override
  String get persistentCredits => 'نقاط دائمة (لا تنتهي بنهاية الشهر)';

  @override
  String publishUseSomeCreditsMessage(int count) {
    return 'سيستخدم هذا $count من نقاطك المتاحة. استمرار؟';
  }

  @override
  String get renewPropertyConfirm => 'تجديد العقار؟';

  @override
  String get renewPropertyDescription =>
      'سيتم خصم نقطة واحدة من نقاطك وتمديد الإدراج لمدة 60 يومًا.';

  @override
  String get great => 'رائع!';

  @override
  String get noCreditsMessage =>
      'لا توجد نقاط نشر متبقية. يرجى شراء باقة نقاط لإدراج عقارك.';

  @override
  String purchaseSuccessSubtitle(int credits, int remaining) {
    return 'لقد حصلت على $credits نقطة نشر.\nرصيد النقاط المتبقي: $remaining نقطة';
  }

  @override
  String featurePostingCredits(int count) {
    return '$count نقطة نشر';
  }

  @override
  String get featurePersistentCredits => 'النقاط لا تنتهي أبداً';

  @override
  String get featurePersistentCreditsLong =>
      'النقاط لا تنتهي أبداً (لا خسارة شهرية)';

  @override
  String get featureBasicVisibility => 'ظهور أساسي في البحث';

  @override
  String get featureStandardVisibility => 'ظهور قياسي في البحث';

  @override
  String get featureEnhancedVisibility => 'ظهور محسّن في البحث';

  @override
  String get featureMaximumVisibility => 'أقصى ظهور في البحث';

  @override
  String get featureEmailSupport => 'دعم عبر البريد الإلكتروني';

  @override
  String get featurePrioritySupport => 'دعم ذو أولوية';

  @override
  String get featureDedicatedManager => 'مدير حساب مخصص';

  @override
  String get standardPackage => 'الباقة القياسية';

  @override
  String get businessPackage => 'باقة الأعمال';

  @override
  String get packagePlus => 'بلس';

  @override
  String get buyPoints => 'شراء نقاط';

  @override
  String get boostApplied => 'Boost Applied!';

  @override
  String boostSuccessSubtitle(String packageName, int days) {
    return 'Your listing has been boosted with $packageName for $days days.';
  }

  @override
  String get prioritySearch => 'Priority Search';
}
