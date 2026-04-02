import 'package:employee_activity_app/features/attendance/presentation/pages/mark_attendance_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  Widget wrapWithRouter(MarkAttendanceScreen child) {
    final router = GoRouter(
      initialLocation: '/mark',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Home')),
          ),
          routes: [
            GoRoute(
              path: 'mark',
              builder: (context, state) => child,
            ),
          ],
        ),
      ],
    );

    return MaterialApp.router(routerConfig: router);
  }

  testWidgets('shows permission error and retry actions when location is denied',
      (tester) async {
    final dataSource = FakeAttendanceDataSource();
    final locationService = FakeAttendanceLocationService(
      hasPermissionValue: false,
    );

    await tester.pumpWidget(
      wrapWithRouter(
        MarkAttendanceScreen(
          dataSource: dataSource,
          locationService: locationService,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Location Not Available'), findsOneWidget);
    expect(
      find.textContaining('Location permission denied'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Open Settings'), findsOneWidget);
  });

  testWidgets('marks attendance after location is captured', (tester) async {
    final dataSource = FakeAttendanceDataSource();
    final locationService = FakeAttendanceLocationService(
      location: const LocationSnapshot(
        latitude: 12.9716,
        longitude: 77.5946,
        accuracy: 15,
        address: 'MG Road, Bengaluru',
      ),
    );

    await tester.pumpWidget(
      wrapWithRouter(
        MarkAttendanceScreen(
          dataSource: dataSource,
          locationService: locationService,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Location Captured'), findsOneWidget);
    expect(find.text('MG Road, Bengaluru'), findsOneWidget);

    final markButton = find.widgetWithText(ElevatedButton, 'Mark Attendance');
    await tester.ensureVisible(markButton);
    await tester.tap(markButton);
    await tester.pumpAndSettle();

    expect(dataSource.markedLatitude, 12.9716);
    expect(dataSource.markedLongitude, 77.5946);
    expect(dataSource.markedAddress, 'MG Road, Bengaluru');
    expect(find.text('Home'), findsOneWidget);
  });
}
