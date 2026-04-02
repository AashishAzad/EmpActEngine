import 'package:employee_activity_app/features/auth/presentation/pages/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  testWidgets('renders branded splash view content', (tester) async {
    await tester.pumpWidget(
      wrapWithMaterialApp(const AppSplashView()),
    );

    expect(find.text('Employee Activity'), findsOneWidget);
    expect(find.text('909 Technologies'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
