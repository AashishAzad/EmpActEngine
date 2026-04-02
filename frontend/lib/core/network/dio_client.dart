import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';
import '../constants/storage_constants.dart';

/// Dio Client
///
/// Configured HTTP client with interceptors for:
/// - Authentication (JWT token)
/// - Logging
/// - Error handling
/// - Token refresh

class DioClient {
  late final Dio _dio;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  DioClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors
    _dio.interceptors.add(_authInterceptor());
    _dio.interceptors.add(_logInterceptor());
    _dio.interceptors.add(_errorInterceptor());
  }

  // Get Dio instance
  Dio get dio => _dio;

  /// Auth Interceptor
  /// Adds JWT token to requests
  Interceptor _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Get access token from secure storage
        final token = await _secureStorage.read(
          key: StorageConstants.accessToken,
        );

        // Add token to headers if exists
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        return handler.next(options);
      },
      onError: (error, handler) async {
        // Some backend auth failures come back as 403 instead of 401.
        if (_shouldAttemptTokenRefresh(error)) {
          // Try to refresh token
          final refreshed = await _refreshToken();

          if (refreshed) {
            // Retry the request with new token
            final options = error.requestOptions;
            options.extra['tokenRetried'] = true;
            final token = await _secureStorage.read(
              key: StorageConstants.accessToken,
            );
            options.headers['Authorization'] = 'Bearer $token';

            try {
              final response = await _dio.fetch(options);
              return handler.resolve(response);
            } catch (e) {
              return handler.next(error);
            }
          }
        }
        return handler.next(error);
      },
    );
  }

  bool _shouldAttemptTokenRefresh(DioException error) {
    final statusCode = error.response?.statusCode;
    final options = error.requestOptions;
    final hasAuthHeader = (options.headers['Authorization']?.toString() ?? '')
        .trim()
        .isNotEmpty;
    final alreadyRetried = options.extra['tokenRetried'] == true;
    final isRefreshCall = options.path == ApiConstants.refresh;

    if (alreadyRetried || isRefreshCall || !hasAuthHeader) {
      return false;
    }

    return statusCode == 401 || statusCode == 403;
  }

  /// Log Interceptor
  /// Logs requests and responses in debug mode
  Interceptor _logInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        print('🌐 REQUEST[${options.method}] => PATH: ${options.path}');
        print('📤 HEADERS: ${options.headers}');
        if (options.data != null) {
          print('📦 BODY: ${options.data}');
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print('✅ RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
        print('📥 DATA: ${response.data}');
        return handler.next(response);
      },
      onError: (error, handler) {
        print('❌ ERROR[${error.response?.statusCode}] => PATH: ${error.requestOptions.path}');
        print('💥 MESSAGE: ${error.message}');
        if (error.response?.data != null) {
          print('📛 ERROR DATA: ${error.response?.data}');
        }
        return handler.next(error);
      },
    );
  }

  /// Error Interceptor
  /// Handles common errors
  Interceptor _errorInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) {
        // Network errors
        if (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            error.type == DioExceptionType.sendTimeout) {
          error = error.copyWith(
            message: 'Connection timeout. Please check your internet connection.',
          );
        } else if (error.type == DioExceptionType.connectionError) {
          error = error.copyWith(
            message: 'No internet connection. Please check your network.',
          );
        }

        // HTTP errors
        if (error.response != null) {
          switch (error.response!.statusCode) {
            case 400:
              error = error.copyWith(
                message: error.response?.data['message'] ?? 'Bad request',
              );
              break;
            case 401:
              error = error.copyWith(
                message: 'Unauthorized. Please login again.',
              );
              break;
            case 403:
              error = error.copyWith(
                message: 'Access forbidden. You don\'t have permission.',
              );
              break;
            case 404:
              error = error.copyWith(
                message: 'Resource not found.',
              );
              break;
            case 409:
              error = error.copyWith(
                message: error.response?.data['message'] ?? 'Conflict occurred',
              );
              break;
            case 500:
              error = error.copyWith(
                message: 'Server error. Please try again later.',
              );
              break;
            default:
              error = error.copyWith(
                message: error.response?.data['message'] ??
                    'Something went wrong. Please try again.',
              );
          }
        }

        return handler.next(error);
      },
    );
  }

  /// Refresh Token
  /// Attempts to refresh the access token using refresh token
  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _secureStorage.read(
        key: StorageConstants.refreshToken,
      );

      if (refreshToken == null || refreshToken.isEmpty) {
        return false;
      }

      // Call refresh endpoint
      final response = await _dio.post(
        ApiConstants.refresh,
        data: {'refreshToken': refreshToken},
        options: Options(
          headers: {
            'Authorization': '', // No auth header for refresh
          },
        ),
      );

      if (response.statusCode == 200) {
        final newAccessToken = response.data['accessToken'];
        final newRefreshToken = response.data['refreshToken'];

        // Save new access token
        await _secureStorage.write(
          key: StorageConstants.accessToken,
          value: newAccessToken,
        );

        // Save new refresh token if backend rotated it
        if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
          await _secureStorage.write(
            key: StorageConstants.refreshToken,
            value: newRefreshToken,
          );
        }

        print('✅ Token refreshed successfully');
        return true;
      }

      return false;
    } catch (e) {
      print('❌ Token refresh failed: $e');
      // Clear tokens on refresh failure
      await _secureStorage.delete(key: StorageConstants.accessToken);
      await _secureStorage.delete(key: StorageConstants.refreshToken);
      return false;
    }
  }

  /// Clear all stored tokens
  Future<void> clearTokens() async {
    await _secureStorage.delete(key: StorageConstants.accessToken);
    await _secureStorage.delete(key: StorageConstants.refreshToken);
  }
}