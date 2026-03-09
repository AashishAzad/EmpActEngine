import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

/// Leaves Page
///
/// Shows leave balance and apply leave option

class LeavesPage extends StatelessWidget {
  const LeavesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Leaves'),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Leave Balance Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Total Leave Balance',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${user.totalLeaveBalance}',
                          style: AppTextStyles.statNumber.copyWith(
                            color: AppColors.white,
                            fontSize: 48,
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

                  // Leave Types
                  Text(
                    'Leave Types',
                    style: AppTextStyles.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _buildLeaveTypeCard(
                    'Casual Leave',
                    user.casualLeaveBalance ?? 0,
                    8,
                    AppColors.casualLeave,
                    Icons.coffee,
                  ),
                  const SizedBox(height: 12),
                  _buildLeaveTypeCard(
                    'Sick Leave',
                    user.sickLeaveBalance ?? 0,
                    8,
                    AppColors.sickLeave,
                    Icons.local_hospital,
                  ),
                  const SizedBox(height: 12),
                  _buildLeaveTypeCard(
                    'All Purpose Leave',
                    user.allPurposeLeaveBalance ?? 0,
                    10,
                    AppColors.allPurposeLeave,
                    Icons.event,
                  ),

                  const SizedBox(height: 32),

                  // Actions
                  CustomButton(
                    text: 'Apply for Leave',
                    onPressed: () {
                      context.push('/leaves/apply');
                    },
                    icon: Icons.add,
                    isFullWidth: true,
                  ),
                  const SizedBox(height: 12),
                  CustomButton(
                    text: 'View Leave History',
                    onPressed: () {
                      context.push('/leaves/history');
                    },
                    variant: ButtonVariant.secondary,
                    icon: Icons.history,
                    isFullWidth: true,
                  ),
                ],
              ),
            );
          }

          return const Center(
            child: CircularProgressIndicator(),
          );
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
      ) {
    final percentage = (remaining / total * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '$remaining of $total days remaining',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: remaining / total,
                    backgroundColor: color.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$percentage%',
            style: AppTextStyles.titleMedium.copyWith(
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}