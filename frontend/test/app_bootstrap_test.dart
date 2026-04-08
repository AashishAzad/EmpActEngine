import 'dart:async';

import 'package:employee_activity_app/features/auth/presentation/pages/app_splash_view.dart';
import 'package:employee_activity_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_helpers.dart';

void main() {
  testWidgets('shows splash view while storage initialization is pending',
      (tester) async {
    final completer = Completer<void>();

    await tester.pumpWidget(
      AppBootstrap(
        storageHelper: testStorageHelper(),
        initialization: completer.future,
      ),
    );

    expect(find.byType(AppSplashView), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows startup error message when initialization fails',
      (tester) async {
    final completer = Completer<void>();

    await tester.pumpWidget(
      AppBootstrap(
        storageHelper: testStorageHelper(),
        initialization: completer.future,
      ),
    );
    completer.completeError('boom');
    await tester.pump();
    await tester.pump();

    expect(find.text('Failed to start app: boom'), findsOneWidget);
  });
}
