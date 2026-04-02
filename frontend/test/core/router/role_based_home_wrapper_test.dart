import 'package:employee_activity_app/core/router/role_based_home_wrapper.dart';
import 'package:employee_activity_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:employee_activity_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

void main() {
  testWidgets('shows admin home for admin users and employee home for managers',
      (tester) async {
    final bloc = AuthBloc(
      authRepository: FakeAuthRepository(),
      storageHelper: testStorageHelper(),
    );

    await tester.pumpWidget(
      wrapWithMaterialApp(
        BlocProvider<AuthBloc>.value(
          value: bloc,
          child: RoleBasedHomeWrapper(
            adminHome: const Scaffold(body: Text('Admin Home')),
            employeeHome: const Scaffold(body: Text('Employee Home')),
          ),
        ),
      ),
    );

    bloc.emit(const Authenticated(testAdminUser));
    await tester.pump();
    expect(find.text('Admin Home'), findsOneWidget);

    bloc.emit(const Authenticated(testUser));
    await tester.pump();
    expect(find.text('Employee Home'), findsOneWidget);
  });
}
