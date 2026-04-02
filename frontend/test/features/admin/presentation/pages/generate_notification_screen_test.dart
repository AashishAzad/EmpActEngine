import 'package:employee_activity_app/features/admin/presentation/pages/generate_notification_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  Widget wrapWithRouter(Widget child) {
    final router = GoRouter(
      initialLocation: '/generate',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Home')),
          ),
          routes: [
            GoRoute(
              path: 'generate',
              builder: (context, state) => child,
            ),
          ],
        ),
      ],
    );

    return MaterialApp.router(
      routerConfig: router,
    );
  }

  FakeAdminEmployeeDataSource buildEmployeeSource() {
    return FakeAdminEmployeeDataSource(
      employees: [
        {
          'id': '1',
          'firstName': 'Aashi',
          'lastName': 'Sharma',
          'employeeId': 'EMP001',
          'designation': 'Engineer',
        },
        {
          'id': '2',
          'firstName': 'Rohit',
          'lastName': 'Verma',
          'employeeId': 'EMP002',
          'designation': 'Designer',
        },
      ],
    );
  }

  testWidgets('shows snackbar when submitting without recipients', (tester) async {
    final employeeDataSource = buildEmployeeSource();
    final notificationDataSource = FakeAdminNotificationDataSource();

    await tester.pumpWidget(
      wrapWithRouter(
        GenerateNotificationScreen(
          employeeDataSource: employeeDataSource,
          notificationDataSource: notificationDataSource,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.enterText(find.byType(TextFormField).at(0), 'Policy Update');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Please review the new handbook.',
    );
    await tester.ensureVisible(find.text('Send Notification'));
    await tester.tap(find.text('Send Notification'));
    await tester.pumpAndSettle();

    expect(
      find.text('Please select at least one employee or send to all'),
      findsOneWidget,
    );
    expect(notificationDataSource.lastTitle, isNull);
  });

  testWidgets('sends a global notification and pops back', (tester) async {
    final employeeDataSource = buildEmployeeSource();
    final notificationDataSource = FakeAdminNotificationDataSource();

    await tester.pumpWidget(
      wrapWithRouter(
        GenerateNotificationScreen(
          employeeDataSource: employeeDataSource,
          notificationDataSource: notificationDataSource,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.enterText(find.byType(TextFormField).at(0), 'All Hands');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Meeting starts at 4 PM.',
    );
    await tester.ensureVisible(find.text('Send to All Employees'));
    await tester.tap(find.text('Send to All Employees'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Send Notification'));
    await tester.tap(find.text('Send Notification'));
    await tester.pumpAndSettle();

    expect(notificationDataSource.lastTitle, 'All Hands');
    expect(notificationDataSource.lastMessage, 'Meeting starts at 4 PM.');
    expect(notificationDataSource.lastType, isNotNull);
    expect(notificationDataSource.lastIsGlobal, isTrue);
    expect(notificationDataSource.lastRecipientIds, isNull);
    expect(find.text('Home'), findsOneWidget);
  });
}
