import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../admin/data/datasources/admin_employee_data_source.dart';
import '../../abstracts/admin_employee_source.dart';

/// Add Employee Screen
///
/// Admin adds a new employee.
/// POST /employees → EmployeeResponse (201)

class AddEmployeeScreen extends StatefulWidget {
  AddEmployeeScreen({
    super.key,
    AdminEmployeeSource? dataSource,
    Future<DateTime?> Function(BuildContext context)? datePicker,
  })  : dataSource = dataSource ?? AdminEmployeeDataSource(dioClient: DioClient()),
        datePicker = datePicker ?? _defaultDatePicker;

  final AdminEmployeeSource dataSource;
  final Future<DateTime?> Function(BuildContext context) datePicker;

  static Future<DateTime?> _defaultDatePicker(BuildContext context) {
    return showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
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
  State<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends State<AddEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();

  final _employeeIdController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _designationController = TextEditingController();
  final _departmentController = TextEditingController();

  String _selectedRole = 'EMPLOYEE';
  DateTime? _dateOfJoining;
  bool _isLoading = false;

  final List<String> _roles = ['EMPLOYEE', 'MANAGER', 'ADMIN'];

  @override
  void dispose() {
    _employeeIdController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _designationController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await widget.datePicker(context);
    if (picked != null) setState(() => _dateOfJoining = picked);
  }

  Future<void> _addEmployee() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await widget.dataSource.addEmployee(
        employeeId: _employeeIdController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        role: _selectedRole,
        phoneNumber: _phoneController.text.isEmpty
            ? null
            : _phoneController.text.trim(),
        designation: _designationController.text.isEmpty
            ? null
            : _designationController.text.trim(),
        department: _departmentController.text.isEmpty
            ? null
            : _departmentController.text.trim(),
        dateOfJoining: _dateOfJoining != null
            ? DateFormat('yyyy-MM-dd').format(_dateOfJoining!)
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Employee added successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add employee: ${e.toString()}'),
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
        title: const Text('Add Employee'),
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
              Text('Basic Information', style: AppTextStyles.titleLarge),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _employeeIdController,
                label: 'Employee ID',
                hint: 'e.g. EMP004',
                prefixIcon: const Icon(Icons.badge),
                validator: Validators.validateRequired,
                enabled: !_isLoading,
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _firstNameController,
                      label: 'First Name',
                      hint: 'Enter first name',
                      prefixIcon: const Icon(Icons.person),
                      validator: Validators.validateName,
                      enabled: !_isLoading,
                      textCapitalization: TextCapitalization.words,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: _lastNameController,
                      label: 'Last Name',
                      hint: 'Enter last name',
                      prefixIcon:
                      const Icon(Icons.person_outline),
                      validator: Validators.validateName,
                      enabled: !_isLoading,
                      textCapitalization: TextCapitalization.words,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _emailController,
                label: 'Email',
                hint: 'Enter email address',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Icons.email),
                validator: Validators.validateEmail,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _passwordController,
                label: 'Password',
                hint: 'Enter initial password',
                obscureText: true,
                prefixIcon: const Icon(Icons.lock),
                validator: Validators.validatePassword,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _phoneController,
                label: 'Phone Number (Optional)',
                hint: 'Enter phone number',
                keyboardType: TextInputType.phone,
                prefixIcon: const Icon(Icons.phone),
                enabled: !_isLoading,
                validator: Validators.validateIndianPhoneNumber,
              ),
              const SizedBox(height: 24),

              Text('Work Information', style: AppTextStyles.titleLarge),
              const SizedBox(height: 16),

              Text('Role', style: AppTextStyles.titleMedium),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
                ),
                items: _roles
                    .map((r) =>
                    DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: _isLoading
                    ? null
                    : (v) => setState(() => _selectedRole = v!),
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _designationController,
                label: 'Designation (Optional)',
                hint: 'Enter designation',
                prefixIcon: const Icon(Icons.work),
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _departmentController,
                label: 'Department (Optional)',
                hint: 'Enter department',
                prefixIcon: const Icon(Icons.business),
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),

              Text('Date of Joining (Optional)',
                  style: AppTextStyles.titleMedium),
              const SizedBox(height: 8),
              InkWell(
                onTap: _isLoading ? null : _selectDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _dateOfJoining == null
                          ? AppColors.border
                          : AppColors.primary,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: _dateOfJoining == null
                            ? AppColors.textSecondary
                            : AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _dateOfJoining == null
                            ? 'Select date'
                            : DateFormat('dd MMM yyyy')
                            .format(_dateOfJoining!),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: _dateOfJoining == null
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              CustomButton(
                text: 'Add Employee',
                onPressed: _isLoading ? null : _addEmployee,
                isLoading: _isLoading,
                isFullWidth: true,
                icon: Icons.person_add,
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
}
