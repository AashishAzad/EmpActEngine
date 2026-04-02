import 'package:employee_activity_app/features/admin/presentation/pages/add_employee_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  Widget wrapWithRouter(Widget child) {
    final router = GoRouter(
      initialLocation: '/add',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Home')),
          ),
          routes: [
            GoRoute(
              path: 'add',
              builder: (context, state) => child,
            ),
          ],
        ),
      ],
    );

    return MaterialApp.router(routerConfig: router);
  }

  testWidgets('submits new employee details', (tester) async {
    final dataSource = FakeAdminEmployeeDataSource();

    await tester.pumpWidget(
      wrapWithRouter(
        AddEmployeeScreen(
          dataSource: dataSource,
          datePicker: (_) async => DateTime(2025, 1, 15),
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextFormField).at(0), 'EMP777');
    await tester.enterText(find.byType(TextFormField).at(1), 'Aashi');
    await tester.enterText(find.byType(TextFormField).at(2), 'Sharma');
    await tester.enterText(
      find.byType(TextFormField).at(3),
      'new.employee@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(4), 'secret123');
    await tester.enterText(find.byType(TextFormField).at(5), '9876543210');
    await tester.enterText(find.byType(TextFormField).at(6), 'Engineer');
    await tester.enterText(find.byType(TextFormField).at(7), 'Tech');

    final joinDateCard = find.ancestor(
      of: find.text('Select date'),
      matching: find.byType(InkWell),
    );
    await tester.ensureVisible(joinDateCard.first);
    await tester.tap(joinDateCard.first);
    await tester.pumpAndSettle();

    final submitButton = find.widgetWithText(ElevatedButton, 'Add Employee');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(dataSource.addedEmployeeIdValue, 'EMP777');
    expect(dataSource.addedFirstName, 'Aashi');
    expect(dataSource.addedLastName, 'Sharma');
    expect(dataSource.addedEmail, 'new.employee@example.com');
    expect(dataSource.addedPassword, 'secret123');
    expect(dataSource.addedPhoneNumber, '9876543210');
    expect(dataSource.addedDesignation, 'Engineer');
    expect(dataSource.addedDepartment, 'Tech');
    expect(dataSource.addedRole, 'EMPLOYEE');
    expect(dataSource.addedDateOfJoining, '2025-01-15');
    expect(find.text('Home'), findsOneWidget);
  });
}
