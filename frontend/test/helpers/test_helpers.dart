import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:employee_activity_app/core/errors/exceptions.dart';
import 'package:employee_activity_app/core/theme/app_theme.dart';
import 'package:employee_activity_app/core/utils/storage_helper.dart';
import 'package:employee_activity_app/features/auth/domain/entities/user.dart';
import 'package:employee_activity_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:employee_activity_app/features/admin/data/datasources/admin_employee_data_source.dart';
import 'package:employee_activity_app/features/admin/data/datasources/admin_notification_data_source.dart';
import 'package:employee_activity_app/features/admin/data/datasources/admin_payroll_data_source.dart';
import 'package:employee_activity_app/features/attendance/data/datasources/attendance_remote_data_source.dart';
import 'package:employee_activity_app/features/attendance/presentation/pages/mark_attendance_screen.dart';
import 'package:employee_activity_app/features/leaves/data/datasources/leave_remote_data_source.dart';
import 'package:employee_activity_app/features/letters/data/datasources/letter_remote_data_source.dart';
import 'package:employee_activity_app/features/notification/data/datasources/notification_remote_data_source.dart';
import 'package:employee_activity_app/features/payroll/data/datasources/payroll_remote_data_source.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const testUser = User(
  id: '1',
  employeeId: 'EMP001',
  firstName: 'Aashi',
  lastName: 'Sharma',
  email: 'aashi@example.com',
  role: 'EMPLOYEE',
);

const testAdminUser = User(
  id: '99',
  employeeId: 'ADM001',
  firstName: 'Admin',
  lastName: 'User',
  email: 'admin@example.com',
  role: 'ADMIN',
  phoneNumber: '9876543210',
  designation: 'HR Manager',
  department: 'People',
  dateOfJoining: '2024-01-10',
  qualification: 'MBA',
  address: 'Bengaluru',
  emergencyContact: 'Parent 9999999999',
  casualLeaveBalance: 5,
  sickLeaveBalance: 3,
  allPurposeLeaveBalance: 2,
);

Widget wrapWithMaterialApp(Widget child) {
  GoogleFonts.config.allowRuntimeFetching = false;
  return MaterialApp(
    theme: AppTheme.lightTheme,
    home: child,
  );
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.loginHandler,
    this.getProfileHandler,
    this.logoutHandler,
    this.isLoggedInHandler,
    this.getCurrentUserHandler,
    this.refreshTokenHandler,
  });

  Future<Either<Failure, User>> Function(String employeeId, String password)?
      loginHandler;
  Future<Either<Failure, User>> Function()? getProfileHandler;
  Future<Either<Failure, void>> Function()? logoutHandler;
  Future<Either<Failure, bool>> Function()? isLoggedInHandler;
  Future<Either<Failure, User>> Function()? getCurrentUserHandler;
  Future<Either<Failure, User>> Function(String refreshToken)?
      refreshTokenHandler;

  String? lastLoginEmployeeId;
  String? lastLoginPassword;
  String? lastRefreshToken;
  var logoutCalls = 0;

  @override
  Future<Either<Failure, User>> login(String employeeId, String password) async {
    lastLoginEmployeeId = employeeId;
    lastLoginPassword = password;
    final handler = loginHandler;
    if (handler != null) {
      return handler(employeeId, password);
    }
    return const Right(testUser);
  }

  @override
  Future<Either<Failure, User>> getProfile() async {
    final handler = getProfileHandler;
    if (handler != null) {
      return handler();
    }
    return const Right(testUser);
  }

  @override
  Future<Either<Failure, void>> logout() async {
    logoutCalls += 1;
    final handler = logoutHandler;
    if (handler != null) {
      return handler();
    }
    return const Right(null);
  }

  @override
  Future<Either<Failure, bool>> isLoggedIn() async {
    final handler = isLoggedInHandler;
    if (handler != null) {
      return handler();
    }
    return const Right(false);
  }

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    final handler = getCurrentUserHandler;
    if (handler != null) {
      return handler();
    }
    return const Right(testUser);
  }

  @override
  Future<Either<Failure, User>> refreshToken(String refreshToken) async {
    lastRefreshToken = refreshToken;
    final handler = refreshTokenHandler;
    if (handler != null) {
      return handler(refreshToken);
    }
    return const Right(testUser);
  }
}

Future<void> flushMicrotasks() => Future<void>.delayed(Duration.zero);

StorageHelper testStorageHelper() => StorageHelper();

class FakeNotificationDataSource implements NotificationDataSource {
  FakeNotificationDataSource({
    List<Map<String, dynamic>>? notifications,
    this.getNotificationsError,
    this.markAsReadError,
  }) : notifications = notifications ?? <Map<String, dynamic>>[];

