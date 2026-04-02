import 'package:employee_activity_app/core/utils/date_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DateUtils', () {
    test('formats month and year correctly', () {
      expect(
        DateUtils.formatMonthYear(DateTime(2026, 4, 1)),
        'April 2026',
      );
    });

    test('returns null for invalid parsed date', () {
      expect(DateUtils.parseDate('not-a-date'), isNull);
    });

    test('calculates working days excluding weekends and holidays', () {
      final start = DateTime(2026, 3, 30); // Monday
      final end = DateTime(2026, 4, 3); // Friday
      final holiday = DateTime(2026, 4, 1);

      expect(
        DateUtils.workingDaysBetween(start, end, holidays: [holiday]),
        4,
      );
    });

    test('returns relative labels for today yesterday and tomorrow', () {
      expect(
        DateUtils.getRelativeDateString(DateTime.now()),
        'Today',
      );
      expect(
        DateUtils.getRelativeDateString(
          DateTime.now().subtract(const Duration(days: 1)),
        ),
        'Yesterday',
      );
      expect(
        DateUtils.getRelativeDateString(
          DateTime.now().add(const Duration(days: 1)),
        ),
        'Tomorrow',
      );
    });

    test('formats time ago strings across ranges', () {
      expect(
        DateUtils.getTimeAgo(
          DateTime.now().subtract(const Duration(seconds: 30)),
        ),
        'Just now',
      );
      expect(
        DateUtils.getTimeAgo(
          DateTime.now().subtract(const Duration(hours: 2)),
        ),
        '2 hours ago',
      );
      expect(
        DateUtils.getTimeAgo(
          DateTime.now().subtract(const Duration(days: 10)),
        ),
        '1 week ago',
      );
    });
  });
}
