import 'package:employee_activity_app/features/payroll/presentation/pages/my_salary_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  testWidgets('renders salary breakdown from injected data source',
      (tester) async {
    final dataSource = FakePayrollDataSource(
      salaryData: {
        'basicPay': 30000,
        'hra': 12000,
        'specialAllowance': 5000,
        'otherAllowances': 2000,
        'pf': 1800,
        'professionalTax': 200,
        'otherDeductions': 0,
        'grossPay': 49000,
        'netPay': 47000,
      },
    );

    await tester.pumpWidget(
      wrapWithMaterialApp(
        MySalaryScreen(dataSource: dataSource),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Net Salary'), findsOneWidget);
    expect(find.textContaining('47,000'), findsWidgets);
    expect(find.text('Gross Salary'), findsOneWidget);
    expect(find.text('Deductions'), findsWidgets);
    expect(find.text('Basic Pay'), findsOneWidget);
    expect(find.text('House Rent Allowance (HRA)'), findsOneWidget);
    expect(find.text('Annual CTC'), findsOneWidget);
  });

  testWidgets('shows error state when salary loading fails', (tester) async {
    final dataSource = FakePayrollDataSource(
      salaryError: Exception('salary api down'),
    );

    await tester.pumpWidget(
      wrapWithMaterialApp(
        MySalaryScreen(dataSource: dataSource),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Failed to load salary'), findsOneWidget);
    expect(find.text('Exception: salary api down'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
