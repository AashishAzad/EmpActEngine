import 'package:employee_activity_app/core/theme/app_colors.dart';
import 'package:employee_activity_app/features/home/presentation/widgets/stat_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  testWidgets('renders stat values and shows navigation affordance when tappable',
      (tester) async {
    await tester.pumpWidget(
      wrapWithMaterialApp(
        Scaffold(
          body: StatCard(
            title: 'Attendance',
            value: '95%',
            subtitle: 'This month',
            icon: Icons.check_circle,
            color: AppColors.success,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('Attendance'), findsOneWidget);
    expect(find.text('95%'), findsOneWidget);
    expect(find.text('This month'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.byIcon(Icons.arrow_forward_ios), findsOneWidget);
  });

  testWidgets('omits navigation arrow when onTap is null', (tester) async {
    await tester.pumpWidget(
      wrapWithMaterialApp(
        Scaffold(
          body: StatCard(
            title: 'Notifications',
            value: '3',
            subtitle: 'Unread',
            icon: Icons.notifications,
            color: AppColors.error,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.arrow_forward_ios), findsNothing);
  });
}
