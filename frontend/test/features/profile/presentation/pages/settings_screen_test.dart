import 'package:employee_activity_app/features/profile/presentation/pages/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  testWidgets('renders settings sections and options', (tester) async {
    await tester.pumpWidget(
      wrapWithMaterialApp(const SettingsScreen()),
    );
    await tester.pump();

    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Privacy & Permissions'), findsOneWidget);
    expect(find.text('About'), findsWidgets);
    expect(find.text('Push Notifications'), findsOneWidget);
    expect(find.text('Dark Mode'), findsOneWidget);
    expect(find.text('About App'), findsOneWidget);
  });

  testWidgets('shows about dialog when about app is tapped', (tester) async {
    await tester.pumpWidget(
      wrapWithMaterialApp(const SettingsScreen()),
    );
    await tester.pump();

    await tester.tap(find.text('About App'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Employee Activity Management System'), findsOneWidget);
    expect(find.text('Built with Flutter'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
  });

  testWidgets('shows dark mode info snackbar when switch is toggled',
      (tester) async {
    await tester.pumpWidget(
      wrapWithMaterialApp(const SettingsScreen()),
    );
    await tester.pump();

    await tester.tap(find.byType(Switch).at(1));
    await tester.pump();

    expect(
      find.text('Dark mode will be available in next update'),
      findsOneWidget,
    );
  });
}
