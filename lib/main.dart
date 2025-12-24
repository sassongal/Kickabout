import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:kattrick/theme/premium_theme.dart';
import 'package:kattrick/core/constants.dart';
import 'package:kattrick/firebase_options.dart';
import 'package:kattrick/config/env.dart';
import 'package:kattrick/l10n/app_localizations.dart';
import 'package:kattrick/routing/app_router.dart';
import 'package:kattrick/services/push_notification_service.dart';
import 'package:kattrick/services/deep_link_service.dart';
import 'package:kattrick/services/error_handler_service.dart';
import 'package:kattrick/services/analytics_service.dart';
import 'package:kattrick/services/remote_config_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';
import 'package:kattrick/widgets/animations/kinetic_loading_animation.dart';
// Conditional import for Crashlytics (not available on Web)
import 'package:firebase_crashlytics/firebase_crashlytics.dart'
    if (dart.library.html) 'package:kattrick/services/crashlytics_stub.dart';
import 'package:kattrick/services/web_maps_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

/// Initialize background services (non-blocking)
Future<void> _initializeBackgroundServices() async {
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
}

/// Main entry point of the application.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // Inject Google Maps API key to window for web platform
  // This allows index.html to access it via JavaScript
  injectGoogleMapsApiKeyForWeb();

  final bool servicesInitialized = await _initializeAppServices();

  if (servicesInitialized) {
    runApp(
      const ProviderScope(
        child: MyApp(),
      ),
    );
  } else {
    runApp(
      const MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        home: LimitedModeScreen(),
      ),
    );
  }
}


/// Initializes all essential app services and returns true on success.
Future<bool> _initializeAppServices() async {
  try {
    // Initialize Firebase first, as it's critical.
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized successfully');

    // Enable Firebase App Check (debug providers for dev)
    // In debug mode: Uses debug provider which generates a debug token
    // In production: Uses Play Integrity (Android) or App Attest (iOS)
    await FirebaseAppCheck.instance.activate(
      androidProvider:
          kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.appAttest,
    );

    if (kDebugMode) {
      debugPrint('🔐 Firebase App Check enabled in DEBUG mode');
      debugPrint('📋 IMPORTANT: Look for "DebugAppCheckProvider" in logcat to get the debug token');
      debugPrint('📝 Then add it to Firebase Console > App Check > Apps > Manage debug tokens');
      debugPrint('⚠️ Debug token changes when you reinstall the app!');
    } else {
      debugPrint('✅ Firebase App Check enabled (production mode)');
    }

    // Set up global error handling and Crashlytics.
    _initializeErrorHandling();

    // Enable Firestore offline persistence.
    _initializeFirestoreCache();

    // UX FIX: Keep guest sessions active to improve retention
    // Anonymous users can now persist their data across app restarts
    // They should explicitly sign out or link their account to save data permanently
    // await _handleAnonymousUserSignOut();  // REMOVED

    // Initialize non-critical services in parallel.
    await Future.wait([
      _initializePushNotifications(),
      _initializeBackgroundServices(), // This is already fire-and-forget
    ]);

    Env.limitedMode = false;
    return true;
  } catch (e, stackTrace) {
    // If any critical initialization fails, enter limited mode.
    Env.limitedMode = true;
    debugPrint('⚠️ Firebase initialization failed: $e');
    debugPrint('Stack trace: $stackTrace');
    debugPrint('⚠️ App running in LIMITED MODE (Firebase features disabled)');
    debugPrint('💡 To enable Firebase, run: flutterfire configure');
    return false;
  }
}

