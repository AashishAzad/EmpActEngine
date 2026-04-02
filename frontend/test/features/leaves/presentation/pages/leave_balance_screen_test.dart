import 'package:employee_activity_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:employee_activity_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:employee_activity_app/features/leaves/presentation/pages/leave_balance_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  testWidgets('renders leave balance details for authenticated user',
      (tester) async {
    final bloc = AuthBloc(
      authRepository: FakeAuthRepository(),
      storageHelper: testStorageHelper(),
    );
    bloc.emit(const Authenticated(testAdminUser));

    await tester.pumpWidget(
      wrapWithMaterialApp(
        BlocProvider<AuthBloc>.value(
          value: bloc,
          child: const LeaveBalanceScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Leave Balance'), findsOneWidget);
    expect(find.text('Total Leave Balance'), findsOneWidget);
    expect(find.text('10'), findsWidgets);
    expect(find.text('Casual Leave'), findsOneWidget);
    expect(find.text('Sick Leave'), findsOneWidget);
    expect(find.text('All Purpose Leave'), findsOneWidget);
    expect(find.text('Leave Policy'), findsOneWidget);
  });
}
