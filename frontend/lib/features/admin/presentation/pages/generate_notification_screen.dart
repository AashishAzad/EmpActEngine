import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../admin/data/datasources/admin_employee_data_source.dart';
import '../../../admin/data/datasources/admin_notification_data_source.dart';

/// Generate Notification Screen
///
/// Admin creates notifications for selected employees or all.
/// Calls POST /notifications
///
/// CreateNotificationRequest fields:
/// title, message, type, isGlobal (bool), recipientIds (List<UUID>),
/// visibleTill (optional), referenceId (optional), referenceType (optional)

class GenerateNotificationScreen extends StatefulWidget {
  GenerateNotificationScreen({
    super.key,
    AdminEmployeeSource? employeeDataSource,
    AdminNotificationSource? notificationDataSource,
  })  : employeeDataSource =
            employeeDataSource ?? AdminEmployeeDataSource(dioClient: DioClient()),
        notificationDataSource = notificationDataSource ??
            AdminNotificationDataSource(dioClient: DioClient());

  final AdminEmployeeSource employeeDataSource;
  final AdminNotificationSource notificationDataSource;

  @override
  State<GenerateNotificationScreen> createState() =>
      _GenerateNotificationScreenState();
}

class _GenerateNotificationScreenState
    extends State<GenerateNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  bool _isLoading = false;
  bool _isLoadingEmployees = false;
  List<dynamic> _employees = [];
  Set<String> _selectedEmployeeIds = {};
  bool _isGlobal = false; // maps to CreateNotificationRequest.isGlobal

  // Notification type values from AppConstants / backend
  // Backend type field is a free-form String — use the constant values
  // that match what the backend recognizes: ANNOUNCEMENT, LEAVE_REQUEST,
  // PAYSLIP_GENERATED, ATTENDANCE_REMINDER, LETTER_READY
  String _selectedType = AppConstants.notificationAnnouncement;

  final List<Map<String, String>> _notificationTypes = [
    {'value': AppConstants.notificationAnnouncement, 'label': 'Announcement'},
    {'value': AppConstants.notificationLeaveRequest, 'label': 'Leave'},
    {'value': AppConstants.notificationPayslipGenerated, 'label': 'Payslip'},
    {'value': AppConstants.notificationAttendanceReminder, 'label': 'Attendance'},
    {'value': AppConstants.notificationLetterReady, 'label': 'Letter'},
  ];

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    setState(() => _isLoadingEmployees = true);
    try {
      final employees = await widget.employeeDataSource.getAllEmployees();
      setState(() {
        _employees = employees;
        _isLoadingEmployees = false;
      });
    } catch (e) {
      setState(() => _isLoadingEmployees = false);
    }
  }

  void _toggleGlobal() {
    setState(() {
      _isGlobal = !_isGlobal;
      if (_isGlobal) _selectedEmployeeIds.clear();
    });
  }

  void _toggleEmployee(String id) {
    setState(() {
      if (_selectedEmployeeIds.contains(id)) {
        _selectedEmployeeIds.remove(id);
      } else {
        _selectedEmployeeIds.add(id);
        // If all selected manually, auto-switch to global
        if (_selectedEmployeeIds.length == _employees.length) {
          _isGlobal = true;
          _selectedEmployeeIds.clear();
        }
      }
    });
  }

  Future<void> _generateNotification() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isGlobal && _selectedEmployeeIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please select at least one employee or send to all'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // POST /notifications
      // isGlobal = true → send to everyone, recipientIds not needed
      // isGlobal = false → send to selected employees via recipientIds
      await widget.notificationDataSource.createNotification(
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
        type: _selectedType,
        isGlobal: _isGlobal,
        recipientIds: _isGlobal ? null : _selectedEmployeeIds.toList(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isGlobal
                  ? 'Notification sent to all employees!'
                  : 'Notification sent to ${_selectedEmployeeIds.length} employee(s)!',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send notification: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Generate Notification'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: _isLoadingEmployees
          ? const LoadingIndicator(message: 'Loading employees...')
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.info.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: AppColors.info, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Create and send notifications to selected employees or everyone',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.info),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Type ─────────────────────────────────────────────
              Text('Notification Type',
                  style: AppTextStyles.titleMedium),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
                ),
                items: _notificationTypes.map((t) {
                  return DropdownMenuItem(
                    value: t['value'],
                    child: Text(t['label']!),
                  );
                }).toList(),
                onChanged: (value) =>
                    setState(() => _selectedType = value!),
              ),
              const SizedBox(height: 16),

              // ── Title ─────────────────────────────────────────────
              CustomTextField(
                controller: _titleController,
                label: 'Title',
                hint: 'Enter notification title',
                prefixIcon: const Icon(Icons.title),
                validator: Validators.validateRequired,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),

              // ── Message ───────────────────────────────────────────
              CustomTextField(
                controller: _messageController,
                label: 'Message',
                hint: 'Enter notification message',
                maxLines: 5,
                prefixIcon: const Icon(Icons.message),
                validator: Validators.validateRequired,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 24),

              // ── Recipients ────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Select Recipients',
                      style: AppTextStyles.titleMedium),
                  Text(
                    _isGlobal
                        ? 'All (${_employees.length})'
                        : '${_selectedEmployeeIds.length} selected',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Send to all — sets isGlobal: true
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isGlobal
                      ? AppColors.primary.withOpacity(0.1)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isGlobal
                        ? AppColors.primary
                        : AppColors.border,
                    width: _isGlobal ? 2 : 1,
                  ),
                ),
                child: InkWell(
                  onTap: _toggleGlobal,
                  child: Row(
                    children: [
                      Checkbox(
                        value: _isGlobal,
                        onChanged: (_) => _toggleGlobal(),
                        activeColor: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text('Send to All Employees',
                                style: AppTextStyles.titleMedium),
                            Text(
                              'Global notification to all ${_employees.length} employees',
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Individual employees — only shown when not global
              if (!_isGlobal) ...[
                Text(
                  'Or select specific employees:',
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Container(
                  constraints:
                  const BoxConstraints(maxHeight: 300),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _employees.length,
                    separatorBuilder: (_, __) =>
                    const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final emp = _employees[index];
                      final id = emp['id'].toString();
                      final isSelected =
                      _selectedEmployeeIds.contains(id);
                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (_) => _toggleEmployee(id),
                        title: Text(
                          '${emp['firstName']} ${emp['lastName']}',
                          style: AppTextStyles.bodyMedium,
                        ),
                        subtitle: Text(
                          '${emp['employeeId']} • ${emp['designation'] ?? 'N/A'}',
                          style: AppTextStyles.caption,
                        ),
                        activeColor: AppColors.primary,
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 32),

              CustomButton(
                text: 'Send Notification',
                onPressed:
                _isLoading ? null : _generateNotification,
                isLoading: _isLoading,
                isFullWidth: true,
                icon: Icons.send,
              ),
              const SizedBox(height: 12),
              CustomButton(
                text: 'Cancel',
                onPressed:
                _isLoading ? null : () => context.pop(),
                variant: ButtonVariant.secondary,
                isFullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}