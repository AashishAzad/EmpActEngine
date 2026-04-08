import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_utils.dart' as app_date;
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../abstracts/attendance_data_source.dart';
import '../../data/datasources/attendance_remote_data_source.dart';

/// Manual Attendance Request Screen
///
/// Request attendance for a missed day.
/// Calls POST /attendance/manual-request
///
/// ManualAttendanceRequestDto fields (from entity):
///   requestDate (LocalDate) — sent as "yyyy-MM-dd"
///   reason (String, required)

class ManualAttendanceRequestScreen extends StatefulWidget {
  ManualAttendanceRequestScreen({
    super.key,
    AttendanceDataSource? dataSource,
    Future<DateTime?> Function(BuildContext context)? datePicker,
  })  : dataSource = dataSource ?? AttendanceRemoteDataSource(dioClient: DioClient()),
        datePicker = datePicker ?? _defaultDatePicker;

  final AttendanceDataSource dataSource;
  final Future<DateTime?> Function(BuildContext context) datePicker;

  static Future<DateTime?> _defaultDatePicker(BuildContext context) {
    return showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 1)),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().subtract(const Duration(days: 1)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme:
              const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
  }

  @override
  State<ManualAttendanceRequestScreen> createState() =>
      _ManualAttendanceRequestScreenState();
}

class _ManualAttendanceRequestScreenState
    extends State<ManualAttendanceRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  DateTime? _selectedDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await widget.datePicker(context);
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a date'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // POST /attendance/manual-request
      // Body: { requestDate: "yyyy-MM-dd", reason: "..." }
      // NOTE: field name is "requestDate" (from ManualAttendanceRequest entity)
      // NOT "date" — date is formatted as LocalDate string, not full DateTime
      await widget.dataSource.requestManualAttendance(
        date: _selectedDate!,
        reason: _reasonController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Manual attendance request submitted!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit: ${e.toString()}'),
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
        title: const Text('Manual Attendance Request'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: SingleChildScrollView(
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
                  border:
                  Border.all(color: AppColors.info.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: AppColors.info, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Use this form to request attendance for days you forgot to mark. '
                            'Requests require manager approval.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.info,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── Date Selection ─────────────────────────────────────────
              Text('Select Date', style: AppTextStyles.titleMedium),
              const SizedBox(height: 8),
              InkWell(
                onTap: _isLoading ? null : _selectDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedDate == null
                          ? AppColors.border
                          : AppColors.primary,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: _selectedDate == null
                            ? AppColors.textSecondary
                            : AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedDate == null
                              ? 'Select the date you missed'
                              : app_date.DateUtils.formatDate(_selectedDate!),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: _selectedDate == null
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_drop_down,
                          color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Reason ─────────────────────────────────────────────────
              CustomTextField(
                controller: _reasonController,
                label: 'Reason',
                hint: 'Explain why you missed marking attendance',
                maxLines: 5,
                validator: (value) => Validators.validateReason(value),
                enabled: !_isLoading,
              ),
              const SizedBox(height: 32),

              // ── Guidelines ─────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.rule, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Text('Guidelines', style: AppTextStyles.titleSmall),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildGuidelineItem(
                        'You can only request for dates within the last 30 days'),
                    _buildGuidelineItem(
                        'Requests require manager or admin approval'),
                    _buildGuidelineItem(
                        'Provide a valid reason for missing attendance'),
                    _buildGuidelineItem(
                        'You cannot request for weekends or holidays'),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              CustomButton(
                text: 'Submit Request',
                onPressed: _isLoading ? null : _submitRequest,
                isLoading: _isLoading,
                isFullWidth: true,
                icon: Icons.send,
              ),
              const SizedBox(height: 12),
              CustomButton(
                text: 'Cancel',
                onPressed: _isLoading ? null : () => context.pop(),
                variant: ButtonVariant.secondary,
                isFullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuidelineItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: AppTextStyles.bodySmall),
          ),
        ],
      ),
    );
  }
}