import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

/// More Page
///
/// Profile, settings, and other options.
/// Edit Profile is only visible to ADMIN users.

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('More'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Unauthenticated) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) context.go('/login');
            });
          }
        },
        builder: (context, state) {
          if (state is AuthLoading) {
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Logging out...'),
                  ],
                ),
              ),
            );
          }

          if (state is Authenticated) {
            final user = state.user;

            return SingleChildScrollView(
              child: Column(
                children: [
                  // Profile Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.white,
                          child: Text(
                            user.firstName[0] + user.lastName[0],
                            style: AppTextStyles.displaySmall.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          user.fullName,
                          style: AppTextStyles.headlineMedium.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.employeeId,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            user.role,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Account section
                  // Edit Profile only shown to ADMIN
                  _buildMenuSection('Account', [
                    _buildMenuItem(
                      'My Profile',
                      Icons.person,
                          () => context.push('/profile'),
                    ),
                    if (user.isAdmin)
                      _buildMenuItem(
                        'Edit Profile',
                        Icons.edit,
                            () => context.push('/profile/edit'),
                      ),
                    _buildMenuItem(
                      'Change Password',
                      Icons.lock_reset,
                          () => context.push('/profile/change-password'),
                    ),
                    _buildMenuItem(
                      'Settings',
                      Icons.settings,
                          () => context.push('/profile/settings'),
                    ),
                  ]),

                  _buildMenuSection('Work', [
                    _buildMenuItem(
                      'My Salary',
                      Icons.account_balance_wallet,
                          () => context.push('/payroll/salary'),
                    ),
                    _buildMenuItem(
                      'Payslips',
                      Icons.receipt_long,
                          () => context.push('/payroll/payslips'),
                    ),
                    _buildMenuItem(
                      'My Letters',
                      Icons.description,
                          () => context.push('/letters/my-requests'),
                    ),
                  ]),

                  if (user.isAdminOrManager)
                    _buildMenuSection('Management', [
                      _buildMenuItem(
                        'Leave Requests',
                        Icons.pending_actions,
                            () => context.push('/admin/pending-leaves'),
                      ),
                      _buildMenuItem(
                        'Generate Notification',
                        Icons.notifications_active,
                            () => context.push('/admin/generate-notification'),
                      ),
                    ]),

                  _buildMenuSection('Others', [
                    _buildMenuItem(
                      'Notifications',
                      Icons.notifications,
                          () => context.push('/notifications'),
                    ),
                    _buildMenuItem(
                      'Help & Support',
                      Icons.help,
                          () {
                        // TODO: Implement help
                      },
                    ),
                    _buildMenuItem(
                      'About',
                      Icons.info,
                          () {
                        // TODO: Implement about
                      },
                    ),
                  ]),

                  const SizedBox(height: 16),

                  // Logout Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: InkWell(
                      onTap: () => _showLogoutDialog(context),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.error.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.logout, color: AppColors.error),
                            const SizedBox(width: 12),
                            Text(
                              'Logout',
                              style: AppTextStyles.titleMedium.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  Text('Version 1.0.0', style: AppTextStyles.caption),
                  const SizedBox(height: 8),
                  Text('© 2026 909 Technologies', style: AppTextStyles.caption),
                  const SizedBox(height: 32),
                ],
              ),
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildMenuSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: AppTextStyles.titleSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildMenuItem(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.borderLight),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(title, style: AppTextStyles.bodyMedium),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(const LogoutRequested());
            },
            child: Text(
              'Logout',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}