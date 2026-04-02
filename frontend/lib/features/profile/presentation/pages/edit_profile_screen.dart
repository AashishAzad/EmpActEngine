import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

/// Edit Profile Screen — ADMIN ONLY
///
/// Admins can edit any employee's profile.
/// When accessed from the More page (own profile), the current
/// logged-in admin's own data is pre-filled.
///
/// Calls: PATCH /api/v1/employees/{id}
/// Backend DTO: UpdateEmployeeRequest (all fields optional/nullable)

class EditProfileScreen extends StatefulWidget {
  /// Optional — if null, edits the currently logged-in user (admin editing own profile).
  /// Pass a specific employeeId UUID string to edit another employee.
  final String? targetUserId;
  final Future<void> Function(String targetId, Map<String, dynamic> data)?
      onUpdateProfile;

  const EditProfileScreen({
    super.key,
    this.targetUserId,
    this.onUpdateProfile,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Personal
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _qualificationController = TextEditingController();

  // Work (admin-only fields)
  final _designationController = TextEditingController();
  final _departmentController = TextEditingController();

  bool _isLoading = false;
  bool _initialized = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emergencyContactController.dispose();
    _qualificationController.dispose();
    _designationController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  void _initFields(User user) {
    if (_initialized) return;
    _initialized = true;
    _firstNameController.text = user.firstName;
    _lastNameController.text = user.lastName;
    _emailController.text = user.email;
    _phoneController.text = user.phoneNumber ?? '';
    _addressController.text = user.address ?? '';
    _emergencyContactController.text = user.emergencyContact ?? '';
    _qualificationController.text = user.qualification ?? '';
    _designationController.text = user.designation ?? '';
    _departmentController.text = user.department ?? '';
  }

  Future<void> _updateProfile(User user) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Target: either a specific employee or the logged-in admin themselves
      final String targetId = widget.targetUserId ?? user.id;

      // Build payload — only send changed fields (backend treats null as "no change")
      final Map<String, dynamic> data = {};

      if (_firstNameController.text.trim() != user.firstName)
        data['firstName'] = _firstNameController.text.trim();
      if (_lastNameController.text.trim() != user.lastName)
        data['lastName'] = _lastNameController.text.trim();
      if (_emailController.text.trim() != user.email)
        data['email'] = _emailController.text.trim();
      if (_phoneController.text.trim() != (user.phoneNumber ?? ''))
        data['phoneNumber'] = _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim();
      if (_addressController.text.trim() != (user.address ?? ''))
        data['address'] = _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim();
      if (_emergencyContactController.text.trim() != (user.emergencyContact ?? ''))
        data['emergencyContact'] =
        _emergencyContactController.text.trim().isEmpty
            ? null
            : _emergencyContactController.text.trim();
      if (_qualificationController.text.trim() != (user.qualification ?? ''))
        data['qualification'] =
        _qualificationController.text.trim().isEmpty
            ? null
            : _qualificationController.text.trim();
      if (_designationController.text.trim() != (user.designation ?? ''))
        data['designation'] = _designationController.text.trim().isEmpty
            ? null
            : _designationController.text.trim();
      if (_departmentController.text.trim() != (user.department ?? ''))
        data['department'] = _departmentController.text.trim().isEmpty
            ? null
            : _departmentController.text.trim();

      if (data.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No changes to save'),
              backgroundColor: AppColors.info,
            ),
          );
        }
        return;
      }

      // PATCH /employees/{id} — Admin only
      final updateProfile = widget.onUpdateProfile;
      if (updateProfile != null) {
        await updateProfile(targetId, data);
      } else {
        final dioClient = DioClient();
        await dioClient.dio.patch(
          ApiConstants.employeeById(targetId),
          data: data,
        );
      }

      if (mounted) {
        // If admin edited their own profile, refresh AuthBloc
        // so updated name shows in header/more page immediately
        if (widget.targetUserId == null) {
          context.read<AuthBloc>().add(const GetProfileRequested());
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: ${e.toString()}'),
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
        title: const Text('Edit Profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is Authenticated) {
            final user = state.user;

            // Guard — only admins should ever reach this screen
            if (!user.isAdmin) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock, size: 64, color: AppColors.textSecondary),
                    const SizedBox(height: 16),
                    Text(
                      'Access Denied',
                      style: AppTextStyles.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Only admins can edit profiles.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    CustomButton(
                      text: 'Go Back',
                      onPressed: () => context.pop(),
                      variant: ButtonVariant.secondary,
                    ),
                  ],
                ),
              );
            }

            _initFields(user);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Avatar
                    Center(
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border:
                          Border.all(color: AppColors.primary, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            user.firstName[0] + user.lastName[0],
                            style: AppTextStyles.displaySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Personal Information ─────────────────────────────────
                    Text('Personal Information', style: AppTextStyles.titleMedium),
                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: _firstNameController,
                      label: 'First Name',
                      hint: 'Enter first name',
                      prefixIcon: const Icon(Icons.person),
                      validator: Validators.validateName,
                      textCapitalization: TextCapitalization.words,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: _lastNameController,
                      label: 'Last Name',
                      hint: 'Enter last name',
                      prefixIcon: const Icon(Icons.person_outline),
                      validator: Validators.validateName,
                      textCapitalization: TextCapitalization.words,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: _emailController,
                      label: 'Email',
                      hint: 'Enter email',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: const Icon(Icons.email),
                      validator: Validators.validateEmail,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      hint: 'Enter phone number',
                      keyboardType: TextInputType.phone,
                      prefixIcon: const Icon(Icons.phone),
                      validator: (value) {
                        if (value == null || value.isEmpty) return null;
                        return Validators.validatePhoneNumber(value);
                      },
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: _addressController,
                      label: 'Address',
                      hint: 'Enter address',
                      prefixIcon: const Icon(Icons.home),
                      enabled: !_isLoading,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: _emergencyContactController,
                      label: 'Emergency Contact',
                      hint: 'Name and phone number',
                      prefixIcon: const Icon(Icons.emergency),
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: _qualificationController,
                      label: 'Qualification',
                      hint: 'e.g. B.Tech Computer Science',
                      prefixIcon: const Icon(Icons.school),
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 24),

                    // ── Work Information (admin-editable) ───────────────────
                    Text('Work Information', style: AppTextStyles.titleMedium),
                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: _designationController,
                      label: 'Designation',
                      hint: 'e.g. Software Engineer',
                      prefixIcon: const Icon(Icons.work),
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: _departmentController,
                      label: 'Department',
                      hint: 'e.g. Engineering',
                      prefixIcon: const Icon(Icons.business),
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 16),

                    // Read-only fields
                    CustomTextField(
                      initialValue: user.employeeId,
                      label: 'Employee ID',
                      readOnly: true,
                      enabled: false,
                      prefixIcon: const Icon(Icons.badge),
                    ),
                    const SizedBox(height: 32),

                    // ── Actions ──────────────────────────────────────────────
                    CustomButton(
                      text: 'Update Profile',
                      onPressed:
                      _isLoading ? null : () => _updateProfile(user),
                      isLoading: _isLoading,
                      isFullWidth: true,
                      icon: Icons.check,
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
}