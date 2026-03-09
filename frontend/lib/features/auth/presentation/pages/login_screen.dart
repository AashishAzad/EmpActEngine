import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// Login Screen
///
/// User login with employee ID and password

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _employeeIdController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _employeeIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        LoginRequested(
          employeeId: _employeeIdController.text.trim(),
          password: _passwordController.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            // Navigate to home
            context.go('/home');
          } else if (state is AuthError) {
            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo/Icon
                      Icon(
                        Icons.business_center,
                        size: 80,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 24),

                      // Title
                      Text(
                        'Employee Activity',
                        style: AppTextStyles.displayMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '909 Technologies',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),

                      // Employee ID Field
                      CustomTextField(
                        controller: _employeeIdController,
                        label: 'Employee ID',
                        hint: 'Enter your employee ID',
                        keyboardType: TextInputType.text,
                        textCapitalization: TextCapitalization.characters,
                        prefixIcon: const Icon(Icons.badge),
                        validator: Validators.validateEmployeeId,
                        enabled: !isLoading,
                      ),
                      const SizedBox(height: 20),

                      // Password Field
                      CustomTextField(
                        controller: _passwordController,
                        label: 'Password',
                        hint: 'Enter your password',
                        obscureText: true,
                        prefixIcon: const Icon(Icons.lock),
                        validator: Validators.validatePassword,
                        enabled: !isLoading,
                        onSubmitted: (_) => _handleLogin(),
                      ),
                      const SizedBox(height: 32),

                      // Login Button
                      CustomButton(
                        text: 'Login',
                        onPressed: isLoading ? null : _handleLogin,
                        isLoading: isLoading,
                        isFullWidth: true,
                      ),
                      const SizedBox(height: 16),

                      // Test Credentials Info
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
                                  size: 20,
                                  color: AppColors.info,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Test Credentials',
                                  style: AppTextStyles.titleSmall.copyWith(
                                    color: AppColors.info,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildCredentialRow('Admin', 'ADM001'),
                            const SizedBox(height: 4),
                            _buildCredentialRow('Manager', 'MGR001'),
                            const SizedBox(height: 4),
                            _buildCredentialRow('Employee', 'EMP001'),
                            const SizedBox(height: 8),
                            Text(
                              'Password: password123',
                              style: AppTextStyles.caption.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCredentialRow(String role, String id) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$role:',
            style: AppTextStyles.caption,
          ),
        ),
        Text(
          id,
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w600,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}