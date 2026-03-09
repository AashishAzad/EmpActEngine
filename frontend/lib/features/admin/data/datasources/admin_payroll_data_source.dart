import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';

/// Admin Payroll Data Source
///
/// Handles admin operations for payroll and letter management.
///
/// Endpoints:
/// POST /payroll/salary              → SalaryResponse (201) — upsert salary
/// POST /payroll/generate-payslip    → PayslipResponse (201)
/// GET  /payroll/payslips            → PagedResponse<PayslipResponse> (Admin/Manager)
/// GET  /letters/pending             → List<LetterRequestResponse>
/// POST /letters/{id}/upload         → LetterRequestResponse (multipart/form-data)
/// PATCH /letters/{id}/reject        → LetterRequestResponse

class AdminPayrollDataSource {
  final DioClient dioClient;

  AdminPayrollDataSource({required this.dioClient});

  // ── Upsert Salary ──────────────────────────────────────────────────────────

  /// POST /payroll/salary — Admin only
  ///
  /// UpsertSalaryRequest fields:
  /// employeeId (UUID), basicPay, hra, specialAllowance,
  /// otherAllowances (default 0), pf, professionalTax (default 0),
  /// otherDeductions (default 0)
  ///
  /// NOTE: Old code sent basicSalary, conveyance, medical, incomeTax — all wrong.
  /// Correct field names from UpsertSalaryRequest: basicPay, hra,
  /// specialAllowance, otherAllowances, pf, professionalTax, otherDeductions.
  Future<Map<String, dynamic>> upsertSalary({
    required String employeeId,
    required double basicPay,
    required double hra,
    required double specialAllowance,
    double otherAllowances = 0.0,
    required double pf,
    double professionalTax = 0.0,
    double otherDeductions = 0.0,
  }) async {
    try {
      final response = await dioClient.dio.post(
        ApiConstants.createSalary, // → /payroll/salary
        data: {
          'employeeId': employeeId,
          'basicPay': basicPay,
          'hra': hra,
          'specialAllowance': specialAllowance,
          'otherAllowances': otherAllowances,
          'pf': pf,
          'professionalTax': professionalTax,
          'otherDeductions': otherDeductions,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('Failed to upsert salary: ${e.message}');
    }
  }

  // ── Generate Payslip ───────────────────────────────────────────────────────

  /// POST /payroll/generate-payslip — Admin only
  ///
  /// GeneratePayslipRequest fields: employeeId (UUID), month (1-12), year (2020-2100)
  ///
  /// NOTE: Old code sent workingDays, presentDays, leaveDays — those fields
  /// do NOT exist in GeneratePayslipRequest. Only employeeId, month, year.
  Future<Map<String, dynamic>> generatePayslip({
    required String employeeId,
    required int month,
    required int year,
  }) async {
    try {
      final response = await dioClient.dio.post(
        ApiConstants.generatePayslip, // → /payroll/generate-payslip
        data: {
          'employeeId': employeeId,
          'month': month,
          'year': year,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('Failed to generate payslip: ${e.message}');
    }
  }

  // ── Get All Payslips ───────────────────────────────────────────────────────

  /// GET /payroll/payslips?page=1&limit=20 — Admin/Manager
  /// Returns PagedResponse<PayslipResponse> — extracts 'data' array.
  ///
  /// NOTE: Old code assumed plain List — backend returns PagedResponse wrapper.
  Future<List<dynamic>> getAllPayslips({
    String? employeeId,
    int? month,
    int? year,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await dioClient.dio.get(
        ApiConstants.payslips, // → /payroll/payslips
        queryParameters: {
          'page': page,
          'limit': limit,
          if (employeeId != null) 'employeeId': employeeId,
          if (month != null) 'month': month,
          if (year != null) 'year': year,
        },
      );

      // Backend returns PagedResponse<PayslipResponse> — extract 'data'
      if (response.data is Map && response.data['data'] != null) {
        return response.data['data'] as List<dynamic>;
      }
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw Exception('Failed to get payslips: ${e.message}');
    }
  }

  // ── Get Pending Letter Requests ────────────────────────────────────────────

  /// GET /letters/pending — Admin only
  /// Returns List<LetterRequestResponse> directly.
  Future<List<dynamic>> getPendingLetterRequests() async {
    try {
      final response =
      await dioClient.dio.get(ApiConstants.pendingLetters);
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw Exception('Failed to get pending letters: ${e.message}');
    }
  }

  // ── Upload Letter (Multipart) ──────────────────────────────────────────────

  /// POST /letters/{id}/upload — Admin only
  /// Expects multipart/form-data with 'file' field (PDF).
  ///
  /// NOTE: Old code sent JSON { fileUrl: filePath } — completely wrong.
  /// Backend uses @RequestParam("file") MultipartFile — must send as FormData.
  Future<Map<String, dynamic>> uploadLetter({
    required String requestId,
    required String filePath, // Local file path on device
  }) async {
    try {
      final fileName = filePath.split('/').last;

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
        ),
      });

      final response = await dioClient.dio.post(
        ApiConstants.uploadLetter(requestId), // → /letters/{id}/upload
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('Failed to upload letter: ${e.message}');
    }
  }

  // ── Reject Letter ──────────────────────────────────────────────────────────

  /// PATCH /letters/{id}/reject — Admin only
  /// Body: { remarks: "..." } (optional)
  Future<Map<String, dynamic>> rejectLetter({
    required String requestId,
    String? remarks,
  }) async {
    try {
      final response = await dioClient.dio.patch(
        ApiConstants.rejectLetter(requestId), // → /letters/{id}/reject
        data: remarks != null ? {'remarks': remarks} : null,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('Failed to reject letter: ${e.message}');
    }
  }
}