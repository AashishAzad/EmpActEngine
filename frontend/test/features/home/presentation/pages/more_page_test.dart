import 'package:employee_activity_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:employee_activity_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:employee_activity_app/features/home/presentation/pages/more_page.dart';
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
            child: const MorePage(),
          ),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Profile Route')),
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

  testWidgets('shows admin management options and navigates to profile',
      (tester) async {
    final bloc = AuthBloc(
      authRepository: FakeAuthRepository(),
      storageHelper: testStorageHelper(),
    );
    bloc.emit(const Authenticated(testAdminUser));

    await tester.pumpWidget(wrapWithRouter(bloc));
    await tester.pump();

    expect(find.text('My Profile'), findsOneWidget);
    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.text('Leave Requests'), findsOneWidget);
    expect(find.text('Generate Notification'), findsOneWidget);

    await tester.tap(find.text('My Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Profile Route'), findsOneWidget);
  });

  testWidgets('navigates to login when auth becomes unauthenticated',
      (tester) async {
    final bloc = AuthBloc(
      authRepository: FakeAuthRepository(),
      storageHelper: testStorageHelper(),
    );
    bloc.emit(const Authenticated(testUser));

    await tester.pumpWidget(wrapWithRouter(bloc));
    await tester.pump();

    bloc.emit(const Unauthenticated());
    await tester.pumpAndSettle();

    expect(find.text('Login Route'), findsOneWidget);
  });
}
