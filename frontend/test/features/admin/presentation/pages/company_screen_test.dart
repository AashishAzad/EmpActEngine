import 'package:employee_activity_app/features/admin/presentation/pages/company_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  testWidgets('removes employee after confirmation', (tester) async {
    final dataSource = FakeAdminEmployeeDataSource(
      employees: [
        {
          'id': '1',
          'firstName': 'Aashi',
          'lastName': 'Sharma',
          'employeeId': 'EMP001',
          'email': 'aashi@example.com',
          'designation': 'Engineer',
          'department': 'Tech',
          'role': 'EMPLOYEE',
          'status': 'ACTIVE',
        },
      ],
    );

    await tester.pumpWidget(
      wrapWithMaterialApp(
        CompanyScreen(dataSource: dataSource),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Aashi Sharma'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove'));
    await tester.pumpAndSettle();

    expect(find.text('Remove Employee'), findsOneWidget);

    await tester.tap(find.text('Remove').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    expect(dataSource.deletedEmployeeId, '1');
    expect(find.text('Employee removed successfully'), findsOneWidget);
    expect(find.text('No Employees'), findsOneWidget);
  });
}
