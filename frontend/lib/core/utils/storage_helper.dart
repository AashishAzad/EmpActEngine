import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/storage_constants.dart';

/// Storage Helper
///
/// Manages both secure storage (tokens) and shared preferences (user data)
///
/// Secure Storage: For sensitive data (tokens, passwords)
/// Shared Preferences: For non-sensitive data (user info, settings)

class StorageHelper {
  static final StorageHelper _instance = StorageHelper._internal();
  factory StorageHelper() => _instance;
  StorageHelper._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  SharedPreferences? _prefs;

  /// Initialize SharedPreferences
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ========== SECURE STORAGE (Tokens) ==========

  /// Save access token
  Future<void> saveAccessToken(String token) async {
    await _secureStorage.write(
      key: StorageConstants.accessToken,
      value: token,
    );
  }

  /// Get access token
  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: StorageConstants.accessToken);
  }

  /// Save refresh token
  Future<void> saveRefreshToken(String token) async {
    await _secureStorage.write(
      key: StorageConstants.refreshToken,
      value: token,
    );
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: StorageConstants.refreshToken);
  }

  /// Save both tokens
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      saveAccessToken(accessToken),
      saveRefreshToken(refreshToken),
    ]);
  }

  /// Clear all tokens
  Future<void> clearTokens() async {
    await Future.wait([
      _secureStorage.delete(key: StorageConstants.accessToken),
      _secureStorage.delete(key: StorageConstants.refreshToken),
    ]);
  }

  /// Check if user is logged in (has access token)
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // ========== USER DATA (SharedPreferences) ==========

  /// Save user ID
  Future<void> saveUserId(String userId) async {
    await _prefs?.setString(StorageConstants.userId, userId);
  }

  /// Get user ID
  String? getUserId() {
    return _prefs?.getString(StorageConstants.userId);
  }

  /// Save employee ID
  Future<void> saveEmployeeId(String employeeId) async {
    await _prefs?.setString(StorageConstants.employeeId, employeeId);
  }

  /// Get employee ID
  String? getEmployeeId() {
    return _prefs?.getString(StorageConstants.employeeId);
  }

  /// Save user name
  Future<void> saveUserName({
    required String firstName,
    required String lastName,
  }) async {
    await Future.wait([
      _prefs?.setString(StorageConstants.firstName, firstName) ?? Future.value(),
      _prefs?.setString(StorageConstants.lastName, lastName) ?? Future.value(),
    ]);
  }

  /// Get first name
  String? getFirstName() {
    return _prefs?.getString(StorageConstants.firstName);
  }

  /// Get last name
  String? getLastName() {
    return _prefs?.getString(StorageConstants.lastName);
  }

  /// Get full name
  String? getFullName() {
    final firstName = getFirstName();
    final lastName = getLastName();

    if (firstName == null && lastName == null) return null;
    if (firstName == null) return lastName;
    if (lastName == null) return firstName;

    return '$firstName $lastName';
  }

  /// Save email
  Future<void> saveEmail(String email) async {
    await _prefs?.setString(StorageConstants.email, email);
  }

  /// Get email
  String? getEmail() {
    return _prefs?.getString(StorageConstants.email);
  }

  /// Save user role
  Future<void> saveUserRole(String role) async {
    await _prefs?.setString(StorageConstants.role, role);
  }

  /// Get user role
  String? getUserRole() {
    return _prefs?.getString(StorageConstants.role);
  }

  /// Save phone number
  Future<void> savePhoneNumber(String phone) async {
    await _prefs?.setString(StorageConstants.phoneNumber, phone);
  }

  /// Get phone number
  String? getPhoneNumber() {
    return _prefs?.getString(StorageConstants.phoneNumber);
  }

  /// Save designation
  Future<void> saveDesignation(String designation) async {
    await _prefs?.setString(StorageConstants.designation, designation);
  }

  /// Get designation
  String? getDesignation() {
    return _prefs?.getString(StorageConstants.designation);
  }

  /// Save department
  Future<void> saveDepartment(String department) async {
    await _prefs?.setString(StorageConstants.department, department);
  }

  /// Get department
  String? getDepartment() {
    return _prefs?.getString(StorageConstants.department);
  }

  /// Save complete user data
  Future<void> saveUserData({
    required String userId,
    required String employeeId,
    required String firstName,
    required String lastName,
    required String email,
    required String role,
    String? phoneNumber,
    String? designation,
    String? department,
  }) async {
    await Future.wait([
      saveUserId(userId),
      saveEmployeeId(employeeId),
      saveUserName(firstName: firstName, lastName: lastName),
      saveEmail(email),
      saveUserRole(role),
      if (phoneNumber != null) savePhoneNumber(phoneNumber),
      if (designation != null) saveDesignation(designation),
      if (department != null) saveDepartment(department),
    ]);
  }

  // ========== APP SETTINGS ==========

  /// Set first launch flag
  Future<void> setFirstLaunch(bool value) async {
    await _prefs?.setBool(StorageConstants.isFirstLaunch, value);
  }

  /// Check if first launch
  bool isFirstLaunch() {
    return _prefs?.getBool(StorageConstants.isFirstLaunch) ?? true;
  }

  /// Set dark mode
  Future<void> setDarkMode(bool value) async {
    await _prefs?.setBool(StorageConstants.isDarkMode, value);
  }

  /// Check if dark mode enabled
  bool isDarkMode() {
    return _prefs?.getBool(StorageConstants.isDarkMode) ?? false;
  }

  /// Set notifications enabled
  Future<void> setNotificationsEnabled(bool value) async {
    await _prefs?.setBool(StorageConstants.notificationsEnabled, value);
  }

  /// Check if notifications enabled
  bool areNotificationsEnabled() {
    return _prefs?.getBool(StorageConstants.notificationsEnabled) ?? true;
  }

  /// Set location permission granted
  Future<void> setLocationPermissionGranted(bool value) async {
    await _prefs?.setBool(StorageConstants.locationPermissionGranted, value);
  }

  /// Check if location permission granted
  bool isLocationPermissionGranted() {
    return _prefs?.getBool(StorageConstants.locationPermissionGranted) ?? false;
  }

  /// Save language
  Future<void> saveLanguage(String languageCode) async {
    await _prefs?.setString(StorageConstants.language, languageCode);
  }

  /// Get language
  String getLanguage() {
    return _prefs?.getString(StorageConstants.language) ?? 'en';
  }

  // ========== CACHE MANAGEMENT ==========

  /// Save last sync time
  Future<void> saveLastSyncTime(DateTime time) async {
    await _prefs?.setString(
      StorageConstants.lastSyncTime,
      time.toIso8601String(),
    );
  }

  /// Get last sync time
  DateTime? getLastSyncTime() {
    final timeString = _prefs?.getString(StorageConstants.lastSyncTime);
    if (timeString == null) return null;
    return DateTime.tryParse(timeString);
  }

  // ========== CLEAR DATA ==========

  /// Clear all user data (logout)
  Future<void> clearUserData() async {
    await Future.wait([
      clearTokens(),
      _prefs?.remove(StorageConstants.userId) ?? Future.value(),
      _prefs?.remove(StorageConstants.employeeId) ?? Future.value(),
      _prefs?.remove(StorageConstants.firstName) ?? Future.value(),
      _prefs?.remove(StorageConstants.lastName) ?? Future.value(),
      _prefs?.remove(StorageConstants.email) ?? Future.value(),
      _prefs?.remove(StorageConstants.role) ?? Future.value(),
      _prefs?.remove(StorageConstants.phoneNumber) ?? Future.value(),
      _prefs?.remove(StorageConstants.designation) ?? Future.value(),
      _prefs?.remove(StorageConstants.department) ?? Future.value(),
    ]);
  }

  /// Clear all data (complete reset)
  Future<void> clearAll() async {
    await Future.wait([
      _secureStorage.deleteAll(),
      _prefs?.clear() ?? Future.value(),
    ]);
  }

  // ========== HELPER METHODS ==========

  /// Check if user is admin
  bool isAdmin() {
    return getUserRole()?.toUpperCase() == 'ADMIN';
  }

  /// Check if user is manager
  bool isManager() {
    return getUserRole()?.toUpperCase() == 'MANAGER';
  }

  /// Check if user is employee
  bool isEmployee() {
    return getUserRole()?.toUpperCase() == 'EMPLOYEE';
  }

  /// Check if user has admin or manager role
  bool isAdminOrManager() {
    return isAdmin() || isManager();
  }
}