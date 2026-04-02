import 'package:employee_activity_app/core/theme/app_colors.dart';
import 'package:employee_activity_app/features/home/presentation/widgets/quick_action_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  testWidgets('renders title subtitle and triggers tap callback',
      (tester) async {
    var tapCount = 0;

    await tester.pumpWidget(
      wrapWithMaterialApp(
        Scaffold(
          body: QuickActionCard(
            title: 'Apply for Leave',
            subtitle: 'Request time off',
            icon: Icons.event,
            color: AppColors.secondary,
            onTap: () => tapCount += 1,
          ),
        ),
      ),
    );

    expect(find.text('Apply for Leave'), findsOneWidget);
    expect(find.text('Request time off'), findsOneWidget);
    expect(find.byIcon(Icons.event), findsOneWidget);

    await tester.tap(find.byType(QuickActionCard));
    await tester.pump();

    expect(tapCount, 1);
  });
}
