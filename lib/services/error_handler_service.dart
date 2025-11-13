import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:kickadoor/config/env.dart';

/// Centralized error handling service
class ErrorHandlerService {
  static final ErrorHandlerService _instance = ErrorHandlerService._internal();
  factory ErrorHandlerService() => _instance;
  ErrorHandlerService._internal();

  /// Log an error to Crashlytics
  void logError(
    dynamic error, {
    StackTrace? stackTrace,
    String? reason,
    bool fatal = false,
  }) {
    if (!Env.isFirebaseAvailable) {
      debugPrint('Error (Firebase not available): $error');
      if (stackTrace != null) {
        debugPrint('Stack trace: $stackTrace');
      }
      return;
    }

    try {
      if (fatal) {
        FirebaseCrashlytics.instance.recordError(
          error,
          stackTrace,
          reason: reason,
          fatal: fatal,
        );
      } else {
        FirebaseCrashlytics.instance.recordError(
          error,
          stackTrace,
          reason: reason,
        );
      }
    } catch (e) {
      // Fallback if Crashlytics fails
      debugPrint('Failed to log error to Crashlytics: $e');
      debugPrint('Original error: $error');
    }
  }

  /// Log a message to Crashlytics
  void logMessage(String message) {
    if (!Env.isFirebaseAvailable) {
      debugPrint('Log: $message');
      return;
    }

    try {
      FirebaseCrashlytics.instance.log(message);
    } catch (e) {
      debugPrint('Failed to log message to Crashlytics: $e');
      debugPrint('Original message: $message');
    }
  }

  /// Set user identifier for crash reports
  void setUserId(String userId) {
    if (!Env.isFirebaseAvailable) return;

    try {
      FirebaseCrashlytics.instance.setUserIdentifier(userId);
    } catch (e) {
      debugPrint('Failed to set user ID: $e');
    }
  }

  /// Set custom key-value pair for crash reports
  void setCustomKey(String key, dynamic value) {
    if (!Env.isFirebaseAvailable) return;

    try {
      FirebaseCrashlytics.instance.setCustomKey(key, value);
    } catch (e) {
      debugPrint('Failed to set custom key: $e');
    }
  }

  /// Handle and log an exception with user-friendly message
  String handleException(dynamic error, {String? context}) {
    final errorString = error.toString().toLowerCase();
    String userMessage;

    if (errorString.contains('network') || 
        errorString.contains('connection') ||
        errorString.contains('socket') ||
        errorString.contains('timeout')) {
      userMessage = 'שגיאת רשת. נסה שוב.';
    } else if (errorString.contains('permission') || 
               errorString.contains('unauthorized') ||
               errorString.contains('access denied')) {
      userMessage = 'אין לך הרשאה לבצע פעולה זו.';
    } else if (errorString.contains('auth') || 
               errorString.contains('login') ||
               errorString.contains('sign in')) {
      userMessage = 'שגיאת אימות. נסה להתחבר מחדש.';
    } else if (errorString.contains('not found')) {
      userMessage = 'הפריט המבוקש לא נמצא.';
    } else if (errorString.contains('already exists') ||
               errorString.contains('duplicate')) {
      userMessage = 'הפריט כבר קיים.';
    } else {
      userMessage = 'שגיאה לא ידועה. נסה שוב.';
    }

    // Log to Crashlytics
    logError(
      error,
      reason: context != null ? '$context: $userMessage' : userMessage,
    );

    return userMessage;
  }
}

