import 'package:employee_activity_app/features/admin/presentation/pages/admin_home_screen.dart';
import 'package:employee_activity_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:employee_activity_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  Widget buildTestApp({
    required FakeLeaveDataSource leaveDataSource,
    required FakeAdminPayrollDataSource payrollDataSource,
  }) {
    final authBloc = AuthBloc(
      authRepository: FakeAuthRepository(),
      storageHelper: testStorageHelper(),
    )..add(const CurrentUserLoaded());

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => BlocProvider.value(
            value: authBloc,
            child: AdminHomeScreen(
              leaveDataSource: leaveDataSource,
              payrollDataSource: payrollDataSource,
            ),
          ),
        ),
        GoRoute(
          path: '/admin/pending-leaves',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Pending Leaves Route')),
          ),
        ),
        GoRoute(
          path: '/admin/pending-letters',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Pending Letters Route')),
          ),
        ),
      ],
    );

    return MaterialApp.router(routerConfig: router);
  }

  testWidgets('renders combined pending requests sorted by newest first',
      (tester) async {
    final leaveDataSource = FakeLeaveDataSource(
      pendingLeaves: [
        {
          'id': 'leave-1',
          'createdAt': '2026-04-01T10:00:00',
          'employee': {'firstName': 'Aashi'},
        },
      ],
    );
    final payrollDataSource = FakeAdminPayrollDataSource(
      pendingLetters: [
        {
          'id': 'letter-1',
          'createdAt': '2026-04-02T09:00:00',
          'letterType': 'BONAFIDE',
          'employee': {'firstName': 'Rohit'},
        },
      ],
    );

    await tester.pumpWidget(
      buildTestApp(
        leaveDataSource: leaveDataSource,
        payrollDataSource: payrollDataSource,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Aashi Sharma'), findsOneWidget);
    expect(find.text('EMP001'), findsOneWidget);
    expect(find.text('Pending Requests'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    expect(find.text('Letter Request'), findsOneWidget);
    expect(find.text('Rohit requested BONAFIDE'), findsOneWidget);
    expect(find.text('Leave Request'), findsOneWidget);
    expect(find.text('Aashi requested leave'), findsOneWidget);

    final letterPosition = tester.getTopLeft(find.text('Letter Request'));
    final leavePosition = tester.getTopLeft(find.text('Leave Request'));
    expect(letterPosition.dy, lessThan(leavePosition.dy));
  });

  testWidgets('navigates to pending letters route when tapping a letter request',
      (tester) async {
    final leaveDataSource = FakeLeaveDataSource();
    final payrollDataSource = FakeAdminPayrollDataSource(
      pendingLetters: [
        {
          'id': 'letter-1',
          'createdAt': '2026-04-02T09:00:00',
          'letterType': 'BONAFIDE',
          'employee': {'firstName': 'Rohit'},
        },
      ],
    );

    await tester.pumpWidget(
      buildTestApp(
        leaveDataSource: leaveDataSource,
        payrollDataSource: payrollDataSource,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('Letter Request'));
    await tester.pumpAndSettle();

    expect(find.text('Pending Letters Route'), findsOneWidget);
  });
}
