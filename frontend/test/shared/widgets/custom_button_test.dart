import 'package:employee_activity_app/shared/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

void main() {
  testWidgets('renders loading indicator and disables press when loading',
      (tester) async {
    var tapCount = 0;

    await tester.pumpWidget(
      wrapWithMaterialApp(
        Scaffold(
          body: CustomButton(
            text: 'Login',
            isLoading: true,
            onPressed: () => tapCount += 1,
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(tapCount, 0);
  });

  testWidgets('renders icon button variant with label and icon', (tester) async {
    await tester.pumpWidget(
      wrapWithMaterialApp(
        Scaffold(
          body: CustomButton(
            text: 'Add employee',
            variant: ButtonVariant.icon,
            icon: Icons.person_add,
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(find.text('Add employee'), findsOneWidget);
    expect(find.byIcon(Icons.person_add), findsOneWidget);
  });
}
