import 'package:employee_activity_app/features/payroll/presentation/pages/payslip_detail_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  testWidgets('renders payslip detail breakdown from injected data source',
      (tester) async {
    final dataSource = FakePayrollDataSource(
      payslipById: {
        'month': 3,
        'year': 2026,
        'employee': {
          'firstName': 'Aashi',
          'lastName': 'Sharma',
          'designation': 'Engineer',
          'department': 'Engineering',
        },
        'basicPay': 30000,
        'hra': 12000,
        'specialAllowance': 5000,
        'otherAllowances': 2000,
        'pf': 1800,
        'professionalTax': 200,
        'otherDeductions': 0,
        'grossPay': 49000,
        'netPay': 47000,
        'totalWorkingDays': 22,
        'daysPresent': 20,
        'daysAbsent': 1,
        'daysOnLeave': 1,
        'isGenerated': true,
      },
    );

    await tester.pumpWidget(
      wrapWithMaterialApp(
        PayslipDetailScreen(
          payslipId: 'p1',
          dataSource: dataSource,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('March 2026'), findsOneWidget);
    expect(find.text('Aashi Sharma'), findsOneWidget);
    expect(find.text('Attendance Summary'), findsOneWidget);
    expect(find.text('Earnings'), findsOneWidget);
    expect(find.text('Deductions'), findsOneWidget);
    expect(find.text('Net Pay'), findsWidgets);
    expect(find.text('Download Payslip PDF'), findsOneWidget);
  });

  testWidgets('shows error state when payslip loading fails',
      (tester) async {
    final dataSource = FakePayrollDataSource(
      payslipByIdError: Exception('payslip api down'),
    );

    await tester.pumpWidget(
      wrapWithMaterialApp(
        PayslipDetailScreen(
          payslipId: 'missing',
          dataSource: dataSource,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Failed to load payslip'), findsOneWidget);
    expect(find.text('Exception: payslip api down'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
