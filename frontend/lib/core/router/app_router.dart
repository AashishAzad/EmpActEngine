import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/attendance/presentation/pages/attendance_history_screen.dart';
import '../../features/attendance/presentation/pages/mark_attendance_screen.dart';
import '../../features/leaves/presentation/pages/apply_leave_screen.dart';
import '../../features/leaves/presentation/pages/leave_history_screen.dart';
import '../../features/leaves/presentation/pages/pending_leaves_screen.dart';
import '../../features/letters/presentation/pages/request_letter_screen.dart';
import '../../features/notification/presentation/pages/notifications_screen.dart';
import '../../features/payroll/presentation/pages/my_salary_screen.dart';
import '../../features/payroll/presentation/pages/payslips_screen.dart';
import '../../features/profile/presentation/pages/settings_screen.dart';
import '../utils/storage_helper.dart';
import '../../features/auth/presentation/pages/splash_screen.dart';
import '../../features/auth/presentation/pages/login_screen.dart';
import 'role_based_home_wrapper.dart';

// Attendance imports
import '../../features/attendance/presentation/pages/manual_attendance_request_screen.dart';

// Leave imports
import '../../features/leaves/presentation/pages/leave_balance_screen.dart';

// Payroll imports
import '../../features/payroll/presentation/pages/payslip_detail_screen.dart';

import '../../features/letters/presentation/pages/my_letter_requests_screen.dart';

// Profile imports
import '../../features/profile/presentation/pages/profile_screen.dart';
import '../../features/profile/presentation/pages/edit_profile_screen.dart';

// Admin imports
import '../../features/admin/presentation/pages/generate_notification_screen.dart';
import '../../features/admin/presentation/pages/add_employee_screen.dart';
import '../../features/admin/presentation/pages/edit_employee_screen.dart';
import '../../features/admin/presentation/pages/admin_pending_leaves_screen.dart';
import '../../features/admin/presentation/pages/admin_pending_letters_screen.dart';
import '../../features/admin/presentation/pages/company_screen.dart';
import '../../features/admin/presentation/pages/correction_screen.dart';
import '../../features/admin/presentation/pages/generator_screen.dart';

/// App Router
///
/// Centralized navigation using go_router
///
/// Routes:
/// - /splash - Splash screen
/// - /login - Login screen
/// - /home - Home with bottom navigation
/// - /attendance - Attendance screens
/// - /leaves - Leave management
/// - /payroll - Salary & payslips
/// - /notifications - Notifications
/// - /profile - User profile

class AppRouter {
  static final _storageHelper = StorageHelper();

  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    redirect: _handleRedirect,
    routes: [
      // ========== SPLASH ==========
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // ========== AUTH ==========
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      // ========== HOME ==========
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const RoleBasedHomeWrapper(), // ✅ CHANGED: Role-based routing
        routes: [
          // Home nested routes can go here
        ],
      ),

      // ========== ATTENDANCE ==========
      GoRoute(
        path: '/attendance/mark',
        name: 'mark-attendance',
        builder: (context, state) => const MarkAttendanceScreen(),
      ),
      GoRoute(
        path: '/attendance/history',
        name: 'attendance-history',
        builder: (context, state) => const AttendanceHistoryScreen(),
      ),
      GoRoute(
        path: '/attendance/manual-request',
        name: 'manual-attendance-request',
        builder: (context, state) => const ManualAttendanceRequestScreen(),
      ),

      // ========== LEAVES ==========
      GoRoute(
        path: '/leaves/apply',
        name: 'apply-leave',
        builder: (context, state) => const ApplyLeaveScreen(),
      ),
      GoRoute(
        path: '/leaves/history',
        name: 'leave-history',
        builder: (context, state) => const LeaveHistoryScreen(),
      ),
      GoRoute(
        path: '/leaves/balance',
        name: 'leave-balance',
        builder: (context, state) => const LeaveBalanceScreen(),
      ),
      GoRoute(
        path: '/leaves/pending',
        name: 'pending-leaves',
        builder: (context, state) => const PendingLeavesScreen(),
      ),

      // ========== PAYROLL ==========
      GoRoute(
        path: '/payroll/salary',
        name: 'my-salary',
        builder: (context, state) => const MySalaryScreen(),
      ),
      GoRoute(
        path: '/payroll/payslips',
        name: 'payslips',
        builder: (context, state) => const PayslipsScreen(),
      ),
      GoRoute(
        path: '/payroll/payslips/:id',
        name: 'payslip-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return PayslipDetailScreen(payslipId: id);
        },
      ),

      // ========== NOTIFICATIONS ==========
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),

      // ========== LETTERS ==========
      GoRoute(
        path: '/letters/request',
        name: 'request-letter',
        builder: (context, state) => const RequestLetterScreen(),
      ),
      GoRoute(
        path: '/letters/my-requests',
        name: 'my-letter-requests',
        builder: (context, state) => const MyLetterRequestsScreen(),
      ),

      // ========== PROFILE ==========
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
        routes: [
          GoRoute(
            path: 'edit',
            name: 'edit-profile',
            builder: (context, state) => const EditProfileScreen(),
          ),
          GoRoute(
            path: 'settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),

      // ========== ADMIN ROUTES ==========
      GoRoute(
        path: '/admin/generate-notification',
        name: 'admin-generate-notification',
        builder: (context, state) => const GenerateNotificationScreen(),
      ),
      GoRoute(
        path: '/admin/add-employee',
        name: 'admin-add-employee',
        builder: (context, state) => const AddEmployeeScreen(),
      ),
      GoRoute(
        path: '/admin/edit-employee/:id',
        name: 'admin-edit-employee',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return EditEmployeeScreen(employeeId: id);
        },
      ),
      GoRoute(
        path: '/admin/pending-leaves',
        name: 'admin-pending-leaves',
        builder: (context, state) => const AdminPendingLeavesScreen(),
      ),
      GoRoute(
        path: '/admin/pending-letters',
        name: 'admin-pending-letters',
        builder: (context, state) => const AdminPendingLettersScreen(),
      ),
      GoRoute(
        path: '/admin/company',
        name: 'admin-company',
        builder: (context, state) => const CompanyScreen(),
      ),
      GoRoute(
        path: '/admin/correction',
        name: 'admin-correction',
        builder: (context, state) => const CorrectionScreen(),
      ),
      GoRoute(
        path: '/admin/generator',
        name: 'admin-generator',
        builder: (context, state) => const GeneratorScreen(),
      ),
    ],
    errorBuilder: (context, state) => const ErrorScreen(),
  );

  /// Handle redirects for authentication
  static Future<String?> _handleRedirect(
      BuildContext context,
      GoRouterState state,
      ) async {
    final isLoggedIn = await _storageHelper.isLoggedIn();
    final isGoingToLogin = state.matchedLocation == '/login';
    final isGoingToSplash = state.matchedLocation == '/splash';

    // Always allow splash screen
    if (isGoingToSplash) {
      return null;
    }

    // If not logged in and not going to login, redirect to login
    if (!isLoggedIn && !isGoingToLogin) {
      return '/login';
    }

    // If logged in and going to login, redirect to home
    if (isLoggedIn && isGoingToLogin) {
      return '/home';
    }

    // No redirect needed
    return null;
  }
}

// ========== ERROR SCREEN ==========

class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('404 - Page Not Found'),
      ),
    );
  }
}