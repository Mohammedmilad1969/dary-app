// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get noInternetConnection => 'No Internet Connection';

  @override
  String get pleaseCheckConnection => 'Please check your network settings';

  @override
  String get propertyLegalNote =>
      'Please verify all property paperwork. Dary is not responsible for any legal discrepancies or issues.';

  @override
  String get propertyLegalNoteAr =>
      'يرجى التحقق من جميع أوراق العقار. داري ليست مسؤولة عن أي خلافات أو مشاكل قانونية.';

  @override
  String get paymentSuccessful => 'Payment Successful!';

  @override
  String get paymentFailed =>
      'Payment failed. Please check your card details and try again.';

  @override
  String get changePhoneNumber => 'Change Phone Number';

  @override
  String get processing => 'Processing...';

  @override
  String get payNow => 'Pay Now';

  @override
  String get cardDetails => 'Card Details';

  @override
  String get cardNumber => 'Card Number';

  @override
  String get expiryDate => 'Expiry Date';

  @override
  String get cvv => 'CVV';

  @override
  String get cardholderName => 'Cardholder Name';

  @override
  String get errorOccurred => 'An error occurred. Please try again.';

  @override
  String get appTitle => 'Dary Properties';

  @override
  String get home => 'Home';

  @override
  String get addProperty => 'Add Property';

  @override
  String get wallet => 'Wallet';

  @override
  String get profile => 'Profile';

  @override
  String get welcomeMessage => 'Welcome to Dary!';

  @override
  String get subtitleMessage => 'Your minimal Flutter app with Material 3';

  @override
  String get navigationHint => 'Use the bottom navigation to explore features';

  @override
  String get currentBalance => 'Current Balance';

  @override
  String get recharge => 'Top up';

  @override
  String get transactionHistory => 'Transaction History';

  @override
  String get export => 'Export';

  @override
  String get myProfile => 'My Profile';

  @override
  String get manageAccountSettings => 'Manage your account settings';

  @override
  String get activeListings => 'Active Listings';

  @override
  String get viewAll => 'View All';

  @override
  String get accountManagement => 'Account Management';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get upgradeToPremium => 'Upgrade to Premium';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get upgradeToPremiumTitle => 'Buy Points';

  @override
  String get boostYourListings => '10x More Clicks';

  @override
  String get getMoreVisibility =>
      'Purchase posting points to list your properties';

  @override
  String get limitedTimeOffer => '✨ Limited Time Offer';

  @override
  String get chooseYourPackage => 'Choose Your Points Package';

  @override
  String get selectPerfectDuration => 'Points are permanent and never expire';

  @override
  String get topListing => 'Top Listing';

  @override
  String get oneDay => '1 Day';

  @override
  String get oneWeek => '1 Week';

  @override
  String get oneMonth => '1 Month';

  @override
  String get popular => 'POPULAR';

  @override
  String get perfectForQuickPromotion => 'Perfect for quick promotion';

  @override
  String get greatForTestingWaters => 'Great for testing the waters';

  @override
  String get bestValueForSeriousSellers => 'Best value for serious sellers';

  @override
  String get priorityPlacement => 'Priority placement in search results';

  @override
  String get featuredBadge => 'Featured Badge';

  @override
  String get increasedVisibility => 'Priority Search';

  @override
  String get dayBoost => '24-hour boost';

  @override
  String get weekBoost => '7-day boost';

  @override
  String get monthBoost => '30-day boost';

  @override
  String get analyticsDashboard => 'Analytics dashboard';

  @override
  String get premiumSupport => 'Priority support';

  @override
  String get multipleListingPromotion => 'Multiple listing promotion';

  @override
  String get customListingDesign => 'Custom listing design';

  @override
  String get buyOneDay => 'Buy 1 Day';

  @override
  String get buyOneWeek => 'Buy 1 Week';

  @override
  String get buyOneMonth => 'Buy 1 Month';

  @override
  String get whyChooseTopListing => 'Why Boost your Listing?';

  @override
  String get increasedVisibilityDescription =>
      'Your listing appears at the top of search results';

  @override
  String get featuredBadgeDescription =>
      'Stand out with a premium featured badge';

  @override
  String get analyticsDashboardDescription =>
      'Track views, clicks, and engagement metrics';

  @override
  String get premiumSupportDescription => 'Get priority customer support';

  @override
  String successfullyPurchased(String packageName) {
    return 'Successfully purchased $packageName!';
  }

  @override
  String get viewDetails => 'View Details';

  @override
  String get purchaseFailed => 'Purchase failed. Please try again.';

  @override
  String errorProcessingPurchase(String error) {
    return 'Error processing purchase: $error';
  }

  @override
  String get addPropertyTitle => 'Add Property';

  @override
  String get propertyTitle => 'Property';

  @override
  String get enterPropertyTitle => 'Enter property title';

  @override
  String get description => 'Description';

  @override
  String get describeYourProperty => 'Describe your property';

  @override
  String get price => 'Price';

  @override
  String get enterPrice => 'Enter price';

  @override
  String get size => 'Size (sqm)';

  @override
  String get enterSize => 'Enter size in square meters';

  @override
  String get features => 'Features';

  @override
  String get balcony => 'Balcony';

  @override
  String get propertyHasBalcony => 'Property has a balcony';

  @override
  String get garden => 'Garden';

  @override
  String get propertyHasGarden => 'Property has a garden';

  @override
  String get parking => 'Parking';

  @override
  String get propertyHasParking => 'Property has parking';

  @override
  String get images => 'Images';

  @override
  String get uploadImages => 'Upload Images (up to 10)';

  @override
  String imagesSelected(int count) {
    return '$count images selected';
  }

  @override
  String get selectedImages => 'Selected Images:';

  @override
  String get addPropertyButton => 'Add Property';

  @override
  String get addingProperty => 'Adding Property...';

  @override
  String get propertyAddedSuccessfully => 'Property added successfully!';

  @override
  String get languageToggle => 'Language';

  @override
  String get noTransactionsYet => 'No transactions yet';

  @override
  String get exportTransactions => 'Export transactions';

  @override
  String get searchProperties => 'Search properties...';

  @override
  String get featured => 'Cover';

  @override
  String get verified => 'Verified';

  @override
  String get priceRange => 'Price Range';

  @override
  String get clearFilters => 'Clear Filters';

  @override
  String get advancedFilters => 'Advanced';

  @override
  String get propertyType => 'Property Type';

  @override
  String get propertyStatus => 'Property Status';

  @override
  String get applyFilters => 'Apply Filters';

  @override
  String get forSale => 'For Sale';

  @override
  String get forRent => 'For Rent';

  @override
  String get sold => 'Sold';

  @override
  String get rented => 'Rented';

  @override
  String get apartment => 'Apartment';

  @override
  String get house => 'House';

  @override
  String get villa => 'Villa';

  @override
  String get townhouse => 'Townhouse';

  @override
  String get studio => 'Studio';

  @override
  String get penthouse => 'Penthouse';

  @override
  String get commercial => 'Commercial';

  @override
  String get land => 'Land';

  @override
  String get noPropertiesFound => 'No properties found';

  @override
  String get tryAdjustingFilters => 'Try adjusting your filters';

  @override
  String get basicInformation => 'Basic Information';

  @override
  String get locationInformation => 'Location Information';

  @override
  String get propertyDetails => 'Property Details';

  @override
  String get contactInformation => 'Contact Information';

  @override
  String get pleaseEnterTitle => 'Please enter a title';

  @override
  String get pleaseEnterDescription => 'Please enter a description';

  @override
  String get pleaseEnterPrice => 'Please enter a price';

  @override
  String get pleaseEnterValidPrice => 'Please enter a valid price';

  @override
  String get pleaseEnterSize => 'Please enter the size';

  @override
  String get pleaseEnterValidSize => 'Please enter a valid size';

  @override
  String get maxImages => 'You can upload a maximum of 10 images.';

  @override
  String get failedToPickImages => 'Failed to pick images:';

  @override
  String get selectImages => 'Select Images';

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get fullName => 'Full Name';

  @override
  String get phoneNumber => 'PhoneNumber';

  @override
  String get loginTitle => 'Welcome Back';

  @override
  String get loginSubtitle => 'Sign in to your account';

  @override
  String get registerTitle => 'Create Account';

  @override
  String get registerSubtitle => 'Join Dary Properties today';

  @override
  String get loginButton => 'Sign In';

  @override
  String get registerButton => 'Create Account';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get signInHere => 'Sign in here';

  @override
  String get signUpHere => 'Sign up here';

  @override
  String get enterEmail => 'Enter your email';

  @override
  String get enterPassword => 'Enter your password';

  @override
  String get enterConfirmPassword => 'Confirm your password';

  @override
  String get enterFullName => 'Enter your full name';

  @override
  String get enterPhoneNumber => 'Enter your phone number';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get nameRequired => 'Full name is required';

  @override
  String get phoneRequired => 'Phone number is required';

  @override
  String get confirmPasswordRequired => 'Please confirm your password';

  @override
  String get invalidEmail => 'Invalid email';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get loginSuccess => 'Login successful! Welcome back';

  @override
  String get registerSuccess => 'Account created successfully! Welcome to Dary';

  @override
  String get loginFailed => 'Login failed. Please check your credentials';

  @override
  String get registerFailed => 'Registration failed. Please try again';

  @override
  String get firebaseWrongPassword => 'Incorrect password. Please try again.';

  @override
  String get firebaseUserNotFound =>
      'No account found with this email or phone number.';

  @override
  String get firebaseEmailAlreadyInUse =>
      'This email is already registered. Please sign in.';

  @override
  String get firebasePhoneAlreadyInUse =>
      'This phone number is already registered.';

  @override
  String get firebaseWeakPassword =>
      'Password is too weak. Please choose a stronger password.';

  @override
  String get firebaseTooManyRequests =>
      'Too many attempts. Please wait a moment and try again.';

  @override
  String get firebaseNetworkError =>
      'Network error. Please check your internet connection.';

  @override
  String get firebaseInvalidCredential =>
      'Invalid credentials. Please check your email and password.';

  @override
  String get firebaseUserDisabled =>
      'This account has been disabled. Please contact support.';

  @override
  String get firebaseOperationNotAllowed =>
      'This operation is not allowed. Please contact support.';

  @override
  String get firebaseInvalidEmail => 'Invalid email format.';

  @override
  String get firebaseAccountExistsWithDifferentCredential =>
      'An account already exists with the same email but different credentials.';

  @override
  String get firebaseRequiresRecentLogin =>
      'This operation is sensitive and requires recent authentication. Please sign in again.';

  @override
  String get firebaseGenericError => 'An error occurred. Please try again.';

  @override
  String get loggingIn => 'Signing in...';

  @override
  String get registering => 'Creating account...';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get forgotPasswordTitle => 'Forgot Password?';

  @override
  String get forgotPasswordDescription =>
      'Don\'t worry! Enter your email below to receive password reset instructions.';

  @override
  String get sendInstructions => 'Send Instructions';

  @override
  String get rememberPassword => 'Remember password?';

  @override
  String get backToLogin => 'Back to Login';

  @override
  String get enterValidEmail => 'Please enter a valid email';

  @override
  String get resetInstructionsSent =>
      'Password reset instructions sent to your email.';

  @override
  String get checkEmail => 'Check your email';

  @override
  String get pleaseVerifyEmail => 'Verify Your Email';

  @override
  String get verificationEmailSentDesc =>
      'A verification link was sent to your email. Please verify it to access all features.';

  @override
  String get resend => 'Resend';

  @override
  String get verificationEmailSent => 'Verification email sent!';

  @override
  String get verifiedAccount => 'Verified Account';

  @override
  String get unverifiedAccount => 'Unverified Account';

  @override
  String get rememberMe => 'Remember Me';

  @override
  String get tooManyAttempts => 'Too many attempts. Please try again later.';

  @override
  String get emailNotVerifiedTitle => 'Email Not Verified';

  @override
  String get emailNotVerifiedMessage =>
      'Please verify your email to unlock all features. Check your inbox for the verification link.';

  @override
  String get becomeRealEstateOffice => 'Become a Real Estate Office';

  @override
  String realEstateOfficeRequestMessage(String name, String id) {
    return 'Hello, I would like to upgrade my account to a real estate office.\nName: $name\nAccount ID: $id';
  }

  @override
  String get propertyExpiringSoonTitle => 'Property Expiring Soon!';

  @override
  String propertyExpiringSoonMessage(String title, int days) {
    return 'Your listing \"$title\" will expire in $days days. Renew it now to keep it active!';
  }

  @override
  String get termsAndConditions => 'Terms & Conditions';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get logoutSuccess => 'Logged out successfully';

  @override
  String get messages => 'Messages';

  @override
  String get chat => 'Chat';

  @override
  String get typeMessage => 'Type a message...';

  @override
  String get noMessagesYet => 'No messages yet';

  @override
  String get startConversation => 'Start the conversation!';

  @override
  String get noConversationsYet => 'No conversations yet';

  @override
  String get startConversationWithSeller =>
      'Start a conversation with a seller to discuss properties!';

  @override
  String get browseProperties => 'Browse Properties';

  @override
  String get conversationNotFound => 'Conversation not found';

  @override
  String get errorLoadingMessages => 'Error loading messages';

  @override
  String get errorSendingMessage => 'Error sending message';

  @override
  String get errorLoadingConversations => 'Error loading conversations';

  @override
  String get pleaseLoginFirst => 'Please login first';

  @override
  String get cannotContactYourself => 'You cannot contact yourself';

  @override
  String get errorCreatingConversation => 'Error creating conversation';

  @override
  String get errorContactingSeller => 'Error contacting seller';

  @override
  String get contactSeller => 'Contact Seller';

  @override
  String get creatingConversation => 'Creating conversation...';

  @override
  String get agentInfo => 'Agent Information';

  @override
  String get realEstateAgent => 'Real Estate Agent';

  @override
  String get views => 'Views';

  @override
  String get listedOn => 'Listed on';

  @override
  String get bedrooms => 'Bedrooms';

  @override
  String get bathrooms => 'Bathrooms';

  @override
  String get sqm => 'sqm';

  @override
  String get pool => 'Pool';

  @override
  String get gym => 'Gym';

  @override
  String get security => 'Security';

  @override
  String get elevator => 'Elevator';

  @override
  String get ac => 'AC';

  @override
  String get furnished => 'Furnished';

  @override
  String get newConversationStarted => 'New conversation started';

  @override
  String get about => 'About';

  @override
  String get view => 'View';

  @override
  String get testNotification => 'Test Notification';

  @override
  String get verification => 'Verification';

  @override
  String get verificationInfo => 'Verification Information';

  @override
  String get verificationDescription =>
      'To become a verified seller, please upload your ID card and business license. This helps us verify your identity and build trust with potential buyers.';

  @override
  String get uploadIdCard => 'Upload ID Card';

  @override
  String get uploadBusinessLicense => 'Upload Business License';

  @override
  String get tapToUploadIdCard => 'Tap to upload ID card';

  @override
  String get tapToUploadLicense => 'Tap to upload business license';

  @override
  String get submitVerification => 'Submit for Verification';

  @override
  String get verificationSuccess => 'You are now a verified seller!';

  @override
  String get verificationSuccessMessage =>
      'Your documents have been verified. You can now enjoy all the benefits of being a verified seller.';

  @override
  String get continueText => 'Continue';

  @override
  String get alreadyVerified => 'You are already verified!';

  @override
  String get alreadyVerifiedMessage =>
      'Your account has been verified. You can enjoy all the benefits of being a verified seller.';

  @override
  String get backToProfile => 'Back to Profile';

  @override
  String get getVerified => 'Get Verified';

  @override
  String get privacyNotice =>
      'Your documents are encrypted and stored securely. We only use them for verification purposes.';

  @override
  String get pleaseUploadBothDocuments => 'Please upload both documents';

  @override
  String get verificationError => 'Verification failed. Please try again.';

  @override
  String errorPickingImage(Object error) {
    return 'Error picking image: $error';
  }

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Gallery';

  @override
  String get analytics => 'Analytics';

  @override
  String get viewAnalytics => 'View Analytics';

  @override
  String get performanceOverview => 'Performance Overview';

  @override
  String get topPerformingListing => 'Top Performing Listing';

  @override
  String get averageEngagement => 'Average Engagement';

  @override
  String get totalViews => 'Total Views';

  @override
  String get totalContacts => 'Total Contacts';

  @override
  String get dailyViews => 'Daily Views (Last 7 Days)';

  @override
  String get propertyTypePerformance => 'Property Type Performance';

  @override
  String get detailedMetrics => 'Detailed Metrics';

  @override
  String get totalListings => 'Total Listings';

  @override
  String get averageViewsPerListing => 'Average Views per Listing';

  @override
  String get contactConversionRate => 'Contact Conversion Rate';

  @override
  String get errorLoadingAnalytics => 'Error loading analytics data';

  @override
  String get adminDashboard => 'Admin Dashboard';

  @override
  String get users => 'Users';

  @override
  String get properties => 'Properties';

  @override
  String get payments => 'Payments';

  @override
  String get totalUsers => 'Total Users';

  @override
  String get totalProperties => 'Total Properties';

  @override
  String get totalPayments => 'Total Payments';

  @override
  String get totalRevenue => 'Total Revenue';

  @override
  String get name => 'Name';

  @override
  String get phone => 'Phone';

  @override
  String get active => 'Active';

  @override
  String get listings => 'Listings';

  @override
  String get actions => 'Actions';

  @override
  String get title => 'Title';

  @override
  String get owner => 'Owner';

  @override
  String get city => 'City';

  @override
  String get status => 'Status';

  @override
  String get user => 'User';

  @override
  String get type => 'Type';

  @override
  String get amount => 'Amount';

  @override
  String get date => 'Date';

  @override
  String get errorLoadingAdminData => 'Error loading admin data';

  @override
  String get premiumListings => 'Premium Listings';

  @override
  String get sortBy => 'Sort by';

  @override
  String get purchaseDate => 'Purchase Date';

  @override
  String get packagePrice => 'Package Price';

  @override
  String get package => 'Package';

  @override
  String get expiry => 'Expiry';

  @override
  String get boostedProperties => 'Boosted Properties';

  @override
  String get featuredProperties => 'Featured Properties';

  @override
  String get allProperties => 'All Properties';

  @override
  String get rent => 'Rent';

  @override
  String get savedSearches => 'Saved Searches';

  @override
  String get noSavedSearches => 'No Saved Searches';

  @override
  String get noSavedSearchesDescription =>
      'Save your property searches to get notified when new matching properties are added';

  @override
  String get startSearching => 'Start Searching';

  @override
  String get runSearch => 'Run Search';

  @override
  String get checkNewMatches => 'Check New';

  @override
  String get saveSearch => 'Save Search';

  @override
  String get enterSearchName => 'Enter a name for this search:';

  @override
  String get searchSavedSuccessfully => 'Search saved successfully!';

  @override
  String get failedToSaveSearch => 'Failed to save search';

  @override
  String get pleaseLoginToSaveSearches => 'Please login to save searches';

  @override
  String get searchDeletedSuccessfully => 'Search deleted successfully';

  @override
  String get failedToDeleteSearch => 'Failed to delete search';

  @override
  String get deleteSavedSearch => 'Delete Saved Search';

  @override
  String areYouSureDeleteSearch(Object searchName) {
    return 'Are you sure you want to delete \"$searchName\"?';
  }

  @override
  String foundNewProperties(Object count, Object searchName) {
    return 'Found $count new properties matching \"$searchName\"';
  }

  @override
  String get delete => 'Delete';

  @override
  String get sell => 'Sell';

  @override
  String get notificationSettings => 'Notification Settings';

  @override
  String get notificationStatus => 'Notification Status';

  @override
  String get notificationsEnabled => 'Notifications are enabled';

  @override
  String get notificationsDisabled => 'Notifications are disabled';

  @override
  String get enableNotifications => 'Enable Notifications';

  @override
  String get enableNotificationsSubtitle =>
      'Receive notifications for new properties and messages';

  @override
  String get firebaseCloudMessaging => 'Firebase Cloud Messaging';

  @override
  String get fcmEnabled => 'FCM is enabled and working';

  @override
  String get fcmDisabled => 'FCM is disabled or not available';

  @override
  String get fcmToken => 'FCM Token';

  @override
  String get fcmTokenDescription =>
      'This token is used to send push notifications to your device';

  @override
  String get fcmTokenNotAvailable => 'FCM token is not available';

  @override
  String get notificationTypes => 'Notification Types';

  @override
  String get newListingsNotifications => 'New Listings';

  @override
  String get newListingsNotificationsSubtitle =>
      'Get notified when new properties match your saved searches';

  @override
  String get chatNotifications => 'Chat Messages';

  @override
  String get chatNotificationsSubtitle =>
      'Get notified when you receive new messages';

  @override
  String get priceDropNotifications => 'Price Drops';

  @override
  String get priceDropNotificationsSubtitle =>
      'Get notified when prices drop on properties you\'re watching';

  @override
  String get testNotifications => 'Test Notifications';

  @override
  String get testNotificationsDescription =>
      'Test your notification setup by sending a test notification';

  @override
  String get sendTestNotification => 'Send Test';

  @override
  String get testNotificationSent => 'Test notification sent!';

  @override
  String get clearAllNotifications => 'Clear All';

  @override
  String get markAllAsRead => 'Mark all as read';

  @override
  String get noNotificationsYet => 'No notifications yet';

  @override
  String get notificationsDiscoverySubtitle =>
      'We\'ll notify you when something important happens';

  @override
  String get notificationsCleared => 'All notifications cleared';

  @override
  String get lastCheckTime => 'Last Check Time';

  @override
  String get lastCheckTimeDescription =>
      'The last time the app checked for new matching properties';

  @override
  String get editDetails => 'Edit Details';

  @override
  String get unpublish => 'Unpublish';

  @override
  String get publishNow => 'Publish Now';

  @override
  String get publish => 'Publish';

  @override
  String get renewListing => 'Renew Listing';

  @override
  String get deleteForever => 'Delete Forever';

  @override
  String viewsCount(int count) {
    return '$count views';
  }

  @override
  String get publishedStatus => 'Published';

  @override
  String get unpublishedStatus => 'Unpublished';

  @override
  String get boostedStatus => 'BOOSTED';

  @override
  String get expiredStatus => 'Expired';

  @override
  String daysLeftCount(int count) {
    return '$count days left';
  }

  @override
  String get edit => 'Edit';

  @override
  String get renew => 'Renew';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get unpublishSuccess => 'Property unpublished successfully';

  @override
  String get unpublishFailed => 'Failed to unpublish property';

  @override
  String get publishSuccess => 'Property published successfully';

  @override
  String get publishFailed => 'Failed to publish property';

  @override
  String get renewSuccess => 'Property renewed successfully';

  @override
  String get renewFailed => 'Failed to renew property';

  @override
  String get deleteSuccess => 'Property deleted successfully';

  @override
  String get deleteFailed => 'Failed to delete property';

  @override
  String get deletePropertyTitle => 'Delete Property';

  @override
  String get deletePropertyConfirm =>
      'Are you sure you want to delete this property? This action cannot be undone.';

  @override
  String get neighborhood => 'Neighborhood';

  @override
  String get kitchens => 'Kitchens';

  @override
  String get sizeRange => 'Size Range';

  @override
  String get priceRangeLyd => 'Price Range (LYD)';

  @override
  String bedroomsCount(int count) {
    return '$count Bedrooms';
  }

  @override
  String bathroomsCount(int count) {
    return '$count Bathrooms';
  }

  @override
  String get typeApartment => 'Apartment';

  @override
  String get typeHouse => 'House';

  @override
  String get typeVilla => 'Villa';

  @override
  String get typeVacationHome => 'Vacation Home';

  @override
  String get typeTownhouse => 'Townhouse';

  @override
  String get typeStudio => 'Studio';

  @override
  String get typePenthouse => 'Penthouse';

  @override
  String get typeCommercial => 'Commercial';

  @override
  String get typeLand => 'Land';

  @override
  String get statusForSale => 'For Sale';

  @override
  String get statusForRent => 'For Rent';

  @override
  String get statusSold => 'Sold';

  @override
  String get statusRented => 'Rented';

  @override
  String get condNewConstruction => 'New Construction';

  @override
  String get condExcellent => 'Excellent';

  @override
  String get condGood => 'Good';

  @override
  String get condFair => 'Fair';

  @override
  String get condNeedsRenovation => 'Needs Renovation';

  @override
  String get whatTypeProperty => 'What type of property?';

  @override
  String get selectCategoryDescription =>
      'Select the category that best describes your property';

  @override
  String get listingType => 'Listing Type';

  @override
  String get tellUsAboutProperty => 'Tell us about your property';

  @override
  String get addCompellingDescription =>
      'Add a compelling title and description';

  @override
  String get titleHint => 'e.g., Beautiful 3BR Apartment in City Center';

  @override
  String get descriptionHint =>
      'Describe your property features, neighborhood, and what makes it special...';

  @override
  String get proTip => 'Pro Tip';

  @override
  String get detailedDescriptionTip =>
      'Properties with detailed descriptions get 40% more views!';

  @override
  String get whereIsProperty => 'Where is your property?';

  @override
  String get helpBuyersFind => 'Help buyers find your property easily';

  @override
  String get streetAddress => 'Street Address';

  @override
  String get addressHint => 'e.g., 123 Main Street';

  @override
  String get roomsSizePricing => 'Rooms, size, and pricing';

  @override
  String get salePriceLyd => 'Sale Price (LYD)';

  @override
  String get monthlyRent => 'Monthly Rent';

  @override
  String get dailyRent => 'Daily Rent';

  @override
  String get enterMonthlyRent => 'Enter monthly rent';

  @override
  String get enterDailyRent => 'Enter daily rent';

  @override
  String get beds => 'Beds';

  @override
  String get baths => 'Baths';

  @override
  String get landSizeM2 => 'Land Size (m²)';

  @override
  String get buildingSizeM2 => 'Building Size (m²)';

  @override
  String get enterSizeM2 => 'Enter size in square meters';

  @override
  String get floors => 'Floors';

  @override
  String get yearBuilt => 'Year Built';

  @override
  String get discardChangesTitle => 'Discard Changes?';

  @override
  String get discardChangesMessage =>
      'Are you sure you want to leave? Your progress will be lost.';

  @override
  String get discard => 'Discard';

  @override
  String get continueButton => 'Continue';

  @override
  String stepProgress(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get editProperty => 'Edit Property';

  @override
  String get saving => 'Saving...';

  @override
  String get updateProperty => 'Update Property';

  @override
  String get publishProperty => 'Publish Property';

  @override
  String get back => 'Back';

  @override
  String get photosAdded => 'photos added';

  @override
  String get photoTipsDescription =>
      '• Use good lighting\n• Show all rooms\n• Include exterior photos';

  @override
  String get indoorFeatures => 'Indoor Features';

  @override
  String get outdoorFeatures => 'Outdoor Features';

  @override
  String get buildingFeatures => 'Building Features';

  @override
  String get nearby => 'Nearby';

  @override
  String minImagesError(int count) {
    return 'Please upload at least 4 photos. You have uploaded $count photo(s).';
  }

  @override
  String uploadingImages(int count) {
    return 'Uploading $count images...';
  }

  @override
  String insufficientBalance(
      String amount, Object balance, Object currency, Object price) {
    return 'Insufficient balance. You need $price $currency but only have $balance $currency';
  }

  @override
  String get propertyUpdatedSuccessfully => 'Property updated successfully!';

  @override
  String get propertyPublishedSuccessfully =>
      'Property published successfully!';

  @override
  String get boostActivated => 'Boost Activated!';

  @override
  String get selectPackage => 'Select Package';

  @override
  String get chooseBoostPackage => 'Choose your Boost Package';

  @override
  String get plusBoost => 'Plus Boost';

  @override
  String get emeraldBoost => 'Emerald Boost';

  @override
  String get eliteBoost => 'Elite Boost';

  @override
  String get premiumBoost => 'Premium Boost';

  @override
  String get durationOneDay => '1 Day';

  @override
  String get durationThreeDays => '3 Days';

  @override
  String get durationSevenDays => '7 Days';

  @override
  String get durationThirtyDays => '30 Days';

  @override
  String get rooms => 'Rooms';

  @override
  String get location => 'Location';

  @override
  String get select => 'Select';

  @override
  String get packageSelected => 'package selected for your property';

  @override
  String get changePackage => 'Change Package';

  @override
  String get upgradeBoost => 'Upgrade Your Ad';

  @override
  String get boostDescription =>
      'Get maximum visibility and reach more buyers instantly';

  @override
  String get eliteBranding => 'Elite branding';

  @override
  String get dedicatedSupport => 'Dedicated support';

  @override
  String get packageCleared => 'Package selection cleared';

  @override
  String get loginRequired => 'Login Required';

  @override
  String get pleaseLoginToAddProperty =>
      'Please login to add properties to the platform';

  @override
  String get backToHome => 'Back to Home';

  @override
  String get close => 'Close';

  @override
  String packageSelectedWithPrice(Object package, Object price) {
    return 'Package Selected: $package ($price LYD)';
  }

  @override
  String get clearSelection => 'Clear Selection';

  @override
  String selectedWithPrice(Object package, Object price) {
    return 'Selected: $package ($price LYD)';
  }

  @override
  String get basicInfo => 'Basic Info';

  @override
  String get details => 'Details';

  @override
  String get amenities => 'Amenities';

  @override
  String get photos => 'Photos';

  @override
  String get showItOff => 'Show it off';

  @override
  String get condition => 'Condition';

  @override
  String get selectCity => 'Select City';

  @override
  String get selectCityFirst => 'Select City First';

  @override
  String get selectNeighborhood => 'Select Neighborhood';

  @override
  String get pleaseSelectCity => 'Please select a city';

  @override
  String get pleaseSelectNeighborhood => 'Please select a neighborhood';

  @override
  String get pleaseEnterAddress => 'Please enter an address';

  @override
  String get pleaseEnterMonthlyRent => 'Please enter monthly rent';

  @override
  String get pleaseEnterDailyRent => 'Please enter daily rent';

  @override
  String get pleaseEnterLandSize => 'Please enter land size';

  @override
  String get pleaseEnterBuildingSize => 'Please enter building size';

  @override
  String get pleaseAddPhoto => 'Please add at least one photo';

  @override
  String get heating => 'Heating';

  @override
  String get waterWell => 'Water Well';

  @override
  String get petFriendly => 'Pet Friendly';

  @override
  String get nearbySchools => 'Nearby Schools';

  @override
  String get nearbyHospitals => 'Nearby Hospitals';

  @override
  String get nearbyShopping => 'Nearby Shopping';

  @override
  String get publicTransport => 'Public Transport';

  @override
  String get listingExpiry => 'Listing Expiry';

  @override
  String get expiresToday => 'Expires Today';

  @override
  String listingWillExpireIn(Object time) {
    return 'Listing will expire in $time';
  }

  @override
  String get openInGoogleMaps => 'Open in Google Maps';

  @override
  String get daysSuffix => 'days';

  @override
  String get hoursSuffix => 'hours';

  @override
  String get minutesSuffix => 'minutes';

  @override
  String get now => 'Now';

  @override
  String get call => 'Call';

  @override
  String get whatsApp => 'WhatsApp';

  @override
  String get sqmSuffix => 'm²';

  @override
  String get propertyRenewedSuccessfully => 'Property renewed successfully';

  @override
  String interestedInProperty(Object title) {
    return 'I\'m interested in this property: $title';
  }

  @override
  String get phoneNumberNotAvailable => 'Phone number not available';

  @override
  String get whatsAppNotAvailable => 'WhatsApp not available';

  @override
  String get starter => 'Starter';

  @override
  String get starterDesc => 'Perfect for getting started (60 Days)';

  @override
  String get professional => 'Professional';

  @override
  String get professionalDesc => 'Ideal for growing businesses (60 Days)';

  @override
  String get enterprise => 'Enterprise';

  @override
  String get enterpriseDesc => 'For large-scale operations (60 Days)';

  @override
  String get elite => 'Elite';

  @override
  String get eliteDesc => 'Unlimited possibilities (60 Days)';

  @override
  String get premiumSlots => 'Premium Slots';

  @override
  String get scaleYourBusiness => 'Scale your real estate business';

  @override
  String get currentLimitLabel => 'CURRENT LIMIT';

  @override
  String get usedSlotsLabel => 'USED SLOTS';

  @override
  String get currentActivePackages => 'Current Active Packages';

  @override
  String get chooseNewPackage => 'Choose New Package';

  @override
  String get mostPopular => 'MOST POPULAR';

  @override
  String get orderTotal => 'Order Total';

  @override
  String get billedOnce => 'Billed once';

  @override
  String get pleaseSelectPackage => 'Please select a package';

  @override
  String amountAddedToWallet(Object amount) {
    return '$amount LYD has been added to your wallet.';
  }

  @override
  String get testCards => 'Test Cards';

  @override
  String get boosted => 'Boosted';

  @override
  String get boostExpired => 'Boost expired';

  @override
  String get unlimited => 'Unlimited';

  @override
  String get unknownUser => 'Unknown User';

  @override
  String get propertyOwner => 'Property Owner';

  @override
  String get listingExpired => 'Listing Expired';

  @override
  String get listingExpiredDesc =>
      'This property is no longer visible to the public.';

  @override
  String get renewNow => 'Renew now';

  @override
  String get area => 'Area';

  @override
  String get securityDeposit => 'Security Deposit';

  @override
  String sharePropertyText(Object city, Object title) {
    return 'Check out this property: $title in $city!';
  }

  @override
  String shareProfileText(Object name) {
    return 'Check out this profile on Dary: $name';
  }

  @override
  String get viewProfile => 'View profile';

  @override
  String get listed => 'Listed';

  @override
  String get messageSeller => 'Message Seller';

  @override
  String get manageBoost => 'Manage Boost';

  @override
  String get failedToCreateConversation =>
      'Failed to create conversation. Please try again.';

  @override
  String failedToStartConversation(Object error) {
    return 'Failed to start conversation: $error';
  }

  @override
  String get starterPackage => 'Starter';

  @override
  String get professionalPackage => 'Professional';

  @override
  String get enterprisePackage => 'Enterprise';

  @override
  String get elitePackage => 'Elite';

  @override
  String get scaleBusiness => 'Scale your real estate business';

  @override
  String get currentLimit => 'CURRENT LIMIT';

  @override
  String get usedSlots => 'USED SLOTS';

  @override
  String expiresInDays(String days) {
    return 'Expires in $days days';
  }

  @override
  String get slots => 'slots';

  @override
  String get sixtyDays => '60 Days';

  @override
  String get newLimit => 'New Limit';

  @override
  String get packagesExpiryWarning =>
      'Packages expire after 60 days. Properties will be unpublished (but not deleted) when the package expires until new slots are purchased.';

  @override
  String get completePurchase => 'Complete Purchase';

  @override
  String durationDays(String days) {
    return '$days Days';
  }

  @override
  String get shortTermPromo => 'Perfect for short-term promotion';

  @override
  String get quickPromo => 'Perfect for quick promotion';

  @override
  String get testingWaters => 'Great for testing the market';

  @override
  String get bestValueSerious => 'Best value for serious sellers';

  @override
  String buyPackage(String duration) {
    return 'Buy $duration';
  }

  @override
  String get perDay => '/day';

  @override
  String get perMonth => '/month';

  @override
  String boostedWithTime(String time) {
    return 'Boosted ($time left)';
  }

  @override
  String get hoursShort => 'h';

  @override
  String get minutesShort => 'm';

  @override
  String addedToWallet(Object amount) {
    return '$amount has been added to your wallet.';
  }

  @override
  String get payWithCard => 'Pay with Card';

  @override
  String amountLabel(Object amount) {
    return 'Amount: $amount';
  }

  @override
  String get enterCardNumber => 'Please enter card number';

  @override
  String get cardTooShort => 'Card number must be at least 13 digits';

  @override
  String get requiredField => 'Required';

  @override
  String get invalidFormat => 'Invalid format';

  @override
  String get tooShort => 'Too short';

  @override
  String get enterCardholderName => 'Please enter cardholder name';

  @override
  String get testCardsInfo =>
      'Success: 4242 4242 4242 4242\nDecline: 4000 0000 0000 0002\nExpired: 4000 0000 0000 0069';

  @override
  String get loginToContactSeller => 'Please log in to contact the seller.';

  @override
  String get viewMoreDetails => 'View more details';

  @override
  String get noPhoneNumberAvailable => 'No phone number available';

  @override
  String get whatsappMessageIntro => 'Hello! I am interested in this property:';

  @override
  String get addedToFavorites => 'Added to favorites';

  @override
  String get removedFromFavorites => 'Removed from favorites';

  @override
  String get cannotMakePhoneCall => 'Cannot make phone call from this device';

  @override
  String get share => 'Share';

  @override
  String get save => 'Save';

  @override
  String get boostProperty => 'Boost Property';

  @override
  String get boostPropertyDescription =>
      'Choose a premium package to boost your property visibility.';

  @override
  String get viewPackages => 'View Packages';

  @override
  String get airConditioning => 'Air Conditioning';

  @override
  String get currencyLYD => 'LYD';

  @override
  String get daysShort => 'd';

  @override
  String get whatsAppShort => 'WA';

  @override
  String timeAgoYears(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count years ago',
      one: '1 year ago',
    );
    return '$_temp0';
  }

  @override
  String timeAgoMonths(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months ago',
      one: '1 month ago',
    );
    return '$_temp0';
  }

  @override
  String timeAgoDays(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String timeAgoHours(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String timeAgoMinutes(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String timeAgoSeconds(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seconds ago',
      one: 'Just now',
    );
    return '$_temp0';
  }

  @override
  String get welcomeToDary => 'Welcome to Dary';

  @override
  String get yourSmartPropertyCompanion => 'Your smart property companion';

  @override
  String get emailOrPhone => 'Email or Phone';

  @override
  String get enterEmailOrPhone => 'Enter your email or phone';

  @override
  String get signIn => 'Sign In';

  @override
  String get orContinueWith => 'Or continue with';

  @override
  String get google => 'Google';

  @override
  String get signUp => 'Sign Up';

  @override
  String get signingInWithGoogle => 'Signing in with Google...';

  @override
  String get createAccount => 'Create Account';

  @override
  String get joinDaryFindDreamHome => 'Join Dary and find your dream home';

  @override
  String get emailAddress => 'Email Address';

  @override
  String get confirmYourPassword => 'Confirm your password';

  @override
  String get enterPasswordValidation => 'Enter password';

  @override
  String get passwordMinLength => 'Password must be at least 8 characters';

  @override
  String get passwordNeedsCapital => 'Must contain at least one capital letter';

  @override
  String get passwordNeedsNumber => 'Must contain at least one number';

  @override
  String get passwordNeedsSymbol => 'Must contain at least one symbol';

  @override
  String get agreeToTermsPrivacy => 'I agree to the Terms & Privacy Policy';

  @override
  String get orSignUpWith => 'Or sign up with';

  @override
  String get googleAccount => 'Google Account';

  @override
  String get activeListingsLabel => 'Active Listings';

  @override
  String get upgradeAd => 'Upgrade Ad';

  @override
  String get moreSlots => 'More Slots';

  @override
  String get boostAd => 'Boost Ad';

  @override
  String get myFavorites => 'My Favorites';

  @override
  String get officeDashboard => 'Office Dashboard';

  @override
  String get allCaughtUp => 'All caught up!';

  @override
  String get localCreditCard => 'Local credit card';

  @override
  String feePercentage(Object fee) {
    return 'Fee percentage $fee';
  }

  @override
  String get transactionFeePercentage => 'Fee Percentage';

  @override
  String get topUp => 'Top up';

  @override
  String get pleaseEnterValidAmount => 'Please enter a valid amount';

  @override
  String get daryVouchers => 'DARY Vouchers';

  @override
  String get enter13DigitCode => 'Enter 13-digit code';

  @override
  String get whereToBuyVouchers =>
      'Where to buy vouchers / أين يتم شراء القسائم ؟';

  @override
  String get purchaseFromStore =>
      '• Purchase from any store with Umbrella or Anis POS terminals.';

  @override
  String get purchaseFromStoreAr =>
      '• يمكنك الشراء من أي محل تتوفر لديه ماكينة دفع (المظلة) أو (أنيس).';

  @override
  String get directSupport => 'Direct Support / الدعم الفني';

  @override
  String get customerSupport => 'Customer Support / الدعم الفني';

  @override
  String get ibanCopied => 'IBAN copied to clipboard';

  @override
  String get copy => 'Copy';

  @override
  String get selectChargeMethod => 'Select charge method';

  @override
  String get pleaseEnterValid13DigitCode =>
      'Please enter a valid 13-digit code';

  @override
  String get pleaseLoginToRecharge => 'Please login to recharge your wallet';

  @override
  String walletRechargedSuccessfully(Object balance, Object currency) {
    return 'Wallet recharged successfully! New balance: $balance $currency';
  }

  @override
  String get invalidRechargeCode => 'Invalid recharge code. Please try again.';

  @override
  String errorProcessingRecharge(Object error) {
    return 'Error processing recharge: $error';
  }

  @override
  String get couldNotLaunchWhatsApp => 'Could not launch WhatsApp';

  @override
  String get balance => 'Balance';

  @override
  String get transactions => 'Transactions';

  @override
  String get recentTransactions => 'Recent Transactions';

  @override
  String get transactionRecharge => 'Recharge';

  @override
  String get transactionPurchase => 'Purchase';

  @override
  String transactionBoost(String name) {
    return 'Boost: $name';
  }

  @override
  String transactionRefund(Object reason) {
    return 'Refund - $reason';
  }

  @override
  String get transactionFee => 'Fee';

  @override
  String get add => 'Add';

  @override
  String get search => 'Search';

  @override
  String get filters => 'Filters';

  @override
  String get sortByDate => 'Date';

  @override
  String get sortByPrice => 'Price';

  @override
  String get sortByPriceLowToHigh => 'Price: Low to High';

  @override
  String get sortByPriceHighToLow => 'Price: High to Low';

  @override
  String get sortByNewest => 'Newest First';

  @override
  String get sortByOldest => 'Oldest First';

  @override
  String get minPrice => 'Min Price';

  @override
  String get maxPrice => 'Max Price';

  @override
  String get minSize => 'Min Size';

  @override
  String get maxSize => 'Max Size';

  @override
  String get featuredOnly => 'Featured Only';

  @override
  String get hasParking => 'Has Parking';

  @override
  String get hasPool => 'Has Pool';

  @override
  String get hasGarden => 'Has Garden';

  @override
  String get hasElevator => 'Has Elevator';

  @override
  String get hasFurnished => 'Furnished';

  @override
  String get hasAC => 'Has A/C';

  @override
  String slotsUsed(Object used, Object total) {
    return '$used / $total slots used';
  }

  @override
  String get buyMoreSlots => 'Buy More Slots';

  @override
  String get boostYourAd => 'Boost Your Ad';

  @override
  String selectListingToBoost(Object packageName) {
    return 'Select which listing you want to boost with $packageName:';
  }

  @override
  String get noActiveListingsFound =>
      'No active listings found. Please create a listing first.';

  @override
  String get allListingsBoosted =>
      'All your active listings are currently boosted. Wait for boost to expire before boosting again.';

  @override
  String get information => 'Information';

  @override
  String get settings => 'Settings';

  @override
  String get logout => 'Logout';

  @override
  String get myListings => 'My Listings';

  @override
  String get savedProperties => 'Saved Properties';

  @override
  String get accountSettings => 'Account Settings';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get notifications => 'Notifications';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get aboutUs => 'About Us';

  @override
  String get contactUs => 'Contact Us';

  @override
  String get version => 'Version';

  @override
  String get boostElite => 'ELITE';

  @override
  String get boostPremium => 'PREMIUM';

  @override
  String get boostEmerald => 'Emerald';

  @override
  String get boostPlus => 'Plus';

  @override
  String get packageEmerald => 'Emerald';

  @override
  String get packageBronze => 'Bronze';

  @override
  String get packageSilver => 'Silver';

  @override
  String get packageGold => 'Gold';

  @override
  String get packageBasic => 'Basic';

  @override
  String get packageStandard => 'Standard';

  @override
  String get packagePremium => 'Premium';

  @override
  String get packageEnterprise => 'Enterprise';

  @override
  String get packageMonth => 'Month';

  @override
  String get packageMonths => 'Months';

  @override
  String get packageYear => 'Year';

  @override
  String get packagePerMonth => 'per month';

  @override
  String get packagePerYear => 'per year';

  @override
  String packageSlots(Object count) {
    return '$count Slots';
  }

  @override
  String packageBoosts(Object count) {
    return '$count Boosts';
  }

  @override
  String get packagePriority => 'Priority Support';

  @override
  String get packageAnalytics => 'Advanced Analytics';

  @override
  String get packageVerified => 'Verified Badge';

  @override
  String get currentPlan => 'Current Plan';

  @override
  String get upgradePlan => 'Upgrade Plan';

  @override
  String get downgradePlan => 'Downgrade Plan';

  @override
  String get freePlan => 'Free Plan';

  @override
  String get searchPropertiesCities => 'Search properties, cities...';

  @override
  String get rentalProperties => 'Rental properties';

  @override
  String get propertiesForSale => 'Properties for sale';

  @override
  String get advanced => 'Advanced';

  @override
  String get set => 'Set';

  @override
  String get more => 'More';

  @override
  String pleaseLoginToAccess(Object feature) {
    return 'Please login to access $feature';
  }

  @override
  String get manageBalanceTransactions =>
      'Manage your balance and transactions';

  @override
  String get transactionCompleted => 'Completed';

  @override
  String get transactionPending => 'Pending';

  @override
  String get transactionFailed => 'Failed';

  @override
  String get verifiedSeller => 'Verified Seller';

  @override
  String memberSince(Object date) {
    return 'Member since $date';
  }

  @override
  String get increasePropertyLimit => 'Increase Property Limit';

  @override
  String get areYouSureLogout => 'Are you sure you want to logout?';

  @override
  String get hourBoost24 => '24-hour boost';

  @override
  String get apply => 'Apply';

  @override
  String get reset => 'Reset';

  @override
  String get increasedVisibilityTitle => 'Increased Visibility';

  @override
  String get increasedVisibilityDesc =>
      'Your listing appears at the top of search results';

  @override
  String get featuredBadgeTitle => 'Featured Badge';

  @override
  String get featuredBadgeDesc => 'Stand out with a premium featured badge';

  @override
  String get analyticsDashboardTitle => 'Analytics Dashboard';

  @override
  String get analyticsDashboardDesc =>
      'Track views, clicks, and engagement metrics';

  @override
  String get premiumSupportTitle => 'Premium Support';

  @override
  String get premiumSupportDesc => 'Get priority customer support';

  @override
  String get moreFilters => 'More Filters';

  @override
  String get updatePersonalInfo => 'Update your personal information';

  @override
  String get tapToAddCover => 'Tap to add cover photo';

  @override
  String get slotsValidity =>
      'Properties that use slots are valid for 60 days total';

  @override
  String get profileUpdatedSuccess => 'Profile updated successfully!';

  @override
  String get profileUpdateFail => 'Failed to update profile. Please try again.';

  @override
  String get errorRemovingFavorite => 'Error removing favorite';

  @override
  String get errorLoadingFavorites => 'Error loading favorites';

  @override
  String get realEstateOffice => 'Real Estate Office';

  @override
  String get propertyLimit => 'Property Limit';

  @override
  String get overview => 'Overview';

  @override
  String get contactClicks => 'Contact Clicks';

  @override
  String get phoneCalls => 'Phone Calls';

  @override
  String get whatsapp => 'WhatsApp';

  @override
  String get walletBalance => 'Wallet Balance';

  @override
  String get soldRented => 'Sold/Rented';

  @override
  String get buySlots => 'Buy Slots';

  @override
  String get boost => 'Boost';

  @override
  String get viewsOverTime => 'Views Over Time';

  @override
  String get noData => 'No data';

  @override
  String get byType => 'By Type';

  @override
  String get byStatus => 'By Status';

  @override
  String get engagementMetrics => 'Engagement Metrics';

  @override
  String get avgViewsPerProperty => 'Average Views per Property';

  @override
  String get conversionRate => 'Conversion Rate';

  @override
  String get all => 'All';

  @override
  String get expired => 'Expired';

  @override
  String get changeCover => 'Change Cover';

  @override
  String get premiumSlotsStatus => 'Premium Slots Status';

  @override
  String get statTotalListings => 'Total Listings';

  @override
  String get statActiveListings => 'Active Listings';

  @override
  String get statTotalProperties => 'Total Properties';

  @override
  String get statAvailableProperties => 'Available Properties';

  @override
  String get unlimitedCapacity => 'Unlimited Capacity';

  @override
  String totalSlotsCount(int count) {
    return '$count Total Slots';
  }

  @override
  String hoursLeftCount(int count) {
    return '$count hours left';
  }

  @override
  String get unlimitedPackage => 'Unlimited Package';

  @override
  String get scaleWithoutLimits => 'Scale your business without limits';

  @override
  String moreSlotsCount(int count) {
    return '+ $count more slots';
  }

  @override
  String get upgrade => 'Upgrade';

  @override
  String get editCover => 'Edit Cover';

  @override
  String get whoWeAreTitle => 'Who We Are';

  @override
  String get whoWeAreContent =>
      'Dary is the ultimate Libyan digital real estate companion. We’ve built more than just an app; we’ve created a seamless marketplace where property dreams become reality. From high-end villas to cozy apartments, we bridge the gap between Libyan homeowners and seekers.';

  @override
  String get ourMissionTitle => 'Our Mission';

  @override
  String get ourMissionContent =>
      'To revolutionize the Libyan real estate market through transparency, technology, and trust. We empower users with detailed insights, high-quality media, and direct communication channels.';

  @override
  String get whyDaryTitle => 'Why Dary?';

  @override
  String get whyDaryContent =>
      '• Verified Listings\n• Secure Direct Contact\n• Advanced Filtering\n• Real-time Analytics\n• Specialized Office Dashboards';

  @override
  String get userAgreementTitle => '1. User Agreement';

  @override
  String get userAgreementContent =>
      'By accessing Dary, you agree to provide authentic information. Users are responsible for all activity under their accounts.';

  @override
  String get listingAuthenticityTitle => '2. Listing Authenticity';

  @override
  String get listingAuthenticityContent =>
      'All properties must be genuine. False advertising, misleading prices, or duplicate listings are strictly prohibited and will lead to account suspension.';

  @override
  String get communicationTitle => '3. Communication';

  @override
  String get communicationContent =>
      'Dary facilitates connection but is not responsible for external agreements between users. Always exercise caution and verify property details in person.';

  @override
  String get paymentServicesTitle => '4. Payment Services';

  @override
  String get paymentServicesContent =>
      'Premium features and wallet recharges are final. Payments are handled via secure third-party integration (Ma\'amalat).';

  @override
  String get getInTouch => 'Get in Touch';

  @override
  String get reachOutHelp => 'We\'re here to help you with any questions';

  @override
  String get emailSupport => 'Email Support';

  @override
  String get response24h => 'Response within 24 hours';

  @override
  String get callUs => 'Call Us';

  @override
  String lineCount(int count) {
    return 'Line $count';
  }

  @override
  String get whatsAppChat => 'WhatsApp Chat';

  @override
  String supportDeskCount(int count) {
    return 'Support Desk $count';
  }

  @override
  String showMoreCount(int count) {
    return 'Show More ($count more)';
  }

  @override
  String get showLess => 'Show Less';

  @override
  String selectedCount(int count) {
    return '$count Selected';
  }

  @override
  String get selectAll => 'Select All';

  @override
  String get deselectAll => 'Deselect All';

  @override
  String get deleteSelected => 'Delete Selected';

  @override
  String get noListingsYet => 'No listings yet';

  @override
  String propertiesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count properties',
      one: '1 property',
    );
    return '$_temp0';
  }

  @override
  String get listingsExpiringSoon => 'Listings Expiring Soon!';

  @override
  String get listingsExpiryWarning =>
      'The following properties are about to expire. Please renew them to keep them visible to the public.';

  @override
  String andMoreCount(int count) {
    return '...and $count more';
  }

  @override
  String get later => 'Later';

  @override
  String get gotIt => 'Got it';

  @override
  String renewAll(int count) {
    return 'Renew All ($count)';
  }

  @override
  String renewedSuccessfully(int count) {
    return '$count properties renewed successfully!';
  }

  @override
  String notEnoughPointsToRenew(int available, int required) {
    return 'Not enough points. You have $available pts but need $required pts.';
  }

  @override
  String get renewingProperties => 'Renewing properties...';

  @override
  String get office => 'OFFICE';

  @override
  String get userNotFound => 'User not found';

  @override
  String get goBack => 'Go Back';

  @override
  String totalCount(int count) {
    return '$count total';
  }

  @override
  String get deleteAccountTitle => 'Delete Account';

  @override
  String get deleteAccountConfirmation =>
      'Are you sure you want to delete your account? This action cannot be undone.';

  @override
  String get googleReauthDeletion =>
      'Since you signed in with Google, you will be asked to re-authenticate with Google to confirm deletion.';

  @override
  String get enterPasswordToConfirm => 'Please enter your password to confirm:';

  @override
  String get passwordHint => 'Password';

  @override
  String get pleaseEnterPassword => 'Please enter your password';

  @override
  String get accountDeletedSuccessfully =>
      'Your account has been successfully deleted.';

  @override
  String get deleteAccountComingSoon =>
      'Delete account functionality coming soon!';

  @override
  String deletePropertiesCountTitle(int count) {
    return 'Delete $count Properties?';
  }

  @override
  String deletePropertiesConfirmation(int count) {
    return 'Are you sure you want to delete the selected $count properties? This action cannot be undone and these slots will remain used (burned).';
  }

  @override
  String get deleteAll => 'Delete All';

  @override
  String deletePropertiesSuccessCount(int successCount, int totalCount) {
    return 'Successfully deleted $successCount out of $totalCount properties';
  }

  @override
  String errorUpdatingProfile(Object error) {
    return 'Error updating profile: $error';
  }

  @override
  String get noUserFound => 'No user found';

  @override
  String get emailChangeInfo =>
      'This email is linked to your account and cannot be changed.';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get customizeExperience => 'Customize your experience';

  @override
  String get pleaseEnterName => 'Please enter your name';

  @override
  String get nameTooShort => 'Name must be at least 2 characters';

  @override
  String get phoneTooShort => 'Phone number is too short';

  @override
  String daysCount(Object count) {
    return '$count Days';
  }

  @override
  String get allTime => 'All Time';

  @override
  String get performance => 'Performance';

  @override
  String get topPerformingProperties => 'Top Performing Properties';

  @override
  String get noPerformanceData => 'No performance data available';

  @override
  String get totalSpent => 'Total Spent';

  @override
  String get totalRecharged => 'Total Recharged';

  @override
  String get spendingBreakdown => 'Spending Breakdown';

  @override
  String get boostPackages => 'Boost Packages';

  @override
  String get propertySlots => 'Property Slots';

  @override
  String get manageWallet => 'Manage Wallet';

  @override
  String get activeBoosts => 'Active Boosts';

  @override
  String engagementRate(Object rate) {
    return 'Engagement Rate: $rate%';
  }

  @override
  String get calls => 'Calls';

  @override
  String get saves => 'Saves';

  @override
  String get expiring => 'Expiring';

  @override
  String get comingSoon => 'Coming Soon';

  @override
  String get boostActive => 'Boost Active';

  @override
  String get noActiveBoosts => 'No active boosts';

  @override
  String get expires => 'Expires';

  @override
  String avgViews(Object count) {
    return '$count avg';
  }

  @override
  String leadsPercentage(Object count) {
    return '$count% of leads';
  }

  @override
  String get available => 'Available';

  @override
  String ratePercentage(Object rate) {
    return '$rate% rate';
  }

  @override
  String get transactionRechargeMoamalat => 'Recharged via Moamalat Card';

  @override
  String transactionPurchaseSlots(Object count, Object name) {
    return 'Purchase $name - Add $count property slots';
  }

  @override
  String transactionTopListing(Object name) {
    return 'Top Listing Purchase - $name';
  }

  @override
  String get transactionBoostPlus => 'Boost New Listing: Plus';

  @override
  String get transactionVoucherRecharge => 'Voucher Recharge';

  @override
  String get transactionAdminCredit => 'Manual Admin Credit';

  @override
  String get packageStarter => 'Starter';

  @override
  String get packageProfessional => 'Professional';

  @override
  String get packageElite => 'Elite';

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
    return 'New message from $senderName';
  }

  @override
  String aboutProperty(Object propertyTitle) {
    return 'About $propertyTitle';
  }

  @override
  String get property => 'Property';

  @override
  String get loading => 'Loading...';

  @override
  String get pleaseLoginToPurchase => 'Please log in to purchase packages';

  @override
  String get noActiveListingsToBoost =>
      'No active listings found. Please create a listing first.';

  @override
  String get chooseListingToBoost => 'Choose Listing to Boost';

  @override
  String get boostListing => 'Boost Listing';

  @override
  String weeksAgo(Object count) {
    return '$count weeks ago';
  }

  @override
  String monthsAgo(Object count) {
    return '$count months ago';
  }

  @override
  String boostSuccessMessage(
      Object balance, Object listingTitle, Object packageName) {
    return '$listingTitle is now boosted with $packageName!\nRemaining balance: $balance LYD';
  }

  @override
  String get bulkBoostActivated => 'Bulk Boost Activated!';

  @override
  String bulkBoostSuccessMessage(
      Object balance, Object count, Object packageName) {
    return '$count properties are now boosted with $packageName!\nRemaining balance: $balance LYD';
  }

  @override
  String get awesome => 'Awesome!';

  @override
  String get insufficientBalanceAction => 'Top up';

  @override
  String get oneWeekAgo => '1 week ago';

  @override
  String get oneMonthAgo => '1 month ago';

  @override
  String get voucherPurchaseInstruction1 =>
      '• Purchase from any store with Umbrella or Anis POS terminals.';

  @override
  String get voucherPurchaseInstruction2 =>
      '• يمكنك الشراء من أي محل تتوفر لديه ماكينة دفع (المظلة) أو (أنيس).';

  @override
  String get securePayment => 'Secure Payment';

  @override
  String get invalidVoucherCode =>
      'Invalid voucher code. Please check and try again.';

  @override
  String get voucherAlreadyRedeemed =>
      'This voucher has already been redeemed.';

  @override
  String voucherRechargeSuccess(Object balance, Object currency) {
    return 'Wallet recharged successfully! New balance: $balance $currency';
  }

  @override
  String get processingVoucher => 'Processing voucher...';

  @override
  String get done => 'Done';

  @override
  String get rechargeSuccessful => 'Recharge Successful';

  @override
  String get analyticsAssistant => 'Analytics Assistant';

  @override
  String get aiPoweredInsights => 'AI-Powered Performance Insights';

  @override
  String get lowVisibility => 'Low Visibility';

  @override
  String get greatEngagement => 'Great Engagement!';

  @override
  String get goodContactConversion => 'Good Contact Conversion';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get boostProperties => 'Boost Properties';

  @override
  String get rechargeWallet => 'Recharge Wallet';

  @override
  String get propertySaved => 'Property Saved';

  @override
  String get suggestions => 'Suggestions:';

  @override
  String propertiesSavedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count properties saved',
      one: '1 property saved',
    );
    return '$_temp0';
  }

  @override
  String get noFavoritesYet => 'No favorites yet';

  @override
  String get startAddingToFavorites =>
      'Start adding properties to your favorites';

  @override
  String get idLabel => 'ID';

  @override
  String get boostedStatusBadge => 'BOOSTED';

  @override
  String get helpSupport => 'Help & Support';

  @override
  String get onboardingTitle1 => 'Find Your Dream Home';

  @override
  String get onboardingDesc1 =>
      'Explore thousands of premium properties in the best locations across Libya.';

  @override
  String get onboardingTitle2 => 'Smart Search & Filters';

  @override
  String get onboardingDesc2 =>
      'Use our advanced search engine to find exactly what you need with just a few taps.';

  @override
  String get onboardingTitle3 => 'Secure & Direct Contact';

  @override
  String get onboardingDesc3 =>
      'Connect directly with sellers and agents through our secure messaging system.';

  @override
  String get skip => 'Skip';

  @override
  String get start => 'Start';

  @override
  String get next => 'Next';

  @override
  String get pageNotFound => 'Page not found';

  @override
  String get goHome => 'Go Home';

  @override
  String get loadingProperty => 'Loading property...';

  @override
  String get error => 'Error';

  @override
  String get splashTagline => 'Finding your dream home...';

  @override
  String get noViewsTitle => 'No Views Detected';

  @override
  String get noViewsMessage =>
      'Your properties have received no views. This might be because:\n• Properties are not published\n• Poor quality images or missing photos\n• Unclear or unappealing titles\n• Properties might be hidden or inactive';

  @override
  String get checkPublished => 'Check if all properties are published';

  @override
  String get addHighQualityPhotos =>
      'Add high-quality photos to all properties';

  @override
  String get writeClearTitles => 'Write clear, descriptive titles';

  @override
  String get considerBoosting =>
      'Consider boosting your properties for visibility';

  @override
  String get lowVisibilityTitle => 'Low Visibility';

  @override
  String lowVisibilityMessage(String average) {
    return 'Your properties are getting very few views (average $average per listing).\nThis suggests your listings need better optimization.';
  }

  @override
  String get improvePhotos => 'Improve property photos quality';

  @override
  String get detailedDescriptions =>
      'Write more detailed and appealing descriptions';

  @override
  String get addMorePhotos => 'Add more photos (at least 5-10 per property)';

  @override
  String get verifyPricing => 'Verify your pricing is competitive';

  @override
  String get lowEngagementTitle => 'Low Engagement Rate';

  @override
  String lowEngagementMessage(String rate) {
    return 'Your engagement rate is $rate%, which is below average.\nThis means people view your properties but don\'t take action.';
  }

  @override
  String get compellingDescriptions =>
      'Add more compelling property descriptions';

  @override
  String get includeAmenities => 'Include all amenities and features';

  @override
  String get verifyContactInfo => 'Verify contact information is correct';

  @override
  String get adjustPricing =>
      'Consider adjusting pricing to be more competitive';

  @override
  String get addLocationDetails =>
      'Add property location details (neighborhood, nearby amenities)';

  @override
  String get veryLowContactTitle => 'Very Low Contact Rate';

  @override
  String veryLowContactMessage(String rate) {
    return 'Only $rate% of viewers are contacting you.\nThis suggests properties might be overpriced or lack important information.';
  }

  @override
  String get reviewPricing => 'Review and adjust pricing to market rates';

  @override
  String get completeInfo => 'Add complete property information';

  @override
  String get highlightPoints => 'Highlight unique selling points';

  @override
  String get visiblePhoneNumber => 'Ensure contact phone number is visible';

  @override
  String get respondQuickly => 'Respond quickly to inquiries when they come';

  @override
  String get noListingsTitle => 'No Listings Yet';

  @override
  String get noListingsMessage =>
      'You don\'t have any active listings. Start by adding your first property!';

  @override
  String get addFirstProperty =>
      'Click \"Add Property\" to create your first listing';

  @override
  String get fillDetails => 'Fill in all property details completely';

  @override
  String get publishVisible => 'Publish your property to make it visible';

  @override
  String get increaseExposureTitle => 'Increase Your Exposure';

  @override
  String get increaseExposureMessage =>
      'Having only one listing limits your visibility. Consider adding more properties.';

  @override
  String get addMoreProperties =>
      'Add more properties to increase your portfolio';

  @override
  String get eachPropertyVisibility =>
      'Each property increases your overall visibility';

  @override
  String get diversify => 'Diversify property types and locations';

  @override
  String get greatEngagementTitle => 'Great Engagement!';

  @override
  String greatEngagementMessage(String rate) {
    return 'Your engagement rate of $rate% is excellent!\nKeep up the good work by maintaining quality listings.';
  }

  @override
  String get maintainQuality => 'Continue maintaining high-quality listings';

  @override
  String get keepUpdated => 'Keep property information updated';

  @override
  String get addRegularly => 'Add new properties regularly';

  @override
  String get goodContactTitle => 'Good Contact Conversion';

  @override
  String goodContactMessage(String rate) {
    return 'Your contact rate of $rate% shows good conversion.\nMake sure to respond promptly to all inquiries.';
  }

  @override
  String get respond24h => 'Respond to inquiries within 24 hours';

  @override
  String get keepContactUpdated => 'Keep contact information up to date';

  @override
  String get beProfessional => 'Be professional and helpful in communications';

  @override
  String get doingGreatTitle => 'You\'re Doing Great!';

  @override
  String get doingGreatMessage =>
      'Your properties are performing well. No major issues detected.';

  @override
  String get monitorMetrics => 'Continue monitoring your metrics';

  @override
  String get refreshListings =>
      'Refresh listings periodically to keep them at the top';

  @override
  String get keepDescriptionsFresh => 'Keep descriptions fresh and detailed';

  @override
  String get monitorWeekly => 'Monitor analytics weekly';

  @override
  String get boostPeakTimes => 'Consider boosting properties during peak times';

  @override
  String get gatherFeedback => 'Gather and respond to user feedback';

  @override
  String get verifyPhoneNumber => 'Verify Phone Number';

  @override
  String get otpSentTo => 'We\'ve sent a 6-digit verification code to';

  @override
  String get verify => 'Verify';

  @override
  String get resendCode => 'Resend Code';

  @override
  String get unpublishAll => 'Unpublish All';

  @override
  String get publishAll => 'Publish All';

  @override
  String unpublishPropertiesTitle(int count) {
    return 'Unpublish $count Properties?';
  }

  @override
  String get unpublishConfirmMessage =>
      'Are you sure you want to unpublish the selected properties? they will disappear from public search.';

  @override
  String publishPropertiesTitle(int count) {
    return 'Publish $count Properties?';
  }

  @override
  String get publishReuseSlotsMessage =>
      'These properties will reuse your existing slots. No new slots will be consumed. Continue?';

  @override
  String publishUseSomeSlotsMessage(int count) {
    return 'This will use $count of your available slots. The rest are reusing existing slots. Continue?';
  }

  @override
  String get slotLimitReached => 'Slot Limit Reached';

  @override
  String notEnoughSlotsMessage(int needed, int available) {
    return 'You don\'t have enough slots to publish these properties. You need $needed new slots but only have $available available.';
  }

  @override
  String get mockPropertySuccess => 'Mock Property Created Successfully!';

  @override
  String get propertyLimitReachedAdd =>
      'You have reached your property limit. Please purchase more slots to add properties.';

  @override
  String get propertyLimitReachedGeneral =>
      'You have reached your property limit. Please purchase more slots.';

  @override
  String get purchaseSuccessfulLabel => 'Purchase Successful!';

  @override
  String addedSlotsNewLimit(int slots, int limit) {
    return 'Added $slots property slots.\nNew limit: $limit properties';
  }

  @override
  String get moreCredits => 'Purchase More Points';

  @override
  String get buyMoreCredits => 'Buy More Points';

  @override
  String packageCredits(int count) {
    return '$count Points';
  }

  @override
  String get buyCredits => 'Buy Points';

  @override
  String get buyNow => 'Buy Now';

  @override
  String get purchaseSuccess => 'Purchase Successful!';

  @override
  String get totalBalance => 'Total Points';

  @override
  String get creditsLabel => 'Points';

  @override
  String get postingCreditFooter =>
      'Each property listing consumes 1 posting point.';

  @override
  String get postingCreditsTitle => 'Posting Points';

  @override
  String get oneTimePurchase => 'One-time purchase';

  @override
  String get persistentCredits => 'Persistent points (no monthly loss)';

  @override
  String publishUseSomeCreditsMessage(int count) {
    return 'This will use $count of your available points. Continue?';
  }

  @override
  String get renewPropertyConfirm => 'Renew Property?';

  @override
  String get renewPropertyDescription =>
      'This will deduct 1 point from your points and extend the listing for 60 days.';

  @override
  String get great => 'Great!';

  @override
  String get noCreditsMessage =>
      'No posting points remaining. Please purchase a points package to list your property.';

  @override
  String purchaseSuccessSubtitle(int credits, int remaining) {
    return 'You have received $credits posting points.\nRemaining balance: $remaining points';
  }

  @override
  String featurePostingCredits(int count) {
    return '$count Posting Points';
  }

  @override
  String get featurePersistentCredits => 'Points never expire';

  @override
  String get featurePersistentCreditsLong =>
      'Points never expire (no monthly loss)';

  @override
  String get featureBasicVisibility => 'Basic search visibility';

  @override
  String get featureStandardVisibility => 'Standard search visibility';

  @override
  String get featureEnhancedVisibility => 'Enhanced search visibility';

  @override
  String get featureMaximumVisibility => 'Maximum search visibility';

  @override
  String get featureEmailSupport => 'Email support';

  @override
  String get featurePrioritySupport => 'Priority support';

  @override
  String get featureDedicatedManager => 'Dedicated account manager';

  @override
  String get standardPackage => 'Standard Package';

  @override
  String get businessPackage => 'Business Package';

  @override
  String get packagePlus => 'Plus';

  @override
  String get buyPoints => 'Buy Points';

  @override
  String get boostApplied => 'Boost Applied!';

  @override
  String boostSuccessSubtitle(String packageName, int days) {
    return 'Your listing has been boosted with $packageName for $days days.';
  }

  @override
  String get prioritySearch => 'Priority Search';
}
