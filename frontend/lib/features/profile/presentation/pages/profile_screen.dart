import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

/// Profile Screen
///
/// Shows user profile details

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.edit),
        //     onPressed: () => context.push('/profile/edit'),
        //     tooltip: 'Edit Profile',
        //   ),
        // ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is Authenticated) {
            final user = state.user;

            return SingleChildScrollView(
              child: Column(
                children: [
                  // Profile Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                    ),
                    child: Column(
                      children: [
                        // Profile Picture
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.white,
                              width: 4,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              user.firstName[0] + user.lastName[0],
                              style: AppTextStyles.displayMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user.fullName,
                          style: AppTextStyles.headlineMedium.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.employeeId,
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            user.role,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Profile Details
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Personal Information
                        Text(
                          'Personal Information',
                          style: AppTextStyles.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        _buildInfoCard(
                          icon: Icons.email,
                          label: 'Email',
                          value: user.email,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 12),
                        if (user.phoneNumber != null)
                          _buildInfoCard(
                            icon: Icons.phone,
                            label: 'Phone Number',
                            value: user.phoneNumber!,
                            color: AppColors.success,
                          ),
                        const SizedBox(height: 24),

                        // Work Information
                        Text(
                          'Work Information',
                          style: AppTextStyles.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        if (user.designation != null)
                          _buildInfoCard(
                            icon: Icons.work,
                            label: 'Designation',
                            value: user.designation!,
                            color: AppColors.secondary,
                          ),
                        if (user.designation != null) const SizedBox(height: 12),
                        if (user.department != null)
                          _buildInfoCard(
                            icon: Icons.business,
                            label: 'Department',
                            value: user.department!,
                            color: AppColors.warning,
                          ),
                        if (user.department != null) const SizedBox(height: 12),
                        if (user.dateOfJoining != null)
                          _buildInfoCard(
                            icon: Icons.calendar_today,
                            label: 'Date of Joining',
                            value: user.dateOfJoining!,
                            color: AppColors.info,
                          ),
                        const SizedBox(height: 24),

                        // Leave Balance
                        Text(
                          'Leave Balance',
                          style: AppTextStyles.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildLeaveCard(
                                'Casual',
                                user.casualLeaveBalance ?? 0,
                                AppColors.casualLeave,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildLeaveCard(
                                'Sick',
                                user.sickLeaveBalance ?? 0,
                                AppColors.sickLeave,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildLeaveCard(
                                'APL',
                                user.allPurposeLeaveBalance ?? 0,
                                AppColors.allPurposeLeave,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Action Buttons
                        // CustomButton(
                        //   text: 'Edit Profile',
                        //   onPressed: () => context.push('/profile/edit'),
                        //   icon: Icons.edit,
                        //   isFullWidth: true,
                        // ),
                        // const SizedBox(height: 12),
                        // CustomButton(
                        //   text: 'Settings',
                        //   onPressed: () => context.push('/profile/settings'),
                        //   variant: ButtonVariant.secondary,
                        //   icon: Icons.settings,
                        //   isFullWidth: true,
                        // ),
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

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
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
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveCard(String label, int balance, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            balance.toString(),
            style: AppTextStyles.headlineMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}