import 'package:flutter/foundation.dart';

/// Performance utilities for optimization
class PerformanceUtils {
  /// Check if running in release mode
  static bool get isReleaseMode => kReleaseMode;

  /// Check if running in debug mode
  static bool get isDebugMode => kDebugMode;

  /// Disable debug logging in release mode
  static void debugLog(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  /// Measure execution time
  static T measureTime<T>(String label, T Function() function) {
    if (kDebugMode) {
      final stopwatch = Stopwatch()..start();
      final result = function();
      stopwatch.stop();
      debugPrint('⏱️ $label: ${stopwatch.elapsedMilliseconds}ms');
      return result;
    }
    return function();
  }

  /// Debounce function calls
  static void debounce(
    String tag,
    Duration delay,
    VoidCallback action,
  ) {
    // Simple debounce implementation
    // In production, use a proper debounce utility
    Future.delayed(delay, action);
  }
}

