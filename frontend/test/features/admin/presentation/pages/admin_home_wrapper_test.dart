import 'package:employee_activity_app/features/admin/presentation/pages/admin_home_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  testWidgets('switches between admin bottom navigation tabs', (tester) async {
    await tester.pumpWidget(
      wrapWithMaterialApp(
        AdminHomeWrapper(
          pages: const [
            Scaffold(body: Center(child: Text('Home Tab'))),
            Scaffold(body: Center(child: Text('Correction Tab'))),
            Scaffold(body: Center(child: Text('Company Tab'))),
            Scaffold(body: Center(child: Text('Generator Tab'))),
          ],
        ),
      ),
    );

    expect(find.text('Home Tab'), findsOneWidget);

    await tester.tap(find.text('Correction'));
    await tester.pumpAndSettle();
    expect(find.text('Correction Tab'), findsOneWidget);

    await tester.tap(find.text('Company'));
    await tester.pumpAndSettle();
    expect(find.text('Company Tab'), findsOneWidget);

    await tester.tap(find.text('Generator'));
    await tester.pumpAndSettle();
    expect(find.text('Generator Tab'), findsOneWidget);
  });
}
