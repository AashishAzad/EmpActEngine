import 'package:dartz/dartz.dart';
import 'package:employee_activity_app/core/errors/exceptions.dart';
import 'package:employee_activity_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:employee_activity_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:employee_activity_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  group('AuthBloc', () {
    test('emits loading then authenticated when login succeeds', () async {
      final repository = FakeAuthRepository(
        loginHandler: (_, __) async => const Right(testUser),
      );
      final bloc = AuthBloc(
        authRepository: repository,
        storageHelper: testStorageHelper(),
      );

      final states = <AuthState>[];
      final subscription = bloc.stream.listen(states.add);

      bloc.add(const LoginRequested(employeeId: 'EMP001', password: 'secret1'));
      await flushMicrotasks();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(states, [const AuthLoading(), const Authenticated(testUser)]);
      expect(repository.lastLoginEmployeeId, 'EMP001');
      expect(repository.lastLoginPassword, 'secret1');

      await subscription.cancel();
      await bloc.close();
    });

    test('emits loading then error when login fails', () async {
      final repository = FakeAuthRepository(
        loginHandler: (_, __) async => const Left(AuthFailure('Bad credentials')),
      );
      final bloc = AuthBloc(
        authRepository: repository,
        storageHelper: testStorageHelper(),
      );

      final states = <AuthState>[];
      final subscription = bloc.stream.listen(states.add);

      bloc.add(const LoginRequested(employeeId: 'EMP001', password: 'wrong'));
      await flushMicrotasks();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(states, [const AuthLoading(), const AuthError('Bad credentials')]);

      await subscription.cancel();
      await bloc.close();
    });

    test('loads current user after auth status check when already logged in',
        () async {
      final repository = FakeAuthRepository(
        isLoggedInHandler: () async => const Right(true),
        getCurrentUserHandler: () async => const Right(testUser),
      );
      final bloc = AuthBloc(
        authRepository: repository,
        storageHelper: testStorageHelper(),
      );

      final states = <AuthState>[];
      final subscription = bloc.stream.listen(states.add);

      bloc.add(const AuthStatusChecked());
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(states, [const AuthLoading(), const Authenticated(testUser)]);

      await subscription.cancel();
      await bloc.close();
    });

    test('emits token refreshing then token refreshed for authenticated user',
        () async {
      final repository = FakeAuthRepository(
        refreshTokenHandler: (_) async => const Right(testUser),
      );
      final bloc = AuthBloc(
        authRepository: repository,
        storageHelper: testStorageHelper(),
      );

      final states = <AuthState>[];
      final subscription = bloc.stream.listen(states.add);

      bloc.emit(const Authenticated(testUser));
      states.clear();
      bloc.add(const RefreshTokenRequested(refreshToken: 'refresh-token'));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(
        states,
        containsAllInOrder(
          [
          const TokenRefreshing(testUser),
          const TokenRefreshed(testUser),
          ],
        ),
      );
      expect(repository.lastRefreshToken, 'refresh-token');

      await subscription.cancel();
      await bloc.close();
    });

    test('emits unauthenticated even when logout cleanup throws', () async {
      final repository = FakeAuthRepository(
        logoutHandler: () async => throw Exception('storage failed'),
      );
      final bloc = AuthBloc(
        authRepository: repository,
        storageHelper: testStorageHelper(),
      );

      final states = <AuthState>[];
      final subscription = bloc.stream.listen(states.add);

      bloc.add(const LogoutRequested());
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(states, [const AuthLoading(), const Unauthenticated()]);

      await subscription.cancel();
      await bloc.close();
    });
  });
}
