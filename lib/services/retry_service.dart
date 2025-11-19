import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// Retry configuration
class RetryConfig {
  final int maxAttempts;
  final Duration initialDelay;
  final Duration maxDelay;
  final double backoffMultiplier;
  final bool Function(dynamic error)? shouldRetry;

  const RetryConfig({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 30),
    this.backoffMultiplier = 2.0,
    this.shouldRetry,
  });

  /// Default retry config for network operations
  static const RetryConfig network = RetryConfig(
    maxAttempts: 3,
    initialDelay: Duration(seconds: 1),
    maxDelay: Duration(seconds: 10),
  );

  /// Retry config for critical operations
  static const RetryConfig critical = RetryConfig(
    maxAttempts: 5,
    initialDelay: Duration(seconds: 2),
    maxDelay: Duration(seconds: 30),
  );

  /// Retry config for non-critical operations
  static const RetryConfig quick = RetryConfig(
    maxAttempts: 2,
    initialDelay: Duration(milliseconds: 500),
    maxDelay: Duration(seconds: 5),
  );
}

/// Service for retrying operations with exponential backoff
class RetryService {
  static final RetryService _instance = RetryService._internal();
  factory RetryService() => _instance;
  RetryService._internal();

  /// Execute a function with retry logic
  Future<T> execute<T>(
    Future<T> Function() operation, {
    RetryConfig config = RetryConfig.network,
    String? operationName,
  }) async {
    int attempt = 0;
    Duration delay = config.initialDelay;
    Exception? lastError;

    while (attempt < config.maxAttempts) {
      try {
        final result = await operation();
        if (attempt > 0) {
          debugPrint('✅ Retry succeeded for ${operationName ?? "operation"} after $attempt attempts');
        }
        return result;
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        attempt++;

        // Check if we should retry this error
        if (config.shouldRetry != null && !config.shouldRetry!(e)) {
          debugPrint('❌ Not retrying ${operationName ?? "operation"}: $e');
          rethrow;
        }

        if (attempt >= config.maxAttempts) {
          debugPrint('❌ Max retries reached for ${operationName ?? "operation"}: $e');
          rethrow;
        }

        // Calculate next delay with exponential backoff and jitter
        delay = Duration(
          milliseconds: min(
            (delay.inMilliseconds * config.backoffMultiplier).round(),
            config.maxDelay.inMilliseconds,
          ),
        );
        
        // Add jitter to prevent thundering herd
        final jitter = Random().nextInt(500);
        final finalDelay = Duration(milliseconds: delay.inMilliseconds + jitter);

        debugPrint('⚠️ Retry ${operationName ?? "operation"} attempt $attempt/$config.maxAttempts after ${finalDelay.inMilliseconds}ms: $e');
        await Future.delayed(finalDelay);
      }
    }

    throw lastError ?? Exception('Operation failed after ${config.maxAttempts} attempts');
  }

  /// Execute with custom retry condition
  Future<T> executeWithCondition<T>(
    Future<T> Function() operation,
    bool Function(dynamic error) shouldRetry, {
    RetryConfig config = RetryConfig.network,
    String? operationName,
  }) {
    return execute(
      operation,
      config: RetryConfig(
        maxAttempts: config.maxAttempts,
        initialDelay: config.initialDelay,
        maxDelay: config.maxDelay,
        backoffMultiplier: config.backoffMultiplier,
        shouldRetry: shouldRetry,
      ),
      operationName: operationName,
    );
  }
}

/// Helper functions for common retry scenarios
class RetryHelpers {
  /// Retry only on network errors
  static bool isNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('socket') ||
        errorString.contains('timeout') ||
        errorString.contains('failed host lookup');
  }

  /// Retry only on transient errors (not permanent failures)
  static bool isTransientError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return isNetworkError(error) ||
        errorString.contains('service unavailable') ||
        errorString.contains('internal server error') ||
        errorString.contains('bad gateway');
  }

  /// Don't retry on permission errors
  static bool shouldNotRetry(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('permission') ||
        errorString.contains('unauthorized') ||
        errorString.contains('forbidden') ||
        errorString.contains('not found') ||
        errorString.contains('already exists');
  }
}

