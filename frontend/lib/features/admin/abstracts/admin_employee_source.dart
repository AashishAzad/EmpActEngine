abstract class AdminEmployeeSource {
  Future<List<dynamic>> getAllEmployees({
    String? search,
    String? role,
    String? status,
    String? department,
    int page = 1,
    int limit = 100,
  });

  Future<Map<String, dynamic>> getEmployeeById(String id);

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
  });

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
  });

  Future<void> deleteEmployee(String id);
  Future<Map<String, dynamic>> getEmployeeStatistics();
}