import 'package:dio/dio.dart';

/// Custom Exceptions
///
/// Domain-specific exceptions for better error handling

// ========== BASE EXCEPTION ==========

abstract class AppException implements Exception {
  final String message;
  final String? code;

  AppException(this.message, [this.code]);

  @override
  String toString() => message;
}

// ========== GENERIC EXCEPTION ==========

class GenericException extends AppException {
  GenericException([String? message])
      : super(message ?? 'An error occurred');
}

// ========== NETWORK EXCEPTIONS ==========

class NetworkException extends AppException {
  NetworkException([String? message])
      : super(message ?? 'Network error. Please check your connection.');
}

class TimeoutException extends AppException {
  TimeoutException([String? message])
      : super(message ?? 'Connection timeout. Please try again.');
}

class NoInternetException extends AppException {
  NoInternetException([String? message])
      : super(message ?? 'No internet connection. Please check your network.');
}

// ========== AUTH EXCEPTIONS ==========

class UnauthorizedException extends AppException {
  UnauthorizedException([String? message])
      : super(message ?? 'Unauthorized. Please login again.');
}

class ForbiddenException extends AppException {
  ForbiddenException([String? message])
      : super(message ?? 'Access forbidden. You don\'t have permission.');
}

class TokenExpiredException extends AppException {
  TokenExpiredException([String? message])
      : super(message ?? 'Session expired. Please login again.');
}

// ========== DATA EXCEPTIONS ==========

class NotFoundException extends AppException {
  NotFoundException([String? message])
      : super(message ?? 'Resource not found.');
}

class ConflictException extends AppException {
  ConflictException([String? message])
      : super(message ?? 'Conflict occurred. Resource already exists.');
}

class ValidationException extends AppException {
  final Map<String, dynamic>? errors;

  ValidationException([String? message, this.errors])
      : super(message ?? 'Validation failed.');
}

// ========== SERVER EXCEPTIONS ==========

class ServerException extends AppException {
  ServerException([String? message])
      : super(message ?? 'Server error. Please try again later.');
}

class BadRequestException extends AppException {
  BadRequestException([String? message])
      : super(message ?? 'Bad request. Please check your input.');
}

// ========== LOCATION EXCEPTIONS ==========

class LocationException extends AppException {
  LocationException([String? message])
      : super(message ?? 'Unable to get location. Please enable GPS.');
}

class LocationPermissionException extends AppException {
  LocationPermissionException([String? message])
      : super(message ?? 'Location permission denied. Please grant permission.');
}

// ========== STORAGE EXCEPTIONS ==========

class StorageException extends AppException {
  StorageException([String? message])
      : super(message ?? 'Storage error occurred.');
}

class CacheException extends AppException {
  CacheException([String? message])
      : super(message ?? 'Cache error occurred.');
}

// ========== PARSE EXCEPTIONS ==========

class ParseException extends AppException {
  ParseException([String? message])
      : super(message ?? 'Failed to parse data.');
}

// ========== EXCEPTION FACTORY ==========

/// Exception Factory
///
/// Converts Dio exceptions to custom exceptions

class ExceptionFactory {
  static AppException fromDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException(error.message);

      case DioExceptionType.connectionError:
        return NoInternetException();

      case DioExceptionType.badResponse:
        return _handleBadResponse(error.response);

      case DioExceptionType.cancel:
        return GenericException('Request cancelled'); // ← Fixed: Using GenericException

      default:
        return NetworkException(error.message);
    }
  }

  static AppException _handleBadResponse(Response? response) {
    if (response == null) {
      return ServerException();
    }

    final statusCode = response.statusCode;
    final data = response.data;

    // Extract error message from response
    String? message;
    if (data is Map<String, dynamic>) {
      message = data['message'] as String?;
    }

    switch (statusCode) {
      case 400:
        return BadRequestException(message);

      case 401:
        return UnauthorizedException(message);

      case 403:
        return ForbiddenException(message);

      case 404:
        return NotFoundException(message);

      case 409:
        return ConflictException(message);

      case 422:
        final errors = data is Map ? data['errors'] : null;
        return ValidationException(message, errors);

      case 500:
      case 502:
      case 503:
        return ServerException(message);

      default:
        return ServerException(message ?? 'Unknown error occurred');
    }
  }

  static AppException fromException(Object error) {
    if (error is DioException) {
      return fromDioException(error);
    } else if (error is AppException) {
      return error;
    } else {
      return GenericException(error.toString()); // ← Fixed: Using GenericException
    }
  }
}

// ========== FAILURES (for Clean Architecture) ==========

/// Failure
///
/// Represents failure in use cases (Clean Architecture pattern)

abstract class Failure {
  final String message;
  final String? code;

  const Failure(this.message, [this.code]);

  @override
  String toString() => message;
}

class ServerFailure extends Failure {
  const ServerFailure([String? message])
      : super(message ?? 'Server error occurred');
}

class NetworkFailure extends Failure {
  const NetworkFailure([String? message])
      : super(message ?? 'Network error occurred');
}

class CacheFailure extends Failure {
  const CacheFailure([String? message])
      : super(message ?? 'Cache error occurred');
}

class AuthFailure extends Failure {
  const AuthFailure([String? message])
      : super(message ?? 'Authentication failed');
}

class ValidationFailure extends Failure {
  const ValidationFailure([String? message])
      : super(message ?? 'Validation failed');
}

class LocationFailure extends Failure {
  const LocationFailure([String? message])
      : super(message ?? 'Location error occurred');
}

// ========== FAILURE FACTORY ==========

class FailureFactory {
  static Failure fromException(Object error) {
    if (error is UnauthorizedException || error is TokenExpiredException) {
      return AuthFailure(error.toString());
    } else if (error is NetworkException ||
        error is TimeoutException ||
        error is NoInternetException) {
      return NetworkFailure(error.toString());
    } else if (error is ServerException || error is BadRequestException) {
      return ServerFailure(error.toString());
    } else if (error is ValidationException) {
      return ValidationFailure(error.toString());
    } else if (error is LocationException ||
        error is LocationPermissionException) {
      return LocationFailure(error.toString());
    } else if (error is CacheException || error is StorageException) {
      return CacheFailure(error.toString());
    } else {
      return ServerFailure(error.toString());
    }
  }
}