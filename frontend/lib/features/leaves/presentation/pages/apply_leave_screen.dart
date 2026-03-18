import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../data/datasources/leave_remote_data_source.dart';

/// Apply Leave Screen
///
/// Calls POST /leaves
/// ApplyLeaveRequest fields:
/// leaveType, startDate, endDate, contactNumber (@NotBlank), contactEmail, remarks

class ApplyLeaveScreen extends StatefulWidget {
  const ApplyLeaveScreen({super.key});

  @override
  State<ApplyLeaveScreen> createState() => _ApplyLeaveScreenState();
}

class _ApplyLeaveScreenState extends State<ApplyLeaveScreen> {
  final _formKey = GlobalKey<FormState>();
  final _remarksController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _dataSource = LeaveRemoteDataSource(dioClient: DioClient());

  String? _selectedLeaveType;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;
  bool _contactPrefilled = false;

  @override
  void dispose() {
    _remarksController.dispose();
    _contactNumberController.dispose();
    super.dispose();
  }

  /// Pre-fill contact number from user profile once
  void _prefillContact(user) {
    if (_contactPrefilled) return;
    _contactPrefilled = true;
    if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) {
      _contactNumberController.text = user.phoneNumber!;
    }
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme:
          const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(_startDate!)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select start date first'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate!,
      firstDate: _startDate!,
      lastDate: _startDate!.add(const Duration(days: 90)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme:
          const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  int _calculateDays() {
    if (_startDate == null || _endDate == null) return 0;
    return _endDate!.difference(_startDate!).inDays + 1;
  }

  Future<void> _submitLeave(user) async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedLeaveType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select leave type'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select date range'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // POST /leaves
      // contactNumber is @NotBlank — use field value, fallback to email prefix
      final contactNumber = _contactNumberController.text.trim().isNotEmpty
          ? _contactNumberController.text.trim()
          : 'N/A'; // edge case: user has no phone number saved

      await _dataSource.applyLeave(
        leaveType: _selectedLeaveType!,
        startDate: DateFormat('yyyy-MM-dd').format(_startDate!),
        endDate: DateFormat('yyyy-MM-dd').format(_endDate!),
        contactNumber: contactNumber,
        contactEmail: user.email,
        remarks: _remarksController.text.trim().isEmpty
            ? null
            : _remarksController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Leave application submitted successfully!'),
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
    final days = _calculateDays();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Apply for Leave'),
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.white,
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is Authenticated) {
            final user = state.user;
            _prefillContact(user);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Leave Balance Banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Available Leave Balance',
                            style: AppTextStyles.titleSmall.copyWith(
                              color: AppColors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${user.totalLeaveBalance} Days',
                            style: AppTextStyles.displaySmall.copyWith(
                              color: AppColors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Leave Type ────────────────────────────────────────
                    Text('Leave Type', style: AppTextStyles.titleMedium),
                    const SizedBox(height: 8),
                    _buildLeaveTypeCard(
                      AppConstants.casualLeave,
                      'Casual Leave',
                      user.casualLeaveBalance ?? 0,
                      AppColors.casualLeave,
                      Icons.coffee,
                    ),
                    const SizedBox(height: 12),
                    _buildLeaveTypeCard(
                      AppConstants.sickLeave,
                      'Sick Leave',
                      user.sickLeaveBalance ?? 0,
                      AppColors.sickLeave,
                      Icons.local_hospital,
                    ),
                    const SizedBox(height: 12),
                    _buildLeaveTypeCard(
                      AppConstants.allPurposeLeave,
                      'All Purpose Leave',
                      user.allPurposeLeaveBalance ?? 0,
                      AppColors.allPurposeLeave,
                      Icons.event,
                    ),
                    const SizedBox(height: 24),

                    // ── Date Range ────────────────────────────────────────
                    Text('Date Range', style: AppTextStyles.titleMedium),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateCard(
                              'Start Date', _startDate, _selectStartDate),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDateCard(
                              'End Date', _endDate, _selectEndDate),
                        ),
                      ],
                    ),
                    if (days > 0) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppColors.info.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.event_note,
                                color: AppColors.info, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Total Days: $days',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.info,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // ── Contact Number ────────────────────────────────────
                    // @NotBlank in ApplyLeaveRequest — required field
                    CustomTextField(
                      controller: _contactNumberController,
                      label: 'Contact Number During Leave',
                      hint: 'Phone number to reach you',
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      prefixIcon: const Icon(Icons.phone),
                      validator: (value) {
                        final contactNumber = value?.trim() ?? '';
                        if (contactNumber.isEmpty) {
                          return 'Contact number is required';
                        }
                        if (contactNumber.length != 10) {
                          return 'Contact number must be 10 digits';
                        }
                        return null;
                      },
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 16),

                    // ── Remarks (reason) ──────────────────────────────────
                    // Backend field: remarks (optional)
                    CustomTextField(
                      controller: _remarksController,
                      label: 'Reason for Leave',
                      hint: 'Enter reason for leave',
                      maxLines: 4,
                      validator: (value) => Validators.validateReason(value),
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 32),

                    CustomButton(
                      text: 'Submit Application',
                      onPressed:
                      _isLoading ? null : () => _submitLeave(user),
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
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildLeaveTypeCard(
      String value,
      String title,
      int balance,
      Color color,
      IconData icon,
      ) {
    final isSelected = _selectedLeaveType == value;
    return InkWell(
      onTap: () => setState(() => _selectedLeaveType = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.titleMedium),
                  Text('$balance days available',
                      style: AppTextStyles.caption),
                ],
              ),
            ),
            isSelected
                ? Icon(Icons.check_circle, color: color, size: 24)
                : Icon(Icons.circle_outlined,
                color: AppColors.border, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDateCard(
      String label, DateTime? date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: date == null ? AppColors.border : AppColors.primary,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.caption),
            const SizedBox(height: 4),
            Text(
              date == null
                  ? 'Select date'
                  : DateFormat('dd MMM yyyy').format(date),
              style: AppTextStyles.bodyMedium.copyWith(
                color: date == null
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}