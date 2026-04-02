import 'package:employee_activity_app/features/leaves/presentation/pages/leave_history_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  testWidgets('renders leave history and filters approved entries',
      (tester) async {
    final dataSource = FakeLeaveDataSource(
      myLeaves: [
        {
          'id': 'l1',
          'leaveType': 'CASUAL',
          'status': 'APPROVED',
          'startDate': '2026-04-01',
          'endDate': '2026-04-02',
          'numberOfDays': 2,
          'remarks': 'Family event',
          'createdAt': '2026-03-28T00:00:00',
        },
        {
          'id': 'l2',
          'leaveType': 'SICK',
          'status': 'PENDING',
          'startDate': '2026-04-05',
          'endDate': '2026-04-05',
          'numberOfDays': 1,
          'remarks': 'Fever',
          'createdAt': '2026-03-30T00:00:00',
        },
      ],
    );

    await tester.pumpWidget(
      wrapWithMaterialApp(
        LeaveHistoryScreen(dataSource: dataSource),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Casual Leave'), findsOneWidget);
    expect(find.text('Sick Leave'), findsOneWidget);
    expect(find.text('APPROVED'), findsOneWidget);
    expect(find.text('PENDING'), findsOneWidget);

    await tester.tap(find.text('Approved'));
    await tester.pump();

    expect(find.text('Casual Leave'), findsOneWidget);
    expect(find.text('Sick Leave'), findsNothing);
  });

  testWidgets('shows empty filtered state when no rejected leaves exist',
      (tester) async {
    final dataSource = FakeLeaveDataSource(
      myLeaves: [
        {
          'id': 'l1',
          'leaveType': 'CASUAL',
          'status': 'APPROVED',
          'startDate': '2026-04-01',
          'endDate': '2026-04-01',
          'numberOfDays': 1,
          'remarks': 'Family event',
          'createdAt': '2026-03-28T00:00:00',
        },
      ],
    );

    await tester.pumpWidget(
      wrapWithMaterialApp(
        LeaveHistoryScreen(dataSource: dataSource),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('Rejected'));
    await tester.pump();

    expect(find.text('No Leave Applications'), findsOneWidget);
    expect(find.text('No REJECTED leaves found'), findsOneWidget);
  });
}
