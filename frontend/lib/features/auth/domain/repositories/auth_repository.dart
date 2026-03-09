import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../entities/user.dart';

/// Auth Repository Interface
///
/// Defines the contract for auth operations.

abstract class AuthRepository {
  Future<Either<Failure, User>> login(String employeeId, String password);
  Future<Either<Failure, User>> getProfile();
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, bool>> isLoggedIn();
  Future<Either<Failure, User>> getCurrentUser();

  /// Refresh token — returns updated User with new tokens saved to storage.
  /// If refresh token is expired, returns AuthFailure and clears local storage.
  Future<Either<Failure, User>> refreshToken(String refreshToken);
}