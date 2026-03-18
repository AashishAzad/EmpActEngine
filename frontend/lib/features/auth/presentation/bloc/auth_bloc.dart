import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/storage_helper.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// Auth BLoC
///
/// Manages authentication state and business logic.
///
/// State flow:
/// App launch  → AuthStatusChecked → AuthLoading → Authenticated / Unauthenticated
/// Login       → LoginRequested    → AuthLoading → Authenticated / AuthError
/// Logout      → LogoutRequested   → AuthLoading → Unauthenticated
/// 401 error   → RefreshTokenRequested → TokenRefreshing → TokenRefreshed / Unauthenticated

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  final StorageHelper storageHelper;

  AuthBloc({
    required this.authRepository,
    required this.storageHelper,
  }) : super(const AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<GetProfileRequested>(_onGetProfileRequested);
    on<AuthStatusChecked>(_onAuthStatusChecked);
    on<CurrentUserLoaded>(_onCurrentUserLoaded);
    on<RefreshTokenRequested>(_onRefreshTokenRequested);
  }

  // ── Login ─────────────────────────────────────────────────────────────────

  Future<void> _onLoginRequested(
      LoginRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(const AuthLoading());

    final result = await authRepository.login(
      event.employeeId,
      event.password,
    );

    result.fold(
          (failure) => emit(AuthError(failure.message)),
          (user) => emit(Authenticated(user)),
    );
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Future<void> _onLogoutRequested(
      LogoutRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(const AuthLoading());
    try {
      await authRepository.logout();
    } catch (_) {
      // Even if local cleanup throws, force the app back to logged-out state.
    } finally {
      emit(const Unauthenticated());
    }
  }

  // ── Get Profile ───────────────────────────────────────────────────────────

  Future<void> _onGetProfileRequested(
      GetProfileRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(const AuthLoading());

    final result = await authRepository.getProfile();

    result.fold(
          (failure) => emit(AuthError(failure.message)),
          (user) => emit(Authenticated(user)),
    );
  }

  // ── Check Auth Status (app launch) ────────────────────────────────────────

  Future<void> _onAuthStatusChecked(
      AuthStatusChecked event,
      Emitter<AuthState> emit,
      ) async {
    emit(const AuthLoading());

    final result = await authRepository.isLoggedIn();

    result.fold(
          (_) => emit(const Unauthenticated()),
          (isLoggedIn) {
        if (isLoggedIn) {
          add(const CurrentUserLoaded());
        } else {
          emit(const Unauthenticated());
        }
      },
    );
  }

  // ── Load Current User from Cache ──────────────────────────────────────────

  Future<void> _onCurrentUserLoaded(
      CurrentUserLoaded event,
      Emitter<AuthState> emit,
      ) async {
    final result = await authRepository.getCurrentUser();

    result.fold(
          (_) => emit(const Unauthenticated()),
          (user) => emit(Authenticated(user)),
    );
  }

  // ── Refresh Token ─────────────────────────────────────────────────────────

  Future<void> _onRefreshTokenRequested(
      RefreshTokenRequested event,
      Emitter<AuthState> emit,
      ) async {
    // Use TokenRefreshing instead of AuthLoading so the UI doesn't flash
    // a loading screen — the user stays on their current screen during refresh.
    final currentState = state;
    if (currentState is Authenticated) {
      emit(TokenRefreshing(currentState.user));
    }

    final result = await authRepository.refreshToken(event.refreshToken);

    result.fold(
          (failure) {
        // Refresh token expired or invalid — force logout
        emit(const Unauthenticated());
      },
          (user) => emit(TokenRefreshed(user)),
    );
  }

  // ── Helper: Trigger Refresh Using Stored Token ────────────────────────────

  /// Call this from your Dio interceptor when you get a 401.
  /// Gets the refresh token from storage and fires the event.
  Future<void> triggerTokenRefresh() async {
    final refreshToken = await storageHelper.getRefreshToken();
    if (refreshToken != null) {
      add(RefreshTokenRequested(refreshToken: refreshToken));
    } else {
      // No refresh token — force logout
      add(const LogoutRequested());
    }
  }
}