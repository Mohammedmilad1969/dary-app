import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:dary/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';
import 'app/app_router.dart';
import 'services/language_service.dart';
import 'providers/auth_provider.dart';
import 'features/chat/chat_service.dart';
import 'features/chat/chat_notification_service.dart';
import 'services/saved_search_service.dart';
import 'services/notification_service.dart';
import 'services/property_cache_service.dart';
import 'services/firebase_service.dart';
import 'services/property_service.dart';
import 'services/wallet_service.dart';
import 'services/paywall_service.dart';
import 'services/persistence_service.dart';
import 'services/user_preferences_service.dart';
import 'services/theme_service.dart';
import 'config/env_config.dart';
import 'services/api_client.dart';
import 'utils/app_animations.dart';
import 'providers/navigation_provider.dart';

void main() async {
  // Initialize services
  WidgetsFlutterBinding.ensureInitialized();
  
  // Preload fonts for better performance
  await ThemeService.preloadFonts();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://kxerrtfaraljjcolgxsg.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt4ZXJydGZhcmFsampjb2xneHNnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA0Nzc1MDAsImV4cCI6MjA3NjA1MzUwMH0.zoUjUuslukaTNAHFx5rLur3hBL2MsWOqqPEDiL3LXXg',
  );
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Add debug property
  // await addNewVillaProperty(); // Commented out to prevent duplicates
  
  // Initialize Firebase services
  final firebaseService = FirebaseService();
  await firebaseService.initialize();
  
  // Initialize Persistence Service
  final persistenceService = PersistenceService();
  
  // Initialize notification service
  final notificationService = ChatNotificationService();
  await notificationService.initialize();
  
  // Initialize property cache service
  final propertyCacheService = PropertyCacheService();
  await propertyCacheService.initialize();
  
  // Initialize paywall service
  final paywallService = PaywallService();
  await paywallService.initialize();
  
  // Print environment configuration in debug mode
  EnvConfig.printConfig();
  
  runApp(const DaryApp());
}

class DaryApp extends StatelessWidget {
  const DaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => LanguageService()),
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => ChatService()),
        ChangeNotifierProvider(create: (context) => ChatNotificationService()),
        ChangeNotifierProvider(create: (context) => SavedSearchService()),
        ChangeNotifierProvider(create: (context) => NotificationService()),
        ChangeNotifierProvider(create: (context) => PropertyService()),
        ChangeNotifierProvider(create: (context) => WalletService()),
        ChangeNotifierProvider(create: (context) => PaywallService()),
        ChangeNotifierProvider(create: (context) => UserPreferencesService()),
        ChangeNotifierProvider(create: (context) => NavigationProvider()),
        Provider(create: (context) => PersistenceService()),
      ],
      child: Consumer2<LanguageService, AuthProvider>(
        builder: (context, languageService, authProvider, child) {
          final theme = ThemeService.getLightTheme(context);
          return MaterialApp.router(
            title: 'Dary',
            theme: theme.copyWith(
              pageTransitionsTheme: AppPageTransitions.slideFromRight,
            ),
            themeMode: ThemeMode.light,
            routerConfig: AppRouter.router,
            locale: languageService.currentLocale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'), // English
              Locale('ar'), // Arabic
            ],
            builder: (context, child) {
              // Set up global error handler with current context
              GlobalErrorHandler.setContext(context);
              
              return Directionality(
                textDirection: languageService.textDirection,
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}