/// Configures Crashlytics and global error handlers.
void _initializeErrorHandling() {
  if (kIsWeb) {
    // Basic error handling for Web (without Crashlytics)
    FlutterError.onError = FlutterError.presentError;
    PlatformDispatcher.instance.onError = (error, stack) => true;
    debugPrint('✅ Crashlytics disabled for Web. Basic error handling enabled.');
    return;
  }

  try {
    // Pass all uncaught Flutter framework errors to Crashlytics.
    FlutterError.onError = (errorDetails) {
      final message = errorDetails.exceptionAsString();
      if (message.contains('RenderFlex overflowed')) {
        FlutterError.presentError(errorDetails);
        FirebaseCrashlytics.instance.recordError(
          errorDetails.exception,
          errorDetails.stack ?? StackTrace.current,
          fatal: false,
          reason: 'RenderFlex overflow',
        );
        return;
      }
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };

    // Pass all uncaught async errors to Crashlytics.
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true; // Mark as handled.
    };
    debugPrint('✅ Crashlytics initialized');
  } catch (e) {
    debugPrint('⚠️ Crashlytics initialization failed: $e');
    // Fallback to basic error handling if Crashlytics fails.
    FlutterError.onError = FlutterError.presentError;
    PlatformDispatcher.instance.onError = (error, stack) => true;
  }
}

/// Enables Firestore's offline persistence.
void _initializeFirestoreCache() {
  try {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    debugPrint('✅ Firestore offline persistence enabled');
  } catch (e) {
    ErrorHandlerService()
        .logError(e, reason: 'Failed to enable Firestore cache');
  }
}

/// Initializes push notifications and background message handler.
Future<void> _initializePushNotifications() async {
  try {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await PushNotificationService().initialize();
    debugPrint('✅ Push notifications initialized');
  } catch (e) {
    ErrorHandlerService()
        .logError(e, reason: 'Failed to init push notifications');
  }
}

/// UX FIX: Guest sessions are now persisted to improve retention
/// Previously this function signed out anonymous users on every app restart,
/// causing data loss and poor UX for users trying the app.
///
/// Users who want to try the app anonymously can keep their data
/// until they explicitly sign out or link their account.
///
/// REMOVED - Keeping for reference
// Future<void> _handleAnonymousUserSignOut() async {
//   final auth = FirebaseAuth.instance;
//   if (auth.currentUser?.isAnonymous ?? false) {
//     debugPrint('🔓 Signing out anonymous user on startup...');
//     await auth.signOut();
//     debugPrint('✅ Anonymous user signed out.');
//   }
// }

/// Limited mode screen - shown when Firebase initialization fails
class LimitedModeScreen extends StatefulWidget {
  const LimitedModeScreen({super.key});

  @override
  State<LimitedModeScreen> createState() => _LimitedModeScreenState();
}

class _LimitedModeScreenState extends State<LimitedModeScreen> {
  bool _isRetrying = false;

  Future<void> _retryInitialization() async {
    setState(() => _isRetrying = true);

    final bool success = await _initializeAppServices();

    if (success && mounted) {
      // On success, run the main app.
      runApp(const ProviderScope(child: MyApp()));
    } else if (mounted) {
      // On failure, stop the loading indicator and show a snackbar.
      setState(() => _isRetrying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('החיבור נכשל. נסה שוב מאוחר יותר.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud_off,
                size: 80,
                color: Colors.orange,
              ),
              const SizedBox(height: 24),
              Text(
                'שגיאת חיבור לשרת',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'לא ניתן להתחבר לשרת. אנא סגור ופתח את האפליקציה מחדש.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'אם הבעיה נמשכת, בדוק את חיבור האינטרנט שלך.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (_isRetrying)
                const KineticLoadingAnimation(size: 40)
              else
                ElevatedButton.icon(
                  onPressed: _retryInitialization,
                  icon: const Icon(Icons.refresh),
                  label: const Text('נסה שוב'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
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

      // Theme - Premium Football Design
      theme: premiumTheme,
      darkTheme: premiumTheme,
      themeMode: ThemeMode.dark, // Force dark mode for premium theme

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
          // Check if user is authenticated before redirecting
          final isAuthenticated = FirebaseAuth.instance.currentUser != null;

          // Show error screen instead of red screen
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'שגיאה בטעינת האפליקציה',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      details.exception.toString(),
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        // Navigate to home if authenticated, otherwise to auth
                        if (isAuthenticated) {
                          router.go('/');
                        } else {
                          router.go('/auth');
                        }
                      },
                      child: const Text('נסה שוב'),
                    ),
                  ],
                ),
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
