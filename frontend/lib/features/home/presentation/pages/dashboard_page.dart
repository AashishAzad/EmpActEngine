import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_utils.dart' as app_date;
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../widgets/stat_card.dart';
import '../widgets/quick_action_card.dart';

/// Dashboard Page
///
/// Shows user stats and quick actions.
///
/// Stats are loaded via direct API calls using Dio.
/// The dashboard intentionally reloads every time the user navigates
/// back to it (wantKeepAlive = false) to show fresh data.

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with AutomaticKeepAliveClientMixin {

  // ── Stats State ────────────────────────────────────────────────────────────

  int _attendancePercentage = 0;
  int _pendingLeavesCount = 0;
  int _unreadNotificationsCount = 0;
  bool _isLoadingStats = true;
  String? _statsError;

  @override
  bool get wantKeepAlive => false; // Reload on every tab switch

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadDashboardStats();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (mounted) {
      _loadDashboardStats();
    }
  }

  // ── Load Stats ─────────────────────────────────────────────────────────────
  //
  // Each stat is loaded independently so a failure in one
  // doesn't block the others from rendering.

  Future<void> _loadDashboardStats() async {
    if (!mounted) return;
    setState(() {
      _isLoadingStats = true;
      _statsError = null;
    });

    final now = DateTime.now();

    // Attendance percentage this month
    // Backend: GET /attendance/summary?month=X&year=Y
    // Returns: { totalDays, presentDays, absentDays, leaveDays, percentage }
    await _loadStat(() async {
      // TODO: Replace with your actual AttendanceDataSource call when ready.
      // Example:
      // final summary = await attendanceDataSource.getAttendanceSummary(
      //   month: now.month, year: now.year,
      // );
      // _attendancePercentage = (summary['percentage'] as num).toInt();
      _attendancePercentage = 0; // placeholder until datasource wired up
    });

    // Pending leave count
    // Backend: GET /leaves/my-leaves → List of leave objects with 'status' field
    await _loadStat(() async {
      // TODO: Replace with your actual LeaveDataSource call when ready.
      // Example:
      // final leaves = await leaveDataSource.getMyLeaves();
      // _pendingLeavesCount = leaves.where((l) => l.status == 'PENDING').length;
      _pendingLeavesCount = 0; // placeholder
    });

    // Unread notifications count
    // Backend: GET /notifications/unread-count → { count: N }
    await _loadStat(() async {
      // TODO: Replace with your actual NotificationDataSource call when ready.
      // Example:
      // _unreadNotificationsCount = await notificationDataSource.getUnreadCount();
      _unreadNotificationsCount = 0; // placeholder
    });

    if (mounted) {
      setState(() => _isLoadingStats = false);
    }
  }

  /// Runs a stat-loading lambda and silently catches errors.
  /// Individual stat failures show 0 rather than crashing the whole dashboard.
  Future<void> _loadStat(Future<void> Function() loader) async {
    try {
      await loader();
    } catch (_) {
      // Individual stat failure — keep default value (0), don't crash
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {

        // While token is silently refreshing, keep showing the current user
        // so the dashboard doesn't flash a loading screen
        if (state is TokenRefreshing) {
          return _buildDashboard(context, state.currentUser);
        }

        if (state is TokenRefreshed) {
          return _buildDashboard(context, state.user);
        }

        if (state is Authenticated) {
          return _buildDashboard(context, state.user);
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildDashboard(BuildContext context, dynamic user) {
    return CustomScrollView(
      slivers: [
        // ── App Bar ────────────────────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 200,
          floating: false,
          pinned: true,
          backgroundColor: AppColors.primary,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(gradient: AppColors.primaryGradient),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Welcome Back,',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.white.withOpacity(0.9),
                        ),
                      ),
                      Text(
                        user.firstName,
                        style: AppTextStyles.displaySmall.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        app_date.DateUtils.getCurrentDate(),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // ── Content ────────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Quick Stats
                Text('Quick Stats', style: AppTextStyles.titleLarge),
                const SizedBox(height: 16),

                _isLoadingStats
                    ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: CircularProgressIndicator(),
                  ),
                )
                    : Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            title: 'Attendance',
                            value: '$_attendancePercentage%',
                            subtitle: 'This month',
                            icon: Icons.check_circle,
                            color: AppColors.success,
                            onTap: () =>
                                context.push('/attendance/history'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            title: 'Leave Balance',
                            // totalLeaveBalance computed from
                            // casual + sick + allPurpose on User entity
                            value: '${user.totalLeaveBalance}',
                            subtitle: 'Days remaining',
                            icon: Icons.beach_access,
                            color: AppColors.warning,
                            onTap: () =>
                                context.push('/leaves/balance'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            title: 'Pending Leaves',
                            value: '$_pendingLeavesCount',
                            subtitle: 'Awaiting approval',
                            icon: Icons.pending_actions,
                            color: AppColors.info,
                            onTap: () =>
                                context.push('/leaves/history'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            title: 'Notifications',
                            value: '$_unreadNotificationsCount',
                            subtitle: 'Unread',
                            icon: Icons.notifications,
                            color: AppColors.error,
                            onTap: () =>
                                context.push('/notifications'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Quick Actions
                Text('Quick Actions', style: AppTextStyles.titleLarge),
                const SizedBox(height: 16),
                QuickActionCard(
                  title: 'Mark Attendance',
                  subtitle: 'Mark your today\'s attendance',
                  icon: Icons.location_on,
                  color: AppColors.primary,
                  onTap: () => context.push('/attendance/mark'),
                ),
                const SizedBox(height: 12),
                QuickActionCard(
                  title: 'Apply for Leave',
                  subtitle: 'Request a leave',
                  icon: Icons.event,
                  color: AppColors.secondary,
                  onTap: () => context.push('/leaves/apply'),
                ),
                const SizedBox(height: 12),
                QuickActionCard(
                  title: 'View Salary',
                  subtitle: 'Check your salary details',
                  icon: Icons.account_balance_wallet,
                  color: AppColors.success,
                  onTap: () => context.push('/payroll/salary'),
                ),
                const SizedBox(height: 12),
                QuickActionCard(
                  title: 'Request Letter',
                  subtitle: 'Request employment letter',
                  icon: Icons.description,
                  color: AppColors.warning,
                  onTap: () => context.push('/letters/request'),
                ),

                const SizedBox(height: 24),

                // User Profile Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor:
                            AppColors.primary.withOpacity(0.1),
                            child: Text(
                              user.firstName[0] + user.lastName[0],
                              style: AppTextStyles.titleLarge.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.fullName,
                                  style: AppTextStyles.titleMedium,
                                ),
                                Text(
                                  user.employeeId,
                                  style: AppTextStyles.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      _buildProfileRow(
                          Icons.work, 'Designation', user.designation ?? 'N/A'),
                      const SizedBox(height: 8),
                      _buildProfileRow(
                          Icons.business, 'Department', user.department ?? 'N/A'),
                      const SizedBox(height: 8),
                      _buildProfileRow(Icons.badge, 'Role', user.role),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}