import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../admin/data/datasources/admin_employee_data_source.dart';
import '../../abstracts/admin_employee_source.dart';

/// Company Screen
///
/// Admin views all employees, adds new, removes existing.
/// GET    /employees      → PagedResponse<EmployeeResponse> (data array)
/// DELETE /employees/{id} → soft delete (status → TERMINATED)

class CompanyScreen extends StatefulWidget {
  CompanyScreen({
    super.key,
    AdminEmployeeSource? dataSource,
  }) : dataSource = dataSource ?? AdminEmployeeDataSource(dioClient: DioClient());

  final AdminEmployeeSource dataSource;

  @override
  State<CompanyScreen> createState() => _CompanyScreenState();
}

class _CompanyScreenState extends State<CompanyScreen> {
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load employees: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  List<dynamic> get _filteredEmployees {
    if (_searchQuery.isEmpty) return _employees;
    final q = _searchQuery.toLowerCase();
    return _employees.where((emp) {
      final name =
      '${emp['firstName']} ${emp['lastName']}'.toLowerCase();
      final empId = (emp['employeeId'] ?? '').toLowerCase();
      final designation =
      (emp['designation'] ?? '').toLowerCase();
      return name.contains(q) ||
          empId.contains(q) ||
          designation.contains(q);
    }).toList();
  }

  Future<void> _deleteEmployee(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Employee'),
        content: Text(
            'Are you sure you want to remove $name from the company?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Remove',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await widget.dataSource.deleteEmployee(id);
      setState(() =>
          _employees.removeWhere((emp) => emp['id'].toString() == id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Employee removed successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Company'),
            Text(
              '${_employees.length} employees',
              style: AppTextStyles.caption.copyWith(
                  color: AppColors.white.withOpacity(0.9)),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: Column(
        children: [
          // Search
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, ID, or designation...',
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
                  ? 'No employees found in the company'
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

      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 60),
        child: FloatingActionButton.extended(
          heroTag: 'company_add_employee_fab',
          onPressed: () async {
            await context.push('/admin/add-employee');
            _loadEmployees();
          },
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.person_add, color: AppColors.white),
          label: Text(
            'Add Employee',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeCard(Map<String, dynamic> employee) {
    final id = employee['id'].toString();
    final firstName = employee['firstName']?.toString() ?? '';
    final lastName = employee['lastName']?.toString() ?? '';
    final employeeId = employee['employeeId']?.toString() ?? '';
    final email = employee['email']?.toString() ?? '';
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
          onLongPress: () =>
              _deleteEmployee(id, '$firstName $lastName'),
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
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.email,
                              size: 14,
                              color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              email,
                              style: AppTextStyles.caption,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () =>
                          context.push('/admin/edit-employee/$id'),
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      icon: Icon(Icons.delete,
                          size: 20, color: AppColors.error),
                      onPressed: () =>
                          _deleteEmployee(id, '$firstName $lastName'),
                      tooltip: 'Remove',
                    ),
                  ],
                ),
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