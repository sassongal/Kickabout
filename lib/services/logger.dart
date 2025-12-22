import 'package:flutter/foundation.dart';

class AppLogger {
  static void debug(String message, {Object? error, StackTrace? stackTrace}) {
    if (!kDebugMode) return;
    if (error != null) {
      debugPrint('$message: $error');
    } else {
      debugPrint(message);
    }
    if (stackTrace != null) {
      debugPrint(stackTrace.toString());
    }
  }
}
