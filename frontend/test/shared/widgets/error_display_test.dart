import 'package:employee_activity_app/shared/widgets/error_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

void main() {
  testWidgets('renders error message and retry button', (tester) async {
    var retryCount = 0;

    await tester.pumpWidget(
      wrapWithMaterialApp(
        ErrorDisplay(
          message: 'Salary service unavailable',
          onRetry: () => retryCount += 1,
        ),
      ),
    );

    expect(find.text('Oops! Something went wrong'), findsOneWidget);
    expect(find.text('Salary service unavailable'), findsOneWidget);
    expect(find.text('Try Again'), findsOneWidget);

    await tester.tap(find.text('Try Again'));
    await tester.pump();

    expect(retryCount, 1);
  });

  testWidgets('omits retry button when callback is missing', (tester) async {
    await tester.pumpWidget(
      wrapWithMaterialApp(
        const ErrorDisplay(message: 'Temporary failure'),
      ),
    );

    expect(find.text('Temporary failure'), findsOneWidget);
    expect(find.text('Try Again'), findsNothing);
  });
}