  final List<Map<String, dynamic>> notifications;
  final Object? getNotificationsError;
  final Object? markAsReadError;
  String? lastMarkedId;

  @override
  Future<void> deleteNotification(String id) async {}

  @override
  Future<List<dynamic>> getNotifications({
    bool unreadOnly = false,
    bool includeExpired = false,
    String? type,
  }) async {
    if (getNotificationsError != null) {
      throw getNotificationsError!;
    }
    return notifications;
  }

  @override
  Future<int> getUnreadCount() async {
    return notifications.where((item) => item['isRead'] == false).length;
  }

  @override
  Future<Map<String, dynamic>> markAsRead(String id) async {
    if (markAsReadError != null) {
      throw markAsReadError!;
    }
    lastMarkedId = id;
    return {'id': id, 'isRead': true};
  }
}

class FakeAdminEmployeeDataSource implements AdminEmployeeSource {
  FakeAdminEmployeeDataSource({
    List<Map<String, dynamic>>? employees,
    this.getAllEmployeesError,
    this.deleteEmployeeError,
  }) : employees = employees ?? <Map<String, dynamic>>[];

  final List<Map<String, dynamic>> employees;
  final Object? getAllEmployeesError;
  final Object? deleteEmployeeError;
  String? addedEmployeeIdValue;
  String? addedEmail;
  String? addedPassword;
  String? addedFirstName;
  String? addedLastName;
  String? addedRole;
  String? addedPhoneNumber;
  String? addedDesignation;
  String? addedDepartment;
  String? addedDateOfJoining;
  String? deletedEmployeeId;
  String? updatedEmployeeId;
  Map<String, dynamic>? updatedEmployeePayload;

  @override
  Future<Map<String, dynamic>> addEmployee({
    required String employeeId,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
    String? phoneNumber,
    String? designation,
    String? department,
    String? dateOfJoining,
  }) async {
    addedEmployeeIdValue = employeeId;
    addedEmail = email;
    addedPassword = password;
    addedFirstName = firstName;
    addedLastName = lastName;
    addedRole = role;
    addedPhoneNumber = phoneNumber;
    addedDesignation = designation;
    addedDepartment = department;
    addedDateOfJoining = dateOfJoining;
    return <String, dynamic>{};
  }

  @override
  Future<void> deleteEmployee(String id) async {
    if (deleteEmployeeError != null) {
      throw deleteEmployeeError!;
    }
    deletedEmployeeId = id;
    employees.removeWhere((employee) => employee['id'].toString() == id);
  }

  @override
  Future<List<dynamic>> getAllEmployees({
    String? search,
    String? role,
    String? status,
    String? department,
    int page = 1,
    int limit = 100,
  }) async {
    if (getAllEmployeesError != null) {
      throw getAllEmployeesError!;
    }
    return employees;
  }

  @override
  Future<Map<String, dynamic>> getEmployeeById(String id) async {
    return employees.firstWhere(
      (employee) => employee['id'].toString() == id,
      orElse: () => <String, dynamic>{},
    );
  }

  @override
  Future<Map<String, dynamic>> getEmployeeStatistics() async {
    return <String, dynamic>{};
  }

  @override
  Future<Map<String, dynamic>> updateEmployee({
    required String id,
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? designation,
    String? department,
    String? role,
    String? status,
    String? dateOfJoining,
  }) async {
    updatedEmployeeId = id;
    updatedEmployeePayload = <String, dynamic>{
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'designation': designation,
      'department': department,
      'role': role,
      'status': status,
      'dateOfJoining': dateOfJoining,
    };
    return <String, dynamic>{};
  }
}

class FakeAdminNotificationDataSource implements AdminNotificationSource {
  FakeAdminNotificationDataSource({this.createNotificationError});

  final Object? createNotificationError;
  String? lastTitle;
  String? lastMessage;
  String? lastType;
  bool? lastIsGlobal;
  List<String>? lastRecipientIds;

  @override
  Future<Map<String, dynamic>> createNotification({
    required String title,
    required String message,
    required String type,
    bool isGlobal = false,
    List<String>? recipientIds,
    DateTime? visibleTill,
    String? referenceId,
    String? referenceType,
  }) async {
    if (createNotificationError != null) {
      throw createNotificationError!;
    }
    lastTitle = title;
    lastMessage = message;
    lastType = type;
    lastIsGlobal = isGlobal;
    lastRecipientIds = recipientIds;
    return <String, dynamic>{};
  }
}

