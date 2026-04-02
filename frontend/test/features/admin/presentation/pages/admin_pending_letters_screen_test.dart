import 'package:employee_activity_app/features/admin/presentation/pages/admin_pending_letters_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  Map<String, dynamic> pendingLetter() {
    return {
      'id': 'letter-1',
      'letterType': 'BONAFIDE',
      'employee': {
        'firstName': 'Aashi',
        'lastName': 'Sharma',
        'employeeId': 'EMP001',
      },
    };
  }

  testWidgets('renders pending letter request details', (tester) async {
    final dataSource = FakeAdminPayrollDataSource(
      pendingLetters: [pendingLetter()],
    );

    await tester.pumpWidget(
      wrapWithMaterialApp(
        AdminPendingLettersScreen(dataSource: dataSource),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Aashi Sharma'), findsOneWidget);
    expect(find.text('EMP001'), findsOneWidget);
    expect(find.text('BONAFIDE'), findsOneWidget);
    expect(find.text('Upload PDF'), findsOneWidget);
  });

  testWidgets('uploads selected pdf and refreshes to empty state', (tester) async {
    final dataSource = FakeAdminPayrollDataSource(
      pendingLetters: [pendingLetter()],
    );

    await tester.pumpWidget(
      wrapWithMaterialApp(
        AdminPendingLettersScreen(
          dataSource: dataSource,
          pickPdfFile: () async => const SelectedPdfFile(
            path: 'C:/temp/bonafide.pdf',
            name: 'bonafide.pdf',
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('Upload PDF'));
    await tester.pumpAndSettle();

    expect(find.text('Upload Letter'), findsOneWidget);
    expect(find.text('File: bonafide.pdf'), findsOneWidget);

    await tester.tap(find.text('Upload').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    expect(dataSource.uploadedRequestId, 'letter-1');
    expect(dataSource.uploadedFilePath, 'C:/temp/bonafide.pdf');
    expect(find.text('Letter uploaded successfully!'), findsOneWidget);
    expect(find.text('No Pending Requests'), findsOneWidget);
  });
}
