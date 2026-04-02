import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../admin/data/datasources/admin_employee_data_source.dart';

/// Correction Screen
///
/// Admin selects an employee to edit their details.
/// GET /employees → PagedResponse<EmployeeResponse> (data array)

class CorrectionScreen extends StatefulWidget {
  CorrectionScreen({
    super.key,
    AdminEmployeeSource? dataSource,
  }) : dataSource = dataSource ?? AdminEmployeeDataSource(dioClient: DioClient());

  final AdminEmployeeSource dataSource;

  @override
  State<CorrectionScreen> createState() => _CorrectionScreenState();
}

class _CorrectionScreenState extends State<CorrectionScreen> {
  final _searchController = TextEditingController();

  bool _isLoading = false;
  List<dynamic> _employees = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    setState(() => _isLoading = true);
    try {
      final employees = await widget.dataSource.getAllEmployees();
      setState(() {
        _employees = employees
            .where((emp) => emp['status'] != 'TERMINATED')
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<dynamic> get _filteredEmployees {
    if (_searchQuery.isEmpty) return _employees;
    final q = _searchQuery.toLowerCase();
    return _employees.where((emp) {
      final name =
      '${emp['firstName']} ${emp['lastName']}'.toLowerCase();
      final empId = (emp['employeeId'] ?? '').toLowerCase();
      return name.contains(q) || empId.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Correction'),
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.white,
      ),
      body: Column(
        children: [
          // Info
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: Row(
              children: [
                Icon(Icons.edit, color: AppColors.secondary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Select an employee to edit their details, salary, or any other information',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),

          // Search
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search employee by name or ID...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(() {
                    _searchController.clear();
                    _searchQuery = '';
                  }),
                )
                    : null,
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),

          // List
          Expanded(
            child: _isLoading
                ? const LoadingIndicator(
                message: 'Loading employees...')
                : _filteredEmployees.isEmpty
                ? EmptyState(
              icon: Icons.people_outline,
              title: _searchQuery.isEmpty
                  ? 'No Employees'
                  : 'No Results',
              message: _searchQuery.isEmpty
                  ? 'No employees found'
                  : 'No employees match your search',
            )
                : RefreshIndicator(
              onRefresh: _loadEmployees,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _filteredEmployees.length,
                itemBuilder: (context, index) =>
                    _buildEmployeeCard(
                        _filteredEmployees[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard(Map<String, dynamic> employee) {
    final id = employee['id'].toString();
    final firstName = employee['firstName']?.toString() ?? '';
    final lastName = employee['lastName']?.toString() ?? '';
    final employeeId = employee['employeeId']?.toString() ?? '';
    final designation = employee['designation']?.toString();
    final department = employee['department']?.toString();
    final role = employee['role']?.toString() ?? 'EMPLOYEE';

    final roleColor = _getRoleColor(role);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/admin/edit-employee/$id'),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: roleColor.withOpacity(0.1),
                  child: Text(
                    firstName.isNotEmpty && lastName.isNotEmpty
                        ? firstName[0] + lastName[0]
                        : '??',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: roleColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text('$firstName $lastName',
                                style: AppTextStyles.titleMedium),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: roleColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              role,
                              style: AppTextStyles.caption.copyWith(
                                color: roleColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        employeeId,
                        style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary),
                      ),
                      if (designation != null || department != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${designation ?? 'N/A'} • ${department ?? 'N/A'}',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios,
                    size: 16, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'ADMIN':
        return AppColors.error;
      case 'MANAGER':
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }
}