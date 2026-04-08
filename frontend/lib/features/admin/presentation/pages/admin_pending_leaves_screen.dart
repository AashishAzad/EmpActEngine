import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../leaves/abstracts/leave_data_source.dart';
import '../../../leaves/data/datasources/leave_remote_data_source.dart';

/// Admin Pending Leaves Screen
///
/// Shows all pending leave requests with approve/reject options.
/// GET  /leaves/pending          → List<LeaveResponse>
/// PATCH /leaves/{id}/approve    → no body
/// PATCH /leaves/{id}/reject     → ActionLeaveRequest { status, actionRemarks }

class AdminPendingLeavesScreen extends StatefulWidget {
  AdminPendingLeavesScreen({
    super.key,
    LeaveDataSource? dataSource,
  }) : dataSource = dataSource ?? LeaveRemoteDataSource(dioClient: DioClient());

  final LeaveDataSource dataSource;

  @override
  State<AdminPendingLeavesScreen> createState() =>
      _AdminPendingLeavesScreenState();
}

class _AdminPendingLeavesScreenState
    extends State<AdminPendingLeavesScreen> {
  bool _isLoading = false;
  List<dynamic> _pendingLeaves = [];

  @override
  void initState() {
    super.initState();
    _loadPendingLeaves();
  }

  Future<void> _loadPendingLeaves() async {
    setState(() => _isLoading = true);
    try {
      final leaves = await widget.dataSource.getPendingLeaves();
      setState(() {
        _pendingLeaves = leaves;
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

  Future<void> _approveLeave(String leaveId, String employeeName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Leave'),
        content: Text('Approve leave request for $employeeName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await widget.dataSource.approveLeave(leaveId: leaveId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Leave approved successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadPendingLeaves();
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

  Future<void> _rejectLeave(String leaveId, String employeeName) async {
    final reasonController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Leave'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reject leave request for $employeeName?'),
            const SizedBox(height: 16),
            CustomTextField(
              controller: reasonController,
              label: 'Reason for rejection',
              hint: 'Enter reason',
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Reject',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (result != true) return;

    if (reasonController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please provide a reason'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    try {
      // rejectLeave expects 'actionRemarks' (from ActionLeaveRequest)
      await widget.dataSource.rejectLeave(
        leaveId: leaveId,
        actionRemarks: reasonController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Leave rejected'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadPendingLeaves();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pending Leaves'),
            Text(
              '${_pendingLeaves.length} requests',
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
          ? const LoadingIndicator(message: 'Loading leave requests...')
          : _pendingLeaves.isEmpty
          ? const EmptyState(
        icon: Icons.check_circle_outline,
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
    final id = leave['id'].toString();
    final employee =
        leave['employee'] as Map<String, dynamic>? ?? {};
    final firstName = employee['firstName']?.toString() ?? 'Unknown';
    final lastName = employee['lastName']?.toString() ?? '';
    final employeeName = '$firstName $lastName';
    final employeeId = employee['employeeId']?.toString() ?? 'N/A';
    final leaveType = leave['leaveType']?.toString() ?? 'N/A';
    final numberOfDays = (leave['numberOfDays'] as num?)?.toInt() ?? 0;
    // remarks = employee's reason (LeaveResponse.remarks)
    final remarks = leave['remarks']?.toString() ?? 'No remarks';
    final contactNumber = leave['contactNumber']?.toString() ?? 'N/A';
    final contactEmail = leave['contactEmail']?.toString() ?? 'N/A';

    DateTime? start;
    DateTime? end;
    try {
      if (leave['startDate'] != null) start = DateTime.parse(leave['startDate']);
      if (leave['endDate'] != null) end = DateTime.parse(leave['endDate']);
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Employee Info ─────────────────────────────────────────
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    firstName.isNotEmpty ? firstName[0] : '?',
                    style: AppTextStyles.titleMedium.copyWith(
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
                      Text(employeeName,
                          style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.bold)),
                      Text(employeeId, style: AppTextStyles.caption),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getLeaveTypeColor(leaveType).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    leaveType,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: _getLeaveTypeColor(leaveType),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Details ───────────────────────────────────────────────
            _buildDetailRow('Duration', '$numberOfDays day(s)'),
            if (start != null)
              _buildDetailRow('From',
                  DateFormat('dd MMM yyyy').format(start)),
            if (end != null)
              _buildDetailRow(
                  'To', DateFormat('dd MMM yyyy').format(end)),
            _buildDetailRow('Contact', contactNumber),
            _buildDetailRow('Email', contactEmail),
            const SizedBox(height: 12),

            // ── Reason ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reason:',
                    style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(remarks, style: AppTextStyles.bodyMedium),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Action Buttons ────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Reject',
                    onPressed: () =>
                        _rejectLeave(id, employeeName),
                    variant: ButtonVariant.text,
                    icon: Icons.close,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: 'Approve',
                    onPressed: () =>
                        _approveLeave(id, employeeName),
                    backgroundColor: AppColors.success,
                    icon: Icons.check,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodySmall
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // LeaveType enum values: CASUAL, SICK, ALL_PURPOSE
  Color _getLeaveTypeColor(String type) {
    switch (type) {
      case 'CASUAL':
        return AppColors.primary;
      case 'SICK':
        return AppColors.error;
      case 'ALL_PURPOSE':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }
}