import 'package:employee_activity_app/features/admin/presentation/pages/edit_employee_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  Widget wrapWithRouter(Widget child) {
    final router = GoRouter(
      initialLocation: '/edit',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Home')),
          ),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) => child,
            ),
          ],
        ),
      ],
    );

    return MaterialApp.router(routerConfig: router);
  }

  testWidgets('loads employee details and submits updates', (tester) async {
    final dataSource = FakeAdminEmployeeDataSource(
      employees: [
        {
          'id': 'emp-1',
          'employeeId': 'EMP001',
          'firstName': 'Aashi',
          'lastName': 'Sharma',
          'email': 'aashi@example.com',
          'phoneNumber': '9876543210',
          'designation': 'Engineer',
          'department': 'Tech',
          'role': 'EMPLOYEE',
          'dateOfJoining': '2024-01-10',
        },
      ],
    );

    await tester.pumpWidget(
      wrapWithRouter(
        EditEmployeeScreen(
          employeeId: 'emp-1',
          dataSource: dataSource,
          datePicker: (_, __) async => DateTime(2024, 2, 20),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('EMP001'), findsOneWidget);
    expect(find.text('Aashi'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Updated');
    await tester.enterText(
      find.byType(TextFormField).at(4),
      'Lead Engineer',
    );

    final joinDateCard = find.ancestor(
      of: find.text('10 Jan 2024'),
      matching: find.byType(InkWell),
    );
    await tester.ensureVisible(joinDateCard.first);
    await tester.tap(joinDateCard.first);
    await tester.pumpAndSettle();

    final submitButton =
        find.widgetWithText(ElevatedButton, 'Update Employee');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(dataSource.updatedEmployeeId, 'emp-1');
    expect(dataSource.updatedEmployeePayload, isNotNull);
    expect(dataSource.updatedEmployeePayload!['firstName'], 'Updated');
    expect(
      dataSource.updatedEmployeePayload!['designation'],
      'Lead Engineer',
    );
    expect(dataSource.updatedEmployeePayload!['dateOfJoining'], '2024-02-20');
    expect(find.text('Home'), findsOneWidget);
  });
}
