import 'package:employee_activity_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:employee_activity_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:employee_activity_app/features/auth/presentation/pages/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  Widget wrapWithRouter(AuthBloc bloc) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => BlocProvider<AuthBloc>.value(
            value: bloc,
            child: const SplashScreen(),
          ),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Home Route')),
          ),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Login Route')),
          ),
        ),
      ],
    );

    return MaterialApp.router(routerConfig: router);
  }

  testWidgets('dispatches auth status check on startup and routes authenticated users',
      (tester) async {
    final bloc = AuthBloc(
      authRepository: FakeAuthRepository(),
      storageHelper: testStorageHelper(),
    );

    await tester.pumpWidget(wrapWithRouter(bloc));
    await tester.pump();

    bloc.emit(const Authenticated(testUser));
    await tester.pumpAndSettle();

    expect(find.text('Home Route'), findsOneWidget);
  });

  testWidgets('routes unauthenticated users to login', (tester) async {
    final bloc = AuthBloc(
      authRepository: FakeAuthRepository(),
      storageHelper: testStorageHelper(),
    );

    await tester.pumpWidget(wrapWithRouter(bloc));
    await tester.pump();

    bloc.emit(const Unauthenticated());
    await tester.pumpAndSettle();

    expect(find.text('Login Route'), findsOneWidget);
  });
}
