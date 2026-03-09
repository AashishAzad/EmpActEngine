class AppConstants {
  // App Info
  static const String appName = 'Employee Activity';
  static const String appVersion = '1.0.0';
  static const String companyName = '909 Technologies';

  // Pagination
  static const int defaultPageSize = 10;
  static const int maxPageSize = 100;

  // Leave Types
  static const String casualLeave = 'CASUAL';
  static const String sickLeave = 'SICK';
  static const String allPurposeLeave = 'ALL_PURPOSE';

  // Leave Balances (defaults)
  static const int casualLeaveBalance = 8;
  static const int sickLeaveBalance = 8;
  static const int allPurposeLeaveBalance = 10;

  // User Roles
  static const String roleEmployee = 'EMPLOYEE';
  static const String roleManager = 'MANAGER';
  static const String roleAdmin = 'ADMIN';

  // Employee Status
  static const String statusActive = 'ACTIVE';
  static const String statusInactive = 'INACTIVE';
  static const String statusTerminated = 'TERMINATED';

  // Attendance Status
  static const String attendancePresent = 'PRESENT';
  static const String attendanceAbsent = 'ABSENT';
  static const String attendanceLeave = 'LEAVE';
  static const String attendanceHoliday = 'HOLIDAY';
  static const String attendanceManualApproved = 'MANUAL_APPROVED';

  // Leave Status
  static const String leavePending = 'PENDING';
  static const String leaveApproved = 'APPROVED';
  static const String leaveRejected = 'REJECTED';

  // Letter Types
  static const String letterExperience = 'EXPERIENCE';
  static const String letterEmployment = 'EMPLOYMENT';
  static const String letterForm16 = 'FORM_16';
  static const String letterAppraisal = 'APPRAISAL';

  // Letter Status
  static const String letterPending = 'PENDING';
  static const String letterCompleted = 'COMPLETED';
  static const String letterRejected = 'REJECTED';

  // Notification Types
  static const String notificationAnnouncement = 'ANNOUNCEMENT';
  static const String notificationLeaveRequest = 'LEAVE_REQUEST';
  static const String notificationLeaveApproved = 'LEAVE_APPROVED';
  static const String notificationLeaveRejected = 'LEAVE_REJECTED';
  static const String notificationAttendanceReminder = 'ATTENDANCE_REMINDER';
  static const String notificationPayslipGenerated = 'PAYSLIP_GENERATED';
  static const String notificationLetterReady = 'LETTER_READY';

  // Date Formats
  static const String dateFormat = 'dd MMM yyyy';
  static const String dateTimeFormat = 'dd MMM yyyy, hh:mm a';
  static const String timeFormat = 'hh:mm a';
  static const String monthYearFormat = 'MMMM yyyy';

  // Validation
  static const int minPasswordLength = 6;
  static const int maxNameLength = 50;
  static const int maxReasonLength = 500;

  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration normalAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // Snackbar Durations
  static const Duration snackbarShortDuration = Duration(seconds: 2);
  static const Duration snackbarNormalDuration = Duration(seconds: 3);
  static const Duration snackbarLongDuration = Duration(seconds: 5);

  // Location
  static const double locationAccuracyThreshold = 100.0; // meters
  static const Duration locationTimeout = Duration(seconds: 10);

  // WebSocket
  static const Duration wsReconnectDelay = Duration(seconds: 5);
  static const int wsMaxReconnectAttempts = 5;

  // File
  static const int maxFileSize = 10 * 1024 * 1024; // 10 MB
  static const List<String> allowedImageExtensions = ['jpg', 'jpeg', 'png'];
  static const List<String> allowedDocumentExtensions = ['pdf', 'doc', 'docx'];
}