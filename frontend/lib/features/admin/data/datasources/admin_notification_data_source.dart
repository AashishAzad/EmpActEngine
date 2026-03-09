import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';

/// Admin Notification Data Source
///
/// Handles Admin/Manager operations for creating notifications.
///
/// Endpoints:
/// POST /notifications — Admin/Manager only → NotificationResponse (201)
///
/// CreateNotificationRequest fields:
/// title (@NotBlank), message (@NotBlank), type (@NotBlank),
/// isGlobal (bool, default false),
/// recipientIds (List<UUID> — required if isGlobal is false),
/// visibleTill (LocalDateTime, optional),
/// referenceId (optional), referenceType (optional)

class AdminNotificationDataSource {
  final DioClient dioClient;

  AdminNotificationDataSource({required this.dioClient});

  // ── Create Notification ────────────────────────────────────────────────────

  /// POST /notifications — Admin/Manager only
  ///
  /// For global announcements: set isGlobal = true, leave recipientIds null.
  /// For targeted notifications: set isGlobal = false, provide recipientIds (UUIDs).
  ///
  /// NOTE: Old code called '/notifications/generate' — that endpoint does NOT exist.
  /// Correct endpoint is POST /notifications.
  Future<Map<String, dynamic>> createNotification({
    required String title,
    required String message,
    required String type,
    bool isGlobal = false,
    List<String>? recipientIds, // List of employee UUID strings
    DateTime? visibleTill,
    String? referenceId,
    String? referenceType,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'title': title,
        'message': message,
        'type': type,
        'isGlobal': isGlobal,
      };

      // recipientIds are UUIDs — pass as strings, backend accepts UUID list
      if (recipientIds != null && recipientIds.isNotEmpty) {
        data['recipientIds'] = recipientIds;
      }

      if (visibleTill != null) {
        // Backend expects LocalDateTime — send as ISO string
        data['visibleTill'] = visibleTill.toIso8601String();
      }

      if (referenceId != null) data['referenceId'] = referenceId;
      if (referenceType != null) data['referenceType'] = referenceType;

      final response = await dioClient.dio.post(
        ApiConstants.notifications, // → POST /notifications
        data: data,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('Failed to create notification: ${e.message}');
    }
  }

// ── NOTE: getAllPendingRequests() removed ──────────────────────────────────
// The old method called '/admin/pending-requests' which does NOT exist
// in the backend. There is no combined pending requests endpoint.
//
// To get pending items use the individual endpoints:
// - Pending leaves:             GET /leaves/pending
// - Pending letter requests:    GET /letters/pending
// - Pending manual attendance:  GET /attendance/manual-requests/pending
//
// These are already handled by their respective data sources.
}