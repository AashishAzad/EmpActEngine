import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/storage_helper.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

/// Auth Repository Implementation
///
/// Implements auth repository with error handling.
/// Bridges between remote data source and domain layer.

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final StorageHelper storageHelper;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.storageHelper,
  });

  // ── Login ─────────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, User>> login(
      String employeeId,
      String password,
      ) async {
    try {
      final response = await remoteDataSource.login(employeeId, password);

      // Save JWT tokens to secure storage
      await storageHelper.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );

      // Save user data to shared preferences for offline access
      await storageHelper.saveUserData(
        userId: response.user.id,
        employeeId: response.user.employeeId,
        firstName: response.user.firstName,
        lastName: response.user.lastName,
        email: response.user.email,
        role: response.user.role,
        phoneNumber: response.user.phoneNumber,
        designation: response.user.designation,
        department: response.user.department,
      );

      return Right(response.user.toEntity());
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ── Get Profile ───────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, User>> getProfile() async {
    try {
      final userModel = await remoteDataSource.getProfile();

      // Update cached user data with latest from server (EmployeeResponse has more fields)
      await storageHelper.saveUserData(
        userId: userModel.id,
        employeeId: userModel.employeeId,
        firstName: userModel.firstName,
        lastName: userModel.lastName,
        email: userModel.email,
        role: userModel.role,
        phoneNumber: userModel.phoneNumber,
        designation: userModel.designation,
        department: userModel.department,
      );

      return Right(userModel.toEntity());
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await remoteDataSource.logout();
    } catch (_) {
      // Backend logout is stateless — even if the API call fails,
      // we still clear local data. JWT becomes invalid on expiry anyway.
    } finally {
      await storageHelper.clearUserData();
    }
    return const Right(null);
  }

  // ── Is Logged In ──────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, bool>> isLoggedIn() async {
    try {
      final isLoggedIn = await storageHelper.isLoggedIn();
      return Right(isLoggedIn);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  // ── Get Current User (from local cache) ───────────────────────────────────

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    try {
      final userId = storageHelper.getUserId();
      final employeeId = storageHelper.getEmployeeId();
      final firstName = storageHelper.getFirstName();
      final lastName = storageHelper.getLastName();
      final email = storageHelper.getEmail();
      final role = storageHelper.getUserRole();
      final phoneNumber = storageHelper.getPhoneNumber();
      final designation = storageHelper.getDesignation();
      final department = storageHelper.getDepartment();

      if (userId == null ||
          employeeId == null ||
          firstName == null ||
          lastName == null ||
          email == null ||
          role == null) {
        return const Left(CacheFailure('User data not found in local storage'));
      }

      return Right(User(
        id: userId,
        employeeId: employeeId,
        firstName: firstName,
        lastName: lastName,
        email: email,
        role: role,
        phoneNumber: phoneNumber,
        designation: designation,
        department: department,
      ));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  // ── Refresh Token ─────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, User>> refreshToken(String refreshToken) async {
    try {
      // Backend returns full AuthResponse (new tokens + updated user)
      final response = await remoteDataSource.refreshToken(refreshToken);

      // Save new tokens
      await storageHelper.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );

      // Update cached user data with refreshed user info
      await storageHelper.saveUserData(
        userId: response.user.id,
        employeeId: response.user.employeeId,
        firstName: response.user.firstName,
        lastName: response.user.lastName,
        email: response.user.email,
        role: response.user.role,
        phoneNumber: response.user.phoneNumber,
        designation: response.user.designation,
        department: response.user.department,
      );

      return Right(response.user.toEntity());
    } on UnauthorizedException catch (e) {
      // Refresh token expired — force logout
      await storageHelper.clearUserData();
      return Left(AuthFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}