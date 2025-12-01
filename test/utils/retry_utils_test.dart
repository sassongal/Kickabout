import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kattrick/firebase_options.dart';
import 'package:kattrick/config/env.dart';
import 'package:kattrick/utils/retry_utils.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    try {
      // Only initialize if not already initialized
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        Env.limitedMode = false;
      }
    } catch (e) {
      // Firebase initialization may fail in test environment
      // Set limited mode so ErrorHandlerService handles it gracefully
      Env.limitedMode = true;
      debugPrint('Firebase initialization skipped in test: $e');
    }
  });

  group('RetryUtils', () {
    test('should retry on retryable errors', () async {
      int attempts = 0;
      
      final result = await RetryUtils.retry(
        operation: () async {
          attempts++;
          if (attempts < 3) {
            throw Exception('network error');
          }
          return 'success';
        },
        maxRetries: 3,
        shouldRetry: (error) => error.toString().contains('network'),
      );

      expect(result, 'success');
      expect(attempts, 3);
    });

    test('should not retry on non-retryable errors', () async {
      int attempts = 0;
      
      expect(
        () => RetryUtils.retry(
          operation: () async {
            attempts++;
            throw Exception('validation error');
          },
          maxRetries: 3,
          shouldRetry: (error) => error.toString().contains('network'),
        ),
        throwsException,
      );

      expect(attempts, 1);
    });

    test('isRetryableError should identify network errors', () {
      expect(RetryUtils.isRetryableError(Exception('network error')), true);
      expect(RetryUtils.isRetryableError(Exception('connection timeout')), true);
      expect(RetryUtils.isRetryableError(Exception('socket error')), true);
      expect(RetryUtils.isRetryableError(Exception('validation error')), false);
    });

    test('retryNetwork should use default settings', () async {
      int attempts = 0;
      
      final result = await RetryUtils.retryNetwork(
        operation: () async {
          attempts++;
          if (attempts < 3) {
            throw Exception('network error');
          }
          return 'success';
        },
      );

      expect(result, 'success');
      expect(attempts, 3);
    });
  });
}