class FakeAdminPayrollDataSource implements AdminPayrollSource {
  FakeAdminPayrollDataSource({
    List<Map<String, dynamic>>? pendingLetters,
    this.pendingLettersError,
    this.uploadLetterError,
  }) : pendingLetters = pendingLetters ?? <Map<String, dynamic>>[];

  final List<Map<String, dynamic>> pendingLetters;
  final Object? pendingLettersError;
  final Object? uploadLetterError;
  String? generatedEmployeeId;
  int? generatedMonth;
  int? generatedYear;
  String? uploadedRequestId;
  String? uploadedFilePath;

  @override
  Future<Map<String, dynamic>> generatePayslip({
    required String employeeId,
    required int month,
    required int year,
  }) async {
    generatedEmployeeId = employeeId;
    generatedMonth = month;
    generatedYear = year;
    return <String, dynamic>{};
  }

  @override
  Future<List<dynamic>> getAllPayslips({
    String? employeeId,
    int? month,
    int? year,
    int page = 1,
    int limit = 20,
  }) async {
    return <dynamic>[];
  }

  @override
  Future<List<dynamic>> getPendingLetterRequests() async {
    if (pendingLettersError != null) {
      throw pendingLettersError!;
    }
    return pendingLetters;
  }

  @override
  Future<Map<String, dynamic>> rejectLetter({
    required String requestId,
    String? remarks,
  }) async {
    return <String, dynamic>{};
  }

  @override
  Future<Map<String, dynamic>> uploadLetter({
    required String requestId,
    required String filePath,
  }) async {
    if (uploadLetterError != null) {
      throw uploadLetterError!;
    }
    uploadedRequestId = requestId;
    uploadedFilePath = filePath;
    pendingLetters.removeWhere((letter) => letter['id'].toString() == requestId);
    return <String, dynamic>{};
  }

  @override
  Future<Map<String, dynamic>> upsertSalary({
    required String employeeId,
    required double basicPay,
    required double hra,
    required double specialAllowance,
    double otherAllowances = 0.0,
    required double pf,
    double professionalTax = 0.0,
    double otherDeductions = 0.0,
  }) async {
    return <String, dynamic>{};
  }
}

class FakeAttendanceDataSource implements AttendanceDataSource {
  FakeAttendanceDataSource({
    List<Map<String, dynamic>>? attendanceHistory,
    this.attendanceHistoryError,
    this.manualAttendanceError,
    this.markAttendanceError,
  }) : attendanceHistory = attendanceHistory ?? <Map<String, dynamic>>[];

  final List<Map<String, dynamic>> attendanceHistory;
  final Object? attendanceHistoryError;
  final Object? manualAttendanceError;
  final Object? markAttendanceError;
  DateTime? requestedDate;
  String? requestedReason;
  double? markedLatitude;
  double? markedLongitude;
  String? markedAddress;

  @override
  Future<List<dynamic>> getAttendanceHistory({
    int? month,
    int? year,
  }) async {
    if (attendanceHistoryError != null) {
      throw attendanceHistoryError!;
    }
    return attendanceHistory;
  }

  @override
  Future<Map<String, dynamic>> getAttendanceSummary({
    required int month,
    required int year,
  }) async {
    return <String, dynamic>{};
  }

  @override
  Future<Map<String, dynamic>> getTodayAttendance() async {
    return <String, dynamic>{};
  }

  @override
  Future<Map<String, dynamic>> markAttendance({
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    if (markAttendanceError != null) {
      throw markAttendanceError!;
    }
    markedLatitude = latitude;
    markedLongitude = longitude;
    markedAddress = address;
    return <String, dynamic>{};
  }

  @override
  Future<Map<String, dynamic>> requestManualAttendance({
    required DateTime date,
    required String reason,
  }) async {
    if (manualAttendanceError != null) {
      throw manualAttendanceError!;
    }
    requestedDate = date;
    requestedReason = reason;
    return <String, dynamic>{};
  }
}

class FakeAttendanceLocationService implements AttendanceLocationService {
  FakeAttendanceLocationService({
    this.hasPermissionValue = true,
    this.serviceEnabledValue = true,
    this.location,
    this.locationError,
  });

  final bool hasPermissionValue;
  final bool serviceEnabledValue;
  final LocationSnapshot? location;
  final Object? locationError;

  @override
  Future<LocationSnapshot> getCurrentLocation() async {
    if (locationError != null) {
      throw locationError!;
    }
    return location ??
        const LocationSnapshot(
          latitude: 12.9716,
          longitude: 77.5946,
          accuracy: 10,
          address: 'MG Road, Bengaluru',
        );
  }

  @override
  Future<bool> hasPermission() async => hasPermissionValue;

