import 'package:employee_activity_app/features/attendance/presentation/pages/attendance_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  testWidgets('renders attendance summary and history records', (tester) async {
    final dataSource = FakeAttendanceDataSource(
      attendanceHistory: [
        {
          'date': '2026-04-01',
          'status': 'PRESENT',
          'checkInTime': '2026-04-01T09:15:00',
          'checkOutTime': '2026-04-01T18:00:00',
        },
      ],
    );

    await tester.pumpWidget(
      wrapWithMaterialApp(
        AttendanceHistoryScreen(dataSource: dataSource),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Attendance History'), findsOneWidget);
    expect(find.text('Present'), findsWidgets);
    expect(find.textContaining('In: 09:15 AM'), findsOneWidget);
    expect(find.text('Attendance'), findsOneWidget);
  });

  testWidgets('changes month when navigating backward', (tester) async {
    final dataSource = FakeAttendanceDataSource();

    await tester.pumpWidget(
      wrapWithMaterialApp(
        AttendanceHistoryScreen(dataSource: dataSource),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final initialLabel = tester.widget<Text>(
      find.textContaining(RegExp(r'^[A-Za-z]+ \d{4}$')).first,
    ).data!;

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final updatedLabel = tester.widget<Text>(
      find.textContaining(RegExp(r'^[A-Za-z]+ \d{4}$')).first,
    ).data!;

    expect(updatedLabel, isNot(initialLabel));
  });
}
