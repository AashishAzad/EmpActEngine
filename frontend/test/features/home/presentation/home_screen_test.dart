import 'package:employee_activity_app/features/home/presentation/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  testWidgets('switches between bottom navigation tabs', (tester) async {
    await tester.pumpWidget(
      wrapWithMaterialApp(
        HomeScreen(
          pages: const [
            Scaffold(body: Center(child: Text('Dashboard Tab'))),
            Scaffold(body: Center(child: Text('Attendance Tab'))),
            Scaffold(body: Center(child: Text('Leaves Tab'))),
            Scaffold(body: Center(child: Text('More Tab'))),
          ],
        ),
      ),
    );

    expect(find.text('Dashboard Tab'), findsOneWidget);

    await tester.tap(find.text('Attendance'));
    await tester.pumpAndSettle();
    expect(find.text('Attendance Tab'), findsOneWidget);

    await tester.tap(find.text('Leaves'));
    await tester.pumpAndSettle();
    expect(find.text('Leaves Tab'), findsOneWidget);

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    expect(find.text('More Tab'), findsOneWidget);
  });
}
