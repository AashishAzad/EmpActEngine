import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';

/// Auth States
///
/// All possible auth states

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial State — before any auth check has been performed
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Loading State — any async auth operation in progress
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Authenticated — user is logged in, user object available
class Authenticated extends AuthState {
  final User user;

  const Authenticated(this.user);

  @override
  List<Object?> get props => [user];
}

/// Unauthenticated — no valid session, show login screen
class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// Token Refreshing — silent background refresh in progress.
/// UI should NOT show loading spinner for this — keep showing current screen.
class TokenRefreshing extends AuthState {
  final User currentUser; // keep current user visible during refresh

  const TokenRefreshing(this.currentUser);

  @override
  List<Object?> get props => [currentUser];
}

/// Token Refreshed — refresh succeeded, new tokens saved
class TokenRefreshed extends AuthState {
  final User user;

  const TokenRefreshed(this.user);

  @override
  List<Object?> get props => [user];
}

/// Auth Error — something went wrong, message available for UI
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}