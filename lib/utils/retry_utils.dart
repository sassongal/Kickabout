import 'dart:async';
import 'package:kattrick/shared/infrastructure/logging/error_handler_service.dart';

/// Retry utility for network operations
class RetryUtils {
  /// Retry an operation with exponential backoff
  static Future<T> retry<T>({
    required Future<T> Function() operation,
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
    bool Function(dynamic error)? shouldRetry,
    String? context,
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (attempt < maxRetries) {
      try {
        return await operation();
      } catch (error) {
        attempt++;

        // Check if we should retry this error
        if (shouldRetry != null && !shouldRetry(error)) {
          ErrorHandlerService().logError(
            error,
            reason: context != null 
                ? '$context: Should not retry' 
                : 'Should not retry',
          );
          rethrow;
        }

        // If this was the last attempt, rethrow
        if (attempt >= maxRetries) {
          ErrorHandlerService().logError(
            error,
            reason: context != null 
                ? '$context: Max retries reached ($maxRetries)' 
                : 'Max retries reached ($maxRetries)',
          );
          rethrow;
        }

        // Wait before retrying (exponential backoff)
        await Future.delayed(delay);
        delay = Duration(
          milliseconds: (delay.inMilliseconds * 2).clamp(0, 10000),
        );

        ErrorHandlerService().logMessage(
          context != null
              ? '$context: Retry attempt $attempt/$maxRetries'
              : 'Retry attempt $attempt/$maxRetries',
        );
      }
    }

    // This should never be reached, but just in case
    throw Exception('Retry failed after $maxRetries attempts');
  }

  /// Check if error is retryable (network errors, timeouts)
  static bool isRetryableError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('timeout') ||
        errorString.contains('socket') ||
        errorString.contains('failed host lookup') ||
        errorString.contains('connection refused');
  }

  /// Retry with default settings for network operations
  static Future<T> retryNetwork<T>({
    required Future<T> Function() operation,
    String? context,
  }) {
    return retry(
      operation: operation,
      maxRetries: 3,
      initialDelay: const Duration(seconds: 1),
      shouldRetry: isRetryableError,
      context: context,
    );
  }
}

