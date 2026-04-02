import 'package:employee_activity_app/features/auth/presentation/pages/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  group('LoginFormView', () {
    testWidgets('shows validation errors when form is submitted empty',
        (tester) async {
      String? submittedEmployeeId;

      await tester.pumpWidget(
        wrapWithMaterialApp(
          Scaffold(
            body: LoginFormView(
              isLoading: false,
              onLoginRequested: (employeeId, password) {
                submittedEmployeeId = employeeId;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Login'));
      await tester.pump();

      expect(find.text('Employee ID is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
      expect(submittedEmployeeId, isNull);
    });

    testWidgets('submits trimmed employee id and password',
        (tester) async {
      String? submittedEmployeeId;
      String? submittedPassword;

      await tester.pumpWidget(
        wrapWithMaterialApp(
          Scaffold(
            body: LoginFormView(
              isLoading: false,
              onLoginRequested: (employeeId, password) {
                submittedEmployeeId = employeeId;
                submittedPassword = password;
              },
            ),
          ),
        ),
      );

      await tester.enterText(
        find.byType(TextFormField).at(0),
        '  EMP001  ',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.tap(find.text('Login'));
      await tester.pump();

      expect(submittedEmployeeId, 'EMP001');
      expect(submittedPassword, 'password123');
    });

    testWidgets('shows loading indicator and disables login while loading',
        (tester) async {
      var submitCalls = 0;

      await tester.pumpWidget(
        wrapWithMaterialApp(
          Scaffold(
            body: LoginFormView(
              isLoading: true,
              onLoginRequested: (_, __) => submitCalls += 1,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(submitCalls, 0);
    });

    testWidgets('renders test credential helper content', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          Scaffold(
            body: LoginFormView(
              isLoading: false,
              onLoginRequested: (_, __) {},
            ),
          ),
        ),
      );

      expect(find.text('Test Credentials'), findsOneWidget);
      expect(find.text('ADM001'), findsOneWidget);
      expect(find.text('MGR001'), findsOneWidget);
      expect(find.text('EMP001'), findsOneWidget);
      expect(find.text('Password: password123'), findsOneWidget);
    });
  });
}
