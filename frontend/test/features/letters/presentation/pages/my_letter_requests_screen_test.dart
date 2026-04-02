import 'package:employee_activity_app/features/letters/presentation/pages/my_letter_requests_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  testWidgets('renders letter request statuses and downloads completed letter',
      (tester) async {
    final dataSource = FakeLetterDataSource(
      myRequests: [
        {
          'id': 'completed-1',
          'letterType': 'EMPLOYMENT',
          'status': 'COMPLETED',
          'fileUrl': 'ready.pdf',
          'createdAt': '2026-04-01T00:00:00',
        },
        {
          'id': 'pending-1',
          'letterType': 'EXPERIENCE',
          'status': 'PENDING',
          'createdAt': '2026-04-02T00:00:00',
        },
        {
          'id': 'rejected-1',
          'letterType': 'FORM_16',
          'status': 'REJECTED',
          'remarks': 'Missing details',
          'createdAt': '2026-04-03T00:00:00',
        },
      ],
    );

    String? savedPath;
    String? openedPath;

    await tester.pumpWidget(
      wrapWithMaterialApp(
        MyLetterRequestsScreen(
          dataSource: dataSource,
          saveLetter: (id, letterType, bytes) async {
            savedPath = 'C:/temp/$id-$letterType.pdf';
            return savedPath!;
          },
          openLetter: (path) async {
            openedPath = path;
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Employment Letter'), findsOneWidget);
    expect(find.text('Experience Letter'), findsOneWidget);
    expect(find.text('Form 16'), findsOneWidget);
    expect(find.text('Your letter is ready!'), findsOneWidget);
    expect(find.text('Waiting for admin to process your request'), findsOneWidget);
    expect(find.text('Your request was rejected'), findsOneWidget);

    await tester.tap(find.text('Download'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(dataSource.downloadedLetterId, 'completed-1');
    expect(savedPath, 'C:/temp/completed-1-EMPLOYMENT.pdf');
    expect(openedPath, savedPath);
  });

  testWidgets('shows empty state when there are no letter requests',
      (tester) async {
    final dataSource = FakeLetterDataSource();

    await tester.pumpWidget(
      wrapWithMaterialApp(
        MyLetterRequestsScreen(dataSource: dataSource),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('No Letter Requests'), findsOneWidget);
    expect(find.text('You haven\'t requested any letters yet'), findsOneWidget);
  });

  testWidgets('shows error snackbar when letter download fails', (tester) async {
    final dataSource = FakeLetterDataSource(
      myRequests: [
        {
          'id': 'completed-1',
          'letterType': 'EMPLOYMENT',
          'status': 'COMPLETED',
          'fileUrl': 'ready.pdf',
          'createdAt': '2026-04-01T00:00:00',
        },
      ],
      downloadError: Exception('download failed'),
    );

    await tester.pumpWidget(
      wrapWithMaterialApp(
        MyLetterRequestsScreen(dataSource: dataSource),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('Download'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Download failed: Exception: download failed'), findsOneWidget);
  });
}
