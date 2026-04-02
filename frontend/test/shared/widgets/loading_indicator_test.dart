import 'package:employee_activity_app/shared/widgets/loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

void main() {
  testWidgets('renders circular variant with message', (tester) async {
    await tester.pumpWidget(
      wrapWithMaterialApp(
        const LoadingIndicator(message: 'Loading salary details...'),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Loading salary details...'), findsOneWidget);
  });

  testWidgets('renders linear variant with message', (tester) async {
    await tester.pumpWidget(
      wrapWithMaterialApp(
        const LoadingIndicator(
          variant: LoadingVariant.linear,
          message: 'Loading notifications...',
        ),
      ),
    );

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('Loading notifications...'), findsOneWidget);
  });

  testWidgets('renders overlay variant with dialog-like container',
      (tester) async {
    await tester.pumpWidget(
      wrapWithMaterialApp(
        const LoadingIndicator.overlay(message: 'Please wait...'),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Please wait...'), findsOneWidget);
  });

  testWidgets('renders small variant without message', (tester) async {
    await tester.pumpWidget(
      wrapWithMaterialApp(
        const LoadingIndicator.small(),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Please wait...'), findsNothing);
  });
}
