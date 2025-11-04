import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Dary Properties'**
  String get appTitle;

  /// Home tab label
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Add Property tab label
  ///
  /// In en, this message translates to:
  /// **'Add Property'**
  String get addProperty;

  /// Wallet tab label
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get wallet;

  /// Profile tab label
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Welcome message on home screen
  ///
  /// In en, this message translates to:
  /// **'Welcome to Dary!'**
  String get welcomeMessage;

  /// Subtitle message on home screen
  ///
  /// In en, this message translates to:
  /// **'Your minimal Flutter app with Material 3'**
  String get subtitleMessage;

  /// Hint text for navigation
  ///
  /// In en, this message translates to:
  /// **'Use the bottom navigation to explore features'**
  String get navigationHint;

  /// Current balance label
  ///
  /// In en, this message translates to:
  /// **'Current Balance'**
  String get currentBalance;

  /// Recharge button text
  ///
  /// In en, this message translates to:
  /// **'Recharge'**
  String get recharge;

  /// Transaction history section title
  ///
  /// In en, this message translates to:
  /// **'Transaction History'**
  String get transactionHistory;

  /// Export button text
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// Profile screen title
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// Profile screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Manage your account settings'**
  String get manageAccountSettings;

  /// Active listings section title
  ///
  /// In en, this message translates to:
  /// **'Active Listings'**
  String get activeListings;

  /// View all button text
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// Account management section title
  ///
  /// In en, this message translates to:
  /// **'Account Management'**
  String get accountManagement;

  /// Edit profile button text
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// Upgrade to premium button text
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Premium'**
  String get upgradeToPremium;

  /// Delete account button text
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// Paywall screen title
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Premium'**
  String get upgradeToPremiumTitle;

  /// Paywall screen header title
  ///
  /// In en, this message translates to:
  /// **'Boost Your Listings'**
  String get boostYourListings;

  /// Paywall screen header subtitle
  ///
  /// In en, this message translates to:
  /// **'Get more visibility with our Top Listing packages'**
  String get getMoreVisibility;

  /// Limited time offer badge
  ///
  /// In en, this message translates to:
  /// **'✨ Limited Time Offer'**
  String get limitedTimeOffer;

  /// Choose package section title
  ///
  /// In en, this message translates to:
  /// **'Choose Your Package'**
  String get chooseYourPackage;

  /// Choose package section subtitle
  ///
  /// In en, this message translates to:
  /// **'Select the perfect duration for your listing promotion'**
  String get selectPerfectDuration;

  /// Package name
  ///
  /// In en, this message translates to:
  /// **'Top Listing'**
  String get topListing;

  /// One day duration
  ///
  /// In en, this message translates to:
  /// **'1 Day'**
  String get oneDay;

  /// One week duration
  ///
  /// In en, this message translates to:
  /// **'1 Week'**
  String get oneWeek;

  /// One month duration
  ///
  /// In en, this message translates to:
  /// **'1 Month'**
  String get oneMonth;

  /// Popular badge text
  ///
  /// In en, this message translates to:
  /// **'POPULAR'**
  String get popular;

  /// One day package description
  ///
  /// In en, this message translates to:
  /// **'Perfect for quick promotion'**
  String get perfectForQuickPromotion;

  /// One week package description
  ///
  /// In en, this message translates to:
  /// **'Great for testing the waters'**
  String get greatForTestingWaters;

  /// One month package description
  ///
  /// In en, this message translates to:
  /// **'Best value for serious sellers'**
  String get bestValueForSeriousSellers;

  /// Feature description
  ///
  /// In en, this message translates to:
  /// **'Priority placement in search results'**
  String get priorityPlacement;

  /// Feature description
  ///
  /// In en, this message translates to:
  /// **'Featured badge on your listing'**
  String get featuredBadge;

  /// Feature description
  ///
  /// In en, this message translates to:
  /// **'Increased visibility'**
  String get increasedVisibility;

  /// Feature description
  ///
  /// In en, this message translates to:
  /// **'24-hour boost'**
  String get dayBoost;

  /// Feature description
  ///
  /// In en, this message translates to:
  /// **'7-day boost'**
  String get weekBoost;

  /// Feature description
  ///
  /// In en, this message translates to:
  /// **'30-day boost'**
  String get monthBoost;

  /// Feature description
  ///
  /// In en, this message translates to:
  /// **'Analytics dashboard'**
  String get analyticsDashboard;

  /// Feature description
  ///
  /// In en, this message translates to:
  /// **'Premium support'**
  String get premiumSupport;

  /// Feature description
  ///
  /// In en, this message translates to:
  /// **'Multiple listing promotion'**
  String get multipleListingPromotion;

  /// Feature description
  ///
  /// In en, this message translates to:
  /// **'Custom listing design'**
  String get customListingDesign;

  /// Buy one day button text
  ///
  /// In en, this message translates to:
  /// **'Buy 1 Day'**
  String get buyOneDay;

  /// Buy one week button text
  ///
  /// In en, this message translates to:
  /// **'Buy 1 Week'**
  String get buyOneWeek;

  /// Buy one month button text
  ///
  /// In en, this message translates to:
  /// **'Buy 1 Month'**
  String get buyOneMonth;

  /// Benefits section title
  ///
  /// In en, this message translates to:
  /// **'Why Choose Top Listing?'**
  String get whyChooseTopListing;

  /// Benefit description
  ///
  /// In en, this message translates to:
  /// **'Your listing appears at the top of search results'**
  String get increasedVisibilityDescription;

  /// Benefit description
  ///
  /// In en, this message translates to:
  /// **'Stand out with a premium featured badge'**
  String get featuredBadgeDescription;

  /// Benefit description
  ///
  /// In en, this message translates to:
  /// **'Track views, clicks, and engagement metrics'**
  String get analyticsDashboardDescription;

  /// Benefit description
  ///
  /// In en, this message translates to:
  /// **'Get priority customer support'**
  String get premiumSupportDescription;

  /// Purchase success message
  ///
  /// In en, this message translates to:
  /// **'Successfully purchased {packageName}!'**
  String successfullyPurchased(String packageName);

  /// View details button text
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// Purchase failure message
  ///
  /// In en, this message translates to:
  /// **'Purchase failed. Please try again.'**
  String get purchaseFailed;

  /// Purchase error message
  ///
  /// In en, this message translates to:
  /// **'Error processing purchase: {error}'**
  String errorProcessingPurchase(String error);

  /// Add property screen title
  ///
  /// In en, this message translates to:
  /// **'Add Property'**
  String get addPropertyTitle;

  /// Property title column header
  ///
  /// In en, this message translates to:
  /// **'Property'**
  String get propertyTitle;

  /// Property title field hint
  ///
  /// In en, this message translates to:
  /// **'Enter property title'**
  String get enterPropertyTitle;

  /// Description column header
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// Description field hint
  ///
  /// In en, this message translates to:
  /// **'Describe your property'**
  String get describeYourProperty;

  /// Price column header
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// Price field hint
  ///
  /// In en, this message translates to:
  /// **'Enter price'**
  String get enterPrice;

  /// Size field label
  ///
  /// In en, this message translates to:
  /// **'Size (sqm)'**
  String get size;

  /// Size field hint
  ///
  /// In en, this message translates to:
  /// **'Enter size in square meters'**
  String get enterSize;

  /// Features section title
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get features;

  /// Balcony feature
  ///
  /// In en, this message translates to:
  /// **'Balcony'**
  String get balcony;

  /// Balcony feature description
  ///
  /// In en, this message translates to:
  /// **'Property has a balcony'**
  String get propertyHasBalcony;

  /// Garden feature
  ///
  /// In en, this message translates to:
  /// **'Garden'**
  String get garden;

  /// Garden feature description
  ///
  /// In en, this message translates to:
  /// **'Property has a garden'**
  String get propertyHasGarden;

  /// Parking feature
  ///
  /// In en, this message translates to:
  /// **'Parking'**
  String get parking;

  /// Parking feature description
  ///
  /// In en, this message translates to:
  /// **'Property has parking'**
  String get propertyHasParking;

  /// Images section title
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get images;

  /// Upload images button text
  ///
  /// In en, this message translates to:
  /// **'Upload Images (up to 10)'**
  String get uploadImages;

  /// Images selected text
  ///
  /// In en, this message translates to:
  /// **'{count} images selected'**
  String imagesSelected(int count);

  /// Selected images label
  ///
  /// In en, this message translates to:
  /// **'Selected Images:'**
  String get selectedImages;

  /// Add property button text
  ///
  /// In en, this message translates to:
  /// **'Add Property'**
  String get addPropertyButton;

  /// Adding property loading text
  ///
  /// In en, this message translates to:
  /// **'Adding Property...'**
  String get addingProperty;

  /// Property added success message
  ///
  /// In en, this message translates to:
  /// **'Property added successfully!'**
  String get propertyAddedSuccessfully;

  /// Language toggle button tooltip
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageToggle;

  /// No transactions message
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get noTransactionsYet;

  /// Export transactions message
  ///
  /// In en, this message translates to:
  /// **'Export transactions'**
  String get exportTransactions;

  /// Search properties placeholder
  ///
  /// In en, this message translates to:
  /// **'Search properties...'**
  String get searchProperties;

  /// Featured properties label
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get featured;

  /// Verified column header
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// Price range label
  ///
  /// In en, this message translates to:
  /// **'Price Range'**
  String get priceRange;

  /// Clear filters button
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get clearFilters;

  /// Advanced filters button
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get advancedFilters;

  /// Property type label
  ///
  /// In en, this message translates to:
  /// **'Property Type'**
  String get propertyType;

  /// Property status label
  ///
  /// In en, this message translates to:
  /// **'Property Status'**
  String get propertyStatus;

  /// Apply filters button
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get applyFilters;

  /// For sale status
  ///
  /// In en, this message translates to:
  /// **'For Sale'**
  String get forSale;

  /// For rent status
  ///
  /// In en, this message translates to:
  /// **'For Rent'**
  String get forRent;

  /// Sold status
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get sold;

  /// Rented status
  ///
  /// In en, this message translates to:
  /// **'Rented'**
  String get rented;

  /// Apartment type
  ///
  /// In en, this message translates to:
  /// **'Apartment'**
  String get apartment;

  /// House type
  ///
  /// In en, this message translates to:
  /// **'House'**
  String get house;

  /// Villa type
  ///
  /// In en, this message translates to:
  /// **'Villa'**
  String get villa;

  /// Townhouse type
  ///
  /// In en, this message translates to:
  /// **'Townhouse'**
  String get townhouse;

  /// Studio type
  ///
  /// In en, this message translates to:
  /// **'Studio'**
  String get studio;

  /// Penthouse type
  ///
  /// In en, this message translates to:
  /// **'Penthouse'**
  String get penthouse;

  /// Commercial type
  ///
  /// In en, this message translates to:
  /// **'Commercial'**
  String get commercial;

  /// Land type
  ///
  /// In en, this message translates to:
  /// **'Land'**
  String get land;

  /// No properties found message
  ///
  /// In en, this message translates to:
  /// **'No properties found'**
  String get noPropertiesFound;

  /// Try adjusting filters message
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search filters'**
  String get tryAdjustingFilters;

  /// Basic information section title
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get basicInformation;

  /// Location information section title
  ///
  /// In en, this message translates to:
  /// **'Location Information'**
  String get locationInformation;

  /// Property details screen title
  ///
  /// In en, this message translates to:
  /// **'Property Details'**
  String get propertyDetails;

  /// Contact information section title
  ///
  /// In en, this message translates to:
  /// **'Contact Information'**
  String get contactInformation;

  /// Title validation message
  ///
  /// In en, this message translates to:
  /// **'Please enter a title'**
  String get pleaseEnterTitle;

  /// Description validation message
  ///
  /// In en, this message translates to:
  /// **'Please enter a description'**
  String get pleaseEnterDescription;

  /// Price validation message
  ///
  /// In en, this message translates to:
  /// **'Please enter a price'**
  String get pleaseEnterPrice;

  /// Valid price validation message
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid price'**
  String get pleaseEnterValidPrice;

  /// Size validation message
  ///
  /// In en, this message translates to:
  /// **'Please enter the size'**
  String get pleaseEnterSize;

  /// Valid size validation message
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid size'**
  String get pleaseEnterValidSize;

  /// Maximum images message
  ///
  /// In en, this message translates to:
  /// **'You can upload a maximum of 10 images.'**
  String get maxImages;

  /// Failed to pick images message
  ///
  /// In en, this message translates to:
  /// **'Failed to pick images:'**
  String get failedToPickImages;

  /// Select images button
  ///
  /// In en, this message translates to:
  /// **'Select Images'**
  String get selectImages;

  /// Login button text
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// Register button text
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// Email column header
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Confirm password field label
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// Full name field label
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// Phone number field label
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// Login screen title
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get loginTitle;

  /// Login screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Sign in to your account'**
  String get loginSubtitle;

  /// Register screen title
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get registerTitle;

  /// Register screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Join Dary Properties today'**
  String get registerSubtitle;

  /// Login button text
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get loginButton;

  /// Register button text
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get registerButton;

  /// Already have account text
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// Don't have account text
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// Sign in link text
  ///
  /// In en, this message translates to:
  /// **'Sign in here'**
  String get signInHere;

  /// Sign up link text
  ///
  /// In en, this message translates to:
  /// **'Sign up here'**
  String get signUpHere;

  /// Email field hint
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterEmail;

  /// Password field hint
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterPassword;

  /// Confirm password field hint
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get enterConfirmPassword;

  /// Full name field hint
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get enterFullName;

  /// Phone number field hint
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get enterPhoneNumber;

  /// Email required validation
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// Password required validation
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// Name required validation
  ///
  /// In en, this message translates to:
  /// **'Full name is required'**
  String get nameRequired;

  /// Phone required validation
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get phoneRequired;

  /// Confirm password required validation
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get confirmPasswordRequired;

  /// Invalid email validation
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get invalidEmail;

  /// Password too short validation
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShort;

  /// Passwords don't match validation
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// Login success message
  ///
  /// In en, this message translates to:
  /// **'Login successful! Welcome back'**
  String get loginSuccess;

  /// Register success message
  ///
  /// In en, this message translates to:
  /// **'Account created successfully! Welcome to Dary'**
  String get registerSuccess;

  /// Login failed message
  ///
  /// In en, this message translates to:
  /// **'Login failed. Please check your credentials'**
  String get loginFailed;

  /// Register failed message
  ///
  /// In en, this message translates to:
  /// **'Registration failed. Please try again'**
  String get registerFailed;

  /// Login loading text
  ///
  /// In en, this message translates to:
  /// **'Signing in...'**
  String get loggingIn;

  /// Register loading text
  ///
  /// In en, this message translates to:
  /// **'Creating account...'**
  String get registering;

  /// Forgot password link
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// Remember me checkbox
  ///
  /// In en, this message translates to:
  /// **'Remember Me'**
  String get rememberMe;

  /// Terms and conditions text
  ///
  /// In en, this message translates to:
  /// **'By signing up, you agree to our Terms and Conditions'**
  String get termsAndConditions;

  /// Privacy policy link
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// Logout success message
  ///
  /// In en, this message translates to:
  /// **'Logged out successfully'**
  String get logoutSuccess;

  /// Messages tab label
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// Chat screen title
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// Placeholder text for message input field
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeMessage;

  /// Text shown when there are no messages in a conversation
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessagesYet;

  /// Text encouraging user to start a conversation
  ///
  /// In en, this message translates to:
  /// **'Start the conversation!'**
  String get startConversation;

  /// Text shown when there are no conversations
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get noConversationsYet;

  /// Text encouraging user to start conversations with sellers
  ///
  /// In en, this message translates to:
  /// **'Start a conversation with a seller to discuss properties!'**
  String get startConversationWithSeller;

  /// Button text to browse properties
  ///
  /// In en, this message translates to:
  /// **'Browse Properties'**
  String get browseProperties;

  /// Error message when conversation is not found
  ///
  /// In en, this message translates to:
  /// **'Conversation not found'**
  String get conversationNotFound;

  /// Error message when messages fail to load
  ///
  /// In en, this message translates to:
  /// **'Error loading messages'**
  String get errorLoadingMessages;

  /// Error message when message fails to send
  ///
  /// In en, this message translates to:
  /// **'Error sending message'**
  String get errorSendingMessage;

  /// Error message when conversations fail to load
  ///
  /// In en, this message translates to:
  /// **'Error loading conversations'**
  String get errorLoadingConversations;

  /// Message shown when user needs to login to contact seller
  ///
  /// In en, this message translates to:
  /// **'Please login first'**
  String get pleaseLoginFirst;

  /// Message shown when user tries to contact themselves
  ///
  /// In en, this message translates to:
  /// **'You cannot contact yourself'**
  String get cannotContactYourself;

  /// Error message when conversation creation fails
  ///
  /// In en, this message translates to:
  /// **'Error creating conversation'**
  String get errorCreatingConversation;

  /// Error message when contacting seller fails
  ///
  /// In en, this message translates to:
  /// **'Error contacting seller'**
  String get errorContactingSeller;

  /// Button text to contact seller
  ///
  /// In en, this message translates to:
  /// **'Contact Seller'**
  String get contactSeller;

  /// Text shown while creating conversation
  ///
  /// In en, this message translates to:
  /// **'Creating conversation...'**
  String get creatingConversation;

  /// Agent information section title
  ///
  /// In en, this message translates to:
  /// **'Agent Information'**
  String get agentInfo;

  /// Real estate agent label
  ///
  /// In en, this message translates to:
  /// **'Real Estate Agent'**
  String get realEstateAgent;

  /// Views column header
  ///
  /// In en, this message translates to:
  /// **'Views'**
  String get views;

  /// Listed date label
  ///
  /// In en, this message translates to:
  /// **'Listed on'**
  String get listedOn;

  /// Bedrooms label
  ///
  /// In en, this message translates to:
  /// **'Bedrooms'**
  String get bedrooms;

  /// Bathrooms label
  ///
  /// In en, this message translates to:
  /// **'Bathrooms'**
  String get bathrooms;

  /// Square meters label
  ///
  /// In en, this message translates to:
  /// **'sqm'**
  String get sqm;

  /// Pool feature
  ///
  /// In en, this message translates to:
  /// **'Pool'**
  String get pool;

  /// Gym feature
  ///
  /// In en, this message translates to:
  /// **'Gym'**
  String get gym;

  /// Security feature
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// Elevator feature
  ///
  /// In en, this message translates to:
  /// **'Elevator'**
  String get elevator;

  /// Air conditioning feature
  ///
  /// In en, this message translates to:
  /// **'AC'**
  String get ac;

  /// Furnished feature
  ///
  /// In en, this message translates to:
  /// **'Furnished'**
  String get furnished;

  /// New message notification prefix
  ///
  /// In en, this message translates to:
  /// **'New message from'**
  String get newMessageFrom;

  /// New conversation notification title
  ///
  /// In en, this message translates to:
  /// **'New conversation started'**
  String get newConversationStarted;

  /// About prefix for property
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// View button text
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// Test notification button text
  ///
  /// In en, this message translates to:
  /// **'Test Notification'**
  String get testNotification;

  /// Verification screen title
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get verification;

  /// Verification information section title
  ///
  /// In en, this message translates to:
  /// **'Verification Information'**
  String get verificationInfo;

  /// Verification description text
  ///
  /// In en, this message translates to:
  /// **'To become a verified seller, please upload your ID card and business license. This helps us verify your identity and build trust with potential buyers.'**
  String get verificationDescription;

  /// Upload ID card section title
  ///
  /// In en, this message translates to:
  /// **'Upload ID Card'**
  String get uploadIdCard;

  /// Upload business license section title
  ///
  /// In en, this message translates to:
  /// **'Upload Business License'**
  String get uploadBusinessLicense;

  /// Tap to upload ID card placeholder
  ///
  /// In en, this message translates to:
  /// **'Tap to upload ID card'**
  String get tapToUploadIdCard;

  /// Tap to upload business license placeholder
  ///
  /// In en, this message translates to:
  /// **'Tap to upload business license'**
  String get tapToUploadLicense;

  /// Submit verification button text
  ///
  /// In en, this message translates to:
  /// **'Submit for Verification'**
  String get submitVerification;

  /// Verification success dialog title
  ///
  /// In en, this message translates to:
  /// **'You are now a verified seller!'**
  String get verificationSuccess;

  /// Verification success dialog message
  ///
  /// In en, this message translates to:
  /// **'Your documents have been verified. You can now enjoy all the benefits of being a verified seller.'**
  String get verificationSuccessMessage;

  /// Continue button text
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// Already verified screen title
  ///
  /// In en, this message translates to:
  /// **'You are already verified!'**
  String get alreadyVerified;

  /// Already verified screen message
  ///
  /// In en, this message translates to:
  /// **'Your account has been verified. You can enjoy all the benefits of being a verified seller.'**
  String get alreadyVerifiedMessage;

  /// Back to profile button text
  ///
  /// In en, this message translates to:
  /// **'Back to Profile'**
  String get backToProfile;

  /// Get verified button text
  ///
  /// In en, this message translates to:
  /// **'Get Verified'**
  String get getVerified;

  /// Privacy notice text
  ///
  /// In en, this message translates to:
  /// **'Your documents are encrypted and stored securely. We only use them for verification purposes.'**
  String get privacyNotice;

  /// Error message when documents are missing
  ///
  /// In en, this message translates to:
  /// **'Please upload both documents'**
  String get pleaseUploadBothDocuments;

  /// Verification error message
  ///
  /// In en, this message translates to:
  /// **'Verification failed. Please try again.'**
  String get verificationError;

  /// Error message when image picking fails
  ///
  /// In en, this message translates to:
  /// **'Error picking image'**
  String get errorPickingImage;

  /// Camera option in image picker
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// Gallery option in image picker
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// Analytics screen title
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// View analytics button text
  ///
  /// In en, this message translates to:
  /// **'View Analytics'**
  String get viewAnalytics;

  /// Performance overview section title
  ///
  /// In en, this message translates to:
  /// **'Performance Overview'**
  String get performanceOverview;

  /// Top performing listing card title
  ///
  /// In en, this message translates to:
  /// **'Top Performing Listing'**
  String get topPerformingListing;

  /// Average engagement card title
  ///
  /// In en, this message translates to:
  /// **'Average Engagement'**
  String get averageEngagement;

  /// Total views card title
  ///
  /// In en, this message translates to:
  /// **'Total Views'**
  String get totalViews;

  /// Total contacts card title
  ///
  /// In en, this message translates to:
  /// **'Total Contacts'**
  String get totalContacts;

  /// Daily views chart title
  ///
  /// In en, this message translates to:
  /// **'Daily Views (Last 7 Days)'**
  String get dailyViews;

  /// Property type performance chart title
  ///
  /// In en, this message translates to:
  /// **'Property Type Performance'**
  String get propertyTypePerformance;

  /// Detailed metrics section title
  ///
  /// In en, this message translates to:
  /// **'Detailed Metrics'**
  String get detailedMetrics;

  /// Total listings metric
  ///
  /// In en, this message translates to:
  /// **'Total Listings'**
  String get totalListings;

  /// Average views per listing metric
  ///
  /// In en, this message translates to:
  /// **'Average Views per Listing'**
  String get averageViewsPerListing;

  /// Contact conversion rate metric
  ///
  /// In en, this message translates to:
  /// **'Contact Conversion Rate'**
  String get contactConversionRate;

  /// Error message when analytics fail to load
  ///
  /// In en, this message translates to:
  /// **'Error loading analytics data'**
  String get errorLoadingAnalytics;

  /// Admin dashboard title
  ///
  /// In en, this message translates to:
  /// **'Admin Dashboard'**
  String get adminDashboard;

  /// Users tab label
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get users;

  /// Properties tab label
  ///
  /// In en, this message translates to:
  /// **'Properties'**
  String get properties;

  /// Payments tab label
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get payments;

  /// Total users stat card
  ///
  /// In en, this message translates to:
  /// **'Total Users'**
  String get totalUsers;

  /// Total properties stat card
  ///
  /// In en, this message translates to:
  /// **'Total Properties'**
  String get totalProperties;

  /// Total payments stat card
  ///
  /// In en, this message translates to:
  /// **'Total Payments'**
  String get totalPayments;

  /// Total revenue stat card
  ///
  /// In en, this message translates to:
  /// **'Total Revenue'**
  String get totalRevenue;

  /// Name column header
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// Phone column header
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// Active column header
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// Listings column header
  ///
  /// In en, this message translates to:
  /// **'Listings'**
  String get listings;

  /// Actions column header
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// Title column header
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// Owner column header
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get owner;

  /// City column header
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// Status column header
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// User column header
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// Type column header
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// Amount column header
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// Date column header
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// Error message when admin data fails to load
  ///
  /// In en, this message translates to:
  /// **'Error loading admin data'**
  String get errorLoadingAdminData;

  /// Premium listings tab label
  ///
  /// In en, this message translates to:
  /// **'Premium Listings'**
  String get premiumListings;

  /// Sort by label
  ///
  /// In en, this message translates to:
  /// **'Sort by:'**
  String get sortBy;

  /// Expiry date column header
  ///
  /// In en, this message translates to:
  /// **'Expiry Date'**
  String get expiryDate;

  /// Purchase date column header
  ///
  /// In en, this message translates to:
  /// **'Purchase Date'**
  String get purchaseDate;

  /// Package price column header
  ///
  /// In en, this message translates to:
  /// **'Package Price'**
  String get packagePrice;

  /// Package column header
  ///
  /// In en, this message translates to:
  /// **'Package'**
  String get package;

  /// Expiry column header
  ///
  /// In en, this message translates to:
  /// **'Expiry'**
  String get expiry;

  /// Boosted properties section title
  ///
  /// In en, this message translates to:
  /// **'Boosted Properties'**
  String get boostedProperties;

  /// Featured properties section title
  ///
  /// In en, this message translates to:
  /// **'Featured Properties'**
  String get featuredProperties;

  /// All properties section title
  ///
  /// In en, this message translates to:
  /// **'All Properties'**
  String get allProperties;

  /// Rent action card title
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get rent;

  /// No description provided for @savedSearches.
  ///
  /// In en, this message translates to:
  /// **'Saved Searches'**
  String get savedSearches;

  /// No description provided for @noSavedSearches.
  ///
  /// In en, this message translates to:
  /// **'No Saved Searches'**
  String get noSavedSearches;

  /// No description provided for @noSavedSearchesDescription.
  ///
  /// In en, this message translates to:
  /// **'Save your property searches to get notified when new matching properties are added'**
  String get noSavedSearchesDescription;

  /// No description provided for @startSearching.
  ///
  /// In en, this message translates to:
  /// **'Start Searching'**
  String get startSearching;

  /// No description provided for @runSearch.
  ///
  /// In en, this message translates to:
  /// **'Run Search'**
  String get runSearch;

  /// No description provided for @checkNewMatches.
  ///
  /// In en, this message translates to:
  /// **'Check New'**
  String get checkNewMatches;

  /// No description provided for @saveSearch.
  ///
  /// In en, this message translates to:
  /// **'Save Search'**
  String get saveSearch;

  /// No description provided for @enterSearchName.
  ///
  /// In en, this message translates to:
  /// **'Enter a name for this search:'**
  String get enterSearchName;

  /// No description provided for @searchSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Search saved successfully!'**
  String get searchSavedSuccessfully;

  /// No description provided for @failedToSaveSearch.
  ///
  /// In en, this message translates to:
  /// **'Failed to save search'**
  String get failedToSaveSearch;

  /// No description provided for @pleaseLoginToSaveSearches.
  ///
  /// In en, this message translates to:
  /// **'Please login to save searches'**
  String get pleaseLoginToSaveSearches;

  /// No description provided for @searchDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Search deleted successfully'**
  String get searchDeletedSuccessfully;

  /// No description provided for @failedToDeleteSearch.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete search'**
  String get failedToDeleteSearch;

  /// No description provided for @deleteSavedSearch.
  ///
  /// In en, this message translates to:
  /// **'Delete Saved Search'**
  String get deleteSavedSearch;

  /// No description provided for @areYouSureDeleteSearch.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{searchName}\"?'**
  String areYouSureDeleteSearch(Object searchName);

  /// No description provided for @foundNewProperties.
  ///
  /// In en, this message translates to:
  /// **'Found {count} new properties matching \"{searchName}\"'**
  String foundNewProperties(Object count, Object searchName);

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Sell action card title
  ///
  /// In en, this message translates to:
  /// **'Sell'**
  String get sell;

  /// Notification settings screen title
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettings;

  /// Notification status section title
  ///
  /// In en, this message translates to:
  /// **'Notification Status'**
  String get notificationStatus;

  /// Notifications enabled status text
  ///
  /// In en, this message translates to:
  /// **'Notifications are enabled'**
  String get notificationsEnabled;

  /// Notifications disabled status text
  ///
  /// In en, this message translates to:
  /// **'Notifications are disabled'**
  String get notificationsDisabled;

  /// Enable notifications toggle label
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get enableNotifications;

  /// Enable notifications toggle subtitle
  ///
  /// In en, this message translates to:
  /// **'Receive notifications for new properties and messages'**
  String get enableNotificationsSubtitle;

  /// FCM section title
  ///
  /// In en, this message translates to:
  /// **'Firebase Cloud Messaging'**
  String get firebaseCloudMessaging;

  /// FCM enabled status text
  ///
  /// In en, this message translates to:
  /// **'FCM is enabled and working'**
  String get fcmEnabled;

  /// FCM disabled status text
  ///
  /// In en, this message translates to:
  /// **'FCM is disabled or not available'**
  String get fcmDisabled;

  /// FCM token label
  ///
  /// In en, this message translates to:
  /// **'FCM Token'**
  String get fcmToken;

  /// FCM token description
  ///
  /// In en, this message translates to:
  /// **'This token is used to send push notifications to your device'**
  String get fcmTokenDescription;

  /// FCM token not available text
  ///
  /// In en, this message translates to:
  /// **'FCM token is not available'**
  String get fcmTokenNotAvailable;

  /// Notification types section title
  ///
  /// In en, this message translates to:
  /// **'Notification Types'**
  String get notificationTypes;

  /// New listings notifications label
  ///
  /// In en, this message translates to:
  /// **'New Listings'**
  String get newListingsNotifications;

  /// New listings notifications subtitle
  ///
  /// In en, this message translates to:
  /// **'Get notified when new properties match your saved searches'**
  String get newListingsNotificationsSubtitle;

  /// Chat notifications label
  ///
  /// In en, this message translates to:
  /// **'Chat Messages'**
  String get chatNotifications;

  /// Chat notifications subtitle
  ///
  /// In en, this message translates to:
  /// **'Get notified when you receive new messages'**
  String get chatNotificationsSubtitle;

  /// Price drop notifications label
  ///
  /// In en, this message translates to:
  /// **'Price Drops'**
  String get priceDropNotifications;

  /// Price drop notifications subtitle
  ///
  /// In en, this message translates to:
  /// **'Get notified when prices drop on properties you\'re watching'**
  String get priceDropNotificationsSubtitle;

  /// Test notifications section title
  ///
  /// In en, this message translates to:
  /// **'Test Notifications'**
  String get testNotifications;

  /// Test notifications description
  ///
  /// In en, this message translates to:
  /// **'Test your notification setup by sending a test notification'**
  String get testNotificationsDescription;

  /// Send test notification button text
  ///
  /// In en, this message translates to:
  /// **'Send Test'**
  String get sendTestNotification;

  /// Test notification sent message
  ///
  /// In en, this message translates to:
  /// **'Test notification sent!'**
  String get testNotificationSent;

  /// Clear all notifications button text
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAllNotifications;

  /// Notifications cleared message
  ///
  /// In en, this message translates to:
  /// **'All notifications cleared'**
  String get notificationsCleared;

  /// Last check time section title
  ///
  /// In en, this message translates to:
  /// **'Last Check Time'**
  String get lastCheckTime;

  /// Last check time description
  ///
  /// In en, this message translates to:
  /// **'The last time the app checked for new matching properties'**
  String get lastCheckTimeDescription;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
