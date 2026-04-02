import 'package:employee_activity_app/features/admin/presentation/pages/correction_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  testWidgets('renders employees and filters by search query', (tester) async {
    final dataSource = FakeAdminEmployeeDataSource(
      employees: [
        {
          'id': '1',
          'firstName': 'Aashi',
          'lastName': 'Sharma',
          'employeeId': 'EMP001',
          'designation': 'Engineer',
          'department': 'Tech',
          'role': 'EMPLOYEE',
          'status': 'ACTIVE',
        },
        {
          'id': '2',
          'firstName': 'Rohit',
          'lastName': 'Verma',
          'employeeId': 'EMP002',
          'designation': 'Manager',
          'department': 'HR',
          'role': 'MANAGER',
          'status': 'ACTIVE',
        },
        {
          'id': '3',
          'firstName': 'Old',
          'lastName': 'User',
          'employeeId': 'EMP003',
          'role': 'EMPLOYEE',
          'status': 'TERMINATED',
        },
      ],
    );

    await tester.pumpWidget(
      wrapWithMaterialApp(
        CorrectionScreen(dataSource: dataSource),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Aashi Sharma'), findsOneWidget);
    expect(find.text('Rohit Verma'), findsOneWidget);
    expect(find.text('Old User'), findsNothing);

    await tester.enterText(
      find.byType(TextField),
      'EMP002',
    );
    await tester.pumpAndSettle();

    expect(find.text('Aashi Sharma'), findsNothing);
    expect(find.text('Rohit Verma'), findsOneWidget);
  });
}
