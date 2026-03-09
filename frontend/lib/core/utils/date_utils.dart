import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

/// Date Utilities
///
/// Helper functions for date formatting and manipulation

class DateUtils {
  // Format date to string
  static String formatDate(DateTime date, {String? format}) {
    return DateFormat(format ?? AppConstants.dateFormat).format(date);
  }

  // Format date time to string
  static String formatDateTime(DateTime dateTime, {String? format}) {
    return DateFormat(format ?? AppConstants.dateTimeFormat).format(dateTime);
  }

  // Format time to string
  static String formatTime(DateTime time, {String? format}) {
    return DateFormat(format ?? AppConstants.timeFormat).format(time);
  }

  // Format month and year
  static String formatMonthYear(DateTime date) {
    return DateFormat(AppConstants.monthYearFormat).format(date);
  }

  // Get month name
  static String getMonthName(int month) {
    final date = DateTime(2000, month);
    return DateFormat('MMMM').format(date);
  }

  // Get short month name
  static String getShortMonthName(int month) {
    final date = DateTime(2000, month);
    return DateFormat('MMM').format(date);
  }

  // Get day name
  static String getDayName(DateTime date) {
    return DateFormat('EEEE').format(date);
  }

  // Get short day name
  static String getShortDayName(DateTime date) {
    return DateFormat('EEE').format(date);
  }

  // Get current date
  static String getCurrentDate() {
    final now = DateTime.now();
    return DateFormat('EEEE, MMMM d, y').format(now);
  }

  // Parse date from string
  static DateTime? parseDate(String dateString, {String? format}) {
    try {
      return DateFormat(format ?? AppConstants.dateFormat).parse(dateString);
    } catch (e) {
      return null;
    }
  }

  // Parse ISO date string (from API)
  static DateTime? parseISODate(String isoString) {
    try {
      return DateTime.parse(isoString);
    } catch (e) {
      return null;
    }
  }

  // Convert to ISO string (for API)
  static String toISOString(DateTime date) {
    return date.toIso8601String();
  }

  // Get start of day
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // Get end of day
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  // Get start of month
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  // Get end of month
  static DateTime endOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0, 23, 59, 59, 999);
  }

  // Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  // Check if date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  // Check if date is tomorrow
  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;
  }

  // Check if date is in current month
  static bool isCurrentMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  // Check if date is weekend (Saturday or Sunday)
  static bool isWeekend(DateTime date) {
    return date.weekday == DateTime.saturday ||
        date.weekday == DateTime.sunday;
  }

  // Get number of days between two dates
  static int daysBetween(DateTime start, DateTime end) {
    final startDate = startOfDay(start);
    final endDate = startOfDay(end);
    return endDate.difference(startDate).inDays;
  }

  // Get working days between two dates (excluding weekends)
  static int workingDaysBetween(DateTime start, DateTime end,
      {List<DateTime>? holidays}) {
    int workingDays = 0;
    DateTime current = startOfDay(start);
    final endDate = startOfDay(end);

    while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
      if (!isWeekend(current)) {
        // Check if not a holiday
        if (holidays == null ||
            !holidays.any((h) => isSameDay(h, current))) {
          workingDays++;
        }
      }
      current = current.add(const Duration(days: 1));
    }

    return workingDays;
  }

  // Check if two dates are the same day
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // Get relative date string (Today, Yesterday, etc.)
  static String getRelativeDateString(DateTime date) {
    if (isToday(date)) {
      return 'Today';
    } else if (isYesterday(date)) {
      return 'Yesterday';
    } else if (isTomorrow(date)) {
      return 'Tomorrow';
    } else {
      return formatDate(date);
    }
  }

  // Get time ago string (2 hours ago, 3 days ago, etc.)
  static String getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }

  // Get all dates in a month
  static List<DateTime> getDatesInMonth(int year, int month) {
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    final dates = <DateTime>[];

    for (int day = 1; day <= lastDay.day; day++) {
      dates.add(DateTime(year, month, day));
    }

    return dates;
  }

  // Get current month and year
  static Map<String, int> getCurrentMonthYear() {
    final now = DateTime.now();
    return {
      'month': now.month,
      'year': now.year,
    };
  }

  // Convert month number to name
  static String monthNumberToName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  // Format date range
  static String formatDateRange(DateTime start, DateTime end) {
    if (isSameDay(start, end)) {
      return formatDate(start);
    }

    if (start.month == end.month && start.year == end.year) {
      return '${start.day} - ${formatDate(end)}';
    }

    return '${formatDate(start)} - ${formatDate(end)}';
  }
}