import 'package:employee_activity_app/features/admin/presentation/pages/admin_pending_leaves_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  Map<String, dynamic> pendingLeave() {
    return {
      'id': 'leave-1',
      'leaveType': 'CASUAL',
      'numberOfDays': 2,
      'remarks': 'Family event',
      'contactNumber': '9876543210',
      'contactEmail': 'aashi@example.com',
      'startDate': '2026-04-10',
      'endDate': '2026-04-11',
      'employee': {
        'firstName': 'Aashi',
        'lastName': 'Sharma',
        'employeeId': 'EMP001',
      },
    };
  }

  testWidgets('renders pending leave request details', (tester) async {
    final dataSource = FakeLeaveDataSource(
      pendingLeaves: [pendingLeave()],
    );

    await tester.pumpWidget(
      wrapWithMaterialApp(
        AdminPendingLeavesScreen(dataSource: dataSource),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Aashi Sharma'), findsOneWidget);
    expect(find.text('EMP001'), findsOneWidget);
    expect(find.text('CASUAL'), findsOneWidget);
    expect(find.text('Family event'), findsOneWidget);
    expect(find.text('9876543210'), findsOneWidget);
    expect(find.text('aashi@example.com'), findsOneWidget);
    expect(find.text('Approve'), findsOneWidget);
    expect(find.text('Reject'), findsOneWidget);
  });

  testWidgets('approves leave after confirmation and refreshes the list',
      (tester) async {
    final dataSource = FakeLeaveDataSource(
      pendingLeaves: [pendingLeave()],
    );

    await tester.pumpWidget(
      wrapWithMaterialApp(
        AdminPendingLeavesScreen(dataSource: dataSource),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('Approve').first);
    await tester.pumpAndSettle();

    expect(find.text('Approve Leave'), findsOneWidget);

    await tester.tap(find.text('Approve').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    expect(dataSource.approvedLeaveId, 'leave-1');
    expect(find.text('Leave approved successfully!'), findsOneWidget);
    expect(find.text('No Pending Requests'), findsOneWidget);
  });

  testWidgets('rejects leave with a reason and refreshes the list',
      (tester) async {
    final dataSource = FakeLeaveDataSource(
      pendingLeaves: [pendingLeave()],
    );

    await tester.pumpWidget(
      wrapWithMaterialApp(
        AdminPendingLeavesScreen(dataSource: dataSource),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('Reject'));
    await tester.pumpAndSettle();

    expect(find.text('Reject Leave'), findsOneWidget);

    await tester.enterText(
      find.byType(EditableText),
      'Manager approval denied',
    );
    await tester.tap(find.text('Reject').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    expect(dataSource.rejectedLeaveId, 'leave-1');
    expect(dataSource.rejectionRemarks, 'Manager approval denied');
    expect(find.text('Leave rejected'), findsOneWidget);
    expect(find.text('No Pending Requests'), findsOneWidget);
  });
}
