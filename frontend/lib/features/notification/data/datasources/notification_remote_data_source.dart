import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';

/// Notification Remote Data Source
///
/// All notification API calls against the Jmix backend.
///
/// Endpoint shapes:
/// GET  /notifications                → List<NotificationResponse>  (NOT paginated, NOT wrapped)
/// GET  /notifications/unread-count   → { "count": Long }
/// PATCH /notifications/{id}/read     → NotificationResponse
/// DELETE /notifications/{id}         → { "message": "..." }  (Admin only)
///
/// NOTE: There is NO markAllAsRead endpoint in the backend.
/// That feature has been removed from the data source.

abstract class NotificationDataSource {
  Future<List<dynamic>> getNotifications({
    bool unreadOnly = false,
    bool includeExpired = false,
    String? type,
  });

  Future<int> getUnreadCount();
  Future<Map<String, dynamic>> markAsRead(String id);
  Future<void> deleteNotification(String id);
}

class NotificationRemoteDataSource implements NotificationDataSource {
  final DioClient dioClient;

  NotificationRemoteDataSource({required this.dioClient});

  // ── Get Notifications ──────────────────────────────────────────────────────

  /// GET /notifications?unreadOnly=false&includeExpired=false&type=
  /// Returns List<NotificationResponse> directly — no pagination wrapper.
  @override
  Future<List<dynamic>> getNotifications({
    bool unreadOnly = false,
    bool includeExpired = false,
    String? type,
  }) async {
    try {
      final response = await dioClient.dio.get(
        ApiConstants.notifications,
        queryParameters: {
          'unreadOnly': unreadOnly,
          'includeExpired': includeExpired,
          if (type != null) 'type': type,
        },
      );
      // Backend returns List<NotificationResponse> directly
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw Exception('Failed to get notifications: ${e.message}');
    }
  }

  // ── Unread Count ───────────────────────────────────────────────────────────

  /// GET /notifications/unread-count
  /// Returns { "count": Long } — key is "count", value is a number
  @override
  Future<int> getUnreadCount() async {
    try {
      final response = await dioClient.dio.get(ApiConstants.unreadCount);
      // Backend: Map.of("count", notificationService.getUnreadCount(userId))
      return (response.data['count'] as num?)?.toInt() ?? 0;
    } on DioException catch (e) {
      return 0; // Non-critical — fail silently
    }
  }

  // ── Mark As Read ───────────────────────────────────────────────────────────

  /// PATCH /notifications/{id}/read
  /// Returns updated NotificationResponse
  @override
  Future<Map<String, dynamic>> markAsRead(String id) async {
    try {
      final response = await dioClient.dio.patch(
        ApiConstants.markAsRead(id), // → /notifications/{id}/read
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('Failed to mark as read: ${e.message}');
    }
  }

  // ── Delete Notification (Admin only) ──────────────────────────────────────

  /// DELETE /notifications/{id}
  /// Admin only — returns { "message": "..." }
  @override
  Future<void> deleteNotification(String id) async {
    try {
      await dioClient.dio.delete(ApiConstants.deleteNotification(id));
    } on DioException catch (e) {
      throw Exception('Failed to delete notification: ${e.message}');
    }
  }
}