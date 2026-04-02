import 'package:employee_activity_app/shared/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

void main() {
  testWidgets('renders small button text and icon and handles taps',
      (tester) async {
    var tapCount = 0;

    await tester.pumpWidget(
      wrapWithMaterialApp(
        Scaffold(
          body: SmallButton(
            text: 'Retry',
            icon: Icons.refresh,
            onPressed: () => tapCount += 1,
          ),
        ),
      ),
    );

    expect(find.text('Retry'), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsOneWidget);

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(tapCount, 1);
  });

  testWidgets('renders without icon when icon is not supplied', (tester) async {
    await tester.pumpWidget(
      wrapWithMaterialApp(
        const Scaffold(
          body: SmallButton(text: 'Save'),
        ),
      ),
    );

    expect(find.text('Save'), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsNothing);
  });
}
