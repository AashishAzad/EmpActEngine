import 'package:employee_activity_app/features/leaves/presentation/pages/pending_leaves_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  testWidgets('renders pending leave request details', (tester) async {
    final dataSource = FakeLeaveDataSource(
      pendingLeaves: [
        {
          'id': 'p1',
          'leaveType': 'CASUAL',
          'numberOfDays': 2,
          'remarks': 'Need time off',
          'startDate': '2026-04-03',
          'endDate': '2026-04-04',
          'createdAt': '2026-04-01T00:00:00',
          'employee': {
            'firstName': 'Aashi',
            'lastName': 'Sharma',
            'employeeId': 'EMP001',
          },
        },
      ],
    );

    await tester.pumpWidget(
      wrapWithMaterialApp(
        PendingLeavesScreen(dataSource: dataSource),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Aashi Sharma'), findsOneWidget);
    expect(find.text('EMP001'), findsOneWidget);
    expect(find.text('Casual Leave'), findsOneWidget);
    expect(find.text('Need time off'), findsOneWidget);
    expect(find.text('Approve'), findsOneWidget);
    expect(find.text('Reject'), findsOneWidget);
  });

  testWidgets('approves leave and removes it from the list', (tester) async {
    final dataSource = FakeLeaveDataSource(
      pendingLeaves: [
        {
          'id': 'p1',
          'leaveType': 'CASUAL',
          'numberOfDays': 1,
          'remarks': 'Urgent work',
          'employee': {
            'firstName': 'Aashi',
            'lastName': 'Sharma',
            'employeeId': 'EMP001',
          },
        },
      ],
    );

    await tester.pumpWidget(
      wrapWithMaterialApp(
        PendingLeavesScreen(dataSource: dataSource),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('Approve'));
    await tester.pump();

    expect(dataSource.approvedLeaveId, 'p1');
    expect(find.text('No Pending Requests'), findsOneWidget);
  });
}
