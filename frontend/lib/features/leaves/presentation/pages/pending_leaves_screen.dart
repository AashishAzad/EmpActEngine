import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_utils.dart' as app_date;
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../abstracts/leave_data_source.dart';
import '../../data/datasources/leave_remote_data_source.dart';

/// Pending Leaves Screen — Admin/Manager only
///
/// Approve or reject pending leave applications.
/// Data from GET /leaves/pending → List<LeaveResponse>
///
/// Approve: PATCH /leaves/{id}/approve (no body)
/// Reject:  PATCH /leaves/{id}/reject  (body: ActionLeaveRequest { status, actionRemarks })

class PendingLeavesScreen extends StatefulWidget {
  PendingLeavesScreen({
    super.key,
    LeaveDataSource? dataSource,
  }) : dataSource = dataSource ??
            LeaveRemoteDataSource(dioClient: DioClient());

  final LeaveDataSource dataSource;

  @override
  State<PendingLeavesScreen> createState() => _PendingLeavesScreenState();
}

class _PendingLeavesScreenState extends State<PendingLeavesScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _pendingLeaves = [];

  @override
  void initState() {
    super.initState();
    _loadPendingLeaves();
  }

  Future<void> _loadPendingLeaves() async {
    setState(() => _isLoading = true);
    try {
      // GET /leaves/pending → List<LeaveResponse> directly
      final raw = await widget.dataSource.getPendingLeaves();
      setState(() {
        _pendingLeaves = raw.cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _approveLeave(String id) async {
    try {
      // PATCH /leaves/{id}/approve — no body needed
      await widget.dataSource.approveLeave(leaveId: id);

      setState(() {
        _pendingLeaves.removeWhere((leave) => leave['id'].toString() == id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Leave approved successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to approve: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _rejectLeave(String id) async {
    final actionRemarks = await _showRejectDialog();
    if (actionRemarks == null) return; // cancelled

    try {
      // PATCH /leaves/{id}/reject
      // Body: ActionLeaveRequest { status: "REJECTED", actionRemarks: "..." }
      await widget.dataSource.rejectLeave(
        leaveId: id,
        actionRemarks: actionRemarks,
      );

      setState(() {
        _pendingLeaves.removeWhere((leave) => leave['id'].toString() == id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Leave rejected'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<String?> _showRejectDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Leave'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Rejection Reason',
            hintText: 'Enter reason for rejection',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Please enter rejection reason')),
                );
                return;
              }
              Navigator.pop(context, controller.text.trim());
            },
            child: Text('Reject',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pending Leave Requests'),
            if (_pendingLeaves.isNotEmpty)
              Text(
                '${_pendingLeaves.length} pending',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.white.withOpacity(0.9),
                ),
              ),
          ],
        ),
        backgroundColor: AppColors.warning,
        foregroundColor: AppColors.white,
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading pending leaves...')
          : _pendingLeaves.isEmpty
          ? const EmptyState(
        icon: Icons.pending_actions,
        title: 'No Pending Requests',
        message: 'All leave requests have been processed',
      )
          : RefreshIndicator(
        onRefresh: _loadPendingLeaves,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _pendingLeaves.length,
          itemBuilder: (context, index) =>
              _buildLeaveCard(_pendingLeaves[index]),
        ),
      ),
    );
  }

  Widget _buildLeaveCard(Map<String, dynamic> leave) {
    final id = leave['id']?.toString() ?? '';
    final leaveType = leave['leaveType']?.toString() ?? 'CASUAL';

    // Employee info from nested EmployeeInfo object
    final employee =
        leave['employee'] as Map<String, dynamic>? ?? {};
    final firstName = employee['firstName']?.toString() ?? 'Unknown';
    final lastName = employee['lastName']?.toString() ?? '';
    final employeeId = employee['employeeId']?.toString() ?? '';

    // Dates
    DateTime? startDate;
    DateTime? endDate;
    try {
      startDate = DateTime.parse(leave['startDate']);
      endDate = DateTime.parse(leave['endDate']);
    } catch (_) {}

    final days = (leave['numberOfDays'] as num?)?.toInt() ??
        (startDate != null && endDate != null
            ? endDate.difference(startDate).inDays + 1
            : 0);

    // remarks = employee's reason for leave (LeaveResponse.remarks)
    final remarks = leave['remarks']?.toString() ?? 'No reason provided';

    DateTime? appliedOn;
    try {
      appliedOn = DateTime.parse(leave['createdAt']);
    } catch (_) {}

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
          // ── Employee Info ───────────────────────────────────────────────
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Text(
                  firstName[0] + (lastName.isNotEmpty ? lastName[0] : ''),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$firstName $lastName',
                        style: AppTextStyles.titleMedium),
                    Text(employeeId, style: AppTextStyles.caption),
                  ],
                ),
              ),
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
            ],
          ),
          const SizedBox(height: 16),

          // ── Leave Details ───────────────────────────────────────────────
          if (startDate != null && endDate != null)
            _buildDetailRow(
              Icons.calendar_today,
              'Period',
              '${DateFormat('dd MMM yyyy').format(startDate)} - ${DateFormat('dd MMM yyyy').format(endDate)}',
            ),
          const SizedBox(height: 8),
          _buildDetailRow(
            Icons.event_note,
            'Duration',
            '$days ${days == 1 ? 'day' : 'days'}',
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            Icons.description,
            'Reason',
            remarks.isEmpty ? 'No reason provided' : remarks,
          ),
          if (appliedOn != null) ...[
            const SizedBox(height: 8),
            _buildDetailRow(
              Icons.access_time,
              'Applied',
              app_date.DateUtils.getTimeAgo(appliedOn),
            ),
          ],
          const SizedBox(height: 16),

          // ── Action Buttons ──────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Reject',
                  onPressed: () => _rejectLeave(id),
                  variant: ButtonVariant.secondary,
                  backgroundColor: AppColors.error,
                  height: 40,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: 'Approve',
                  onPressed: () => _approveLeave(id),
                  backgroundColor: AppColors.success,
                  height: 40,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodySmall
                .copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  String _formatLeaveType(String type) {
    switch (type) {
      case AppConstants.casualLeave:
        return 'Casual Leave';
      case AppConstants.sickLeave:
        return 'Sick Leave';
      case AppConstants.allPurposeLeave:
        return 'All Purpose';
      default:
        return type;
    }
  }
}