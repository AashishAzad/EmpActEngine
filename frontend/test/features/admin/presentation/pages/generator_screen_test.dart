import 'package:employee_activity_app/features/admin/presentation/pages/generator_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  Finder findDropdownWithHint(String hintText) {
    return find.byWidgetPredicate(
      (widget) =>
          widget is DropdownButtonFormField &&
          widget.decoration?.hintText == hintText,
    );
  }

  FakeAdminEmployeeDataSource buildEmployeeSource() {
    return FakeAdminEmployeeDataSource(
      employees: [
        {
          'id': 'uuid-1',
          'firstName': 'Aashi',
          'lastName': 'Sharma',
          'employeeId': 'EMP001',
          'designation': 'Engineer',
          'status': 'ACTIVE',
        },
      ],
    );
  }

  testWidgets('renders generator tabs and payslip form', (tester) async {
    final employeeDataSource = buildEmployeeSource();
    final payrollDataSource = FakeAdminPayrollDataSource();

    await tester.pumpWidget(
      wrapWithMaterialApp(
        GeneratorScreen(
          employeeDataSource: employeeDataSource,
          payrollDataSource: payrollDataSource,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Generate Payslip'), findsWidgets);
    expect(find.text('Upload Letters'), findsOneWidget);
    expect(find.text('Select Employee'), findsOneWidget);
    expect(find.text('Month'), findsOneWidget);
    expect(find.text('Year'), findsOneWidget);
  });

  testWidgets('uploads selected pdf from upload letters tab', (tester) async {
    final employeeDataSource = buildEmployeeSource();
    final payrollDataSource = FakeAdminPayrollDataSource(
      pendingLetters: [
        {
          'id': 'letter-1',
          'letterType': 'BONAFIDE',
          'employee': {
            'firstName': 'Aashi',
            'lastName': 'Sharma',
            'employeeId': 'EMP001',
          },
        },
      ],
    );

    await tester.pumpWidget(
      wrapWithMaterialApp(
        GeneratorScreen(
          employeeDataSource: employeeDataSource,
          payrollDataSource: payrollDataSource,
          pickPdfFile: () async => const SelectedPdfFile(
            path: 'C:/temp/letter.pdf',
            name: 'letter.pdf',
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('Upload Letters'));
    await tester.pumpAndSettle();

    await tester.tap(findDropdownWithHint('Select request'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Aashi Sharma').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Tap to select PDF'));
    await tester.tap(find.text('Tap to select PDF'));
    await tester.pumpAndSettle();

    expect(find.text('letter.pdf'), findsOneWidget);

    await tester.ensureVisible(find.text('Upload Letter'));
    await tester.tap(find.text('Upload Letter'));
    await tester.pumpAndSettle();

    expect(payrollDataSource.uploadedRequestId, 'letter-1');
    expect(payrollDataSource.uploadedFilePath, 'C:/temp/letter.pdf');
    expect(find.text('Letter uploaded successfully!'), findsOneWidget);
  });
}
