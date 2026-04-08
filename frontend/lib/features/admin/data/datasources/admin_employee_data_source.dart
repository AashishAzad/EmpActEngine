import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../abstracts/admin_employee_source.dart';

/// Admin Employee Data Source
///
/// Handles all admin operations for employee management.
///
/// Endpoints:
/// GET    /employees?search=&role=&status=&department=&page=&limit=  → PagedResponse<EmployeeResponse>
/// GET    /employees/{id}                                            → EmployeeResponse
/// POST   /employees                                                 → EmployeeResponse (201)
/// PATCH  /employees/{id}                                            → EmployeeResponse
/// DELETE /employees/{id}                                            → Map<String, String> (soft delete)
/// GET    /employees/statistics                                       → Map<String, Object>

class AdminEmployeeDataSource implements AdminEmployeeSource {
  final DioClient dioClient;

  AdminEmployeeDataSource({required this.dioClient});

  // ── Get All Employees ──────────────────────────────────────────────────────

  /// GET /employees?page=1&limit=100
  /// Returns PagedResponse<EmployeeResponse>:
  /// { data: [...], total: N, page: N, limit: N, totalPages: N }
  /// Extracts the 'data' array.
  Future<List<dynamic>> getAllEmployees({
    String? search,
    String? role,
    String? status,
    String? department,
    int page = 1,
    int limit = 100,
  }) async {
    try {
      final response = await dioClient.dio.get(
        ApiConstants.employees,
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search != null && search.isNotEmpty) 'search': search,
          if (role != null) 'role': role,
          if (status != null) 'status': status,
          if (department != null) 'department': department,
        },
      );

      // Backend returns PagedResponse<EmployeeResponse> — extract 'data' array
      if (response.data is Map && response.data['data'] != null) {
        return response.data['data'] as List<dynamic>;
      }
      // Fallback if response shape changes
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw Exception('Failed to get employees: ${e.message}');
    }
  }

  // ── Get Employee By ID ─────────────────────────────────────────────────────

  /// GET /employees/{id}
  Future<Map<String, dynamic>> getEmployeeById(String id) async {
    try {
      final response =
      await dioClient.dio.get(ApiConstants.employeeById(id));
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('Failed to get employee: ${e.message}');
    }
  }

  // ── Add Employee ───────────────────────────────────────────────────────────

  /// POST /employees — Admin only
  /// CreateEmployeeRequest fields (standard employee creation)
  Future<Map<String, dynamic>> addEmployee({
    required String employeeId,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
    String? phoneNumber,
    String? designation,
    String? department,
    String? dateOfJoining,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'employeeId': employeeId,
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        'role': role,
      };
      if (phoneNumber != null) data['phoneNumber'] = phoneNumber;
      if (designation != null) data['designation'] = designation;
      if (department != null) data['department'] = department;
      if (dateOfJoining != null) data['dateOfJoining'] = dateOfJoining;

      final response = await dioClient.dio.post(
        ApiConstants.employees,
        data: data,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('Failed to add employee: ${e.message}');
    }
  }

  // ── Update Employee ────────────────────────────────────────────────────────

  /// PATCH /employees/{id} — Admin only
  /// UpdateEmployeeRequest — all fields optional, only non-null are updated
  Future<Map<String, dynamic>> updateEmployee({
    required String id,
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? designation,
    String? department,
    String? role,
    String? status,
    String? dateOfJoining,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (firstName != null) data['firstName'] = firstName;
      if (lastName != null) data['lastName'] = lastName;
      if (email != null) data['email'] = email;
      if (phoneNumber != null) data['phoneNumber'] = phoneNumber;
      if (designation != null) data['designation'] = designation;
      if (department != null) data['department'] = department;
      if (role != null) data['role'] = role;
      if (status != null) data['status'] = status;
      if (dateOfJoining != null) data['dateOfJoining'] = dateOfJoining;

      final response = await dioClient.dio.patch(
        ApiConstants.employeeById(id),
        data: data,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('Failed to update employee: ${e.message}');
    }
  }

  // ── Delete Employee ────────────────────────────────────────────────────────

  /// DELETE /employees/{id} — Admin only (soft delete → TERMINATED)
  Future<void> deleteEmployee(String id) async {
    try {
      await dioClient.dio.delete(ApiConstants.employeeById(id));
    } on DioException catch (e) {
      throw Exception('Failed to delete employee: ${e.message}');
    }
  }

  // ── Employee Statistics ────────────────────────────────────────────────────

  /// GET /employees/statistics — Admin/Manager
  Future<Map<String, dynamic>> getEmployeeStatistics() async {
    try {
      final response =
      await dioClient.dio.get(ApiConstants.employeeStatistics);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('Failed to get statistics: ${e.message}');
    }
  }
}