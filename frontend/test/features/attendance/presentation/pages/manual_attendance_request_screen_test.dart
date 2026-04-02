import 'package:employee_activity_app/features/attendance/presentation/pages/manual_attendance_request_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  Widget wrapWithRouter(Widget child) {
    final router = GoRouter(
      initialLocation: '/request',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Home')),
          ),
          routes: [
            GoRoute(
              path: 'request',
              builder: (context, state) => child,
            ),
          ],
        ),
      ],
    );

    return MaterialApp.router(routerConfig: router);
  }

  testWidgets('shows selected date and submits manual request', (tester) async {
    final dataSource = FakeAttendanceDataSource();
    final selectedDate = DateTime(2026, 3, 28);

    await tester.pumpWidget(
      wrapWithRouter(
        ManualAttendanceRequestScreen(
          dataSource: dataSource,
          datePicker: (_) async => selectedDate,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Select the date you missed'));
    await tester.pumpAndSettle();

    expect(find.text('28 Mar 2026'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField),
      'Forgot to mark attendance while on client visit',
    );

    await tester.ensureVisible(find.text('Submit Request'));
    await tester.tap(find.text('Submit Request'));
    await tester.pumpAndSettle();

    expect(dataSource.requestedDate, selectedDate);
    expect(
      dataSource.requestedReason,
      'Forgot to mark attendance while on client visit',
    );
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('shows validation when submitting without a date', (tester) async {
    final dataSource = FakeAttendanceDataSource();

    await tester.pumpWidget(
      wrapWithMaterialApp(
        ManualAttendanceRequestScreen(
          dataSource: dataSource,
          datePicker: (_) async => null,
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(
      find.byType(TextFormField),
      'Forgot to mark attendance',
    );

    await tester.ensureVisible(find.text('Submit Request'));
    await tester.tap(find.text('Submit Request'));
    await tester.pumpAndSettle();

    expect(find.text('Please select a date'), findsOneWidget);
    expect(dataSource.requestedDate, isNull);
  });
}
