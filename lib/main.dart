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
import 'services/connectivity_service.dart';
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
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();
  debugPrint("📩 Handling a background message: ${message.messageId}");
}

void main() async {
  // Initialize services
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  try {
    debugPrint('🚀 Starting App Initialization (Parallel)...');
    final stopwatch = Stopwatch()..start();
    
    // Parallelize core initializations that don't depend on each other
    await Future.wait([
      // 1. Preload fonts
      () async {
        try {
          await ThemeService.preloadFonts();
          debugPrint('✅ ThemeService: Fonts preloaded');
        } catch (e) {
          debugPrint('⚠️ ThemeService warning: $e');
        }
      }(),
      
      // 2. Initialize Supabase
      () async {
        try {
          await Supabase.initialize(
            url: 'https://kxerrtfaraljjcolgxsg.supabase.co',
            anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt4ZXJydGZhcmFsampjb2xneHNnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA0Nzc1MDAsImV4cCI6MjA3NjA1MzUwMH0.zoUjUuslukaTNAHFx5rLur3hBL2MsWOqqPEDiL3LXXg',
          );
          debugPrint('✅ Supabase Initialized');
        } catch (e) {
          debugPrint('⚠️ Supabase warning: $e');
        }
      }(),
      
      // 3. Initialize Firebase
      () async {
        try {
          if (Firebase.apps.isEmpty) {
            await Firebase.initializeApp(
              options: DefaultFirebaseOptions.currentPlatform,
            );
            debugPrint('✅ Firebase Initialized (New)');
          } else {
            debugPrint('ℹ️ Firebase already initialized');
          }
          FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
        } catch (e) {
          debugPrint('⚠️ Firebase warning: $e');
        }
      }(),
    ]);

    // Secondary initializations that might depend on Firebase
    await Future.wait([
      () async {
        try {
          await FirebaseService().initialize();
          debugPrint('✅ FirebaseService Initialized');
        } catch (e) {
          debugPrint('⚠️ FirebaseService warning: $e');
        }
      }(),
      () async {
        try {
          await ChatNotificationService().initialize();
          debugPrint('✅ ChatNotificationService Initialized');
        } catch (e) {
          debugPrint('⚠️ ChatNotificationService warning: $e');
        }
      }(),
      () async {
        try {
          await PropertyCacheService().initialize();
          debugPrint('✅ PropertyCacheService Initialized');
        } catch (e) {
          debugPrint('⚠️ PropertyCacheService warning: $e');
        }
      }(),
      () async {
        try {
          await PaywallService().initialize();
          debugPrint('✅ PaywallService Initialized');
        } catch (e) {
          debugPrint('⚠️ PaywallService warning: $e');
        }
      }(),
      () async {
        try {
          // Initialize NotificationService for scheduled notifications
          // Note: Full initialization with context happens in individual screens if needed,
          // but we can trigger the basic singleton init here.
          final notificationService = NotificationService();
          // We'll call a simplified initialize or just schedule notifications
          await notificationService.scheduleDailyNotifications();
          debugPrint('✅ NotificationService: Daily notifications scheduled');
        } catch (e) {
          debugPrint('⚠️ NotificationService warning: $e');
        }
      }(),
    ]);

    EnvConfig.printConfig();
    debugPrint('🚀 Initialization Complete in ${stopwatch.elapsedMilliseconds}ms. Running App.');
  } catch (e, stackTrace) {
    debugPrint('❌ UNEXPECTED ERROR DURING MAIN INITIALIZATION: $e');
    debugPrint('🔍 Stack trace: $stackTrace');
  }
  
  FlutterNativeSplash.remove();
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
        ChangeNotifierProvider(create: (context) => ConnectivityService()),
        ChangeNotifierProvider(create: (context) => NavigationProvider()),
        Provider(create: (context) => PersistenceService()),
      ],
      child: Consumer2<LanguageService, AuthProvider>(
        builder: (context, languageService, authProvider, child) {
          final theme = ThemeService.getLightTheme(languageService.currentLocale.languageCode);
          return MaterialApp.router(
            title: 'Dary',
            theme: theme.copyWith(
              pageTransitionsTheme: AppPageTransitions.scaleFade,
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