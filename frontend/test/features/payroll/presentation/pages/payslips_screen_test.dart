import 'package:employee_activity_app/features/payroll/presentation/pages/payslips_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  testWidgets('renders payslip list from injected data source', (tester) async {
    final dataSource = FakePayrollDataSource(
      payslipsResponse: {
        'data': [
          {
            'id': 'p1',
            'month': 3,
            'year': 2026,
            'grossPay': 50000,
            'netPay': 47000,
            'isGenerated': true,
            'generatedAt': '2026-03-31T00:00:00',
          },
          {
            'id': 'p2',
            'month': 2,
            'year': 2026,
            'grossPay': 50000,
            'netPay': 46500,
            'isGenerated': false,
          },
        ],
        'totalPages': 1,
      },
    );

    await tester.pumpWidget(
      wrapWithMaterialApp(
        PayslipsScreen(dataSource: dataSource),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('March'), findsOneWidget);
    expect(find.text('February'), findsOneWidget);
    expect(find.text('GENERATED'), findsOneWidget);
    expect(find.text('PENDING'), findsOneWidget);
    expect(find.text('View Details'), findsNWidgets(2));
  });

  testWidgets('shows empty state when no payslips are available', (tester) async {
    final dataSource = FakePayrollDataSource(
      payslipsResponse: {
        'data': [],
        'totalPages': 1,
      },
    );

    await tester.pumpWidget(
      wrapWithMaterialApp(
        PayslipsScreen(dataSource: dataSource),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('No Payslips'), findsOneWidget);
    expect(find.text('No payslips available yet'), findsOneWidget);
  });
}
