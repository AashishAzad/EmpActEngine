import 'package:employee_activity_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:employee_activity_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:employee_activity_app/features/leaves/presentation/pages/apply_leave_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  Widget wrapWithRouter({
    required AuthBloc bloc,
    required Widget child,
  }) {
    final router = GoRouter(
      initialLocation: '/apply',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Home')),
          ),
          routes: [
            GoRoute(
              path: 'apply',
              builder: (context, state) => BlocProvider<AuthBloc>.value(
                value: bloc,
                child: child,
              ),
            ),
          ],
        ),
      ],
    );

    return MaterialApp.router(routerConfig: router);
  }

  testWidgets('submits leave application with injected dates and datasource',
      (tester) async {
    final bloc = AuthBloc(
      authRepository: FakeAuthRepository(),
      storageHelper: testStorageHelper(),
    );
    bloc.emit(const Authenticated(testAdminUser));

    final dataSource = FakeLeaveDataSource();

    await tester.pumpWidget(
      wrapWithRouter(
        bloc: bloc,
        child: ApplyLeaveScreen(
          dataSource: dataSource,
          startDatePicker: (_) async => DateTime(2026, 4, 10),
          endDatePicker: (_, __) async => DateTime(2026, 4, 12),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Casual Leave'));
    await tester.pumpAndSettle();

    final startDateCard = find.ancestor(
      of: find.text('Select date').first,
      matching: find.byType(InkWell),
    );
    await tester.ensureVisible(startDateCard.first);
    await tester.tap(startDateCard.first);
    await tester.pumpAndSettle();

    final endDateCard = find.ancestor(
      of: find.text('Select date').last,
      matching: find.byType(InkWell),
    );
    await tester.ensureVisible(endDateCard.first);
    await tester.tap(endDateCard.first);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).last,
      'Family function leave',
    );

    await tester.ensureVisible(find.text('Submit Application'));
    await tester.tap(find.text('Submit Application'));
    await tester.pumpAndSettle();

    expect(dataSource.appliedLeaveType, isNotNull);
    expect(dataSource.appliedStartDate, '2026-04-10');
    expect(dataSource.appliedEndDate, '2026-04-12');
    expect(dataSource.appliedContactNumber, '9876543210');
    expect(dataSource.appliedContactEmail, 'admin@example.com');
    expect(dataSource.appliedRemarks, 'Family function leave');
    expect(find.text('Home'), findsOneWidget);
  });
}
