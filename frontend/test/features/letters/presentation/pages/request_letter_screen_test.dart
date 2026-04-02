import 'package:employee_activity_app/features/letters/presentation/pages/request_letter_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  testWidgets('renders all letter type options and remarks field',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      wrapWithMaterialApp(const RequestLetterScreen()),
    );

    expect(find.text('Select Letter Type'), findsOneWidget);
    expect(find.text('Employment Letter'), findsOneWidget);
    expect(find.text('Experience Letter'), findsOneWidget);
    expect(find.text('Appraisal Letter'), findsOneWidget);
    expect(find.text('Form 16'), findsOneWidget);
    expect(find.text('Additional Remarks (Optional)'), findsOneWidget);
    expect(find.text('Submit Request'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('shows snackbar when submit is pressed without selecting type',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      wrapWithMaterialApp(const RequestLetterScreen()),
    );

    await tester.tap(find.text('Submit Request').last);
    await tester.pump();

    expect(find.text('Please select a letter type'), findsOneWidget);
  });

  testWidgets('updates selected letter type indicator when option is tapped',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      wrapWithMaterialApp(const RequestLetterScreen()),
    );

    expect(find.byIcon(Icons.check_circle), findsNothing);

    await tester.tap(find.text('Employment Letter'));
    await tester.pump();

    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });
}
