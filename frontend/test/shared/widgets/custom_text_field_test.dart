import 'package:employee_activity_app/shared/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

void main() {
  testWidgets('shows label and toggles password visibility', (tester) async {
    final controller = TextEditingController(text: 'password123');

    await tester.pumpWidget(
      wrapWithMaterialApp(
        Scaffold(
          body: CustomTextField(
            controller: controller,
            label: 'Password',
            obscureText: true,
          ),
        ),
      ),
    );

    expect(find.text('Password'), findsOneWidget);

    final editableText = tester.widget<EditableText>(find.byType(EditableText));
    expect(editableText.obscureText, isTrue);

    await tester.tap(find.byIcon(Icons.visibility_off));
    await tester.pump();

    final updatedEditableText =
        tester.widget<EditableText>(find.byType(EditableText));
    expect(updatedEditableText.obscureText, isFalse);
  });

  testWidgets('passes submitted value to callback', (tester) async {
    String? submittedValue;

    await tester.pumpWidget(
      wrapWithMaterialApp(
        Scaffold(
          body: CustomTextField(
            hint: 'Employee ID',
            onSubmitted: (value) => submittedValue = value,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField), 'EMP001');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(submittedValue, 'EMP001');
  });
}
