import '../data/models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<LoginResponse> login(String employeeId, String password);
  Future<UserModel> getProfile();
  Future<void> logout();
  Future<LoginResponse> refreshToken(String refreshToken);
}