import '../../features/notification/data/datasources/notification_remote_data_source.dart';
import '../network/dio_client.dart';
import '../../features/attendance/data/datasources/attendance_remote_data_source.dart';
import '../../features/leaves/data/datasources/leave_remote_data_source.dart';
import '../../features/payroll/data/datasources/payroll_remote_data_source.dart';
import '../../features/letters/data/datasources/letter_remote_data_source.dart';
import '../../features/admin/data/datasources/admin_employee_data_source.dart';
import '../../features/admin/data/datasources/admin_notification_data_source.dart';
import '../../features/admin/data/datasources/admin_payroll_data_source.dart';

/// Service Locator
///
/// Provides singleton instances of data sources
/// Use this to get data sources in screens

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  // Dio Client
  final DioClient dioClient = DioClient();

  // Data Sources (Lazy initialization)
  AttendanceRemoteDataSource? _attendanceDataSource;
  LeaveRemoteDataSource? _leaveDataSource;
  PayrollRemoteDataSource? _payrollDataSource;
  NotificationRemoteDataSource? _notificationDataSource;
  LetterRemoteDataSource? _letterDataSource;
  AdminEmployeeDataSource? _adminEmployeeDataSource;
  AdminNotificationDataSource? _adminNotificationDataSource;
  AdminPayrollDataSource? _adminPayrollDataSource;

  // Getters for data sources
  AttendanceRemoteDataSource get attendanceDataSource {
    _attendanceDataSource ??= AttendanceRemoteDataSource(dioClient: dioClient);
    return _attendanceDataSource!;
  }

  LeaveRemoteDataSource get leaveDataSource {
    _leaveDataSource ??= LeaveRemoteDataSource(dioClient: dioClient);
    return _leaveDataSource!;
  }

  PayrollRemoteDataSource get payrollDataSource {
    _payrollDataSource ??= PayrollRemoteDataSource(dioClient: dioClient);
    return _payrollDataSource!;
  }

  NotificationRemoteDataSource get notificationDataSource {
    _notificationDataSource ??= NotificationRemoteDataSource(dioClient: dioClient);
    return _notificationDataSource!;
  }

  LetterRemoteDataSource get letterDataSource {
    _letterDataSource ??= LetterRemoteDataSource(dioClient: dioClient);
    return _letterDataSource!;
  }

  // Admin Data Sources
  AdminEmployeeDataSource get adminEmployeeDataSource {
    _adminEmployeeDataSource ??= AdminEmployeeDataSource(dioClient: dioClient);
    return _adminEmployeeDataSource!;
  }

  AdminNotificationDataSource get adminNotificationDataSource {
    _adminNotificationDataSource ??= AdminNotificationDataSource(dioClient: dioClient);
    return _adminNotificationDataSource!;
  }

  AdminPayrollDataSource get adminPayrollDataSource {
    _adminPayrollDataSource ??= AdminPayrollDataSource(dioClient: dioClient);
    return _adminPayrollDataSource!;
  }
}