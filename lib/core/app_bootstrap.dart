import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kickabout/config/env.dart';
import 'package:kickabout/data/repositories_providers.dart';
import 'package:kickabout/firebase_options.dart';
import 'package:kickabout/services/push_notification_service.dart';

/// תוצאת אתחול האפליקציה (Bootstrap)
class BootstrapResult {
  final bool firebaseInitialized;
  final bool pushNotificationsEnabled;
  final Object? error;

  const BootstrapResult({
    required this.firebaseInitialized,
    required this.pushNotificationsEnabled,
    this.error,
  });

  bool get isLimitedMode => !firebaseInitialized;
}

/// FutureProvider שמבצע אתחול לא-חוסם עבור Firebase ושירותי רקע נוספים.
final appBootstrapProvider = FutureProvider<BootstrapResult>((ref) async {
  bool firebaseInitialized = false;
  bool pushNotificationsEnabled = false;
  Object? bootstrapError;

  // ודא שהפונטים החיצוניים משורשרים בבנייה ולא נשלפים בזמן ריצה (משפר זמני טעינה).
  GoogleFonts.config.allowRuntimeFetching = false;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseInitialized = true;
    Env.limitedMode = false;

    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    }

    try {
      final pushService = ref.read(pushNotificationServiceProvider);
      pushNotificationsEnabled = await pushService.initialize();
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('⚠️ Push notifications bootstrap failed: $e');
        debugPrint(stackTrace.toString());
      }
      pushNotificationsEnabled = false;
    }
  } catch (e) {
    bootstrapError = e;
    firebaseInitialized = false;
    pushNotificationsEnabled = false;
    Env.limitedMode = true;

    if (kDebugMode) {
      debugPrint('⚠️ Firebase bootstrap failed: $e');
    }
  }

  return BootstrapResult(
    firebaseInitialized: firebaseInitialized,
    pushNotificationsEnabled: pushNotificationsEnabled,
    error: bootstrapError,
  );
});
