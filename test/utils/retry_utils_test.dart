import 'package:flutter_test/flutter_test.dart';
import 'package:kickadoor/utils/retry_utils.dart';

void main() {
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

