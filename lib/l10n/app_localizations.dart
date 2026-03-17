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

  /// No description provided for @noInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'No Internet Connection'**
  String get noInternetConnection;

  /// No description provided for @pleaseCheckConnection.
  ///
  /// In en, this message translates to:
  /// **'Please check your network settings'**
  String get pleaseCheckConnection;

  /// No description provided for @propertyLegalNote.
  ///
  /// In en, this message translates to:
  /// **'Please verify all property paperwork. Dary is not responsible for any legal discrepancies or issues.'**
  String get propertyLegalNote;

  /// No description provided for @propertyLegalNoteAr.
  ///
  /// In en, this message translates to:
  /// **'يرجى التحقق من جميع أوراق العقار. داري ليست مسؤولة عن أي خلافات أو مشاكل قانونية.'**
  String get propertyLegalNoteAr;

  /// No description provided for @paymentSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Payment Successful!'**
  String get paymentSuccessful;

  /// No description provided for @paymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment failed. Please check your card details and try again.'**
  String get paymentFailed;

  /// No description provided for @changePhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Change Phone Number'**
  String get changePhoneNumber;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// No description provided for @payNow.
  ///
  /// In en, this message translates to:
  /// **'Pay Now'**
  String get payNow;

  /// No description provided for @cardDetails.
  ///
  /// In en, this message translates to:
  /// **'Card Details'**
  String get cardDetails;

  /// No description provided for @cardNumber.
  ///
  /// In en, this message translates to:
  /// **'Card Number'**
  String get cardNumber;

  /// Expiry date column header
  ///
  /// In en, this message translates to:
  /// **'Expiry Date'**
  String get expiryDate;

  /// No description provided for @cvv.
  ///
  /// In en, this message translates to:
  /// **'CVV'**
  String get cvv;

  /// No description provided for @cardholderName.
  ///
  /// In en, this message translates to:
  /// **'Cardholder Name'**
  String get cardholderName;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please try again.'**
  String get errorOccurred;

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
  /// **'Top up'**
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
  /// **'Buy Points'**
  String get upgradeToPremiumTitle;

  /// Paywall screen header title
  ///
  /// In en, this message translates to:
  /// **'10x More Clicks'**
  String get boostYourListings;

  /// Paywall screen header subtitle
  ///
  /// In en, this message translates to:
  /// **'Purchase posting points to list your properties'**
  String get getMoreVisibility;

  /// Limited time offer badge
  ///
  /// In en, this message translates to:
  /// **'✨ Limited Time Offer'**
  String get limitedTimeOffer;

  /// Choose package section title
  ///
  /// In en, this message translates to:
  /// **'Choose Your Points Package'**
  String get chooseYourPackage;

  /// Choose package section subtitle
  ///
  /// In en, this message translates to:
  /// **'Points are permanent and never expire'**
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
  /// **'Featured Badge'**
  String get featuredBadge;

  /// Feature description
  ///
  /// In en, this message translates to:
  /// **'Priority Search'**
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
  /// **'Priority support'**
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
  /// **'Why Boost your Listing?'**
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
  /// **'Cover'**
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
  /// **'Try adjusting your filters'**
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
  /// **'PhoneNumber'**
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
  /// **'Invalid email'**
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

  /// Firebase wrong password error
  ///
  /// In en, this message translates to:
  /// **'Incorrect password. Please try again.'**
  String get firebaseWrongPassword;

  /// Firebase user not found error
  ///
  /// In en, this message translates to:
  /// **'No account found with this email or phone number.'**
  String get firebaseUserNotFound;

  /// Firebase email already in use error
  ///
  /// In en, this message translates to:
  /// **'This email is already registered. Please sign in.'**
  String get firebaseEmailAlreadyInUse;

  /// Firebase phone already in use error
  ///
  /// In en, this message translates to:
  /// **'This phone number is already registered.'**
  String get firebasePhoneAlreadyInUse;

  /// Firebase weak password error
  ///
  /// In en, this message translates to:
  /// **'Password is too weak. Please choose a stronger password.'**
  String get firebaseWeakPassword;

  /// Firebase too many requests error
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a moment and try again.'**
  String get firebaseTooManyRequests;

  /// Firebase network error
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your internet connection.'**
  String get firebaseNetworkError;

  /// Firebase invalid credential error
  ///
  /// In en, this message translates to:
  /// **'Invalid credentials. Please check your email and password.'**
  String get firebaseInvalidCredential;

  /// Firebase user disabled error
  ///
  /// In en, this message translates to:
  /// **'This account has been disabled. Please contact support.'**
  String get firebaseUserDisabled;

  /// Firebase operation not allowed error
  ///
  /// In en, this message translates to:
  /// **'This operation is not allowed. Please contact support.'**
  String get firebaseOperationNotAllowed;

  /// Firebase invalid email error
  ///
  /// In en, this message translates to:
  /// **'Invalid email format.'**
  String get firebaseInvalidEmail;

  /// Firebase account exists with different credential error
  ///
  /// In en, this message translates to:
  /// **'An account already exists with the same email but different credentials.'**
  String get firebaseAccountExistsWithDifferentCredential;

  /// Firebase requires recent login error
  ///
  /// In en, this message translates to:
  /// **'This operation is sensitive and requires recent authentication. Please sign in again.'**
  String get firebaseRequiresRecentLogin;

  /// Firebase generic error
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please try again.'**
  String get firebaseGenericError;

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

  /// Forgot password screen title
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPasswordTitle;

  /// Forgot password screen description
  ///
  /// In en, this message translates to:
  /// **'Don\'t worry! Enter your email below to receive password reset instructions.'**
  String get forgotPasswordDescription;

  /// Send instructions button text
  ///
  /// In en, this message translates to:
  /// **'Send Instructions'**
  String get sendInstructions;

  /// Remember password text
  ///
  /// In en, this message translates to:
  /// **'Remember password?'**
  String get rememberPassword;

  /// Back to login link text
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get backToLogin;

  /// Enter valid email validation message
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get enterValidEmail;

  /// Reset instructions sent success message
  ///
  /// In en, this message translates to:
  /// **'Password reset instructions sent to your email.'**
  String get resetInstructionsSent;

  /// Check email message
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get checkEmail;

  /// Verification warning title
  ///
  /// In en, this message translates to:
  /// **'Verify Your Email'**
  String get pleaseVerifyEmail;

  /// Verification warning description
  ///
  /// In en, this message translates to:
  /// **'A verification link was sent to your email. Please verify it to access all features.'**
  String get verificationEmailSentDesc;

  /// Resend button text
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get resend;

  /// Verification email sent success message
  ///
  /// In en, this message translates to:
  /// **'Verification email sent!'**
  String get verificationEmailSent;

  /// Verified account status text
  ///
  /// In en, this message translates to:
  /// **'Verified Account'**
  String get verifiedAccount;

  /// Unverified account status text
  ///
  /// In en, this message translates to:
  /// **'Unverified Account'**
  String get unverifiedAccount;

  /// Remember me checkbox
  ///
  /// In en, this message translates to:
  /// **'Remember Me'**
  String get rememberMe;

  /// Error message when email resend rate limit is hit
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please try again later.'**
  String get tooManyAttempts;

  /// Title for email verification notification
  ///
  /// In en, this message translates to:
  /// **'Email Not Verified'**
  String get emailNotVerifiedTitle;

  /// Message for email verification notification
  ///
  /// In en, this message translates to:
  /// **'Please verify your email to unlock all features. Check your inbox for the verification link.'**
  String get emailNotVerifiedMessage;

  /// No description provided for @becomeRealEstateOffice.
  ///
  /// In en, this message translates to:
  /// **'Become a Real Estate Office'**
  String get becomeRealEstateOffice;

  /// Message for real estate office upgrade request
  ///
  /// In en, this message translates to:
  /// **'Hello, I would like to upgrade my account to a real estate office.\nName: {name}\nAccount ID: {id}'**
  String realEstateOfficeRequestMessage(String name, String id);

  /// Title for property expiry notification
  ///
  /// In en, this message translates to:
  /// **'Property Expiring Soon!'**
  String get propertyExpiringSoonTitle;

  /// Message for property expiry notification
  ///
  /// In en, this message translates to:
  /// **'Your listing \"{title}\" will expire in {days} days. Renew it now to keep it active!'**
  String propertyExpiringSoonMessage(String title, int days);

  /// Terms and conditions text
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
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
  /// **'Error picking image: {error}'**
  String errorPickingImage(Object error);

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
  /// **'Sort by'**
  String get sortBy;

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

  /// No description provided for @markAllAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllAsRead;

  /// No description provided for @noNotificationsYet.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotificationsYet;

  /// No description provided for @notificationsDiscoverySubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll notify you when something important happens'**
  String get notificationsDiscoverySubtitle;

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

  /// No description provided for @editDetails.
  ///
  /// In en, this message translates to:
  /// **'Edit Details'**
  String get editDetails;

  /// No description provided for @unpublish.
  ///
  /// In en, this message translates to:
  /// **'Unpublish'**
  String get unpublish;

  /// No description provided for @publishNow.
  ///
  /// In en, this message translates to:
  /// **'Publish Now'**
  String get publishNow;

  /// No description provided for @publish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get publish;

  /// No description provided for @renewListing.
  ///
  /// In en, this message translates to:
  /// **'Renew Listing'**
  String get renewListing;

  /// No description provided for @deleteForever.
  ///
  /// In en, this message translates to:
  /// **'Delete Forever'**
  String get deleteForever;

  /// No description provided for @viewsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} views'**
  String viewsCount(int count);

  /// No description provided for @publishedStatus.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get publishedStatus;

  /// No description provided for @unpublishedStatus.
  ///
  /// In en, this message translates to:
  /// **'Unpublished'**
  String get unpublishedStatus;

  /// No description provided for @boostedStatus.
  ///
  /// In en, this message translates to:
  /// **'BOOSTED'**
  String get boostedStatus;

  /// No description provided for @expiredStatus.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expiredStatus;

  /// No description provided for @daysLeftCount.
  ///
  /// In en, this message translates to:
  /// **'{count} days left'**
  String daysLeftCount(int count);

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @renew.
  ///
  /// In en, this message translates to:
  /// **'Renew'**
  String get renew;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @unpublishSuccess.
  ///
  /// In en, this message translates to:
  /// **'Property unpublished successfully'**
  String get unpublishSuccess;

  /// No description provided for @unpublishFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to unpublish property'**
  String get unpublishFailed;

  /// No description provided for @publishSuccess.
  ///
  /// In en, this message translates to:
  /// **'Property published successfully'**
  String get publishSuccess;

  /// No description provided for @publishFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to publish property'**
  String get publishFailed;

  /// No description provided for @renewSuccess.
  ///
  /// In en, this message translates to:
  /// **'Property renewed successfully'**
  String get renewSuccess;

  /// No description provided for @renewFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to renew property'**
  String get renewFailed;

  /// No description provided for @deleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Property deleted successfully'**
  String get deleteSuccess;

  /// No description provided for @deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete property'**
  String get deleteFailed;

  /// No description provided for @deletePropertyTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Property'**
  String get deletePropertyTitle;

  /// No description provided for @deletePropertyConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this property? This action cannot be undone.'**
  String get deletePropertyConfirm;

  /// No description provided for @neighborhood.
  ///
  /// In en, this message translates to:
  /// **'Neighborhood'**
  String get neighborhood;

  /// No description provided for @kitchens.
  ///
  /// In en, this message translates to:
  /// **'Kitchens'**
  String get kitchens;

  /// No description provided for @sizeRange.
  ///
  /// In en, this message translates to:
  /// **'Size Range'**
  String get sizeRange;

  /// No description provided for @priceRangeLyd.
  ///
  /// In en, this message translates to:
  /// **'Price Range (LYD)'**
  String get priceRangeLyd;

  /// No description provided for @bedroomsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Bedrooms'**
  String bedroomsCount(int count);

  /// No description provided for @bathroomsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Bathrooms'**
  String bathroomsCount(int count);

  /// No description provided for @typeApartment.
  ///
  /// In en, this message translates to:
  /// **'Apartment'**
  String get typeApartment;

  /// No description provided for @typeHouse.
  ///
  /// In en, this message translates to:
  /// **'House'**
  String get typeHouse;

  /// No description provided for @typeVilla.
  ///
  /// In en, this message translates to:
  /// **'Villa'**
  String get typeVilla;

  /// No description provided for @typeVacationHome.
  ///
  /// In en, this message translates to:
  /// **'Vacation Home'**
  String get typeVacationHome;

  /// No description provided for @typeTownhouse.
  ///
  /// In en, this message translates to:
  /// **'Townhouse'**
  String get typeTownhouse;

  /// No description provided for @typeStudio.
  ///
  /// In en, this message translates to:
  /// **'Studio'**
  String get typeStudio;

  /// No description provided for @typePenthouse.
  ///
  /// In en, this message translates to:
  /// **'Penthouse'**
  String get typePenthouse;

  /// No description provided for @typeCommercial.
  ///
  /// In en, this message translates to:
  /// **'Commercial'**
  String get typeCommercial;

  /// No description provided for @typeLand.
  ///
  /// In en, this message translates to:
  /// **'Land'**
  String get typeLand;

  /// No description provided for @statusForSale.
  ///
  /// In en, this message translates to:
  /// **'For Sale'**
  String get statusForSale;

  /// No description provided for @statusForRent.
  ///
  /// In en, this message translates to:
  /// **'For Rent'**
  String get statusForRent;

  /// No description provided for @statusSold.
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get statusSold;

  /// No description provided for @statusRented.
  ///
  /// In en, this message translates to:
  /// **'Rented'**
  String get statusRented;

  /// No description provided for @condNewConstruction.
  ///
  /// In en, this message translates to:
  /// **'New Construction'**
  String get condNewConstruction;

  /// No description provided for @condExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get condExcellent;

  /// No description provided for @condGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get condGood;

  /// No description provided for @condFair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get condFair;

  /// No description provided for @condNeedsRenovation.
  ///
  /// In en, this message translates to:
  /// **'Needs Renovation'**
  String get condNeedsRenovation;

  /// No description provided for @whatTypeProperty.
  ///
  /// In en, this message translates to:
  /// **'What type of property?'**
  String get whatTypeProperty;

  /// No description provided for @selectCategoryDescription.
  ///
  /// In en, this message translates to:
  /// **'Select the category that best describes your property'**
  String get selectCategoryDescription;

  /// No description provided for @listingType.
  ///
  /// In en, this message translates to:
  /// **'Listing Type'**
  String get listingType;

  /// No description provided for @tellUsAboutProperty.
  ///
  /// In en, this message translates to:
  /// **'Tell us about your property'**
  String get tellUsAboutProperty;

  /// No description provided for @addCompellingDescription.
  ///
  /// In en, this message translates to:
  /// **'Add a compelling title and description'**
  String get addCompellingDescription;

  /// No description provided for @titleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Beautiful 3BR Apartment in City Center'**
  String get titleHint;

  /// No description provided for @descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Describe your property features, neighborhood, and what makes it special...'**
  String get descriptionHint;

  /// No description provided for @proTip.
  ///
  /// In en, this message translates to:
  /// **'Pro Tip'**
  String get proTip;

  /// No description provided for @detailedDescriptionTip.
  ///
  /// In en, this message translates to:
  /// **'Properties with detailed descriptions get 40% more views!'**
  String get detailedDescriptionTip;

  /// No description provided for @whereIsProperty.
  ///
  /// In en, this message translates to:
  /// **'Where is your property?'**
  String get whereIsProperty;

  /// No description provided for @helpBuyersFind.
  ///
  /// In en, this message translates to:
  /// **'Help buyers find your property easily'**
  String get helpBuyersFind;

  /// No description provided for @streetAddress.
  ///
  /// In en, this message translates to:
  /// **'Street Address'**
  String get streetAddress;

  /// No description provided for @addressHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., 123 Main Street'**
  String get addressHint;

  /// No description provided for @roomsSizePricing.
  ///
  /// In en, this message translates to:
  /// **'Rooms, size, and pricing'**
  String get roomsSizePricing;

  /// No description provided for @salePriceLyd.
  ///
  /// In en, this message translates to:
  /// **'Sale Price (LYD)'**
  String get salePriceLyd;

  /// No description provided for @monthlyRent.
  ///
  /// In en, this message translates to:
  /// **'Monthly Rent'**
  String get monthlyRent;

  /// No description provided for @dailyRent.
  ///
  /// In en, this message translates to:
  /// **'Daily Rent'**
  String get dailyRent;

  /// No description provided for @enterMonthlyRent.
  ///
  /// In en, this message translates to:
  /// **'Enter monthly rent'**
  String get enterMonthlyRent;

  /// No description provided for @enterDailyRent.
  ///
  /// In en, this message translates to:
  /// **'Enter daily rent'**
  String get enterDailyRent;

  /// No description provided for @beds.
  ///
  /// In en, this message translates to:
  /// **'Beds'**
  String get beds;

  /// No description provided for @baths.
  ///
  /// In en, this message translates to:
  /// **'Baths'**
  String get baths;

  /// No description provided for @landSizeM2.
  ///
  /// In en, this message translates to:
  /// **'Land Size (m²)'**
  String get landSizeM2;

  /// No description provided for @buildingSizeM2.
  ///
  /// In en, this message translates to:
  /// **'Building Size (m²)'**
  String get buildingSizeM2;

  /// No description provided for @enterSizeM2.
  ///
  /// In en, this message translates to:
  /// **'Enter size in square meters'**
  String get enterSizeM2;

  /// No description provided for @floors.
  ///
  /// In en, this message translates to:
  /// **'Floors'**
  String get floors;

  /// No description provided for @yearBuilt.
  ///
  /// In en, this message translates to:
  /// **'Year Built'**
  String get yearBuilt;

  /// No description provided for @discardChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard Changes?'**
  String get discardChangesTitle;

  /// No description provided for @discardChangesMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to leave? Your progress will be lost.'**
  String get discardChangesMessage;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @stepProgress.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String stepProgress(int current, int total);

  /// No description provided for @editProperty.
  ///
  /// In en, this message translates to:
  /// **'Edit Property'**
  String get editProperty;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @updateProperty.
  ///
  /// In en, this message translates to:
  /// **'Update Property'**
  String get updateProperty;

  /// No description provided for @publishProperty.
  ///
  /// In en, this message translates to:
  /// **'Publish Property'**
  String get publishProperty;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @photosAdded.
  ///
  /// In en, this message translates to:
  /// **'photos added'**
  String get photosAdded;

  /// No description provided for @photoTipsDescription.
  ///
  /// In en, this message translates to:
  /// **'• Use good lighting\n• Show all rooms\n• Include exterior photos'**
  String get photoTipsDescription;

  /// No description provided for @indoorFeatures.
  ///
  /// In en, this message translates to:
  /// **'Indoor Features'**
  String get indoorFeatures;

  /// No description provided for @outdoorFeatures.
  ///
  /// In en, this message translates to:
  /// **'Outdoor Features'**
  String get outdoorFeatures;

  /// No description provided for @buildingFeatures.
  ///
  /// In en, this message translates to:
  /// **'Building Features'**
  String get buildingFeatures;

  /// No description provided for @nearby.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get nearby;

  /// No description provided for @minImagesError.
  ///
  /// In en, this message translates to:
  /// **'Please upload at least 4 photos. You have uploaded {count} photo(s).'**
  String minImagesError(int count);

  /// No description provided for @uploadingImages.
  ///
  /// In en, this message translates to:
  /// **'Uploading {count} images...'**
  String uploadingImages(int count);

  /// No description provided for @insufficientBalance.
  ///
  /// In en, this message translates to:
  /// **'Insufficient balance. You need {price} {currency} but only have {balance} {currency}'**
  String insufficientBalance(
      String amount, Object balance, Object currency, Object price);

  /// No description provided for @propertyUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Property updated successfully!'**
  String get propertyUpdatedSuccessfully;

  /// No description provided for @propertyPublishedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Property published successfully!'**
  String get propertyPublishedSuccessfully;

  /// No description provided for @boostActivated.
  ///
  /// In en, this message translates to:
  /// **'Boost Activated!'**
  String get boostActivated;

  /// No description provided for @selectPackage.
  ///
  /// In en, this message translates to:
  /// **'Select Package'**
  String get selectPackage;

  /// No description provided for @chooseBoostPackage.
  ///
  /// In en, this message translates to:
  /// **'Choose your Boost Package'**
  String get chooseBoostPackage;

  /// No description provided for @plusBoost.
  ///
  /// In en, this message translates to:
  /// **'Plus Boost'**
  String get plusBoost;

  /// No description provided for @emeraldBoost.
  ///
  /// In en, this message translates to:
  /// **'Emerald Boost'**
  String get emeraldBoost;

  /// No description provided for @eliteBoost.
  ///
  /// In en, this message translates to:
  /// **'Elite Boost'**
  String get eliteBoost;

  /// No description provided for @premiumBoost.
  ///
  /// In en, this message translates to:
  /// **'Premium Boost'**
  String get premiumBoost;

  /// No description provided for @durationOneDay.
  ///
  /// In en, this message translates to:
  /// **'1 Day'**
  String get durationOneDay;

  /// No description provided for @durationThreeDays.
  ///
  /// In en, this message translates to:
  /// **'3 Days'**
  String get durationThreeDays;

  /// No description provided for @durationSevenDays.
  ///
  /// In en, this message translates to:
  /// **'7 Days'**
  String get durationSevenDays;

  /// No description provided for @durationThirtyDays.
  ///
  /// In en, this message translates to:
  /// **'30 Days'**
  String get durationThirtyDays;

  /// No description provided for @rooms.
  ///
  /// In en, this message translates to:
  /// **'Rooms'**
  String get rooms;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @packageSelected.
  ///
  /// In en, this message translates to:
  /// **'package selected for your property'**
  String get packageSelected;

  /// No description provided for @changePackage.
  ///
  /// In en, this message translates to:
  /// **'Change Package'**
  String get changePackage;

  /// No description provided for @upgradeBoost.
  ///
  /// In en, this message translates to:
  /// **'Upgrade Your Ad'**
  String get upgradeBoost;

  /// No description provided for @boostDescription.
  ///
  /// In en, this message translates to:
  /// **'Get maximum visibility and reach more buyers instantly'**
  String get boostDescription;

  /// No description provided for @eliteBranding.
  ///
  /// In en, this message translates to:
  /// **'Elite branding'**
  String get eliteBranding;

  /// No description provided for @dedicatedSupport.
  ///
  /// In en, this message translates to:
  /// **'Dedicated support'**
  String get dedicatedSupport;

  /// No description provided for @packageCleared.
  ///
  /// In en, this message translates to:
  /// **'Package selection cleared'**
  String get packageCleared;

  /// No description provided for @loginRequired.
  ///
  /// In en, this message translates to:
  /// **'Login Required'**
  String get loginRequired;

  /// No description provided for @pleaseLoginToAddProperty.
  ///
  /// In en, this message translates to:
  /// **'Please login to add properties to the platform'**
  String get pleaseLoginToAddProperty;

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get backToHome;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @packageSelectedWithPrice.
  ///
  /// In en, this message translates to:
  /// **'Package Selected: {package} ({price} LYD)'**
  String packageSelectedWithPrice(Object package, Object price);

  /// No description provided for @clearSelection.
  ///
  /// In en, this message translates to:
  /// **'Clear Selection'**
  String get clearSelection;

  /// No description provided for @selectedWithPrice.
  ///
  /// In en, this message translates to:
  /// **'Selected: {package} ({price} LYD)'**
  String selectedWithPrice(Object package, Object price);

  /// No description provided for @basicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic Info'**
  String get basicInfo;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @amenities.
  ///
  /// In en, this message translates to:
  /// **'Amenities'**
  String get amenities;

  /// No description provided for @photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photos;

  /// No description provided for @showItOff.
  ///
  /// In en, this message translates to:
  /// **'Show it off'**
  String get showItOff;

  /// No description provided for @condition.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get condition;

  /// No description provided for @selectCity.
  ///
  /// In en, this message translates to:
  /// **'Select City'**
  String get selectCity;

  /// No description provided for @selectCityFirst.
  ///
  /// In en, this message translates to:
  /// **'Select City First'**
  String get selectCityFirst;

  /// No description provided for @selectNeighborhood.
  ///
  /// In en, this message translates to:
  /// **'Select Neighborhood'**
  String get selectNeighborhood;

  /// No description provided for @pleaseSelectCity.
  ///
  /// In en, this message translates to:
  /// **'Please select a city'**
  String get pleaseSelectCity;

  /// No description provided for @pleaseSelectNeighborhood.
  ///
  /// In en, this message translates to:
  /// **'Please select a neighborhood'**
  String get pleaseSelectNeighborhood;

  /// No description provided for @pleaseEnterAddress.
  ///
  /// In en, this message translates to:
  /// **'Please enter an address'**
  String get pleaseEnterAddress;

  /// No description provided for @pleaseEnterMonthlyRent.
  ///
  /// In en, this message translates to:
  /// **'Please enter monthly rent'**
  String get pleaseEnterMonthlyRent;

  /// No description provided for @pleaseEnterDailyRent.
  ///
  /// In en, this message translates to:
  /// **'Please enter daily rent'**
  String get pleaseEnterDailyRent;

  /// No description provided for @pleaseEnterLandSize.
  ///
  /// In en, this message translates to:
  /// **'Please enter land size'**
  String get pleaseEnterLandSize;

  /// No description provided for @pleaseEnterBuildingSize.
  ///
  /// In en, this message translates to:
  /// **'Please enter building size'**
  String get pleaseEnterBuildingSize;

  /// No description provided for @pleaseAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Please add at least one photo'**
  String get pleaseAddPhoto;

  /// No description provided for @heating.
  ///
  /// In en, this message translates to:
  /// **'Heating'**
  String get heating;

  /// No description provided for @waterWell.
  ///
  /// In en, this message translates to:
  /// **'Water Well'**
  String get waterWell;

  /// No description provided for @petFriendly.
  ///
  /// In en, this message translates to:
  /// **'Pet Friendly'**
  String get petFriendly;

  /// No description provided for @nearbySchools.
  ///
  /// In en, this message translates to:
  /// **'Nearby Schools'**
  String get nearbySchools;

  /// No description provided for @nearbyHospitals.
  ///
  /// In en, this message translates to:
  /// **'Nearby Hospitals'**
  String get nearbyHospitals;

  /// No description provided for @nearbyShopping.
  ///
  /// In en, this message translates to:
  /// **'Nearby Shopping'**
  String get nearbyShopping;

  /// No description provided for @publicTransport.
  ///
  /// In en, this message translates to:
  /// **'Public Transport'**
  String get publicTransport;

  /// No description provided for @listingExpiry.
  ///
  /// In en, this message translates to:
  /// **'Listing Expiry'**
  String get listingExpiry;

  /// No description provided for @expiresToday.
  ///
  /// In en, this message translates to:
  /// **'Expires Today'**
  String get expiresToday;

  /// No description provided for @listingWillExpireIn.
  ///
  /// In en, this message translates to:
  /// **'Listing will expire in {time}'**
  String listingWillExpireIn(Object time);

  /// No description provided for @openInGoogleMaps.
  ///
  /// In en, this message translates to:
  /// **'Open in Google Maps'**
  String get openInGoogleMaps;

  /// No description provided for @daysSuffix.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get daysSuffix;

  /// No description provided for @hoursSuffix.
  ///
  /// In en, this message translates to:
  /// **'hours'**
  String get hoursSuffix;

  /// No description provided for @minutesSuffix.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get minutesSuffix;

  /// No description provided for @now.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get now;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @whatsApp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsApp;

  /// No description provided for @sqmSuffix.
  ///
  /// In en, this message translates to:
  /// **'m²'**
  String get sqmSuffix;

  /// No description provided for @propertyRenewedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Property renewed successfully'**
  String get propertyRenewedSuccessfully;

  /// No description provided for @interestedInProperty.
  ///
  /// In en, this message translates to:
  /// **'I\'m interested in this property: {title}'**
  String interestedInProperty(Object title);

  /// No description provided for @phoneNumberNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Phone number not available'**
  String get phoneNumberNotAvailable;

  /// No description provided for @whatsAppNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp not available'**
  String get whatsAppNotAvailable;

  /// No description provided for @starter.
  ///
  /// In en, this message translates to:
  /// **'Starter'**
  String get starter;

  /// No description provided for @starterDesc.
  ///
  /// In en, this message translates to:
  /// **'Perfect for getting started (60 Days)'**
  String get starterDesc;

  /// No description provided for @professional.
  ///
  /// In en, this message translates to:
  /// **'Professional'**
  String get professional;

  /// No description provided for @professionalDesc.
  ///
  /// In en, this message translates to:
  /// **'Ideal for growing businesses (60 Days)'**
  String get professionalDesc;

  /// No description provided for @enterprise.
  ///
  /// In en, this message translates to:
  /// **'Enterprise'**
  String get enterprise;

  /// No description provided for @enterpriseDesc.
  ///
  /// In en, this message translates to:
  /// **'For large-scale operations (60 Days)'**
  String get enterpriseDesc;

  /// No description provided for @elite.
  ///
  /// In en, this message translates to:
  /// **'Elite'**
  String get elite;

  /// No description provided for @eliteDesc.
  ///
  /// In en, this message translates to:
  /// **'Unlimited possibilities (60 Days)'**
  String get eliteDesc;

  /// No description provided for @premiumSlots.
  ///
  /// In en, this message translates to:
  /// **'Premium Slots'**
  String get premiumSlots;

  /// No description provided for @scaleYourBusiness.
  ///
  /// In en, this message translates to:
  /// **'Scale your real estate business'**
  String get scaleYourBusiness;

  /// No description provided for @currentLimitLabel.
  ///
  /// In en, this message translates to:
  /// **'CURRENT LIMIT'**
  String get currentLimitLabel;

  /// No description provided for @usedSlotsLabel.
  ///
  /// In en, this message translates to:
  /// **'USED SLOTS'**
  String get usedSlotsLabel;

  /// No description provided for @currentActivePackages.
  ///
  /// In en, this message translates to:
  /// **'Current Active Packages'**
  String get currentActivePackages;

  /// No description provided for @chooseNewPackage.
  ///
  /// In en, this message translates to:
  /// **'Choose New Package'**
  String get chooseNewPackage;

  /// No description provided for @mostPopular.
  ///
  /// In en, this message translates to:
  /// **'MOST POPULAR'**
  String get mostPopular;

  /// No description provided for @orderTotal.
  ///
  /// In en, this message translates to:
  /// **'Order Total'**
  String get orderTotal;

  /// No description provided for @billedOnce.
  ///
  /// In en, this message translates to:
  /// **'Billed once'**
  String get billedOnce;

  /// No description provided for @pleaseSelectPackage.
  ///
  /// In en, this message translates to:
  /// **'Please select a package'**
  String get pleaseSelectPackage;

  /// No description provided for @amountAddedToWallet.
  ///
  /// In en, this message translates to:
  /// **'{amount} LYD has been added to your wallet.'**
  String amountAddedToWallet(Object amount);

  /// No description provided for @testCards.
  ///
  /// In en, this message translates to:
  /// **'Test Cards'**
  String get testCards;

  /// No description provided for @boosted.
  ///
  /// In en, this message translates to:
  /// **'Boosted'**
  String get boosted;

  /// No description provided for @boostExpired.
  ///
  /// In en, this message translates to:
  /// **'Boost expired'**
  String get boostExpired;

  /// No description provided for @unlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get unlimited;

  /// No description provided for @unknownUser.
  ///
  /// In en, this message translates to:
  /// **'Unknown User'**
  String get unknownUser;

  /// No description provided for @propertyOwner.
  ///
  /// In en, this message translates to:
  /// **'Property Owner'**
  String get propertyOwner;

  /// No description provided for @listingExpired.
  ///
  /// In en, this message translates to:
  /// **'Listing Expired'**
  String get listingExpired;

  /// No description provided for @listingExpiredDesc.
  ///
  /// In en, this message translates to:
  /// **'This property is no longer visible to the public.'**
  String get listingExpiredDesc;

  /// No description provided for @renewNow.
  ///
  /// In en, this message translates to:
  /// **'Renew now'**
  String get renewNow;

  /// No description provided for @area.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get area;

  /// No description provided for @securityDeposit.
  ///
  /// In en, this message translates to:
  /// **'Security Deposit'**
  String get securityDeposit;

  /// No description provided for @sharePropertyText.
  ///
  /// In en, this message translates to:
  /// **'Check out this property: {title} in {city}!'**
  String sharePropertyText(Object city, Object title);

  /// No description provided for @shareProfileText.
  ///
  /// In en, this message translates to:
  /// **'Check out this profile on Dary: {name}'**
  String shareProfileText(Object name);

  /// No description provided for @viewProfile.
  ///
  /// In en, this message translates to:
  /// **'View profile'**
  String get viewProfile;

  /// No description provided for @listed.
  ///
  /// In en, this message translates to:
  /// **'Listed'**
  String get listed;

  /// No description provided for @messageSeller.
  ///
  /// In en, this message translates to:
  /// **'Message Seller'**
  String get messageSeller;

  /// No description provided for @manageBoost.
  ///
  /// In en, this message translates to:
  /// **'Manage Boost'**
  String get manageBoost;

  /// No description provided for @failedToCreateConversation.
  ///
  /// In en, this message translates to:
  /// **'Failed to create conversation. Please try again.'**
  String get failedToCreateConversation;

  /// No description provided for @failedToStartConversation.
  ///
  /// In en, this message translates to:
  /// **'Failed to start conversation: {error}'**
  String failedToStartConversation(Object error);

  /// No description provided for @starterPackage.
  ///
  /// In en, this message translates to:
  /// **'Starter'**
  String get starterPackage;

  /// No description provided for @professionalPackage.
  ///
  /// In en, this message translates to:
  /// **'Professional'**
  String get professionalPackage;

  /// No description provided for @enterprisePackage.
  ///
  /// In en, this message translates to:
  /// **'Enterprise'**
  String get enterprisePackage;

  /// No description provided for @elitePackage.
  ///
  /// In en, this message translates to:
  /// **'Elite'**
  String get elitePackage;

  /// No description provided for @scaleBusiness.
  ///
  /// In en, this message translates to:
  /// **'Scale your real estate business'**
  String get scaleBusiness;

  /// No description provided for @currentLimit.
  ///
  /// In en, this message translates to:
  /// **'CURRENT LIMIT'**
  String get currentLimit;

  /// No description provided for @usedSlots.
  ///
  /// In en, this message translates to:
  /// **'USED SLOTS'**
  String get usedSlots;

  /// No description provided for @expiresInDays.
  ///
  /// In en, this message translates to:
  /// **'Expires in {days} days'**
  String expiresInDays(String days);

  /// No description provided for @slots.
  ///
  /// In en, this message translates to:
  /// **'slots'**
  String get slots;

  /// No description provided for @sixtyDays.
  ///
  /// In en, this message translates to:
  /// **'60 Days'**
  String get sixtyDays;

  /// No description provided for @newLimit.
  ///
  /// In en, this message translates to:
  /// **'New Limit'**
  String get newLimit;

  /// No description provided for @packagesExpiryWarning.
  ///
  /// In en, this message translates to:
  /// **'Packages expire after 60 days. Properties will be unpublished (but not deleted) when the package expires until new slots are purchased.'**
  String get packagesExpiryWarning;

  /// No description provided for @completePurchase.
  ///
  /// In en, this message translates to:
  /// **'Complete Purchase'**
  String get completePurchase;

  /// No description provided for @durationDays.
  ///
  /// In en, this message translates to:
  /// **'{days} Days'**
  String durationDays(String days);

  /// No description provided for @shortTermPromo.
  ///
  /// In en, this message translates to:
  /// **'Perfect for short-term promotion'**
  String get shortTermPromo;

  /// No description provided for @quickPromo.
  ///
  /// In en, this message translates to:
  /// **'Perfect for quick promotion'**
  String get quickPromo;

  /// No description provided for @testingWaters.
  ///
  /// In en, this message translates to:
  /// **'Great for testing the market'**
  String get testingWaters;

  /// No description provided for @bestValueSerious.
  ///
  /// In en, this message translates to:
  /// **'Best value for serious sellers'**
  String get bestValueSerious;

  /// No description provided for @buyPackage.
  ///
  /// In en, this message translates to:
  /// **'Buy {duration}'**
  String buyPackage(String duration);

  /// No description provided for @perDay.
  ///
  /// In en, this message translates to:
  /// **'/day'**
  String get perDay;

  /// No description provided for @perMonth.
  ///
  /// In en, this message translates to:
  /// **'/month'**
  String get perMonth;

  /// No description provided for @boostedWithTime.
  ///
  /// In en, this message translates to:
  /// **'Boosted ({time} left)'**
  String boostedWithTime(String time);

  /// No description provided for @hoursShort.
  ///
  /// In en, this message translates to:
  /// **'h'**
  String get hoursShort;

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'m'**
  String get minutesShort;

  /// No description provided for @addedToWallet.
  ///
  /// In en, this message translates to:
  /// **'{amount} has been added to your wallet.'**
  String addedToWallet(Object amount);

  /// No description provided for @payWithCard.
  ///
  /// In en, this message translates to:
  /// **'Pay with Card'**
  String get payWithCard;

  /// No description provided for @amountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount: {amount}'**
  String amountLabel(Object amount);

  /// No description provided for @enterCardNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter card number'**
  String get enterCardNumber;

  /// No description provided for @cardTooShort.
  ///
  /// In en, this message translates to:
  /// **'Card number must be at least 13 digits'**
  String get cardTooShort;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredField;

  /// No description provided for @invalidFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid format'**
  String get invalidFormat;

  /// No description provided for @tooShort.
  ///
  /// In en, this message translates to:
  /// **'Too short'**
  String get tooShort;

  /// No description provided for @enterCardholderName.
  ///
  /// In en, this message translates to:
  /// **'Please enter cardholder name'**
  String get enterCardholderName;

  /// No description provided for @testCardsInfo.
  ///
  /// In en, this message translates to:
  /// **'Success: 4242 4242 4242 4242\nDecline: 4000 0000 0000 0002\nExpired: 4000 0000 0000 0069'**
  String get testCardsInfo;

  /// No description provided for @loginToContactSeller.
  ///
  /// In en, this message translates to:
  /// **'Please log in to contact the seller.'**
  String get loginToContactSeller;

  /// No description provided for @viewMoreDetails.
  ///
  /// In en, this message translates to:
  /// **'View more details'**
  String get viewMoreDetails;

  /// No description provided for @noPhoneNumberAvailable.
  ///
  /// In en, this message translates to:
  /// **'No phone number available'**
  String get noPhoneNumberAvailable;

  /// No description provided for @whatsappMessageIntro.
  ///
  /// In en, this message translates to:
  /// **'Hello! I am interested in this property:'**
  String get whatsappMessageIntro;

  /// No description provided for @addedToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Added to favorites'**
  String get addedToFavorites;

  /// No description provided for @removedFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Removed from favorites'**
  String get removedFromFavorites;

  /// No description provided for @cannotMakePhoneCall.
  ///
  /// In en, this message translates to:
  /// **'Cannot make phone call from this device'**
  String get cannotMakePhoneCall;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @boostProperty.
  ///
  /// In en, this message translates to:
  /// **'Boost Property'**
  String get boostProperty;

  /// No description provided for @boostPropertyDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose a premium package to boost your property visibility.'**
  String get boostPropertyDescription;

  /// No description provided for @viewPackages.
  ///
  /// In en, this message translates to:
  /// **'View Packages'**
  String get viewPackages;

  /// No description provided for @airConditioning.
  ///
  /// In en, this message translates to:
  /// **'Air Conditioning'**
  String get airConditioning;

  /// No description provided for @currencyLYD.
  ///
  /// In en, this message translates to:
  /// **'LYD'**
  String get currencyLYD;

  /// No description provided for @daysShort.
  ///
  /// In en, this message translates to:
  /// **'d'**
  String get daysShort;

  /// No description provided for @whatsAppShort.
  ///
  /// In en, this message translates to:
  /// **'WA'**
  String get whatsAppShort;

  /// No description provided for @timeAgoYears.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 year ago} other{{count} years ago}}'**
  String timeAgoYears(num count);

  /// No description provided for @timeAgoMonths.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 month ago} other{{count} months ago}}'**
  String timeAgoMonths(num count);

  /// No description provided for @timeAgoDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day ago} other{{count} days ago}}'**
  String timeAgoDays(num count);

  /// No description provided for @timeAgoHours.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour ago} other{{count} hours ago}}'**
  String timeAgoHours(num count);

  /// No description provided for @timeAgoMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute ago} other{{count} minutes ago}}'**
  String timeAgoMinutes(num count);

  /// No description provided for @timeAgoSeconds.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Just now} other{{count} seconds ago}}'**
  String timeAgoSeconds(num count);

  /// No description provided for @welcomeToDary.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Dary'**
  String get welcomeToDary;

  /// No description provided for @yourSmartPropertyCompanion.
  ///
  /// In en, this message translates to:
  /// **'Your smart property companion'**
  String get yourSmartPropertyCompanion;

  /// No description provided for @emailOrPhone.
  ///
  /// In en, this message translates to:
  /// **'Email or Phone'**
  String get emailOrPhone;

  /// No description provided for @enterEmailOrPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter your email or phone'**
  String get enterEmailOrPhone;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @orContinueWith.
  ///
  /// In en, this message translates to:
  /// **'Or continue with'**
  String get orContinueWith;

  /// No description provided for @google.
  ///
  /// In en, this message translates to:
  /// **'Google'**
  String get google;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @signingInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Signing in with Google...'**
  String get signingInWithGoogle;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @joinDaryFindDreamHome.
  ///
  /// In en, this message translates to:
  /// **'Join Dary and find your dream home'**
  String get joinDaryFindDreamHome;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @confirmYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get confirmYourPassword;

  /// No description provided for @enterPasswordValidation.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get enterPasswordValidation;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordMinLength;

  /// No description provided for @passwordNeedsCapital.
  ///
  /// In en, this message translates to:
  /// **'Must contain at least one capital letter'**
  String get passwordNeedsCapital;

  /// No description provided for @passwordNeedsNumber.
  ///
  /// In en, this message translates to:
  /// **'Must contain at least one number'**
  String get passwordNeedsNumber;

  /// No description provided for @passwordNeedsSymbol.
  ///
  /// In en, this message translates to:
  /// **'Must contain at least one symbol'**
  String get passwordNeedsSymbol;

  /// No description provided for @agreeToTermsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'I agree to the Terms & Privacy Policy'**
  String get agreeToTermsPrivacy;

  /// No description provided for @orSignUpWith.
  ///
  /// In en, this message translates to:
  /// **'Or sign up with'**
  String get orSignUpWith;

  /// No description provided for @googleAccount.
  ///
  /// In en, this message translates to:
  /// **'Google Account'**
  String get googleAccount;

  /// No description provided for @activeListingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Active Listings'**
  String get activeListingsLabel;

  /// No description provided for @upgradeAd.
  ///
  /// In en, this message translates to:
  /// **'Upgrade Ad'**
  String get upgradeAd;

  /// No description provided for @moreSlots.
  ///
  /// In en, this message translates to:
  /// **'More Slots'**
  String get moreSlots;

  /// No description provided for @boostAd.
  ///
  /// In en, this message translates to:
  /// **'Boost Ad'**
  String get boostAd;

  /// No description provided for @myFavorites.
  ///
  /// In en, this message translates to:
  /// **'My Favorites'**
  String get myFavorites;

  /// No description provided for @officeDashboard.
  ///
  /// In en, this message translates to:
  /// **'Office Dashboard'**
  String get officeDashboard;

  /// No description provided for @allCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'All caught up!'**
  String get allCaughtUp;

  /// No description provided for @localCreditCard.
  ///
  /// In en, this message translates to:
  /// **'Local credit card'**
  String get localCreditCard;

  /// No description provided for @feePercentage.
  ///
  /// In en, this message translates to:
  /// **'Fee percentage {fee}'**
  String feePercentage(Object fee);

  /// No description provided for @transactionFeePercentage.
  ///
  /// In en, this message translates to:
  /// **'Fee Percentage'**
  String get transactionFeePercentage;

  /// No description provided for @topUp.
  ///
  /// In en, this message translates to:
  /// **'Top up'**
  String get topUp;

  /// No description provided for @pleaseEnterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get pleaseEnterValidAmount;

  /// No description provided for @daryVouchers.
  ///
  /// In en, this message translates to:
  /// **'DARY Vouchers'**
  String get daryVouchers;

  /// No description provided for @enter13DigitCode.
  ///
  /// In en, this message translates to:
  /// **'Enter 13-digit code'**
  String get enter13DigitCode;

  /// No description provided for @whereToBuyVouchers.
  ///
  /// In en, this message translates to:
  /// **'Where to buy vouchers / أين يتم شراء القسائم ؟'**
  String get whereToBuyVouchers;

  /// No description provided for @purchaseFromStore.
  ///
  /// In en, this message translates to:
  /// **'• Purchase from any store with Umbrella or Anis POS terminals.'**
  String get purchaseFromStore;

  /// No description provided for @purchaseFromStoreAr.
  ///
  /// In en, this message translates to:
  /// **'• يمكنك الشراء من أي محل تتوفر لديه ماكينة دفع (المظلة) أو (أنيس).'**
  String get purchaseFromStoreAr;

  /// No description provided for @directSupport.
  ///
  /// In en, this message translates to:
  /// **'Direct Support / الدعم الفني'**
  String get directSupport;

  /// No description provided for @customerSupport.
  ///
  /// In en, this message translates to:
  /// **'Customer Support / الدعم الفني'**
  String get customerSupport;

  /// No description provided for @ibanCopied.
  ///
  /// In en, this message translates to:
  /// **'IBAN copied to clipboard'**
  String get ibanCopied;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @selectChargeMethod.
  ///
  /// In en, this message translates to:
  /// **'Select charge method'**
  String get selectChargeMethod;

  /// No description provided for @pleaseEnterValid13DigitCode.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid 13-digit code'**
  String get pleaseEnterValid13DigitCode;

  /// No description provided for @pleaseLoginToRecharge.
  ///
  /// In en, this message translates to:
  /// **'Please login to recharge your wallet'**
  String get pleaseLoginToRecharge;

  /// No description provided for @walletRechargedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Wallet recharged successfully! New balance: {balance} {currency}'**
  String walletRechargedSuccessfully(Object balance, Object currency);

  /// No description provided for @invalidRechargeCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid recharge code. Please try again.'**
  String get invalidRechargeCode;

  /// No description provided for @errorProcessingRecharge.
  ///
  /// In en, this message translates to:
  /// **'Error processing recharge: {error}'**
  String errorProcessingRecharge(Object error);

  /// No description provided for @couldNotLaunchWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Could not launch WhatsApp'**
  String get couldNotLaunchWhatsApp;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// No description provided for @recentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get recentTransactions;

  /// No description provided for @transactionRecharge.
  ///
  /// In en, this message translates to:
  /// **'Recharge'**
  String get transactionRecharge;

  /// No description provided for @transactionPurchase.
  ///
  /// In en, this message translates to:
  /// **'Purchase'**
  String get transactionPurchase;

  /// No description provided for @transactionBoost.
  ///
  /// In en, this message translates to:
  /// **'Boost: {name}'**
  String transactionBoost(String name);

  /// No description provided for @transactionRefund.
  ///
  /// In en, this message translates to:
  /// **'Refund - {reason}'**
  String transactionRefund(Object reason);

  /// No description provided for @transactionFee.
  ///
  /// In en, this message translates to:
  /// **'Fee'**
  String get transactionFee;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @sortByDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get sortByDate;

  /// No description provided for @sortByPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get sortByPrice;

  /// No description provided for @sortByPriceLowToHigh.
  ///
  /// In en, this message translates to:
  /// **'Price: Low to High'**
  String get sortByPriceLowToHigh;

  /// No description provided for @sortByPriceHighToLow.
  ///
  /// In en, this message translates to:
  /// **'Price: High to Low'**
  String get sortByPriceHighToLow;

  /// No description provided for @sortByNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest First'**
  String get sortByNewest;

  /// No description provided for @sortByOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest First'**
  String get sortByOldest;

  /// No description provided for @minPrice.
  ///
  /// In en, this message translates to:
  /// **'Min Price'**
  String get minPrice;

  /// No description provided for @maxPrice.
  ///
  /// In en, this message translates to:
  /// **'Max Price'**
  String get maxPrice;

  /// No description provided for @minSize.
  ///
  /// In en, this message translates to:
  /// **'Min Size'**
  String get minSize;

  /// No description provided for @maxSize.
  ///
  /// In en, this message translates to:
  /// **'Max Size'**
  String get maxSize;

  /// No description provided for @featuredOnly.
  ///
  /// In en, this message translates to:
  /// **'Featured Only'**
  String get featuredOnly;

  /// No description provided for @hasParking.
  ///
  /// In en, this message translates to:
  /// **'Has Parking'**
  String get hasParking;

  /// No description provided for @hasPool.
  ///
  /// In en, this message translates to:
  /// **'Has Pool'**
  String get hasPool;

  /// No description provided for @hasGarden.
  ///
  /// In en, this message translates to:
  /// **'Has Garden'**
  String get hasGarden;

  /// No description provided for @hasElevator.
  ///
  /// In en, this message translates to:
  /// **'Has Elevator'**
  String get hasElevator;

  /// No description provided for @hasFurnished.
  ///
  /// In en, this message translates to:
  /// **'Furnished'**
  String get hasFurnished;

  /// No description provided for @hasAC.
  ///
  /// In en, this message translates to:
  /// **'Has A/C'**
  String get hasAC;

  /// No description provided for @slotsUsed.
  ///
  /// In en, this message translates to:
  /// **'{used} / {total} slots used'**
  String slotsUsed(Object used, Object total);

  /// No description provided for @buyMoreSlots.
  ///
  /// In en, this message translates to:
  /// **'Buy More Slots'**
  String get buyMoreSlots;

  /// No description provided for @boostYourAd.
  ///
  /// In en, this message translates to:
  /// **'Boost Your Ad'**
  String get boostYourAd;

  /// No description provided for @selectListingToBoost.
  ///
  /// In en, this message translates to:
  /// **'Select which listing you want to boost with {packageName}:'**
  String selectListingToBoost(Object packageName);

  /// No description provided for @noActiveListingsFound.
  ///
  /// In en, this message translates to:
  /// **'No active listings found. Please create a listing first.'**
  String get noActiveListingsFound;

  /// No description provided for @allListingsBoosted.
  ///
  /// In en, this message translates to:
  /// **'All your active listings are currently boosted. Wait for boost to expire before boosting again.'**
  String get allListingsBoosted;

  /// No description provided for @information.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get information;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @myListings.
  ///
  /// In en, this message translates to:
  /// **'My Listings'**
  String get myListings;

  /// No description provided for @savedProperties.
  ///
  /// In en, this message translates to:
  /// **'Saved Properties'**
  String get savedProperties;

  /// No description provided for @accountSettings.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get accountSettings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @aboutUs.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get aboutUs;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @boostElite.
  ///
  /// In en, this message translates to:
  /// **'ELITE'**
  String get boostElite;

  /// No description provided for @boostPremium.
  ///
  /// In en, this message translates to:
  /// **'PREMIUM'**
  String get boostPremium;

  /// No description provided for @boostEmerald.
  ///
  /// In en, this message translates to:
  /// **'Emerald'**
  String get boostEmerald;

  /// No description provided for @boostPlus.
  ///
  /// In en, this message translates to:
  /// **'Plus'**
  String get boostPlus;

  /// No description provided for @packageEmerald.
  ///
  /// In en, this message translates to:
  /// **'Emerald'**
  String get packageEmerald;

  /// No description provided for @packageBronze.
  ///
  /// In en, this message translates to:
  /// **'Bronze'**
  String get packageBronze;

  /// No description provided for @packageSilver.
  ///
  /// In en, this message translates to:
  /// **'Silver'**
  String get packageSilver;

  /// No description provided for @packageGold.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get packageGold;

  /// No description provided for @packageBasic.
  ///
  /// In en, this message translates to:
  /// **'Basic'**
  String get packageBasic;

  /// No description provided for @packageStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get packageStandard;

  /// No description provided for @packagePremium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get packagePremium;

  /// No description provided for @packageEnterprise.
  ///
  /// In en, this message translates to:
  /// **'Enterprise'**
  String get packageEnterprise;

  /// No description provided for @packageMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get packageMonth;

  /// No description provided for @packageMonths.
  ///
  /// In en, this message translates to:
  /// **'Months'**
  String get packageMonths;

  /// No description provided for @packageYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get packageYear;

  /// No description provided for @packagePerMonth.
  ///
  /// In en, this message translates to:
  /// **'per month'**
  String get packagePerMonth;

  /// No description provided for @packagePerYear.
  ///
  /// In en, this message translates to:
  /// **'per year'**
  String get packagePerYear;

  /// No description provided for @packageSlots.
  ///
  /// In en, this message translates to:
  /// **'{count} Slots'**
  String packageSlots(Object count);

  /// No description provided for @packageBoosts.
  ///
  /// In en, this message translates to:
  /// **'{count} Boosts'**
  String packageBoosts(Object count);

  /// No description provided for @packagePriority.
  ///
  /// In en, this message translates to:
  /// **'Priority Support'**
  String get packagePriority;

  /// No description provided for @packageAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Advanced Analytics'**
  String get packageAnalytics;

  /// No description provided for @packageVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified Badge'**
  String get packageVerified;

  /// No description provided for @currentPlan.
  ///
  /// In en, this message translates to:
  /// **'Current Plan'**
  String get currentPlan;

  /// No description provided for @upgradePlan.
  ///
  /// In en, this message translates to:
  /// **'Upgrade Plan'**
  String get upgradePlan;

  /// No description provided for @downgradePlan.
  ///
  /// In en, this message translates to:
  /// **'Downgrade Plan'**
  String get downgradePlan;

  /// No description provided for @freePlan.
  ///
  /// In en, this message translates to:
  /// **'Free Plan'**
  String get freePlan;

  /// No description provided for @searchPropertiesCities.
  ///
  /// In en, this message translates to:
  /// **'Search properties, cities...'**
  String get searchPropertiesCities;

  /// No description provided for @rentalProperties.
  ///
  /// In en, this message translates to:
  /// **'Rental properties'**
  String get rentalProperties;

  /// No description provided for @propertiesForSale.
  ///
  /// In en, this message translates to:
  /// **'Properties for sale'**
  String get propertiesForSale;

  /// No description provided for @advanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get advanced;

  /// No description provided for @set.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get set;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @pleaseLoginToAccess.
  ///
  /// In en, this message translates to:
  /// **'Please login to access {feature}'**
  String pleaseLoginToAccess(Object feature);

  /// No description provided for @manageBalanceTransactions.
  ///
  /// In en, this message translates to:
  /// **'Manage your balance and transactions'**
  String get manageBalanceTransactions;

  /// No description provided for @transactionCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get transactionCompleted;

  /// No description provided for @transactionPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get transactionPending;

  /// No description provided for @transactionFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get transactionFailed;

  /// No description provided for @verifiedSeller.
  ///
  /// In en, this message translates to:
  /// **'Verified Seller'**
  String get verifiedSeller;

  /// No description provided for @memberSince.
  ///
  /// In en, this message translates to:
  /// **'Member since {date}'**
  String memberSince(Object date);

  /// No description provided for @increasePropertyLimit.
  ///
  /// In en, this message translates to:
  /// **'Increase Property Limit'**
  String get increasePropertyLimit;

  /// No description provided for @areYouSureLogout.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get areYouSureLogout;

  /// No description provided for @hourBoost24.
  ///
  /// In en, this message translates to:
  /// **'24-hour boost'**
  String get hourBoost24;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @increasedVisibilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Increased Visibility'**
  String get increasedVisibilityTitle;

  /// No description provided for @increasedVisibilityDesc.
  ///
  /// In en, this message translates to:
  /// **'Your listing appears at the top of search results'**
  String get increasedVisibilityDesc;

  /// No description provided for @featuredBadgeTitle.
  ///
  /// In en, this message translates to:
  /// **'Featured Badge'**
  String get featuredBadgeTitle;

  /// No description provided for @featuredBadgeDesc.
  ///
  /// In en, this message translates to:
  /// **'Stand out with a premium featured badge'**
  String get featuredBadgeDesc;

  /// No description provided for @analyticsDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Analytics Dashboard'**
  String get analyticsDashboardTitle;

  /// No description provided for @analyticsDashboardDesc.
  ///
  /// In en, this message translates to:
  /// **'Track views, clicks, and engagement metrics'**
  String get analyticsDashboardDesc;

  /// No description provided for @premiumSupportTitle.
  ///
  /// In en, this message translates to:
  /// **'Premium Support'**
  String get premiumSupportTitle;

  /// No description provided for @premiumSupportDesc.
  ///
  /// In en, this message translates to:
  /// **'Get priority customer support'**
  String get premiumSupportDesc;

  /// No description provided for @moreFilters.
  ///
  /// In en, this message translates to:
  /// **'More Filters'**
  String get moreFilters;

  /// No description provided for @updatePersonalInfo.
  ///
  /// In en, this message translates to:
  /// **'Update your personal information'**
  String get updatePersonalInfo;

  /// No description provided for @tapToAddCover.
  ///
  /// In en, this message translates to:
  /// **'Tap to add cover photo'**
  String get tapToAddCover;

  /// No description provided for @slotsValidity.
  ///
  /// In en, this message translates to:
  /// **'Properties that use slots are valid for 60 days total'**
  String get slotsValidity;

  /// No description provided for @profileUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully!'**
  String get profileUpdatedSuccess;

  /// No description provided for @profileUpdateFail.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile. Please try again.'**
  String get profileUpdateFail;

  /// No description provided for @errorRemovingFavorite.
  ///
  /// In en, this message translates to:
  /// **'Error removing favorite'**
  String get errorRemovingFavorite;

  /// No description provided for @errorLoadingFavorites.
  ///
  /// In en, this message translates to:
  /// **'Error loading favorites'**
  String get errorLoadingFavorites;

  /// No description provided for @realEstateOffice.
  ///
  /// In en, this message translates to:
  /// **'Real Estate Office'**
  String get realEstateOffice;

  /// No description provided for @propertyLimit.
  ///
  /// In en, this message translates to:
  /// **'Property Limit'**
  String get propertyLimit;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @contactClicks.
  ///
  /// In en, this message translates to:
  /// **'Contact Clicks'**
  String get contactClicks;

  /// No description provided for @phoneCalls.
  ///
  /// In en, this message translates to:
  /// **'Phone Calls'**
  String get phoneCalls;

  /// No description provided for @whatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsapp;

  /// No description provided for @walletBalance.
  ///
  /// In en, this message translates to:
  /// **'Wallet Balance'**
  String get walletBalance;

  /// No description provided for @soldRented.
  ///
  /// In en, this message translates to:
  /// **'Sold/Rented'**
  String get soldRented;

  /// No description provided for @buySlots.
  ///
  /// In en, this message translates to:
  /// **'Buy Slots'**
  String get buySlots;

  /// No description provided for @boost.
  ///
  /// In en, this message translates to:
  /// **'Boost'**
  String get boost;

  /// No description provided for @viewsOverTime.
  ///
  /// In en, this message translates to:
  /// **'Views Over Time'**
  String get viewsOverTime;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @byType.
  ///
  /// In en, this message translates to:
  /// **'By Type'**
  String get byType;

  /// No description provided for @byStatus.
  ///
  /// In en, this message translates to:
  /// **'By Status'**
  String get byStatus;

  /// No description provided for @engagementMetrics.
  ///
  /// In en, this message translates to:
  /// **'Engagement Metrics'**
  String get engagementMetrics;

  /// No description provided for @avgViewsPerProperty.
  ///
  /// In en, this message translates to:
  /// **'Average Views per Property'**
  String get avgViewsPerProperty;

  /// No description provided for @conversionRate.
  ///
  /// In en, this message translates to:
  /// **'Conversion Rate'**
  String get conversionRate;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired;

  /// No description provided for @changeCover.
  ///
  /// In en, this message translates to:
  /// **'Change Cover'**
  String get changeCover;

  /// No description provided for @premiumSlotsStatus.
  ///
  /// In en, this message translates to:
  /// **'Premium Slots Status'**
  String get premiumSlotsStatus;

  /// No description provided for @statTotalListings.
  ///
  /// In en, this message translates to:
  /// **'Total Listings'**
  String get statTotalListings;

  /// No description provided for @statActiveListings.
  ///
  /// In en, this message translates to:
  /// **'Active Listings'**
  String get statActiveListings;

  /// No description provided for @statTotalProperties.
  ///
  /// In en, this message translates to:
  /// **'Total Properties'**
  String get statTotalProperties;

  /// No description provided for @statAvailableProperties.
  ///
  /// In en, this message translates to:
  /// **'Available Properties'**
  String get statAvailableProperties;

  /// No description provided for @unlimitedCapacity.
  ///
  /// In en, this message translates to:
  /// **'Unlimited Capacity'**
  String get unlimitedCapacity;

  /// No description provided for @totalSlotsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Total Slots'**
  String totalSlotsCount(int count);

  /// No description provided for @hoursLeftCount.
  ///
  /// In en, this message translates to:
  /// **'{count} hours left'**
  String hoursLeftCount(int count);

  /// No description provided for @unlimitedPackage.
  ///
  /// In en, this message translates to:
  /// **'Unlimited Package'**
  String get unlimitedPackage;

  /// No description provided for @scaleWithoutLimits.
  ///
  /// In en, this message translates to:
  /// **'Scale your business without limits'**
  String get scaleWithoutLimits;

  /// No description provided for @moreSlotsCount.
  ///
  /// In en, this message translates to:
  /// **'+ {count} more slots'**
  String moreSlotsCount(int count);

  /// No description provided for @upgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get upgrade;

  /// No description provided for @editCover.
  ///
  /// In en, this message translates to:
  /// **'Edit Cover'**
  String get editCover;

  /// No description provided for @whoWeAreTitle.
  ///
  /// In en, this message translates to:
  /// **'Who We Are'**
  String get whoWeAreTitle;

  /// No description provided for @whoWeAreContent.
  ///
  /// In en, this message translates to:
  /// **'Dary is the ultimate Libyan digital real estate companion. We’ve built more than just an app; we’ve created a seamless marketplace where property dreams become reality. From high-end villas to cozy apartments, we bridge the gap between Libyan homeowners and seekers.'**
  String get whoWeAreContent;

  /// No description provided for @ourMissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Our Mission'**
  String get ourMissionTitle;

  /// No description provided for @ourMissionContent.
  ///
  /// In en, this message translates to:
  /// **'To revolutionize the Libyan real estate market through transparency, technology, and trust. We empower users with detailed insights, high-quality media, and direct communication channels.'**
  String get ourMissionContent;

  /// No description provided for @whyDaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Why Dary?'**
  String get whyDaryTitle;

  /// No description provided for @whyDaryContent.
  ///
  /// In en, this message translates to:
  /// **'• Verified Listings\n• Secure Direct Contact\n• Advanced Filtering\n• Real-time Analytics\n• Specialized Office Dashboards'**
  String get whyDaryContent;

  /// No description provided for @userAgreementTitle.
  ///
  /// In en, this message translates to:
  /// **'1. User Agreement'**
  String get userAgreementTitle;

  /// No description provided for @userAgreementContent.
  ///
  /// In en, this message translates to:
  /// **'By accessing Dary, you agree to provide authentic information. Users are responsible for all activity under their accounts.'**
  String get userAgreementContent;

  /// No description provided for @listingAuthenticityTitle.
  ///
  /// In en, this message translates to:
  /// **'2. Listing Authenticity'**
  String get listingAuthenticityTitle;

  /// No description provided for @listingAuthenticityContent.
  ///
  /// In en, this message translates to:
  /// **'All properties must be genuine. False advertising, misleading prices, or duplicate listings are strictly prohibited and will lead to account suspension.'**
  String get listingAuthenticityContent;

  /// No description provided for @communicationTitle.
  ///
  /// In en, this message translates to:
  /// **'3. Communication'**
  String get communicationTitle;

  /// No description provided for @communicationContent.
  ///
  /// In en, this message translates to:
  /// **'Dary facilitates connection but is not responsible for external agreements between users. Always exercise caution and verify property details in person.'**
  String get communicationContent;

  /// No description provided for @paymentServicesTitle.
  ///
  /// In en, this message translates to:
  /// **'4. Payment Services'**
  String get paymentServicesTitle;

  /// No description provided for @paymentServicesContent.
  ///
  /// In en, this message translates to:
  /// **'Premium features and wallet recharges are final. Payments are handled via secure third-party integration (Ma\'amalat).'**
  String get paymentServicesContent;

  /// No description provided for @getInTouch.
  ///
  /// In en, this message translates to:
  /// **'Get in Touch'**
  String get getInTouch;

  /// No description provided for @reachOutHelp.
  ///
  /// In en, this message translates to:
  /// **'We\'re here to help you with any questions'**
  String get reachOutHelp;

  /// No description provided for @emailSupport.
  ///
  /// In en, this message translates to:
  /// **'Email Support'**
  String get emailSupport;

  /// No description provided for @response24h.
  ///
  /// In en, this message translates to:
  /// **'Response within 24 hours'**
  String get response24h;

  /// No description provided for @callUs.
  ///
  /// In en, this message translates to:
  /// **'Call Us'**
  String get callUs;

  /// No description provided for @lineCount.
  ///
  /// In en, this message translates to:
  /// **'Line {count}'**
  String lineCount(int count);

  /// No description provided for @whatsAppChat.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp Chat'**
  String get whatsAppChat;

  /// No description provided for @supportDeskCount.
  ///
  /// In en, this message translates to:
  /// **'Support Desk {count}'**
  String supportDeskCount(int count);

  /// No description provided for @showMoreCount.
  ///
  /// In en, this message translates to:
  /// **'Show More ({count} more)'**
  String showMoreCount(int count);

  /// No description provided for @showLess.
  ///
  /// In en, this message translates to:
  /// **'Show Less'**
  String get showLess;

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Selected'**
  String selectedCount(int count);

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// No description provided for @deselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect All'**
  String get deselectAll;

  /// No description provided for @deleteSelected.
  ///
  /// In en, this message translates to:
  /// **'Delete Selected'**
  String get deleteSelected;

  /// No description provided for @noListingsYet.
  ///
  /// In en, this message translates to:
  /// **'No listings yet'**
  String get noListingsYet;

  /// No description provided for @propertiesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 property} other{{count} properties}}'**
  String propertiesCount(int count);

  /// No description provided for @listingsExpiringSoon.
  ///
  /// In en, this message translates to:
  /// **'Listings Expiring Soon!'**
  String get listingsExpiringSoon;

  /// No description provided for @listingsExpiryWarning.
  ///
  /// In en, this message translates to:
  /// **'The following properties are about to expire. Please renew them to keep them visible to the public.'**
  String get listingsExpiryWarning;

  /// No description provided for @andMoreCount.
  ///
  /// In en, this message translates to:
  /// **'...and {count} more'**
  String andMoreCount(int count);

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @renewAll.
  ///
  /// In en, this message translates to:
  /// **'Renew All ({count})'**
  String renewAll(int count);

  /// No description provided for @renewedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'{count} properties renewed successfully!'**
  String renewedSuccessfully(int count);

  /// No description provided for @notEnoughPointsToRenew.
  ///
  /// In en, this message translates to:
  /// **'Not enough points. You have {available} pts but need {required} pts.'**
  String notEnoughPointsToRenew(int available, int required);

  /// No description provided for @renewingProperties.
  ///
  /// In en, this message translates to:
  /// **'Renewing properties...'**
  String get renewingProperties;

  /// No description provided for @office.
  ///
  /// In en, this message translates to:
  /// **'OFFICE'**
  String get office;

  /// No description provided for @userNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get userNotFound;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get goBack;

  /// No description provided for @totalCount.
  ///
  /// In en, this message translates to:
  /// **'{count} total'**
  String totalCount(int count);

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account? This action cannot be undone.'**
  String get deleteAccountConfirmation;

  /// No description provided for @googleReauthDeletion.
  ///
  /// In en, this message translates to:
  /// **'Since you signed in with Google, you will be asked to re-authenticate with Google to confirm deletion.'**
  String get googleReauthDeletion;

  /// No description provided for @enterPasswordToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password to confirm:'**
  String get enterPasswordToConfirm;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordHint;

  /// No description provided for @pleaseEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get pleaseEnterPassword;

  /// No description provided for @accountDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Your account has been successfully deleted.'**
  String get accountDeletedSuccessfully;

  /// No description provided for @deleteAccountComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Delete account functionality coming soon!'**
  String get deleteAccountComingSoon;

  /// No description provided for @deletePropertiesCountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} Properties?'**
  String deletePropertiesCountTitle(int count);

  /// No description provided for @deletePropertiesConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the selected {count} properties? This action cannot be undone and these slots will remain used (burned).'**
  String deletePropertiesConfirmation(int count);

  /// No description provided for @deleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete All'**
  String get deleteAll;

  /// No description provided for @deletePropertiesSuccessCount.
  ///
  /// In en, this message translates to:
  /// **'Successfully deleted {successCount} out of {totalCount} properties'**
  String deletePropertiesSuccessCount(int successCount, int totalCount);

  /// No description provided for @errorUpdatingProfile.
  ///
  /// In en, this message translates to:
  /// **'Error updating profile: {error}'**
  String errorUpdatingProfile(Object error);

  /// No description provided for @noUserFound.
  ///
  /// In en, this message translates to:
  /// **'No user found'**
  String get noUserFound;

  /// No description provided for @emailChangeInfo.
  ///
  /// In en, this message translates to:
  /// **'This email is linked to your account and cannot be changed.'**
  String get emailChangeInfo;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @customizeExperience.
  ///
  /// In en, this message translates to:
  /// **'Customize your experience'**
  String get customizeExperience;

  /// No description provided for @pleaseEnterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get pleaseEnterName;

  /// No description provided for @nameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters'**
  String get nameTooShort;

  /// No description provided for @phoneTooShort.
  ///
  /// In en, this message translates to:
  /// **'Phone number is too short'**
  String get phoneTooShort;

  /// No description provided for @daysCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Days'**
  String daysCount(Object count);

  /// No description provided for @allTime.
  ///
  /// In en, this message translates to:
  /// **'All Time'**
  String get allTime;

  /// No description provided for @performance.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get performance;

  /// No description provided for @topPerformingProperties.
  ///
  /// In en, this message translates to:
  /// **'Top Performing Properties'**
  String get topPerformingProperties;

  /// No description provided for @noPerformanceData.
  ///
  /// In en, this message translates to:
  /// **'No performance data available'**
  String get noPerformanceData;

  /// No description provided for @totalSpent.
  ///
  /// In en, this message translates to:
  /// **'Total Spent'**
  String get totalSpent;

  /// No description provided for @totalRecharged.
  ///
  /// In en, this message translates to:
  /// **'Total Recharged'**
  String get totalRecharged;

  /// No description provided for @spendingBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Spending Breakdown'**
  String get spendingBreakdown;

  /// No description provided for @boostPackages.
  ///
  /// In en, this message translates to:
  /// **'Boost Packages'**
  String get boostPackages;

  /// No description provided for @propertySlots.
  ///
  /// In en, this message translates to:
  /// **'Property Slots'**
  String get propertySlots;

  /// No description provided for @manageWallet.
  ///
  /// In en, this message translates to:
  /// **'Manage Wallet'**
  String get manageWallet;

  /// No description provided for @activeBoosts.
  ///
  /// In en, this message translates to:
  /// **'Active Boosts'**
  String get activeBoosts;

  /// No description provided for @engagementRate.
  ///
  /// In en, this message translates to:
  /// **'Engagement Rate: {rate}%'**
  String engagementRate(Object rate);

  /// No description provided for @calls.
  ///
  /// In en, this message translates to:
  /// **'Calls'**
  String get calls;

  /// No description provided for @saves.
  ///
  /// In en, this message translates to:
  /// **'Saves'**
  String get saves;

  /// No description provided for @expiring.
  ///
  /// In en, this message translates to:
  /// **'Expiring'**
  String get expiring;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// No description provided for @boostActive.
  ///
  /// In en, this message translates to:
  /// **'Boost Active'**
  String get boostActive;

  /// No description provided for @noActiveBoosts.
  ///
  /// In en, this message translates to:
  /// **'No active boosts'**
  String get noActiveBoosts;

  /// No description provided for @expires.
  ///
  /// In en, this message translates to:
  /// **'Expires'**
  String get expires;

  /// No description provided for @avgViews.
  ///
  /// In en, this message translates to:
  /// **'{count} avg'**
  String avgViews(Object count);

  /// No description provided for @leadsPercentage.
  ///
  /// In en, this message translates to:
  /// **'{count}% of leads'**
  String leadsPercentage(Object count);

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @ratePercentage.
  ///
  /// In en, this message translates to:
  /// **'{rate}% rate'**
  String ratePercentage(Object rate);

  /// No description provided for @transactionRechargeMoamalat.
  ///
  /// In en, this message translates to:
  /// **'Recharged via Moamalat Card'**
  String get transactionRechargeMoamalat;

  /// No description provided for @transactionPurchaseSlots.
  ///
  /// In en, this message translates to:
  /// **'Purchase {name} - Add {count} property slots'**
  String transactionPurchaseSlots(Object count, Object name);

  /// No description provided for @transactionTopListing.
  ///
  /// In en, this message translates to:
  /// **'Top Listing Purchase - {name}'**
  String transactionTopListing(Object name);

  /// No description provided for @transactionBoostPlus.
  ///
  /// In en, this message translates to:
  /// **'Boost New Listing: Plus'**
  String get transactionBoostPlus;

  /// No description provided for @transactionVoucherRecharge.
  ///
  /// In en, this message translates to:
  /// **'Voucher Recharge'**
  String get transactionVoucherRecharge;

  /// No description provided for @transactionAdminCredit.
  ///
  /// In en, this message translates to:
  /// **'Manual Admin Credit'**
  String get transactionAdminCredit;

  /// No description provided for @packageStarter.
  ///
  /// In en, this message translates to:
  /// **'Starter'**
  String get packageStarter;

  /// No description provided for @packageProfessional.
  ///
  /// In en, this message translates to:
  /// **'Professional'**
  String get packageProfessional;

  /// No description provided for @packageElite.
  ///
  /// In en, this message translates to:
  /// **'Elite'**
  String get packageElite;

  /// No description provided for @packageTopListing.
  ///
  /// In en, this message translates to:
  /// **'Top Listing'**
  String get packageTopListing;

  /// No description provided for @package1Day.
  ///
  /// In en, this message translates to:
  /// **'1 Day'**
  String get package1Day;

  /// No description provided for @package3Days.
  ///
  /// In en, this message translates to:
  /// **'3 Days'**
  String get package3Days;

  /// No description provided for @package1Week.
  ///
  /// In en, this message translates to:
  /// **'1 Week'**
  String get package1Week;

  /// No description provided for @package1Month.
  ///
  /// In en, this message translates to:
  /// **'1 Month'**
  String get package1Month;

  /// No description provided for @todayAt.
  ///
  /// In en, this message translates to:
  /// **'Today {time}'**
  String todayAt(Object time);

  /// No description provided for @yesterdayAt.
  ///
  /// In en, this message translates to:
  /// **'Yesterday {time}'**
  String yesterdayAt(Object time);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String daysAgo(Object count);

  /// No description provided for @referenceId.
  ///
  /// In en, this message translates to:
  /// **'Reference ID'**
  String get referenceId;

  /// No description provided for @tipsFindProperty.
  ///
  /// In en, this message translates to:
  /// **'Find your dream property'**
  String get tipsFindProperty;

  /// No description provided for @tipsContactSeller.
  ///
  /// In en, this message translates to:
  /// **'Contact seller directly'**
  String get tipsContactSeller;

  /// No description provided for @tipsNegotiateDeal.
  ///
  /// In en, this message translates to:
  /// **'Negotiate and close deal'**
  String get tipsNegotiateDeal;

  /// No description provided for @deleteConversation.
  ///
  /// In en, this message translates to:
  /// **'Delete Conversation'**
  String get deleteConversation;

  /// No description provided for @deleteConversationConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this conversation? This action cannot be undone.'**
  String get deleteConversationConfirmation;

  /// No description provided for @conversationDeleted.
  ///
  /// In en, this message translates to:
  /// **'Conversation deleted'**
  String get conversationDeleted;

  /// No description provided for @errorDeletingConversation.
  ///
  /// In en, this message translates to:
  /// **'Error deleting conversation: {error}'**
  String errorDeletingConversation(Object error);

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @propertyNotFound.
  ///
  /// In en, this message translates to:
  /// **'Property not found'**
  String get propertyNotFound;

  /// No description provided for @errorLoadingProperty.
  ///
  /// In en, this message translates to:
  /// **'Error loading property: {error}'**
  String errorLoadingProperty(Object error);

  /// No description provided for @generalPreferences.
  ///
  /// In en, this message translates to:
  /// **'General Preferences'**
  String get generalPreferences;

  /// No description provided for @maintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get maintenance;

  /// No description provided for @notificationsActive.
  ///
  /// In en, this message translates to:
  /// **'Notifications Active'**
  String get notificationsActive;

  /// No description provided for @notificationsPaused.
  ///
  /// In en, this message translates to:
  /// **'Notifications Paused'**
  String get notificationsPaused;

  /// No description provided for @notificationsActiveDesc.
  ///
  /// In en, this message translates to:
  /// **'You will receive updates about your listings and chats'**
  String get notificationsActiveDesc;

  /// No description provided for @notificationsPausedDesc.
  ///
  /// In en, this message translates to:
  /// **'Turn on notifications to stay updated on opportunities'**
  String get notificationsPausedDesc;

  /// No description provided for @troubleshooting.
  ///
  /// In en, this message translates to:
  /// **'Troubleshooting'**
  String get troubleshooting;

  /// No description provided for @test.
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get test;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @lastSync.
  ///
  /// In en, this message translates to:
  /// **'Last Sync:'**
  String get lastSync;

  /// No description provided for @newMessageFrom.
  ///
  /// In en, this message translates to:
  /// **'New message from {senderName}'**
  String newMessageFrom(Object senderName);

  /// No description provided for @aboutProperty.
  ///
  /// In en, this message translates to:
  /// **'About {propertyTitle}'**
  String aboutProperty(Object propertyTitle);

  /// No description provided for @property.
  ///
  /// In en, this message translates to:
  /// **'Property'**
  String get property;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @pleaseLoginToPurchase.
  ///
  /// In en, this message translates to:
  /// **'Please log in to purchase packages'**
  String get pleaseLoginToPurchase;

  /// No description provided for @noActiveListingsToBoost.
  ///
  /// In en, this message translates to:
  /// **'No active listings found. Please create a listing first.'**
  String get noActiveListingsToBoost;

  /// No description provided for @chooseListingToBoost.
  ///
  /// In en, this message translates to:
  /// **'Choose Listing to Boost'**
  String get chooseListingToBoost;

  /// No description provided for @boostListing.
  ///
  /// In en, this message translates to:
  /// **'Boost Listing'**
  String get boostListing;

  /// No description provided for @weeksAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} weeks ago'**
  String weeksAgo(Object count);

  /// No description provided for @monthsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} months ago'**
  String monthsAgo(Object count);

  /// No description provided for @boostSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'{listingTitle} is now boosted with {packageName}!\nRemaining balance: {balance} LYD'**
  String boostSuccessMessage(
      Object balance, Object listingTitle, Object packageName);

  /// No description provided for @bulkBoostActivated.
  ///
  /// In en, this message translates to:
  /// **'Bulk Boost Activated!'**
  String get bulkBoostActivated;

  /// No description provided for @bulkBoostSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'{count} properties are now boosted with {packageName}!\nRemaining balance: {balance} LYD'**
  String bulkBoostSuccessMessage(
      Object balance, Object count, Object packageName);

  /// No description provided for @awesome.
  ///
  /// In en, this message translates to:
  /// **'Awesome!'**
  String get awesome;

  /// No description provided for @insufficientBalanceAction.
  ///
  /// In en, this message translates to:
  /// **'Top up'**
  String get insufficientBalanceAction;

  /// No description provided for @oneWeekAgo.
  ///
  /// In en, this message translates to:
  /// **'1 week ago'**
  String get oneWeekAgo;

  /// No description provided for @oneMonthAgo.
  ///
  /// In en, this message translates to:
  /// **'1 month ago'**
  String get oneMonthAgo;

  /// No description provided for @voucherPurchaseInstruction1.
  ///
  /// In en, this message translates to:
  /// **'• Purchase from any store with Umbrella or Anis POS terminals.'**
  String get voucherPurchaseInstruction1;

  /// No description provided for @voucherPurchaseInstruction2.
  ///
  /// In en, this message translates to:
  /// **'• يمكنك الشراء من أي محل تتوفر لديه ماكينة دفع (المظلة) أو (أنيس).'**
  String get voucherPurchaseInstruction2;

  /// No description provided for @securePayment.
  ///
  /// In en, this message translates to:
  /// **'Secure Payment'**
  String get securePayment;

  /// No description provided for @invalidVoucherCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid voucher code. Please check and try again.'**
  String get invalidVoucherCode;

  /// No description provided for @voucherAlreadyRedeemed.
  ///
  /// In en, this message translates to:
  /// **'This voucher has already been redeemed.'**
  String get voucherAlreadyRedeemed;

  /// No description provided for @voucherRechargeSuccess.
  ///
  /// In en, this message translates to:
  /// **'Wallet recharged successfully! New balance: {balance} {currency}'**
  String voucherRechargeSuccess(Object balance, Object currency);

  /// No description provided for @processingVoucher.
  ///
  /// In en, this message translates to:
  /// **'Processing voucher...'**
  String get processingVoucher;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @rechargeSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Recharge Successful'**
  String get rechargeSuccessful;

  /// No description provided for @analyticsAssistant.
  ///
  /// In en, this message translates to:
  /// **'Analytics Assistant'**
  String get analyticsAssistant;

  /// No description provided for @aiPoweredInsights.
  ///
  /// In en, this message translates to:
  /// **'AI-Powered Performance Insights'**
  String get aiPoweredInsights;

  /// No description provided for @lowVisibility.
  ///
  /// In en, this message translates to:
  /// **'Low Visibility'**
  String get lowVisibility;

  /// No description provided for @greatEngagement.
  ///
  /// In en, this message translates to:
  /// **'Great Engagement!'**
  String get greatEngagement;

  /// No description provided for @goodContactConversion.
  ///
  /// In en, this message translates to:
  /// **'Good Contact Conversion'**
  String get goodContactConversion;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @boostProperties.
  ///
  /// In en, this message translates to:
  /// **'Boost Properties'**
  String get boostProperties;

  /// No description provided for @rechargeWallet.
  ///
  /// In en, this message translates to:
  /// **'Recharge Wallet'**
  String get rechargeWallet;

  /// No description provided for @propertySaved.
  ///
  /// In en, this message translates to:
  /// **'Property Saved'**
  String get propertySaved;

  /// No description provided for @suggestions.
  ///
  /// In en, this message translates to:
  /// **'Suggestions:'**
  String get suggestions;

  /// No description provided for @propertiesSavedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 property saved} other{{count} properties saved}}'**
  String propertiesSavedCount(int count);

  /// No description provided for @noFavoritesYet.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get noFavoritesYet;

  /// No description provided for @startAddingToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Start adding properties to your favorites'**
  String get startAddingToFavorites;

  /// No description provided for @idLabel.
  ///
  /// In en, this message translates to:
  /// **'ID'**
  String get idLabel;

  /// No description provided for @boostedStatusBadge.
  ///
  /// In en, this message translates to:
  /// **'BOOSTED'**
  String get boostedStatusBadge;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Find Your Dream Home'**
  String get onboardingTitle1;

  /// No description provided for @onboardingDesc1.
  ///
  /// In en, this message translates to:
  /// **'Explore thousands of premium properties in the best locations across Libya.'**
  String get onboardingDesc1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Smart Search & Filters'**
  String get onboardingTitle2;

  /// No description provided for @onboardingDesc2.
  ///
  /// In en, this message translates to:
  /// **'Use our advanced search engine to find exactly what you need with just a few taps.'**
  String get onboardingDesc2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Secure & Direct Contact'**
  String get onboardingTitle3;

  /// No description provided for @onboardingDesc3.
  ///
  /// In en, this message translates to:
  /// **'Connect directly with sellers and agents through our secure messaging system.'**
  String get onboardingDesc3;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @pageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get pageNotFound;

  /// No description provided for @goHome.
  ///
  /// In en, this message translates to:
  /// **'Go Home'**
  String get goHome;

  /// No description provided for @loadingProperty.
  ///
  /// In en, this message translates to:
  /// **'Loading property...'**
  String get loadingProperty;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Finding your dream home...'**
  String get splashTagline;

  /// No description provided for @noViewsTitle.
  ///
  /// In en, this message translates to:
  /// **'No Views Detected'**
  String get noViewsTitle;

  /// No description provided for @noViewsMessage.
  ///
  /// In en, this message translates to:
  /// **'Your properties have received no views. This might be because:\n• Properties are not published\n• Poor quality images or missing photos\n• Unclear or unappealing titles\n• Properties might be hidden or inactive'**
  String get noViewsMessage;

  /// No description provided for @checkPublished.
  ///
  /// In en, this message translates to:
  /// **'Check if all properties are published'**
  String get checkPublished;

  /// No description provided for @addHighQualityPhotos.
  ///
  /// In en, this message translates to:
  /// **'Add high-quality photos to all properties'**
  String get addHighQualityPhotos;

  /// No description provided for @writeClearTitles.
  ///
  /// In en, this message translates to:
  /// **'Write clear, descriptive titles'**
  String get writeClearTitles;

  /// No description provided for @considerBoosting.
  ///
  /// In en, this message translates to:
  /// **'Consider boosting your properties for visibility'**
  String get considerBoosting;

  /// No description provided for @lowVisibilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Low Visibility'**
  String get lowVisibilityTitle;

  /// No description provided for @lowVisibilityMessage.
  ///
  /// In en, this message translates to:
  /// **'Your properties are getting very few views (average {average} per listing).\nThis suggests your listings need better optimization.'**
  String lowVisibilityMessage(String average);

  /// No description provided for @improvePhotos.
  ///
  /// In en, this message translates to:
  /// **'Improve property photos quality'**
  String get improvePhotos;

  /// No description provided for @detailedDescriptions.
  ///
  /// In en, this message translates to:
  /// **'Write more detailed and appealing descriptions'**
  String get detailedDescriptions;

  /// No description provided for @addMorePhotos.
  ///
  /// In en, this message translates to:
  /// **'Add more photos (at least 5-10 per property)'**
  String get addMorePhotos;

  /// No description provided for @verifyPricing.
  ///
  /// In en, this message translates to:
  /// **'Verify your pricing is competitive'**
  String get verifyPricing;

  /// No description provided for @lowEngagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Low Engagement Rate'**
  String get lowEngagementTitle;

  /// No description provided for @lowEngagementMessage.
  ///
  /// In en, this message translates to:
  /// **'Your engagement rate is {rate}%, which is below average.\nThis means people view your properties but don\'t take action.'**
  String lowEngagementMessage(String rate);

  /// No description provided for @compellingDescriptions.
  ///
  /// In en, this message translates to:
  /// **'Add more compelling property descriptions'**
  String get compellingDescriptions;

  /// No description provided for @includeAmenities.
  ///
  /// In en, this message translates to:
  /// **'Include all amenities and features'**
  String get includeAmenities;

  /// No description provided for @verifyContactInfo.
  ///
  /// In en, this message translates to:
  /// **'Verify contact information is correct'**
  String get verifyContactInfo;

  /// No description provided for @adjustPricing.
  ///
  /// In en, this message translates to:
  /// **'Consider adjusting pricing to be more competitive'**
  String get adjustPricing;

  /// No description provided for @addLocationDetails.
  ///
  /// In en, this message translates to:
  /// **'Add property location details (neighborhood, nearby amenities)'**
  String get addLocationDetails;

  /// No description provided for @veryLowContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Very Low Contact Rate'**
  String get veryLowContactTitle;

  /// No description provided for @veryLowContactMessage.
  ///
  /// In en, this message translates to:
  /// **'Only {rate}% of viewers are contacting you.\nThis suggests properties might be overpriced or lack important information.'**
  String veryLowContactMessage(String rate);

  /// No description provided for @reviewPricing.
  ///
  /// In en, this message translates to:
  /// **'Review and adjust pricing to market rates'**
  String get reviewPricing;

  /// No description provided for @completeInfo.
  ///
  /// In en, this message translates to:
  /// **'Add complete property information'**
  String get completeInfo;

  /// No description provided for @highlightPoints.
  ///
  /// In en, this message translates to:
  /// **'Highlight unique selling points'**
  String get highlightPoints;

  /// No description provided for @visiblePhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Ensure contact phone number is visible'**
  String get visiblePhoneNumber;

  /// No description provided for @respondQuickly.
  ///
  /// In en, this message translates to:
  /// **'Respond quickly to inquiries when they come'**
  String get respondQuickly;

  /// No description provided for @noListingsTitle.
  ///
  /// In en, this message translates to:
  /// **'No Listings Yet'**
  String get noListingsTitle;

  /// No description provided for @noListingsMessage.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any active listings. Start by adding your first property!'**
  String get noListingsMessage;

  /// No description provided for @addFirstProperty.
  ///
  /// In en, this message translates to:
  /// **'Click \"Add Property\" to create your first listing'**
  String get addFirstProperty;

  /// No description provided for @fillDetails.
  ///
  /// In en, this message translates to:
  /// **'Fill in all property details completely'**
  String get fillDetails;

  /// No description provided for @publishVisible.
  ///
  /// In en, this message translates to:
  /// **'Publish your property to make it visible'**
  String get publishVisible;

  /// No description provided for @increaseExposureTitle.
  ///
  /// In en, this message translates to:
  /// **'Increase Your Exposure'**
  String get increaseExposureTitle;

  /// No description provided for @increaseExposureMessage.
  ///
  /// In en, this message translates to:
  /// **'Having only one listing limits your visibility. Consider adding more properties.'**
  String get increaseExposureMessage;

  /// No description provided for @addMoreProperties.
  ///
  /// In en, this message translates to:
  /// **'Add more properties to increase your portfolio'**
  String get addMoreProperties;

  /// No description provided for @eachPropertyVisibility.
  ///
  /// In en, this message translates to:
  /// **'Each property increases your overall visibility'**
  String get eachPropertyVisibility;

  /// No description provided for @diversify.
  ///
  /// In en, this message translates to:
  /// **'Diversify property types and locations'**
  String get diversify;

  /// No description provided for @greatEngagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Great Engagement!'**
  String get greatEngagementTitle;

  /// No description provided for @greatEngagementMessage.
  ///
  /// In en, this message translates to:
  /// **'Your engagement rate of {rate}% is excellent!\nKeep up the good work by maintaining quality listings.'**
  String greatEngagementMessage(String rate);

  /// No description provided for @maintainQuality.
  ///
  /// In en, this message translates to:
  /// **'Continue maintaining high-quality listings'**
  String get maintainQuality;

  /// No description provided for @keepUpdated.
  ///
  /// In en, this message translates to:
  /// **'Keep property information updated'**
  String get keepUpdated;

  /// No description provided for @addRegularly.
  ///
  /// In en, this message translates to:
  /// **'Add new properties regularly'**
  String get addRegularly;

  /// No description provided for @goodContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Good Contact Conversion'**
  String get goodContactTitle;

  /// No description provided for @goodContactMessage.
  ///
  /// In en, this message translates to:
  /// **'Your contact rate of {rate}% shows good conversion.\nMake sure to respond promptly to all inquiries.'**
  String goodContactMessage(String rate);

  /// No description provided for @respond24h.
  ///
  /// In en, this message translates to:
  /// **'Respond to inquiries within 24 hours'**
  String get respond24h;

  /// No description provided for @keepContactUpdated.
  ///
  /// In en, this message translates to:
  /// **'Keep contact information up to date'**
  String get keepContactUpdated;

  /// No description provided for @beProfessional.
  ///
  /// In en, this message translates to:
  /// **'Be professional and helpful in communications'**
  String get beProfessional;

  /// No description provided for @doingGreatTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re Doing Great!'**
  String get doingGreatTitle;

  /// No description provided for @doingGreatMessage.
  ///
  /// In en, this message translates to:
  /// **'Your properties are performing well. No major issues detected.'**
  String get doingGreatMessage;

  /// No description provided for @monitorMetrics.
  ///
  /// In en, this message translates to:
  /// **'Continue monitoring your metrics'**
  String get monitorMetrics;

  /// No description provided for @refreshListings.
  ///
  /// In en, this message translates to:
  /// **'Refresh listings periodically to keep them at the top'**
  String get refreshListings;

  /// No description provided for @keepDescriptionsFresh.
  ///
  /// In en, this message translates to:
  /// **'Keep descriptions fresh and detailed'**
  String get keepDescriptionsFresh;

  /// No description provided for @monitorWeekly.
  ///
  /// In en, this message translates to:
  /// **'Monitor analytics weekly'**
  String get monitorWeekly;

  /// No description provided for @boostPeakTimes.
  ///
  /// In en, this message translates to:
  /// **'Consider boosting properties during peak times'**
  String get boostPeakTimes;

  /// No description provided for @gatherFeedback.
  ///
  /// In en, this message translates to:
  /// **'Gather and respond to user feedback'**
  String get gatherFeedback;

  /// No description provided for @verifyPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Verify Phone Number'**
  String get verifyPhoneNumber;

  /// No description provided for @otpSentTo.
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent a 6-digit verification code to'**
  String get otpSentTo;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get resendCode;

  /// No description provided for @unpublishAll.
  ///
  /// In en, this message translates to:
  /// **'Unpublish All'**
  String get unpublishAll;

  /// No description provided for @publishAll.
  ///
  /// In en, this message translates to:
  /// **'Publish All'**
  String get publishAll;

  /// No description provided for @unpublishPropertiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Unpublish {count} Properties?'**
  String unpublishPropertiesTitle(int count);

  /// No description provided for @unpublishConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to unpublish the selected properties? they will disappear from public search.'**
  String get unpublishConfirmMessage;

  /// No description provided for @publishPropertiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Publish {count} Properties?'**
  String publishPropertiesTitle(int count);

  /// No description provided for @publishReuseSlotsMessage.
  ///
  /// In en, this message translates to:
  /// **'These properties will reuse your existing slots. No new slots will be consumed. Continue?'**
  String get publishReuseSlotsMessage;

  /// No description provided for @publishUseSomeSlotsMessage.
  ///
  /// In en, this message translates to:
  /// **'This will use {count} of your available slots. The rest are reusing existing slots. Continue?'**
  String publishUseSomeSlotsMessage(int count);

  /// No description provided for @slotLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Slot Limit Reached'**
  String get slotLimitReached;

  /// No description provided for @notEnoughSlotsMessage.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have enough slots to publish these properties. You need {needed} new slots but only have {available} available.'**
  String notEnoughSlotsMessage(int needed, int available);

  /// No description provided for @mockPropertySuccess.
  ///
  /// In en, this message translates to:
  /// **'Mock Property Created Successfully!'**
  String get mockPropertySuccess;

  /// No description provided for @propertyLimitReachedAdd.
  ///
  /// In en, this message translates to:
  /// **'You have reached your property limit. Please purchase more slots to add properties.'**
  String get propertyLimitReachedAdd;

  /// No description provided for @propertyLimitReachedGeneral.
  ///
  /// In en, this message translates to:
  /// **'You have reached your property limit. Please purchase more slots.'**
  String get propertyLimitReachedGeneral;

  /// No description provided for @purchaseSuccessfulLabel.
  ///
  /// In en, this message translates to:
  /// **'Purchase Successful!'**
  String get purchaseSuccessfulLabel;

  /// No description provided for @addedSlotsNewLimit.
  ///
  /// In en, this message translates to:
  /// **'Added {slots} property slots.\nNew limit: {limit} properties'**
  String addedSlotsNewLimit(int slots, int limit);

  /// No description provided for @moreCredits.
  ///
  /// In en, this message translates to:
  /// **'Purchase More Points'**
  String get moreCredits;

  /// No description provided for @buyMoreCredits.
  ///
  /// In en, this message translates to:
  /// **'Buy More Points'**
  String get buyMoreCredits;

  /// No description provided for @packageCredits.
  ///
  /// In en, this message translates to:
  /// **'{count} Points'**
  String packageCredits(int count);

  /// No description provided for @buyCredits.
  ///
  /// In en, this message translates to:
  /// **'Buy Points'**
  String get buyCredits;

  /// No description provided for @buyNow.
  ///
  /// In en, this message translates to:
  /// **'Buy Now'**
  String get buyNow;

  /// No description provided for @purchaseSuccess.
  ///
  /// In en, this message translates to:
  /// **'Purchase Successful!'**
  String get purchaseSuccess;

  /// No description provided for @totalBalance.
  ///
  /// In en, this message translates to:
  /// **'Total Points'**
  String get totalBalance;

  /// No description provided for @creditsLabel.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get creditsLabel;

  /// No description provided for @postingCreditFooter.
  ///
  /// In en, this message translates to:
  /// **'Each property listing consumes 1 posting point.'**
  String get postingCreditFooter;

  /// No description provided for @postingCreditsTitle.
  ///
  /// In en, this message translates to:
  /// **'Posting Points'**
  String get postingCreditsTitle;

  /// No description provided for @oneTimePurchase.
  ///
  /// In en, this message translates to:
  /// **'One-time purchase'**
  String get oneTimePurchase;

  /// No description provided for @persistentCredits.
  ///
  /// In en, this message translates to:
  /// **'Persistent points (no monthly loss)'**
  String get persistentCredits;

  /// No description provided for @publishUseSomeCreditsMessage.
  ///
  /// In en, this message translates to:
  /// **'This will use {count} of your available points. Continue?'**
  String publishUseSomeCreditsMessage(int count);

  /// No description provided for @renewPropertyConfirm.
  ///
  /// In en, this message translates to:
  /// **'Renew Property?'**
  String get renewPropertyConfirm;

  /// No description provided for @renewPropertyDescription.
  ///
  /// In en, this message translates to:
  /// **'This will deduct 1 point from your points and extend the listing for 60 days.'**
  String get renewPropertyDescription;

  /// No description provided for @great.
  ///
  /// In en, this message translates to:
  /// **'Great!'**
  String get great;

  /// No description provided for @noCreditsMessage.
  ///
  /// In en, this message translates to:
  /// **'No posting points remaining. Please purchase a points package to list your property.'**
  String get noCreditsMessage;

  /// No description provided for @purchaseSuccessSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You have received {credits} posting points.\nRemaining balance: {remaining} points'**
  String purchaseSuccessSubtitle(int credits, int remaining);

  /// No description provided for @featurePostingCredits.
  ///
  /// In en, this message translates to:
  /// **'{count} Posting Points'**
  String featurePostingCredits(int count);

  /// No description provided for @featurePersistentCredits.
  ///
  /// In en, this message translates to:
  /// **'Points never expire'**
  String get featurePersistentCredits;

  /// No description provided for @featurePersistentCreditsLong.
  ///
  /// In en, this message translates to:
  /// **'Points never expire (no monthly loss)'**
  String get featurePersistentCreditsLong;

  /// No description provided for @featureBasicVisibility.
  ///
  /// In en, this message translates to:
  /// **'Basic search visibility'**
  String get featureBasicVisibility;

  /// No description provided for @featureStandardVisibility.
  ///
  /// In en, this message translates to:
  /// **'Standard search visibility'**
  String get featureStandardVisibility;

  /// No description provided for @featureEnhancedVisibility.
  ///
  /// In en, this message translates to:
  /// **'Enhanced search visibility'**
  String get featureEnhancedVisibility;

  /// No description provided for @featureMaximumVisibility.
  ///
  /// In en, this message translates to:
  /// **'Maximum search visibility'**
  String get featureMaximumVisibility;

  /// No description provided for @featureEmailSupport.
  ///
  /// In en, this message translates to:
  /// **'Email support'**
  String get featureEmailSupport;

  /// No description provided for @featurePrioritySupport.
  ///
  /// In en, this message translates to:
  /// **'Priority support'**
  String get featurePrioritySupport;

  /// No description provided for @featureDedicatedManager.
  ///
  /// In en, this message translates to:
  /// **'Dedicated account manager'**
  String get featureDedicatedManager;

  /// No description provided for @standardPackage.
  ///
  /// In en, this message translates to:
  /// **'Standard Package'**
  String get standardPackage;

  /// No description provided for @businessPackage.
  ///
  /// In en, this message translates to:
  /// **'Business Package'**
  String get businessPackage;

  /// No description provided for @packagePlus.
  ///
  /// In en, this message translates to:
  /// **'Plus'**
  String get packagePlus;

  /// No description provided for @buyPoints.
  ///
  /// In en, this message translates to:
  /// **'Buy Points'**
  String get buyPoints;

  /// No description provided for @boostApplied.
  ///
  /// In en, this message translates to:
  /// **'Boost Applied!'**
  String get boostApplied;

  /// No description provided for @boostSuccessSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your listing has been boosted with {packageName} for {days} days.'**
  String boostSuccessSubtitle(String packageName, int days);

  /// No description provided for @prioritySearch.
  ///
  /// In en, this message translates to:
  /// **'Priority Search'**
  String get prioritySearch;
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
