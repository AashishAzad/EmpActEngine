class ApiConstants {
  // Base URLs
  // static const String baseUrl = 'http://10.0.2.2:3000/api/v1'; // Android emulator
  // static const String baseUrl = 'http://192.168.1.34:3000/api/v1'; // Android real device
  // static const String baseUrl = 'http://10.82.130.144:3000/api/v1'; // My personal IP
  // static const String wsUrl = 'ws://10.0.2.2:3000/notifications'; // WebSocket


  static const String baseUrl = 'http://192.168.1.35:8080/api/v1'; // Android real device : Java backend runs on 8080
  static const String wsUrl = 'ws://10.0.2.2:8080/notifications'; // WebSocket : Java backend runs on 8080

  // For physical device, use your computer's IP:
  // static const String baseUrl = 'http://192.168.1.100:3000/api/v1';
  // static const String wsUrl = 'ws://192.168.1.100:3000/notifications';

  // For iOS simulator:
  // static const String baseUrl = 'http://localhost:3000/api/v1';
  // static const String wsUrl = 'ws://localhost:3000/notifications';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Auth Endpoints
  static const String login = '/auth/login';
  static const String profile = '/auth/profile';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';

  // Employee Endpoints
  static const String employees = '/employees';
  static const String employeeStatistics = '/employees/statistics';
  static String employeeById(String id) => '/employees/$id';
  static String employeeByEmployeeId(String employeeId) =>
      '/employees/by-employee-id/$employeeId';

  // Attendance Endpoints
  static const String markAttendance = '/attendance/mark';
  static const String todayAttendance = '/attendance/today';
  static const String manualAttendanceRequest = '/attendance/manual-request';
  static const String pendingManualRequests = '/attendance/manual-requests/pending';
  static const String attendance = '/attendance';
  static const String attendanceSummary = '/attendance/summary';
  static const String myAttendance = '/attendance/my-attendance';
  static String manualRequestAction(String id) =>
      '/attendance/manual-requests/$id/action';

  // Leave Endpoints
  static const String leaves = '/leaves'; // ✅ ADDED for data source
  static const String applyLeave = '/leaves';
  static const String myLeaves = '/leaves/my-leaves';
  static const String myLeaveBalance = '/leaves/my-balance';
  static const String pendingLeaves = '/leaves/pending';
  static const String leaveStatistics = '/leaves/statistics';
  static String leaveBalance(String employeeId) => '/leaves/balance/$employeeId';
  static String leaveAction(String id) => '/leaves/$id/action';

  // Payroll Endpoints
  static const String createSalary = '/payroll/salary';
  static const String generatePayslip = '/payroll/generate-payslip';
  static const String mySalary = '/payroll/my-salary';
  static const String myPayslips = '/payroll/my-payslips';
  static const String myRecentPayslips = '/payroll/my-recent-payslips';
  static const String payslips = '/payroll/payslips';
  static const String payrollStatistics = '/payroll/statistics';
  static String salary(String employeeId) => '/payroll/salary/$employeeId';
  static String downloadPayslip(String id) => '/payroll/payslips/$id/download';

  // Notification Endpoints
  static const String notifications = '/notifications';
  static const String unreadCount = '/notifications/unread-count';
  static const String wsStatus = '/notifications/ws-status';
  static String markAsRead(String id) => '/notifications/$id/read';
  static String deleteNotification(String id) => '/notifications/$id';

  // Letter Endpoints
  static const String letters = '/letters'; // ✅ ADDED for data source
  static const String myLetters = '/letters/my-requests'; // ✅ ADDED for data source
  static const String requestLetter = '/letters/request';
  static const String myLetterRequests = '/letters/my-requests';
  static const String pendingLetters = '/letters/pending';
  static const String letterStatistics = '/letters/statistics';
  static String uploadLetter(String id) => '/letters/$id/upload';
  static String rejectLetter(String id) => '/letters/$id/reject';
  static String downloadLetter(String id) => '/letters/$id/download';
}