  @override
  Future<bool> isServiceEnabled() async => serviceEnabledValue;
}

class FakeLetterDataSource implements LetterDataSource {
  FakeLetterDataSource({
    List<Map<String, dynamic>>? myRequests,
    this.myRequestsError,
    this.downloadError,
  }) : myRequests = myRequests ?? <Map<String, dynamic>>[];

  final List<Map<String, dynamic>> myRequests;
  final Object? myRequestsError;
  final Object? downloadError;
  String? downloadedLetterId;

  @override
  Future<List<int>> downloadLetter(String id) async {
    if (downloadError != null) {
      throw downloadError!;
    }
    downloadedLetterId = id;
    return <int>[1, 2, 3];
  }

  @override
  Future<List<dynamic>> getMyLetterRequests() async {
    if (myRequestsError != null) {
      throw myRequestsError!;
    }
    return myRequests;
  }

  @override
  Future<Map<String, dynamic>> requestLetter({
    required String letterType,
    String? remarks,
  }) async {
    return <String, dynamic>{};
  }
}

class FakeLeaveDataSource implements LeaveDataSource {
  FakeLeaveDataSource({
    List<Map<String, dynamic>>? myLeaves,
    List<Map<String, dynamic>>? pendingLeaves,
    this.myLeavesError,
    this.pendingLeavesError,
  })  : myLeaves = myLeaves ?? <Map<String, dynamic>>[],
        pendingLeaves = pendingLeaves ?? <Map<String, dynamic>>[];

  final List<Map<String, dynamic>> myLeaves;
  final List<Map<String, dynamic>> pendingLeaves;
  final Object? myLeavesError;
  final Object? pendingLeavesError;
  String? appliedLeaveType;
  String? appliedStartDate;
  String? appliedEndDate;
  String? appliedContactNumber;
  String? appliedContactEmail;
  String? appliedRemarks;
  String? approvedLeaveId;
  String? rejectedLeaveId;
  String? rejectionRemarks;

  @override
  Future<Map<String, dynamic>> applyLeave({
    required String leaveType,
    required String startDate,
    required String endDate,
    required String contactNumber,
    required String contactEmail,
    String? remarks,
  }) async {
    appliedLeaveType = leaveType;
    appliedStartDate = startDate;
    appliedEndDate = endDate;
    appliedContactNumber = contactNumber;
    appliedContactEmail = contactEmail;
    appliedRemarks = remarks;
    return <String, dynamic>{};
  }

  @override
  Future<void> approveLeave({required String leaveId}) async {
    approvedLeaveId = leaveId;
    pendingLeaves.removeWhere((leave) => leave['id'].toString() == leaveId);
  }

  @override
  Future<List<dynamic>> getMyLeaves() async {
    if (myLeavesError != null) throw myLeavesError!;
    return myLeaves;
  }

  @override
  Future<List<dynamic>> getPendingLeaves() async {
    if (pendingLeavesError != null) throw pendingLeavesError!;
    return pendingLeaves;
  }

  @override
  Future<void> rejectLeave({
    required String leaveId,
    required String actionRemarks,
  }) async {
    rejectedLeaveId = leaveId;
    rejectionRemarks = actionRemarks;
    pendingLeaves.removeWhere((leave) => leave['id'].toString() == leaveId);
  }
}

class FakePayrollDataSource implements PayrollDataSource {
  FakePayrollDataSource({
    this.salaryData,
    this.salaryError,
    this.payslipsResponse,
    this.payslipsError,
    this.payslipById,
    this.payslipByIdError,
  });

  final Map<String, dynamic>? salaryData;
  final Object? salaryError;
  final Map<String, dynamic>? payslipsResponse;
  final Object? payslipsError;
  final Map<String, dynamic>? payslipById;
  final Object? payslipByIdError;

  @override
  Future<List<int>> downloadPayslip(String id) async => <int>[];

  @override
  Future<Map<String, dynamic>> getMyPayslips({
    int? month,
    int? year,
    int page = 1,
    int limit = 10,
  }) async {
    if (payslipsError != null) {
      throw payslipsError!;
    }
    return payslipsResponse ??
        {
      'data': <Map<String, dynamic>>[],
      'totalPages': 1,
    };
  }

  @override
  Future<List<dynamic>> getMyRecentPayslips() async => <dynamic>[];

  @override
  Future<Map<String, dynamic>> getMySalary() async {
    if (salaryError != null) {
      throw salaryError!;
    }
    return salaryData ?? <String, dynamic>{};
  }

  @override
  Future<Map<String, dynamic>> getPayslipById(String id) async =>
      payslipByIdError != null
          ? throw payslipByIdError!
          : (payslipById ?? <String, dynamic>{});
}
