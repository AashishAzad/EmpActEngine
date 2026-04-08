abstract class AdminNotificationSource {
  Future<Map<String, dynamic>> createNotification({
    required String title,
    required String message,
    required String type,
    bool isGlobal = false,
    List<String>? recipientIds,
    DateTime? visibleTill,
    String? referenceId,
    String? referenceType,
  });
}