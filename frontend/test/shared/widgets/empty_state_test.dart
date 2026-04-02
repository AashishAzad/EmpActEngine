import 'package:employee_activity_app/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

void main() {
  testWidgets('renders title message and action button when provided',
      (tester) async {
    var tapCount = 0;

    await tester.pumpWidget(
      wrapWithMaterialApp(
        EmptyState(
          icon: Icons.inbox,
          title: 'No Data',
          message: 'Nothing to show right now',
          actionText: 'Reload',
          onActionPressed: () => tapCount += 1,
        ),
      ),
    );

    expect(find.text('No Data'), findsOneWidget);
    expect(find.text('Nothing to show right now'), findsOneWidget);
    expect(find.text('Reload'), findsOneWidget);

    await tester.tap(find.text('Reload'));
    await tester.pump();

    expect(tapCount, 1);
  });

  testWidgets('omits action button when no action is supplied', (tester) async {
    await tester.pumpWidget(
      wrapWithMaterialApp(
        const EmptyState(
          icon: Icons.inbox,
          title: 'No Payslips',
          message: 'No payslips available yet',
        ),
      ),
    );

    expect(find.text('No Payslips'), findsOneWidget);
    expect(find.text('No payslips available yet'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsNothing);
  });
}
