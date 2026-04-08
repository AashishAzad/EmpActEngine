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