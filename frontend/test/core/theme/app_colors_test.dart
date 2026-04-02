import 'package:employee_activity_app/core/theme/app_colors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppColors', () {
    test('maps attendance statuses to expected colors', () {
      expect(AppColors.getAttendanceColor('PRESENT'), AppColors.attendancePresent);
      expect(
        AppColors.getAttendanceColor('manual_approved'),
        AppColors.attendancePresent,
      );
      expect(AppColors.getAttendanceColor('PENDING'), AppColors.attendancePending);
      expect(AppColors.getAttendanceColor('UNKNOWN'), AppColors.textSecondary);
    });

    test('maps leave types to expected colors', () {
      expect(AppColors.getLeaveTypeColor('CASUAL'), AppColors.casualLeave);
      expect(AppColors.getLeaveTypeColor('sick'), AppColors.sickLeave);
      expect(
        AppColors.getLeaveTypeColor('all_purpose'),
        AppColors.allPurposeLeave,
      );
      expect(AppColors.getLeaveTypeColor('other'), AppColors.textSecondary);
    });

    test('maps leave statuses to expected colors', () {
      expect(AppColors.getLeaveStatusColor('APPROVED'), AppColors.leaveApproved);
      expect(AppColors.getLeaveStatusColor('rejected'), AppColors.leaveRejected);
      expect(AppColors.getLeaveStatusColor('pending'), AppColors.leavePending);
      expect(AppColors.getLeaveStatusColor('other'), AppColors.textSecondary);
    });

    test('maps roles to expected colors', () {
      expect(AppColors.getRoleColor('ADMIN'), AppColors.roleAdmin);
      expect(AppColors.getRoleColor('manager'), AppColors.roleManager);
      expect(AppColors.getRoleColor('employee'), AppColors.roleEmployee);
      expect(AppColors.getRoleColor('guest'), AppColors.textSecondary);
    });
  });
}
