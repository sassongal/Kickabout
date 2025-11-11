import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kickabout/theme.dart';
import 'package:kickabout/core/constants.dart';
import 'package:kickabout/config/firebase_options.dart';
import 'package:kickabout/config/env.dart';
import 'package:kickabout/l10n/app_localizations.dart';
import 'package:kickabout/routing/app_router.dart';

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

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      
      // Theme
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      
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
