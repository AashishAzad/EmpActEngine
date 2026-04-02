import 'package:employee_activity_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:employee_activity_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:employee_activity_app/features/home/presentation/pages/change_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  testWidgets('validates confirm password mismatch', (tester) async {
    final bloc = AuthBloc(
      authRepository: FakeAuthRepository(),
      storageHelper: testStorageHelper(),
    );
    bloc.emit(const Authenticated(testUser));

    await tester.pumpWidget(
      wrapWithMaterialApp(
        BlocProvider<AuthBloc>.value(
          value: bloc,
          child: const ChangePasswordScreen(),
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextFormField).at(0), 'oldpass');
    await tester.enterText(find.byType(TextFormField).at(1), 'newpass1');
    await tester.enterText(find.byType(TextFormField).at(2), 'different1');

    final submitButton =
        find.widgetWithText(ElevatedButton, 'Change Password');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Passwords do not match'), findsOneWidget);
  });

  testWidgets('submits password change with injected callback', (tester) async {
    final bloc = AuthBloc(
      authRepository: FakeAuthRepository(),
      storageHelper: testStorageHelper(),
    );
    bloc.emit(const Authenticated(testUser));

    String? capturedCurrentPassword;
    String? capturedNewPassword;
    String? capturedConfirmPassword;

    await tester.pumpWidget(
      wrapWithMaterialApp(
        BlocProvider<AuthBloc>.value(
          value: bloc,
          child: ChangePasswordScreen(
            onChangePassword: ({
              required String currentPassword,
              required String newPassword,
              required String confirmPassword,
            }) async {
              capturedCurrentPassword = currentPassword;
              capturedNewPassword = newPassword;
              capturedConfirmPassword = confirmPassword;
            },
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextFormField).at(0), 'oldpass');
    await tester.enterText(find.byType(TextFormField).at(1), 'newpass1');
    await tester.enterText(find.byType(TextFormField).at(2), 'newpass1');

    final submitButton =
        find.widgetWithText(ElevatedButton, 'Change Password');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(capturedCurrentPassword, 'oldpass');
    expect(capturedNewPassword, 'newpass1');
    expect(capturedConfirmPassword, 'newpass1');
    expect(find.text('Password changed successfully'), findsOneWidget);
  });
}
