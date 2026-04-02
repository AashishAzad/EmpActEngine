import 'package:employee_activity_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:employee_activity_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:employee_activity_app/features/home/presentation/pages/leaves_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  Widget wrapWithRouter(AuthBloc bloc) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => BlocProvider<AuthBloc>.value(
            value: bloc,
            child: const LeavesPage(),
          ),
        ),
        GoRoute(
          path: '/leaves/apply',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Apply Route')),
          ),
        ),
        GoRoute(
          path: '/leaves/history',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('History Route')),
          ),
        ),
      ],
    );

    return MaterialApp.router(routerConfig: router);
  }

  testWidgets('renders leave balances and navigates to apply flow',
      (tester) async {
    final bloc = AuthBloc(
      authRepository: FakeAuthRepository(),
      storageHelper: testStorageHelper(),
    );
    bloc.emit(const Authenticated(testAdminUser));

    await tester.pumpWidget(wrapWithRouter(bloc));
    await tester.pump();

    expect(find.text('Total Leave Balance'), findsOneWidget);
    expect(find.text('Casual Leave'), findsOneWidget);
    expect(find.text('Sick Leave'), findsOneWidget);
    expect(find.text('All Purpose Leave'), findsOneWidget);

    final applyButton = find.widgetWithText(ElevatedButton, 'Apply for Leave');
    await tester.ensureVisible(applyButton);
    await tester.tap(applyButton);
    await tester.pumpAndSettle();

    expect(find.text('Apply Route'), findsOneWidget);
  });
}
