import 'package:flutter_test/flutter_test.dart';
import 'package:kickadoor/utils/validation_utils.dart';

void main() {
  group('ValidationUtils', () {
    group('validateEmail', () {
      test('should return null for valid emails', () {
        expect(ValidationUtils.validateEmail('test@example.com'), isNull);
        expect(ValidationUtils.validateEmail('user.name@domain.co.il'), isNull);
        expect(ValidationUtils.validateEmail('user+tag@example.com'), isNull);
      });

      test('should return error message for invalid emails', () {
        expect(ValidationUtils.validateEmail('invalid'), isNotNull);
        expect(ValidationUtils.validateEmail('@example.com'), isNotNull);
        expect(ValidationUtils.validateEmail('user@'), isNotNull);
        expect(ValidationUtils.validateEmail('user@domain'), isNotNull);
        expect(ValidationUtils.validateEmail(''), isNotNull);
      });
    });

    group('validatePhone', () {
      test('should return null for valid Israeli phone numbers', () {
        expect(ValidationUtils.validatePhone('0501234567'), isNull);
        expect(ValidationUtils.validatePhone('052-123-4567'), isNull);
        expect(ValidationUtils.validatePhone('054 123 4567'), isNull);
      });

      test('should return error message for invalid phone numbers', () {
        expect(ValidationUtils.validatePhone('123'), isNotNull);
        expect(ValidationUtils.validatePhone('05012345'), isNotNull);
        expect(ValidationUtils.validatePhone('', required: true), isNotNull);
      });
    });

    group('validateName', () {
      test('should return null for valid names', () {
        expect(ValidationUtils.validateName('John Doe'), isNull);
        expect(ValidationUtils.validateName('יוסי כהן'), isNull);
        expect(ValidationUtils.validateName('Jean-Pierre'), isNull);
      });

      test('should return error message for invalid names', () {
        expect(ValidationUtils.validateName(''), isNotNull);
        expect(ValidationUtils.validateName('A'), isNotNull);
      });
    });

    group('validateCity', () {
      test('should return null for valid cities', () {
        expect(ValidationUtils.validateCity('Tel Aviv'), isNull);
        expect(ValidationUtils.validateCity('תל אביב'), isNull);
        expect(ValidationUtils.validateCity('New York'), isNull);
      });

      test('should return error message for invalid cities', () {
        expect(ValidationUtils.validateCity(''), isNotNull);
        expect(ValidationUtils.validateCity('A'), isNotNull);
      });
    });

    group('validateRating', () {
      test('should return null for valid ratings', () {
        expect(ValidationUtils.validateRating('5.0'), isNull);
        expect(ValidationUtils.validateRating('1.0'), isNull);
        expect(ValidationUtils.validateRating('10.0'), isNull);
        expect(ValidationUtils.validateRating('0.0'), isNull);
      });

      test('should return error message for invalid ratings', () {
        expect(ValidationUtils.validateRating('11.0'), isNotNull);
        expect(ValidationUtils.validateRating('-1.0'), isNotNull);
        expect(ValidationUtils.validateRating('invalid'), isNotNull);
        expect(ValidationUtils.validateRating(''), isNotNull);
      });
    });

    group('sanitizeText', () {
      test('should remove leading/trailing whitespace', () {
        expect(ValidationUtils.sanitizeText('  hello  '), 'hello');
      });

      test('should collapse multiple spaces', () {
        expect(ValidationUtils.sanitizeText('hello    world'), 'hello world');
      });

      test('should handle empty strings', () {
        expect(ValidationUtils.sanitizeText(''), '');
        expect(ValidationUtils.sanitizeText('   '), '');
      });
    });
  });
}

