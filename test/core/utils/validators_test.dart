import 'package:civic_scope/core/utils/validators/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.validateEmail', () {
    test('returns required message when email is null', () {
      expect(Validators.validateEmail(null), 'Email is required');
    });

    test('returns invalid format for malformed email', () {
      expect(Validators.validateEmail('not-an-email'), 'Invalid email format');
    });

    test('returns null for valid email', () {
      expect(Validators.validateEmail('user@example.com'), isNull);
    });
  });

  group('Validators.validatePassword', () {
    test('returns required message when password is empty', () {
      expect(Validators.validatePassword(''), 'Password is required');
    });

    test('returns minimum length message when password is too short', () {
      expect(
        Validators.validatePassword('12345'),
        'Password must be at least 6 characters',
      );
    });

    test('returns null for valid password', () {
      expect(Validators.validatePassword('123456'), isNull);
    });
  });

  group('Validators.validateConfirmPassword', () {
    test('returns required message when confirmation is missing', () {
      expect(
        Validators.validateConfirmPassword(
          password: 'secret123',
          confirmPassword: '',
        ),
        'Please confirm your password',
      );
    });

    test('returns mismatch message when passwords differ', () {
      expect(
        Validators.validateConfirmPassword(
          password: 'secret123',
          confirmPassword: 'secret321',
        ),
        'Passwords do not match',
      );
    });

    test('returns null when passwords match', () {
      expect(
        Validators.validateConfirmPassword(
          password: 'secret123',
          confirmPassword: 'secret123',
        ),
        isNull,
      );
    });
  });

  group('Validators.validateCode', () {
    test('returns required message when code is empty', () {
      expect(Validators.validateCode(''), 'Code is required');
    });

    test('returns length message when code is not six characters', () {
      expect(Validators.validateCode('12345'), 'Code must be 6 characters');
    });

    test('returns numeric message when code contains non-digits', () {
      expect(Validators.validateCode('12ab56'), 'Code must be numeric');
    });

    test('returns null for valid six digit code', () {
      expect(Validators.validateCode('123456'), isNull);
    });
  });
}
