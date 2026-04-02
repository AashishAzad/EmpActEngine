import 'package:employee_activity_app/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.validateEmployeeId', () {
    test('returns error when employee id is empty', () {
      expect(Validators.validateEmployeeId(''), 'Employee ID is required');
    });

    test('returns error when employee id is too short', () {
      expect(
        Validators.validateEmployeeId('E1'),
        'Employee ID must be at least 3 characters',
      );
    });

    test('returns null for a valid employee id', () {
      expect(Validators.validateEmployeeId('EMP001'), isNull);
    });
  });

  group('Validators.validatePassword', () {
    test('returns error when password is empty', () {
      expect(Validators.validatePassword(null), 'Password is required');
    });

    test('returns error when password is too short', () {
      expect(
        Validators.validatePassword('12345'),
        'Password must be at least 6 characters',
      );
    });

    test('returns null for a valid password', () {
      expect(Validators.validatePassword('password123'), isNull);
    });
  });

  group('Validators.validateIndianPhoneNumber', () {
    test('allows empty phone number because field is optional', () {
      expect(Validators.validateIndianPhoneNumber(''), isNull);
    });

    test('accepts a valid indian phone number with formatting', () {
      expect(Validators.validateIndianPhoneNumber('+91 98765 43210'), isNull);
    });

    test('rejects number with invalid starting digit', () {
      expect(
        Validators.validateIndianPhoneNumber('5123456789'),
        'Please enter a valid 10-digit phone number',
      );
    });
  });

  group('Validators.validateDateRange', () {
    test('returns error when end date is before start date', () {
      final startDate = DateTime(2026, 3, 31);
      final endDate = DateTime(2026, 3, 30);

      expect(
        Validators.validateDateRange(startDate, endDate),
        'End date must be after start date',
      );
    });

    test('returns null for a valid date range', () {
      final startDate = DateTime(2026, 3, 31);
      final endDate = DateTime(2026, 4, 1);

      expect(Validators.validateDateRange(startDate, endDate), isNull);
    });
  });

  group('Validators.validateLeaveDays', () {
    test('returns error when leave balance is insufficient', () {
      expect(
        Validators.validateLeaveDays(5, 3),
        'Insufficient leave balance. Available: 3 days',
      );
    });

    test('returns error when leave exceeds 30 days', () {
      expect(
        Validators.validateLeaveDays(31, 40),
        'Cannot apply for more than 30 days at once',
      );
    });

    test('returns null for valid leave days within balance', () {
      expect(Validators.validateLeaveDays(3, 5), isNull);
    });
  });
}
