import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kickadoor/theme/futuristic_theme.dart';
import 'package:kickadoor/core/constants.dart';
import 'package:kickadoor/firebase_options.dart';
import 'package:kickadoor/config/env.dart';
import 'package:kickadoor/l10n/app_localizations.dart';
import 'package:kickadoor/routing/app_router.dart';
import 'package:kickadoor/services/push_notification_service.dart';
import 'package:kickadoor/services/deep_link_service.dart';
import 'package:kickadoor/services/error_handler_service.dart';
import 'package:kickadoor/services/analytics_service.dart';
import 'package:kickadoor/services/remote_config_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'dart:ui';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with safe error handling
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Firebase initialized successfully
    Env.limitedMode = false;
    debugPrint('✅ Firebase initialized successfully');
    
    // Initialize Crashlytics
    try {
      // Pass all uncaught Flutter framework errors to Crashlytics
      FlutterError.onError = (errorDetails) {
        FlutterError.presentError(errorDetails);
        FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
      };
      
      // Pass all uncaught async errors to Crashlytics
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
      
      debugPrint('✅ Crashlytics initialized');
    } catch (e) {
      debugPrint('⚠️ Crashlytics initialization failed: $e');
      // Set up basic error handling even if Crashlytics fails
      FlutterError.onError = (errorDetails) {
        FlutterError.presentError(errorDetails);
      };
      PlatformDispatcher.instance.onError = (error, stack) => true;
    }
    
    // Enable Firestore offline persistence
    try {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      debugPrint('✅ Firestore offline persistence enabled');
    } catch (e) {
      ErrorHandlerService().logError(
        e,
        reason: 'Failed to enable Firestore offline persistence',
      );
      debugPrint('⚠️ Failed to enable offline persistence: $e');
      // Continue without offline support
    }
    
    // Initialize push notifications
    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      final pushService = PushNotificationService();
      await pushService.initialize();
      debugPrint('✅ Push notifications initialized');
    } catch (e) {
      ErrorHandlerService().logError(
        e,
        reason: 'Failed to initialize push notifications',
      );
      debugPrint('⚠️ Push notifications initialization failed: $e');
    }

    // Initialize Analytics
    try {
      AnalyticsService().initialize();
      debugPrint('✅ Analytics initialized');
    } catch (e) {
      debugPrint('⚠️ Analytics initialization failed: $e');
    }

    // Initialize Remote Config
    try {
      final remoteConfig = RemoteConfigService();
      await remoteConfig.initialize();
      debugPrint('✅ Remote Config initialized');
    } catch (e) {
      debugPrint('⚠️ Remote Config initialization failed: $e');
    }
  } catch (e) {
    // Firebase not configured or initialization failed
    // App will continue in limited mode (no crash)
    Env.limitedMode = true;
    debugPrint('⚠️ Firebase initialization failed: $e');
    debugPrint('⚠️ App running in LIMITED MODE (Firebase features disabled)');
    debugPrint('💡 To enable Firebase, run: flutterfire configure');
  }
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    // Initialize deep link service
    DeepLinkService().initialize(router: router);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      
      // Theme - Futuristic Football Design
      theme: futuristicDarkTheme,
      darkTheme: futuristicDarkTheme,
      themeMode: ThemeMode.dark, // Force dark mode for futuristic theme
      
      // Localization & RTL
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('he'), // Default to Hebrew
      
      // Router
      routerConfig: router,
      
      // RTL Support & Error handling
      builder: (context, child) {
        // Set custom error widget builder
        ErrorWidget.builder = (FlutterErrorDetails details) {
          // Show error screen instead of red screen
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'שגיאה בטעינת האפליקציה',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    details.exception.toString(),
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      // Try to navigate to auth
                      router.go('/auth');
                    },
                    child: const Text('נסה שוב'),
                  ),
                ],
              ),
            ),
          );
        };
        
        return Directionality(
          textDirection: TextDirection.rtl, // Hebrew is RTL
          child: child!,
        );
      },
    );
  }
}
