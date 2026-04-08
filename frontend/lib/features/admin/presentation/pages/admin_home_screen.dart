import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_utils.dart' as app_date;
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../leaves/abstracts/leave_data_source.dart';
import '../../../leaves/data/datasources/leave_remote_data_source.dart';
import '../../../admin/data/datasources/admin_payroll_data_source.dart';
import '../../abstracts/admin_payroll_source.dart';

/// Admin Home Screen
///
/// Shows notification feed of all pending requests.
/// Loads from:
///   GET /leaves/pending            → List<LeaveResponse>
///   GET /letters/pending           → List<LetterRequestResponse>

class AdminHomeScreen extends StatefulWidget {
  AdminHomeScreen({
    super.key,
    LeaveDataSource? leaveDataSource,
    AdminPayrollSource? payrollDataSource,
  })  : leaveDataSource =
            leaveDataSource ?? LeaveRemoteDataSource(dioClient: DioClient()),
        payrollDataSource =
            payrollDataSource ?? AdminPayrollDataSource(dioClient: DioClient());

  final LeaveDataSource leaveDataSource;
  final AdminPayrollSource payrollDataSource;

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  bool _isLoading = false;
  List<dynamic> _pendingLeaves = [];
  List<dynamic> _pendingLetters = [];

  @override
  void initState() {
    super.initState();
    _loadPendingRequests();
  }

  Future<void> _loadPendingRequests() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        widget.leaveDataSource.getPendingLeaves(),
        widget.payrollDataSource.getPendingLetterRequests(),
      ]);
      setState(() {
        _pendingLeaves = results[0];
        _pendingLetters = results[1];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _allRequests {
    final requests = <Map<String, dynamic>>[];

    for (var leave in _pendingLeaves) {
      DateTime? time;
      try { time = DateTime.parse(leave['createdAt']); } catch (_) {}
      requests.add({
        'type': 'LEAVE',
        'data': leave,
        'title': 'Leave Request',
        'subtitle': '${leave['employee']?['firstName'] ?? 'Employee'} requested leave',
        'time': time ?? DateTime.now(),
      });
    }

    for (var letter in _pendingLetters) {
      DateTime? time;
      try { time = DateTime.parse(letter['createdAt']); } catch (_) {}
      requests.add({
        'type': 'LETTER',
        'data': letter,
        'title': 'Letter Request',
        'subtitle': '${letter['employee']?['firstName'] ?? 'Employee'} requested ${letter['letterType']}',
        'time': time ?? DateTime.now(),
      });
    }

    requests.sort((a, b) =>
        (b['time'] as DateTime).compareTo(a['time'] as DateTime));
    return requests;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is Authenticated) {
          final user = state.user;

          return Scaffold(
            backgroundColor: AppColors.background,
            body: RefreshIndicator(
              onRefresh: _loadPendingRequests,
              child: CustomScrollView(
                slivers: [
                  // ── App Bar ──────────────────────────────────────────────
                  SliverAppBar(
                    expandedHeight: 180,
                    floating: false,
                    pinned: true,
                    backgroundColor: AppColors.primary,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient),
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  '909 Technologies',
                                  style: AppTextStyles.titleLarge.copyWith(
                                    color: AppColors.white.withOpacity(0.9),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      user.fullName,
                                      style:
                                      AppTextStyles.headlineSmall.copyWith(
                                        color: AppColors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.white.withOpacity(0.2),
                                        borderRadius:
                                        BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        user.employeeId,
                                        style:
                                        AppTextStyles.bodyMedium.copyWith(
                                          color: AppColors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Header ───────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Pending Requests',
                              style: AppTextStyles.titleLarge),
                          if (_allRequests.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${_allRequests.length}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // ── Feed ─────────────────────────────────────────────────
                  _isLoading
                      ? const SliverFillRemaining(
                    child: LoadingIndicator(
                        message: 'Loading requests...'),
                  )
                      : _allRequests.isEmpty
                      ? const SliverFillRemaining(
                    child: EmptyState(
                      icon: Icons.check_circle_outline,
                      title: 'All Caught Up!',
                      message:
                      'No pending requests at the moment',
                    ),
                  )
                      : SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildRequestCard(
                          _allRequests[index]),
                      childCount: _allRequests.length,
                    ),
                  ),
                ],
              ),
            ),

            floatingActionButton: Padding(
              padding: const EdgeInsets.only(bottom: 60),
              child: FloatingActionButton.extended(
                heroTag: 'admin_home_fab',
                onPressed: () =>
                    context.push('/admin/generate-notification'),
                backgroundColor: AppColors.primary,
                icon: const Icon(Icons.notifications_active,
                    color: AppColors.white),
                label: Text(
                  'Generate Notification',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }

        return const Scaffold(
            body: Center(child: CircularProgressIndicator()));
      },
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final type = request['type'] as String;
    final title = request['title'] as String;
    final subtitle = request['subtitle'] as String;
    final time = request['time'] as DateTime;

    Color typeColor;
    IconData typeIcon;
    switch (type) {
      case 'LEAVE':
        typeColor = AppColors.warning;
        typeIcon = Icons.event_busy;
        break;
      case 'LETTER':
        typeColor = AppColors.secondary;
        typeIcon = Icons.description;
        break;
      default:
        typeColor = AppColors.textSecondary;
        typeIcon = Icons.notifications;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (type == 'LEAVE') {
              context.push('/admin/pending-leaves');
            } else if (type == 'LETTER') {
              context.push('/admin/pending-letters');
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(typeIcon, color: typeColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 14,
                              color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            app_date.DateUtils.getTimeAgo(time),
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios,
                    size: 16, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}