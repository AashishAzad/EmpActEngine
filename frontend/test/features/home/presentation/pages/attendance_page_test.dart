import 'package:employee_activity_app/features/home/presentation/pages/attendance_page.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  testWidgets('renders attendance actions', (tester) async {
    await tester.pumpWidget(
      wrapWithMaterialApp(const AttendancePage()),
    );

    expect(find.text('Mark Your Attendance'), findsOneWidget);
    expect(
      find.text('Use GPS location to mark your attendance for today'),
      findsOneWidget,
    );
    expect(find.text('Mark Attendance'), findsOneWidget);
    expect(find.text('View History'), findsOneWidget);
    expect(find.text('Manual Request'), findsOneWidget);
  });
}
