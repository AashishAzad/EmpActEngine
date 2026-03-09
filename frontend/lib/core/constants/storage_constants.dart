class StorageConstants {
  // Secure Storage Keys (for sensitive data)
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';

  // SharedPreferences Keys
  static const String userId = 'user_id';
  static const String employeeId = 'employee_id';
  static const String firstName = 'first_name';
  static const String lastName = 'last_name';
  static const String email = 'email';
  static const String role = 'user_role';
  static const String phoneNumber = 'phone_number';
  static const String designation = 'designation';
  static const String department = 'department';

  // App Preferences
  static const String isFirstLaunch = 'is_first_launch';
  static const String isDarkMode = 'is_dark_mode';
  static const String language = 'language';
  static const String notificationsEnabled = 'notifications_enabled';
  static const String locationPermissionGranted = 'location_permission_granted';

  // Cache
  static const String lastSyncTime = 'last_sync_time';
  static const String cachedNotifications = 'cached_notifications';

  // WebSocket
  static const String wsConnected = 'ws_connected';
}