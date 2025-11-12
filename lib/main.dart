import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kickabout/core/app_bootstrap.dart';
import 'package:kickabout/core/constants.dart';
import 'package:kickabout/l10n/app_localizations.dart';
import 'package:kickabout/routing/app_router.dart';
import 'package:kickabout/services/deep_link_service.dart';
import 'package:kickabout/theme.dart';
import 'package:kickabout/theme/futuristic_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: KickaboutApp(),
    ),
  );
}

class KickaboutApp extends ConsumerStatefulWidget {
  const KickaboutApp({super.key});

  @override
  ConsumerState<KickaboutApp> createState() => _KickaboutAppState();
}

class _KickaboutAppState extends ConsumerState<KickaboutApp> {
  bool _deepLinkInitialized = false;

  @override
  Widget build(BuildContext context) {
    final bootstrap = ref.watch(appBootstrapProvider);

    return bootstrap.when(
      data: (result) {
        final router = ref.watch(routerProvider);
        _initializeDeepLinks(router);
        return _buildMaterialApp(
          router: router,
          limitedMode: result.isLimitedMode,
        );
      },
      loading: () => _buildMaterialApp(
        limitedMode: false,
        loading: true,
      ),
      error: (error, stackTrace) => _buildMaterialApp(
        limitedMode: true,
        error: error,
      ),
    );
  }

  void _initializeDeepLinks(GoRouter router) {
    if (_deepLinkInitialized) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DeepLinkService().initialize(router: router);
    });
    _deepLinkInitialized = true;
  }

  MaterialApp _buildBaseMaterialApp({
    Widget? home,
    required bool limitedMode,
    bool loading = false,
    Object? error,
  }) {
    final builder = (BuildContext context, Widget? child) {
      final content = child ?? const SizedBox.shrink();

      Widget wrappedContent = content;
      if (limitedMode) {
        wrappedContent = Stack(
          children: [
            content,
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Material(
                color: Colors.amber.shade700,
                elevation: 2,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 16.0,
                    ),
                    child: Text(
                      'האפליקציה פועלת במצב מוגבל - חלק מהפונקציות עשויות שלא לפעול.',
                      textAlign: TextAlign.center,
                      style: futuristicDarkTheme.textTheme.bodyMedium?.copyWith(
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }

      return Directionality(
        textDirection: TextDirection.rtl,
        child: wrappedContent,
      );
    };

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: futuristicDarkTheme,
      darkTheme: futuristicDarkTheme,
      themeMode: ThemeMode.dark,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('he'),
      home: home ??
          Scaffold(
            body: Center(
              child: error != null
                  ? Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.cloud_off, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            'אירעה שגיאה באתחול: $error',
                            textAlign: TextAlign.center,
                            style: futuristicDarkTheme.textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'המשכנו במצב מוגבל ללא Firebase.',
                            textAlign: TextAlign.center,
                            style: futuristicDarkTheme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    )
                  : const CircularProgressIndicator.adaptive(),
            ),
          ),
      builder: builder,
    );
  }

  Widget _buildMaterialApp({
    GoRouter? router,
    required bool limitedMode,
    bool loading = false,
    Object? error,
  }) {
    if (router != null && !loading && error == null) {
      return MaterialApp.router(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: futuristicDarkTheme,
        darkTheme: futuristicDarkTheme,
        themeMode: ThemeMode.dark,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('he'),
        routerConfig: router,
        builder: (context, child) {
          final content = child ?? const SizedBox.shrink();

          return Directionality(
            textDirection: TextDirection.rtl,
            child: limitedMode
                ? Stack(
                    children: [
                      content,
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Material(
                          color: Colors.amber.shade700,
                          elevation: 2,
                          child: SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                                horizontal: 16.0,
                              ),
                              child: Text(
                                'האפליקציה פועלת במצב מוגבל - חלק מהפונקציות עשויות שלא לפעול.',
                                textAlign: TextAlign.center,
                                style: futuristicDarkTheme.textTheme.bodyMedium
                                    ?.copyWith(
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : content,
          );
        },
      );
    }

    return _buildBaseMaterialApp(
      limitedMode: limitedMode,
      loading: loading,
      error: error,
    );
  }
}
