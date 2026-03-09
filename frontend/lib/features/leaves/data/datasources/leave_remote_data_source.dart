import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';

/// Leave Remote Data Source
///
/// All leave API calls against the Jmix backend.
///
/// Endpoint shapes:
/// POST  /leaves                  → LeaveResponse (201)
/// GET   /leaves/my-leaves        → List<LeaveResponse> (plain list, no wrapper)
/// GET   /leaves/my-balance       → LeaveBalanceResponse
/// GET   /leaves/pending          → List<LeaveResponse> (plain list, Admin/Manager)
/// PATCH /leaves/{id}/approve     → LeaveResponse (no body needed)
/// PATCH /leaves/{id}/reject      → LeaveResponse (body: ActionLeaveRequest)

class LeaveRemoteDataSource {
  final DioClient dioClient;

  LeaveRemoteDataSource({required this.dioClient});

  // ── Apply Leave ────────────────────────────────────────────────────────────

  /// POST /leaves
  /// ApplyLeaveRequest fields:
  /// leaveType (LeaveType enum), startDate, endDate,
  /// contactNumber (@NotBlank), contactEmail (@NotBlank @Email), remarks (optional)
  Future<Map<String, dynamic>> applyLeave({
    required String leaveType,
    required String startDate, // "yyyy-MM-dd"
    required String endDate,   // "yyyy-MM-dd"
    required String contactNumber,
    required String contactEmail,
    String? remarks,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'leaveType': leaveType,
        'startDate': startDate,
        'endDate': endDate,
        'contactNumber': contactNumber,
        'contactEmail': contactEmail,
      };
      if (remarks != null && remarks.isNotEmpty) {
        data['remarks'] = remarks;
      }

      final response = await dioClient.dio.post(
        ApiConstants.leaves, // → POST /leaves
        data: data,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('Failed to apply leave: ${e.message}');
    }
  }

  // ── My Leaves ──────────────────────────────────────────────────────────────

  /// GET /leaves/my-leaves
  /// Returns List<LeaveResponse> directly — no pagination wrapper.
  Future<List<dynamic>> getMyLeaves() async {
    try {
      final response = await dioClient.dio.get(ApiConstants.myLeaves);
      // Backend returns List<LeaveResponse> directly
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw Exception('Failed to get leaves: ${e.message}');
    }
  }

  // ── Pending Leaves (Admin/Manager) ─────────────────────────────────────────

  /// GET /leaves/pending
  /// Returns List<LeaveResponse> directly — no wrapper.
  Future<List<dynamic>> getPendingLeaves() async {
    try {
      final response = await dioClient.dio.get(ApiConstants.pendingLeaves);
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw Exception('Failed to get pending leaves: ${e.message}');
    }
  }

  // ── Approve Leave ──────────────────────────────────────────────────────────

  /// PATCH /leaves/{id}/approve
  /// No request body needed — backend sets status to APPROVED directly.
  Future<void> approveLeave({required String leaveId}) async {
    try {
      await dioClient.dio.patch(
        '${ApiConstants.leaves}/$leaveId/approve',
      );
    } on DioException catch (e) {
      throw Exception('Failed to approve leave: ${e.message}');
    }
  }

  // ── Reject Leave ───────────────────────────────────────────────────────────

  /// PATCH /leaves/{id}/reject
  /// Body: ActionLeaveRequest { status: "REJECTED", actionRemarks: "..." }
  /// actionRemarks is optional but should be provided for transparency.
  Future<void> rejectLeave({
    required String leaveId,
    required String actionRemarks,
  }) async {
    try {
      await dioClient.dio.patch(
        '${ApiConstants.leaves}/$leaveId/reject',
        data: {
          'status': 'REJECTED',       // ActionLeaveRequest.status
          'actionRemarks': actionRemarks, // ActionLeaveRequest.actionRemarks
        },
      );
    } on DioException catch (e) {
      throw Exception('Failed to reject leave: ${e.message}');
    }
  }
}