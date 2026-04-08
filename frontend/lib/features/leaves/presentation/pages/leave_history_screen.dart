import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../abstracts/leave_data_source.dart';
import '../../data/datasources/leave_remote_data_source.dart';

/// Leave History Screen
///
/// Shows all employee's leave applications.
/// Data from GET /leaves/my-leaves → List<LeaveResponse>
///
/// LeaveResponse fields used:
/// id, leaveType, startDate, endDate, numberOfDays, status,
/// remarks (employee's reason), actionRemarks (manager's rejection note),
/// actionBy, actionDate, createdAt

class LeaveHistoryScreen extends StatefulWidget {
  LeaveHistoryScreen({
    super.key,
    LeaveDataSource? dataSource,
  }) : dataSource = dataSource ??
            LeaveRemoteDataSource(dioClient: DioClient());

  final LeaveDataSource dataSource;

  @override
  State<LeaveHistoryScreen> createState() => _LeaveHistoryScreenState();
}

class _LeaveHistoryScreenState extends State<LeaveHistoryScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _applications = [];
  String _selectedFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadLeaveHistory();
  }

  Future<void> _loadLeaveHistory() async {
    setState(() => _isLoading = true);
    try {
      // GET /leaves/my-leaves → List<LeaveResponse> directly
      final raw = await widget.dataSource.getMyLeaves();
      setState(() {
        _applications = raw.cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load history: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredApplications {
    if (_selectedFilter == 'ALL') return _applications;
    return _applications
        .where((app) => app['status'] == _selectedFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Leave History'),
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.white,
      ),
      body: Column(
        children: [
          // ── Filter Chips ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('ALL', 'All'),
                  const SizedBox(width: 8),
                  _buildFilterChip('PENDING', 'Pending'),
                  const SizedBox(width: 8),
                  _buildFilterChip('APPROVED', 'Approved'),
                  const SizedBox(width: 8),
                  _buildFilterChip('REJECTED', 'Rejected'),
                ],
              ),
            ),
          ),

          // ── Leave List ─────────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const LoadingIndicator(
                message: 'Loading leave history...')
                : _filteredApplications.isEmpty
                ? EmptyState(
              icon: Icons.event_busy,
              title: 'No Leave Applications',
              message: _selectedFilter == 'ALL'
                  ? 'You haven\'t applied for any leaves yet'
                  : 'No $_selectedFilter leaves found',
            )
                : RefreshIndicator(
              onRefresh: _loadLeaveHistory,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _filteredApplications.length,
                itemBuilder: (context, index) =>
                    _buildLeaveCard(_filteredApplications[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = value),
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
      labelStyle: AppTextStyles.bodySmall.copyWith(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildLeaveCard(Map<String, dynamic> leave) {
    final leaveType = leave['leaveType']?.toString() ?? 'CASUAL';
    final status = leave['status']?.toString() ?? 'PENDING';

    // LeaveResponse.startDate / endDate are LocalDate — serialized as "2026-02-23"
    DateTime? startDate;
    DateTime? endDate;
    try {
      startDate = DateTime.parse(leave['startDate']);
      endDate = DateTime.parse(leave['endDate']);
    } catch (_) {}

    // numberOfDays is provided by backend — use it directly, fallback to calculation
    final days = (leave['numberOfDays'] as num?)?.toInt() ??
        (startDate != null && endDate != null
            ? endDate.difference(startDate).inDays + 1
            : 0);

    // remarks = employee's reason (ApplyLeaveRequest.remarks)
    final remarks = leave['remarks']?.toString() ?? '';

    // actionRemarks = manager/admin rejection note (ActionLeaveRequest.actionRemarks)
    final actionRemarks = leave['actionRemarks']?.toString();

    // Applied on date
    DateTime? appliedOn;
    try {
      appliedOn = DateTime.parse(leave['createdAt']);
    } catch (_) {}

    final statusColor = AppColors.getLeaveStatusColor(status);
    final typeColor = AppColors.getLeaveTypeColor(leaveType);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _formatLeaveType(leaveType),
                  style: AppTextStyles.caption.copyWith(
                    color: typeColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: AppTextStyles.caption.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Date Range ─────────────────────────────────────────────────
          if (startDate != null && endDate != null) ...[
            Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  '${DateFormat('dd MMM yyyy').format(startDate)} - ${DateFormat('dd MMM yyyy').format(endDate)}',
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // ── Duration ───────────────────────────────────────────────────
          Row(
            children: [
              Icon(Icons.event_note,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                '$days ${days == 1 ? 'day' : 'days'}',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── Reason (remarks) ───────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.description,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  remarks.isEmpty ? 'No reason provided' : remarks,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontStyle: remarks.isEmpty
                        ? FontStyle.italic
                        : FontStyle.normal,
                    color: remarks.isEmpty
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),

          // ── Action Remarks (rejection note from manager) ───────────────
          // LeaveResponse.actionRemarks — only shown when REJECTED
          if (status == 'REJECTED' &&
              actionRemarks != null &&
              actionRemarks.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: AppColors.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Rejection Note: $actionRemarks',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Applied On ─────────────────────────────────────────────────
          if (appliedOn != null) ...[
            const SizedBox(height: 12),
            Text(
              'Applied on ${DateFormat('dd MMM yyyy').format(appliedOn)}',
              style: AppTextStyles.caption,
            ),
          ],
        ],
      ),
    );
  }

  String _formatLeaveType(String type) {
    switch (type) {
      case AppConstants.casualLeave:
        return 'Casual Leave';
      case AppConstants.sickLeave:
        return 'Sick Leave';
      case AppConstants.allPurposeLeave:
        return 'All Purpose Leave';
      default:
        return type;
    }
  }
}