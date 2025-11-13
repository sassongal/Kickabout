import 'package:flutter_test/flutter_test.dart';
import 'package:kickadoor/utils/validation_utils.dart';

void main() {
  group('ValidationUtils', () {
    group('validateEmail', () {
      test('should return true for valid emails', () {
        expect(ValidationUtils.validateEmail('test@example.com'), true);
        expect(ValidationUtils.validateEmail('user.name@domain.co.il'), true);
        expect(ValidationUtils.validateEmail('user+tag@example.com'), true);
      });

      test('should return false for invalid emails', () {
        expect(ValidationUtils.validateEmail('invalid'), false);
        expect(ValidationUtils.validateEmail('@example.com'), false);
        expect(ValidationUtils.validateEmail('user@'), false);
        expect(ValidationUtils.validateEmail('user@domain'), false);
        expect(ValidationUtils.validateEmail(''), false);
      });
    });

    group('validatePhone', () {
      test('should return true for valid Israeli phone numbers', () {
        expect(ValidationUtils.validatePhone('0501234567'), true);
        expect(ValidationUtils.validatePhone('052-123-4567'), true);
        expect(ValidationUtils.validatePhone('054 123 4567'), true);
        expect(ValidationUtils.validatePhone('+972501234567'), true);
      });

      test('should return false for invalid phone numbers', () {
        expect(ValidationUtils.validatePhone('123'), false);
        expect(ValidationUtils.validatePhone('05012345'), false);
        expect(ValidationUtils.validatePhone(''), false);
      });
    });

    group('validateName', () {
      test('should return true for valid names', () {
        expect(ValidationUtils.validateName('John Doe'), true);
        expect(ValidationUtils.validateName('יוסי כהן'), true);
        expect(ValidationUtils.validateName('Jean-Pierre'), true);
      });

      test('should return false for invalid names', () {
        expect(ValidationUtils.validateName(''), false);
        expect(ValidationUtils.validateName('A'), false);
        expect(ValidationUtils.validateName('123'), false);
      });
    });

    group('validateCity', () {
      test('should return true for valid cities', () {
        expect(ValidationUtils.validateCity('Tel Aviv'), true);
        expect(ValidationUtils.validateCity('תל אביב'), true);
        expect(ValidationUtils.validateCity('New York'), true);
      });

      test('should return false for invalid cities', () {
        expect(ValidationUtils.validateCity(''), false);
        expect(ValidationUtils.validateCity('A'), false);
      });
    });

    group('validateRating', () {
      test('should return true for valid ratings', () {
        expect(ValidationUtils.validateRating(5.0, min: 1.0, max: 10.0), true);
        expect(ValidationUtils.validateRating(1.0, min: 1.0, max: 10.0), true);
        expect(ValidationUtils.validateRating(10.0, min: 1.0, max: 10.0), true);
      });

      test('should return false for invalid ratings', () {
        expect(ValidationUtils.validateRating(0.0, min: 1.0, max: 10.0), false);
        expect(ValidationUtils.validateRating(11.0, min: 1.0, max: 10.0), false);
        expect(ValidationUtils.validateRating(-1.0, min: 1.0, max: 10.0), false);
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

