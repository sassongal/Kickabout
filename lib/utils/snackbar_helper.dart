import 'package:flutter/material.dart';
import 'package:kickabout/core/constants.dart';

/// Helper class for showing snackbars consistently
class SnackbarHelper {
  /// Show success snackbar
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show error snackbar
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Show info snackbar
  static void showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show warning snackbar
  static void showWarning(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show error from exception
  static void showErrorFromException(BuildContext context, dynamic error) {
    String message = ErrorMessages.unknownError;
    
    if (error is Exception) {
      final errorString = error.toString().toLowerCase();
      if (errorString.contains('network') || errorString.contains('connection')) {
        message = ErrorMessages.networkError;
      } else if (errorString.contains('permission') || errorString.contains('unauthorized')) {
        message = ErrorMessages.permissionError;
      } else if (errorString.contains('auth')) {
        message = ErrorMessages.authError;
      } else {
        // Try to extract meaningful message
        final match = RegExp(r"'([^']+)'").firstMatch(error.toString());
        if (match != null) {
          message = match.group(1) ?? ErrorMessages.unknownError;
        }
      }
    }
    
    showError(context, message);
  }
}

