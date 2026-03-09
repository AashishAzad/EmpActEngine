import 'package:equatable/equatable.dart';

/// Auth Events
///
/// All possible auth-related events

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Login Event
class LoginRequested extends AuthEvent {
  final String employeeId;
  final String password;

  const LoginRequested({
    required this.employeeId,
    required this.password,
  });

  @override
  List<Object?> get props => [employeeId, password];
}

/// Logout Event
class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

/// Get Profile Event
class GetProfileRequested extends AuthEvent {
  const GetProfileRequested();
}

/// Check Auth Status Event
/// Fired on app launch to determine if user is already logged in
class AuthStatusChecked extends AuthEvent {
  const AuthStatusChecked();
}

/// Load Current User from local cache
class CurrentUserLoaded extends AuthEvent {
  const CurrentUserLoaded();
}

/// Refresh Token Event
/// Fired when Dio interceptor detects a 401 or when token is about to expire.
/// Pass the current refresh token stored in secure storage.
class RefreshTokenRequested extends AuthEvent {
  final String refreshToken;

  const RefreshTokenRequested({required this.refreshToken});

  @override
  List<Object?> get props => [refreshToken];
}