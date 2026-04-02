import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';

/// Payroll Remote Data Source
///
/// All payroll API calls against the Jmix backend.
///
/// Endpoint shapes:
/// GET /payroll/my-salary         → Map<String, Object> (custom map from PayrollService)
/// GET /payroll/my-payslips       → PagedResponse<PayslipResponse> { data, total, page, limit }
/// GET /payroll/my-recent-payslips → List<PayslipResponse>
/// GET /payroll/payslips/{id}     → PayslipResponse (single payslip by UUID)

abstract class PayrollDataSource {
  Future<Map<String, dynamic>> getMySalary();
  Future<Map<String, dynamic>> getMyPayslips({
    int? month,
    int? year,
    int page = 1,
    int limit = 10,
  });
  Future<List<dynamic>> getMyRecentPayslips();
  Future<Map<String, dynamic>> getPayslipById(String id);
  Future<List<int>> downloadPayslip(String id);
}

class PayrollRemoteDataSource implements PayrollDataSource {
  final DioClient dioClient;

  PayrollRemoteDataSource({required this.dioClient});

  // ── My Salary ─────────────────────────────────────────────────────────────

  /// GET /payroll/my-salary
  /// Returns a Map containing salary breakdown.
  /// Backend returns Map<String, Object> from PayrollService.getMySalary()
  @override
  Future<Map<String, dynamic>> getMySalary() async {
    try {
      final response = await dioClient.dio.get(ApiConstants.mySalary);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('Failed to get salary: ${e.message}');
    }
  }

  // ── My Payslips (paginated) ───────────────────────────────────────────────

  /// GET /payroll/my-payslips?month=&year=&page=1&limit=10
  /// Returns PagedResponse<PayslipResponse>:
  /// { data: [...], total: N, page: N, limit: N, totalPages: N }
  @override
  Future<Map<String, dynamic>> getMyPayslips({
    int? month,
    int? year,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (month != null) 'month': month,
        if (year != null) 'year': year,
      };
      final response = await dioClient.dio.get(
        ApiConstants.myPayslips,
        queryParameters: queryParams,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('Failed to get payslips: ${e.message}');
    }
  }

  // ── Recent Payslips ───────────────────────────────────────────────────────

  /// GET /payroll/my-recent-payslips
  /// Returns List<PayslipResponse> — last 3 payslips, no pagination
  @override
  Future<List<dynamic>> getMyRecentPayslips() async {
    try {
      final response = await dioClient.dio.get(ApiConstants.myRecentPayslips);
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw Exception('Failed to get recent payslips: ${e.message}');
    }
  }

  // ── Single Payslip by ID ──────────────────────────────────────────────────

  /// GET /payroll/payslips/{id}
  /// Returns single PayslipResponse by UUID
  @override
  Future<Map<String, dynamic>> getPayslipById(String id) async {
    try {
      final response = await dioClient.dio.get(
        '${ApiConstants.payslips}/$id',
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('Failed to get payslip: ${e.message}');
    }
  }

  // ── Download Payslip PDF ──────────────────────────────────────────────────

  /// GET /payroll/payslips/{id}/download
  /// Returns PDF as bytes
  @override
  Future<List<int>> downloadPayslip(String id) async {
    try {
      final response = await dioClient.dio.get(
        ApiConstants.downloadPayslip(id),
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data as List<int>;
    } on DioException catch (e) {
      throw Exception('Failed to download payslip: ${e.message}');
    }
  }
}