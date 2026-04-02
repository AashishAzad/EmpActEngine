import 'package:employee_activity_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:employee_activity_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:employee_activity_app/features/home/presentation/pages/dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  Widget wrapWithRouter(AuthBloc bloc) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => BlocProvider<AuthBloc>.value(
            value: bloc,
            child: const Scaffold(
              body: DashboardPage(),
            ),
          ),
        ),
      ],
    );

    return MaterialApp.router(routerConfig: router);
  }

  testWidgets('renders dashboard stats and quick actions', (tester) async {
    final bloc = AuthBloc(
      authRepository: FakeAuthRepository(),
      storageHelper: testStorageHelper(),
    );
    bloc.emit(const Authenticated(testAdminUser));

    await tester.pumpWidget(wrapWithRouter(bloc));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Welcome Back,'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
    expect(find.text('Quick Stats'), findsOneWidget);
    expect(find.text('Quick Actions'), findsOneWidget);
    expect(find.text('Mark Attendance'), findsWidgets);
    expect(find.text('Apply for Leave'), findsOneWidget);
    expect(find.text('View Salary'), findsOneWidget);
    expect(find.text('Request Letter'), findsOneWidget);
  });
}
