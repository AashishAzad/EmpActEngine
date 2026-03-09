import 'package:permission_handler/permission_handler.dart';

/// Permission Utils
///
/// Handles runtime permissions for:
/// - Location (for attendance GPS)
/// - Camera (for profile photo)
/// - Storage (for file downloads)
/// - Notifications

class PermissionUtils {
  // ========== LOCATION PERMISSION ==========

  /// Check if location permission is granted
  static Future<bool> isLocationGranted() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }

  /// Request location permission
  static Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  /// Check if location permission is permanently denied
  static Future<bool> isLocationPermanentlyDenied() async {
    final status = await Permission.location.status;
    return status.isPermanentlyDenied;
  }

  /// Request location permission with dialog
  static Future<PermissionStatus> requestLocation() async {
    var status = await Permission.location.status;

    if (status.isDenied) {
      status = await Permission.location.request();
    }

    return status;
  }

  // ========== CAMERA PERMISSION ==========

  /// Check if camera permission is granted
  static Future<bool> isCameraGranted() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  /// Request camera permission
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Request camera permission with dialog
  static Future<PermissionStatus> requestCamera() async {
    var status = await Permission.camera.status;

    if (status.isDenied) {
      status = await Permission.camera.request();
    }

    return status;
  }

  // ========== STORAGE PERMISSION ==========

  /// Check if storage permission is granted
  static Future<bool> isStorageGranted() async {
    final status = await Permission.storage.status;
    return status.isGranted;
  }

  /// Request storage permission
  static Future<bool> requestStoragePermission() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  /// Request storage permission (for downloads)
  static Future<PermissionStatus> requestStorage() async {
    var status = await Permission.storage.status;

    if (status.isDenied) {
      status = await Permission.storage.request();
    }

    return status;
  }

  // ========== NOTIFICATION PERMISSION ==========

  /// Check if notification permission is granted
  static Future<bool> isNotificationGranted() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// Request notification permission
  static Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Request notification permission with dialog
  static Future<PermissionStatus> requestNotification() async {
    var status = await Permission.notification.status;

    if (status.isDenied) {
      status = await Permission.notification.request();
    }

    return status;
  }

  // ========== PHOTOS PERMISSION (iOS) ==========

  /// Check if photos permission is granted
  static Future<bool> isPhotosGranted() async {
    final status = await Permission.photos.status;
    return status.isGranted;
  }

  /// Request photos permission
  static Future<bool> requestPhotosPermission() async {
    final status = await Permission.photos.request();
    return status.isGranted;
  }

  // ========== MULTIPLE PERMISSIONS ==========

  /// Request multiple permissions at once
  static Future<Map<Permission, PermissionStatus>> requestMultiple(
      List<Permission> permissions,
      ) async {
    return await permissions.request();
  }

  /// Request location and camera (for attendance with photo)
  static Future<bool> requestLocationAndCamera() async {
    final statuses = await [
      Permission.location,
      Permission.camera,
    ].request();

    return statuses[Permission.location]!.isGranted &&
        statuses[Permission.camera]!.isGranted;
  }

  // ========== PERMISSION STATUS HELPERS ==========

  /// Get human-readable permission status message
  static String getPermissionMessage(PermissionStatus status, String permissionName) {
    switch (status) {
      case PermissionStatus.granted:
        return '$permissionName permission granted';
      case PermissionStatus.denied:
        return '$permissionName permission denied';
      case PermissionStatus.permanentlyDenied:
        return '$permissionName permission permanently denied. Please enable in settings.';
      case PermissionStatus.restricted:
        return '$permissionName permission restricted';
      case PermissionStatus.limited:
        return '$permissionName permission limited';
      default:
        return 'Unknown permission status';
    }
  }

  /// Open app settings
  static Future<bool> openSettings() async {
    return await openAppSettings(); // calls permission_handler's top-level function
  }

  // ========== SPECIFIC USE CASES ==========

  /// Check and request permissions for marking attendance
  /// Requires: Location
  static Future<bool> checkAttendancePermissions() async {
    final locationGranted = await isLocationGranted();

    if (locationGranted) {
      return true;
    }

    return await requestLocationPermission();
  }

  /// Check and request permissions for uploading profile photo
  /// Requires: Camera or Photos
  static Future<bool> checkPhotoUploadPermissions() async {
    // Check camera first
    final cameraGranted = await isCameraGranted();
    if (cameraGranted) {
      return true;
    }

    // Try requesting camera
    final cameraRequested = await requestCameraPermission();
    if (cameraRequested) {
      return true;
    }

    // If camera denied, try photos (iOS)
    final photosGranted = await isPhotosGranted();
    if (photosGranted) {
      return true;
    }

    return await requestPhotosPermission();
  }

  /// Check and request permissions for downloading files
  /// Requires: Storage
  static Future<bool> checkDownloadPermissions() async {
    final storageGranted = await isStorageGranted();

    if (storageGranted) {
      return true;
    }

    return await requestStoragePermission();
  }

  /// Check all required app permissions
  static Future<Map<String, bool>> checkAllPermissions() async {
    return {
      'location': await isLocationGranted(),
      'camera': await isCameraGranted(),
      'storage': await isStorageGranted(),
      'notification': await isNotificationGranted(),
    };
  }

  /// Request all app permissions at startup
  static Future<void> requestAllPermissions() async {
    await requestMultiple([
      Permission.location,
      Permission.notification,
    ]);
  }
}