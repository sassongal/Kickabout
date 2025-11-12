import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kickabout/theme.dart';
import 'package:kickabout/theme/futuristic_theme.dart';
import 'package:kickabout/core/constants.dart';
import 'package:kickabout/firebase_options.dart';
import 'package:kickabout/config/env.dart';
import 'package:kickabout/l10n/app_localizations.dart';
import 'package:kickabout/routing/app_router.dart';
import 'package:kickabout/services/push_notification_service.dart';
import 'package:kickabout/services/deep_link_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    
    // Enable Firestore offline persistence
    try {
      await FirebaseFirestore.instance.enablePersistence(
        const PersistenceSettings(synchronizeTabs: true),
      );
      debugPrint('✅ Firestore offline persistence enabled');
    } catch (e) {
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
      debugPrint('⚠️ Push notifications initialization failed: $e');
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
      
      // RTL Support
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl, // Hebrew is RTL
          child: child!,
        );
      },
    );
  }
}
