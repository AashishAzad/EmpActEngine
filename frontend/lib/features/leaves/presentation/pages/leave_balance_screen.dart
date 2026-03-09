import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

/// Leave Balance Screen
///
/// Detailed view of leave balances

class LeaveBalanceScreen extends StatelessWidget {
  const LeaveBalanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Leave Balance'),
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.white,
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is Authenticated) {
            final user = state.user;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Total Balance Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Total Leave Balance',
                          style: AppTextStyles.titleLarge.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${user.totalLeaveBalance}',
                          style: AppTextStyles.statNumber.copyWith(
                            color: AppColors.white,
                            fontSize: 56,
                          ),
                        ),
                        Text(
                          'Days Remaining',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Leave Type Details
                  Text(
                    'Leave Type Details',
                    style: AppTextStyles.titleLarge,
                  ),
                  const SizedBox(height: 16),

                  // Casual Leave
                  _buildLeaveTypeCard(
                    'Casual Leave',
                    user.casualLeaveBalance ?? 0,
                    AppConstants.casualLeaveBalance,
                    AppColors.casualLeave,
                    Icons.coffee,
                    'For personal emergencies and family functions',
                  ),
                  const SizedBox(height: 16),

                  // Sick Leave
                  _buildLeaveTypeCard(
                    'Sick Leave',
                    user.sickLeaveBalance ?? 0,
                    AppConstants.sickLeaveBalance,
                    AppColors.sickLeave,
                    Icons.local_hospital,
                    'For illness and medical appointments',
                  ),
                  const SizedBox(height: 16),

                  // All Purpose Leave
                  _buildLeaveTypeCard(
                    'All Purpose Leave',
                    user.allPurposeLeaveBalance ?? 0,
                    AppConstants.allPurposeLeaveBalance,
                    AppColors.allPurposeLeave,
                    Icons.event,
                    'For any purpose as per your convenience',
                  ),
                  const SizedBox(height: 24),

                  // Leave Policy Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.info.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppColors.info,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Leave Policy',
                              style: AppTextStyles.titleSmall.copyWith(
                                color: AppColors.info,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildPolicyPoint('Leaves are credited annually'),
                        _buildPolicyPoint('Un-availed leaves do not carry forward'),
                        _buildPolicyPoint('Manager approval required for all leaves'),
                        _buildPolicyPoint('Minimum 1 day notice for casual/sick leave'),
                        _buildPolicyPoint('Advance notice recommended for planned leaves'),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildLeaveTypeCard(
      String title,
      int remaining,
      int total,
      Color color,
      IconData icon,
      String description,
      ) {
    final used = total - remaining;
    final percentage = (remaining / total * 100).round();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.titleMedium),
                    Text(
                      description,
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Balance Stats
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Available', remaining, color),
              ),
              Expanded(
                child: _buildStatItem('Used', used, AppColors.textSecondary),
              ),
              Expanded(
                child: _buildStatItem('Total', total, AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Balance',
                    style: AppTextStyles.caption,
                  ),
                  Text(
                    '$percentage%',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: remaining / total,
                  backgroundColor: color.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: AppTextStyles.headlineSmall.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.caption,
        ),
      ],
    );
  }

  Widget _buildPolicyPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.info,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.info,
              ),
            ),
          ),
        ],
      ),
    );
  }
}