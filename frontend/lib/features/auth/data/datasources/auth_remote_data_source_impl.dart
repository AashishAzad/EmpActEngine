import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../abstracts/auth_remote_data_source.dart';
import '../models/user_model.dart';

/// Auth Remote Data Source
///
/// Handles all auth-related API calls against the Jmix/Spring Boot backend.
///
/// Endpoint shapes:
/// POST /auth/login    → AuthResponse { accessToken, refreshToken, user: UserInfo }
/// GET  /auth/profile  → EmployeeResponse (richer shape, same field names)
/// POST /auth/refresh  → AuthResponse { accessToken, refreshToken, user: UserInfo }
/// POST /auth/logout   → { message: "Logged out successfully" }

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient dioClient;

  AuthRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<LoginResponse> login(String employeeId, String password) async {
    try {
      final response = await dioClient.dio.post(
        ApiConstants.login,
        data: {
          'employeeId': employeeId,   // backend LoginRequest field name
          'password': password,
        },
      );
      return LoginResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleDioException(e);
    }
    throw Exception('Login failed: unexpected error');
  }

  @override
  Future<UserModel> getProfile() async {
    try {
      final response = await dioClient.dio.get(ApiConstants.profile);
      // Returns EmployeeResponse shape — UserModel.fromJson handles both shapes
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleDioException(e);
    }
    throw Exception('Get profile failed: unexpected error');
  }

  @override
  Future<void> logout() async {
    try {
      await dioClient.dio.post(ApiConstants.logout);
      // Backend returns { message: "Logged out successfully" } — we ignore it.
      // Stateless JWT logout: client just discards tokens.
    } on DioException catch (e) {
      // Logout errors are non-fatal — local tokens will still be cleared.
      throw Exception('Logout failed: ${e.message}');
    }
  }

  @override
  Future<LoginResponse> refreshToken(String refreshToken) async {
    try {
      final response = await dioClient.dio.post(
        ApiConstants.refresh,
        data: {
          'refreshToken': refreshToken,  // backend RefreshTokenRequest field name
        },
      );
      // Backend returns full AuthResponse (same shape as login)
      return LoginResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleDioException(e);
    }
    throw Exception('Token refresh failed: unexpected error');
  }

  /// Centralized DioException handler
  /// Converts HTTP status codes to typed exceptions your repository catches.
  Never _handleDioException(DioException e) {
    final statusCode = e.response?.statusCode;
    final message = e.response?.data?['message'] as String? ?? e.message ?? 'Unknown error';

    switch (statusCode) {
      case 400:
        throw Exception('Bad request: $message');
      case 401:
        throw Exception('Unauthorized: $message');
      case 403:
        throw Exception('Forbidden: $message');
      case 404:
        throw Exception('Not found: $message');
      case 500:
        throw Exception('Server error: $message');
      default:
        throw Exception('Request failed: $message');
    }
  }
}