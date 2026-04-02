import 'package:employee_activity_app/core/constants/app_constants.dart';
import 'package:employee_activity_app/features/notification/presentation/pages/notifications_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  testWidgets('renders notifications and filters unread items', (tester) async {
    final dataSource = FakeNotificationDataSource(
      notifications: [
        {
          'id': '1',
          'title': 'Unread notice',
          'message': 'Please review',
          'type': AppConstants.notificationAnnouncement,
          'isRead': false,
          'createdAt': DateTime.now()
              .subtract(const Duration(hours: 1))
              .toIso8601String(),
        },
        {
          'id': '2',
          'title': 'Read notice',
          'message': 'Already seen',
          'type': AppConstants.notificationPayslipGenerated,
          'isRead': true,
          'createdAt': DateTime.now()
              .subtract(const Duration(days: 1))
              .toIso8601String(),
        },
      ],
    );

    await tester.pumpWidget(
      wrapWithMaterialApp(
        NotificationsScreen(dataSource: dataSource),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Unread notice'), findsOneWidget);
    expect(find.text('Read notice'), findsOneWidget);
    expect(find.text('1 unread'), findsOneWidget);

    await tester.tap(find.text('Unread'));
    await tester.pump();

    expect(find.text('Unread notice'), findsOneWidget);
    expect(find.text('Read notice'), findsNothing);
  });

  testWidgets('marks unread notification as read on tap', (tester) async {
    final dataSource = FakeNotificationDataSource(
      notifications: [
        {
          'id': 'abc',
          'title': 'Pending leave',
          'message': 'Tap to mark read',
          'type': AppConstants.notificationLeaveRequest,
          'isRead': false,
          'createdAt': DateTime.now().toIso8601String(),
        },
      ],
    );

    await tester.pumpWidget(
      wrapWithMaterialApp(
        NotificationsScreen(dataSource: dataSource),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('Pending leave'));
    await tester.pump();

    expect(dataSource.lastMarkedId, 'abc');
    expect(find.text('1 unread'), findsNothing);
  });

  testWidgets('shows empty unread state when unread filter has no items',
      (tester) async {
    final dataSource = FakeNotificationDataSource(
      notifications: [
        {
          'id': 'r1',
          'title': 'Read item',
          'message': 'Done',
          'type': AppConstants.notificationLetterReady,
          'isRead': true,
          'createdAt': DateTime.now().toIso8601String(),
        },
      ],
    );

    await tester.pumpWidget(
      wrapWithMaterialApp(
        NotificationsScreen(dataSource: dataSource),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('Unread'));
    await tester.pump();

    expect(find.text('No Notifications'), findsOneWidget);
    expect(find.text('You have no unread notifications'), findsOneWidget);
  });

  testWidgets('shows error state when notifications loading fails',
      (tester) async {
    final dataSource = FakeNotificationDataSource(
      getNotificationsError: Exception('notifications down'),
    );

    await tester.pumpWidget(
      wrapWithMaterialApp(
        NotificationsScreen(dataSource: dataSource),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(
      find.text('Failed to load notifications: Exception: notifications down'),
      findsOneWidget,
    );
    expect(find.text('No Notifications'), findsOneWidget);
    expect(find.text('No notifications found'), findsOneWidget);
  });
}
