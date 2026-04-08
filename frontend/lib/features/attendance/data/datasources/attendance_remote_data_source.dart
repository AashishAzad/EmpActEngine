import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../abstracts/attendance_data_source.dart';

/// Attendance Remote Data Source
///
/// All attendance API calls against the Jmix backend.
///
/// Endpoints:
/// POST /attendance/mark                        → AttendanceResponse (201)
/// GET  /attendance/today                       → Map<String, Object>
/// GET  /attendance/my-attendance?month=&year=  → List<AttendanceResponse>
/// GET  /attendance/summary?month=&year=        → AttendanceSummaryResponse
/// POST /attendance/manual-request              → ManualAttendanceRequestResponse (201)

class AttendanceRemoteDataSource implements AttendanceDataSource {
  final DioClient dioClient;

  AttendanceRemoteDataSource({required this.dioClient});

  // ── Mark Attendance ────────────────────────────────────────────────────────

  /// POST /attendance/mark
  /// MarkAttendanceRequest: latitude, longitude, address (@NotBlank)
  Future<Map<String, dynamic>> markAttendance({
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    try {
      final response = await dioClient.dio.post(
        ApiConstants.markAttendance, // → /attendance/mark
        data: {
          'latitude': latitude,
          'longitude': longitude,
          'address': address,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('Failed to mark attendance: ${e.message}');
    }
  }

  // ── Today's Attendance ─────────────────────────────────────────────────────

  /// GET /attendance/today
  /// Returns Map<String, Object> — check if user already marked today
  Future<Map<String, dynamic>> getTodayAttendance() async {
    try {
      final response = await dioClient.dio.get(ApiConstants.todayAttendance);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('Failed to get today\'s attendance: ${e.message}');
    }
  }

  // ── My Attendance History ──────────────────────────────────────────────────

  /// GET /attendance/my-attendance?month=&year=
  /// Returns List<AttendanceResponse> directly — no pagination wrapper.
  /// month and year are optional — backend defaults to current month/year if null.
  Future<List<dynamic>> getAttendanceHistory({
    int? month,
    int? year,
  }) async {
    try {
      final response = await dioClient.dio.get(
        ApiConstants.myAttendance, // → /attendance/my-attendance
        queryParameters: {
          if (month != null) 'month': month,
          if (year != null) 'year': year,
        },
      );
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw Exception('Failed to get attendance history: ${e.message}');
    }
  }

  // ── Monthly Summary ────────────────────────────────────────────────────────

  /// GET /attendance/summary?month=&year=
  /// Returns AttendanceSummaryResponse with stats.
  /// NOTE: Old code called /attendance/my/stats — that endpoint does NOT exist.
  /// Correct endpoint is /attendance/summary
  Future<Map<String, dynamic>> getAttendanceSummary({
    required int month,
    required int year,
  }) async {
    try {
      final response = await dioClient.dio.get(
        ApiConstants.attendanceSummary, // → /attendance/summary
        queryParameters: {
          'month': month,
          'year': year,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('Failed to get attendance summary: ${e.message}');
    }
  }

  // ── Manual Attendance Request ──────────────────────────────────────────────

  /// POST /attendance/manual-request
  /// ManualAttendanceRequestDto fields (inferred from entity):
  ///   requestDate (LocalDate) → send as "yyyy-MM-dd" string
  ///   reason (String, @NotBlank)
  Future<Map<String, dynamic>> requestManualAttendance({
    required DateTime date,
    required String reason,
  }) async {
    try {
      final response = await dioClient.dio.post(
        ApiConstants.manualAttendanceRequest, // → /attendance/manual-request
        data: {
          // Entity field is "requestDate" (LocalDate) — send as date-only string
          'requestDate': DateFormat('yyyy-MM-dd').format(date),
          'reason': reason,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('Failed to submit manual request: ${e.message}');
    }
  }
}