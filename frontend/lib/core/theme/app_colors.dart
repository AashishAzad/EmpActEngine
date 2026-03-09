import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF2196F3); // Blue
  static const Color primaryDark = Color(0xFF1976D2);
  static const Color primaryLight = Color(0xFF64B5F6);

  static const Color secondary = Color(0xFF009688); // Teal
  static const Color secondaryDark = Color(0xFF00796B);
  static const Color secondaryLight = Color(0xFF4DB6AC);

  static const Color accent = Color(0xFF00BCD4); // Cyan

  // Status Colors
  static const Color success = Color(0xFF4CAF50); // Green
  static const Color successLight = Color(0xFF81C784);
  static const Color successDark = Color(0xFF388E3C);

  static const Color error = Color(0xFFF44336); // Red
  static const Color errorLight = Color(0xFFE57373);
  static const Color errorDark = Color(0xFFD32F2F);

  static const Color warning = Color(0xFFFF9800); // Orange
  static const Color warningLight = Color(0xFFFFB74D);
  static const Color warningDark = Color(0xFFF57C00);

  static const Color info = Color(0xFF2196F3); // Blue
  static const Color infoLight = Color(0xFF64B5F6);
  static const Color infoDark = Color(0xFF1976D2);

  // Neutral Colors (Light Theme)
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFFAFAFA);

  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textDisabled = Color(0xFFBDBDBD);
  static const Color textHint = Color(0xFF9E9E9E);

  static const Color divider = Color(0xFFE0E0E0);
  static const Color border = Color(0xFFBDBDBD);
  static const Color borderLight = Color(0xFFEEEEEE);

  // Dark Theme Colors
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color surfaceVariantDark = Color(0xFF2C2C2C);

  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);
  static const Color textDisabledDark = Color(0xFF6B6B6B);
  static const Color textHintDark = Color(0xFF808080);

  static const Color dividerDark = Color(0xFF2C2C2C);
  static const Color borderDark = Color(0xFF3C3C3C);

  // Feature-Specific Colors

  // Attendance
  static const Color attendancePresent = success;
  static const Color attendanceAbsent = error;
  static const Color attendanceLeave = warning;
  static const Color attendanceHoliday = info;
  static const Color attendancePending = Color(0xFF9C27B0); // Purple

  // Leave
  static const Color leaveApproved = success;
  static const Color leaveRejected = error;
  static const Color leavePending = warning;

  // Casual Leave
  static const Color casualLeave = Color(0xFF2196F3); // Blue

  // Sick Leave
  static const Color sickLeave = Color(0xFFFF5722); // Deep Orange

  // All Purpose Leave
  static const Color allPurposeLeave = Color(0xFF9C27B0); // Purple

  // Roles
  static const Color roleAdmin = Color(0xFFF44336); // Red
  static const Color roleManager = Color(0xFFFF9800); // Orange
  static const Color roleEmployee = Color(0xFF4CAF50); // Green

  // Letter Types
  static const Color letterExperience = Color(0xFF2196F3);
  static const Color letterEmployment = Color(0xFF009688);
  static const Color letterForm16 = Color(0xFFFF9800);
  static const Color letterAppraisal = Color(0xFF9C27B0);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [successLight, successDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient errorGradient = LinearGradient(
    colors: [errorLight, errorDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [warningLight, warningDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shadow Colors
  static const Color shadow = Color(0x1A000000);
  static const Color shadowDark = Color(0x33000000);

  // Shimmer Colors
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);

  static const Color shimmerBaseDark = Color(0xFF2C2C2C);
  static const Color shimmerHighlightDark = Color(0xFF3C3C3C);

  // Chart Colors
  static const List<Color> chartColors = [
    Color(0xFF2196F3), // Blue
    Color(0xFF4CAF50), // Green
    Color(0xFFFF9800), // Orange
    Color(0xFF9C27B0), // Purple
    Color(0xFFF44336), // Red
    Color(0xFF009688), // Teal
    Color(0xFFFF5722), // Deep Orange
    Color(0xFF3F51B5), // Indigo
  ];

  // Special
  static const Color transparent = Colors.transparent;
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // Overlay
  static const Color overlay = Color(0x80000000);
  static const Color overlayLight = Color(0x40000000);
  static const Color overlayDark = Color(0xB3000000);

  // Get color by attendance status
  static Color getAttendanceColor(String status) {
    switch (status.toUpperCase()) {
      case 'PRESENT':
      case 'MANUAL_APPROVED':
        return attendancePresent;
      case 'ABSENT':
        return attendanceAbsent;
      case 'LEAVE':
        return attendanceLeave;
      case 'HOLIDAY':
        return attendanceHoliday;
      case 'PENDING':
        return attendancePending;
      default:
        return textSecondary;
    }
  }

  // Get color by leave type
  static Color getLeaveTypeColor(String type) {
    switch (type.toUpperCase()) {
      case 'CASUAL':
        return casualLeave;
      case 'SICK':
        return sickLeave;
      case 'ALL_PURPOSE':
        return allPurposeLeave;
      default:
        return textSecondary;
    }
  }

  // Get color by leave status
  static Color getLeaveStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return leaveApproved;
      case 'REJECTED':
        return leaveRejected;
      case 'PENDING':
        return leavePending;
      default:
        return textSecondary;
    }
  }

  // Get color by role
  static Color getRoleColor(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return roleAdmin;
      case 'MANAGER':
        return roleManager;
      case 'EMPLOYEE':
        return roleEmployee;
      default:
        return textSecondary;
    }
  }
}