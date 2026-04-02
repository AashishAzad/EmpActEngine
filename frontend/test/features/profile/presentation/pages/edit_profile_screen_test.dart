import 'package:employee_activity_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:employee_activity_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:employee_activity_app/features/profile/presentation/pages/edit_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  Widget wrapWithRouter({
    required AuthBloc bloc,
    required Widget child,
  }) {
    final router = GoRouter(
      initialLocation: '/edit',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Home')),
          ),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) => BlocProvider<AuthBloc>.value(
                value: bloc,
                child: child,
              ),
            ),
          ],
        ),
      ],
    );

    return MaterialApp.router(routerConfig: router);
  }

  testWidgets('shows access denied for non-admin users', (tester) async {
    final bloc = AuthBloc(
      authRepository: FakeAuthRepository(),
      storageHelper: testStorageHelper(),
    );
    bloc.emit(const Authenticated(testUser));

    await tester.pumpWidget(
      wrapWithRouter(
        bloc: bloc,
        child: const EditProfileScreen(),
      ),
    );
    await tester.pump();

    expect(find.text('Access Denied'), findsOneWidget);
    expect(find.text('Only admins can edit profiles.'), findsOneWidget);
  });

  testWidgets('submits changed admin profile fields', (tester) async {
    final bloc = AuthBloc(
      authRepository: FakeAuthRepository(),
      storageHelper: testStorageHelper(),
    );
    bloc.emit(const Authenticated(testAdminUser));

    String? capturedTargetId;
    Map<String, dynamic>? capturedData;

    await tester.pumpWidget(
      wrapWithRouter(
        bloc: bloc,
        child: EditProfileScreen(
          onUpdateProfile: (targetId, data) async {
            capturedTargetId = targetId;
            capturedData = data;
          },
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextFormField).at(0), 'UpdatedAdmin');
    await tester.enterText(
      find.byType(TextFormField).at(3),
      '9123456780',
    );

    await tester.ensureVisible(find.text('Update Profile'));
    await tester.tap(find.text('Update Profile'));
    await tester.pumpAndSettle();

    expect(capturedTargetId, testAdminUser.id);
    expect(capturedData, isNotNull);
    expect(capturedData!['firstName'], 'UpdatedAdmin');
    expect(capturedData!['phoneNumber'], '9123456780');
    expect(find.text('Home'), findsOneWidget);
  });
}
