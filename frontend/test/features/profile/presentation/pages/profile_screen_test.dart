import 'package:employee_activity_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:employee_activity_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:employee_activity_app/features/profile/presentation/pages/profile_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  testWidgets('renders authenticated user profile details', (tester) async {
    final bloc = AuthBloc(
      authRepository: FakeAuthRepository(),
      storageHelper: testStorageHelper(),
    );
    bloc.emit(const Authenticated(testAdminUser));

    await tester.pumpWidget(
      wrapWithMaterialApp(
        BlocProvider<AuthBloc>.value(
          value: bloc,
          child: const ProfileScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Admin User'), findsOneWidget);
    expect(find.text('ADM001'), findsOneWidget);
    expect(find.text('ADMIN'), findsOneWidget);
    expect(find.text('admin@example.com'), findsOneWidget);
    expect(find.text('HR Manager'), findsOneWidget);
    expect(find.text('People'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });
}
