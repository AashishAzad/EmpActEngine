abstract class AdminPayrollSource {
  Future<Map<String, dynamic>> upsertSalary({
    required String employeeId,
    required double basicPay,
    required double hra,
    required double specialAllowance,
    double otherAllowances = 0.0,
    required double pf,
    double professionalTax = 0.0,
    double otherDeductions = 0.0,
  });

  Future<Map<String, dynamic>> generatePayslip({
    required String employeeId,
    required int month,
    required int year,
  });

  Future<List<dynamic>> getAllPayslips({
    String? employeeId,
    int? month,
    int? year,
    int page = 1,
    int limit = 20,
  });

  Future<List<dynamic>> getPendingLetterRequests();

  Future<Map<String, dynamic>> uploadLetter({
    required String requestId,
    required String filePath,
  });

  Future<Map<String, dynamic>> rejectLetter({
    required String requestId,
    String? remarks,
  });
}
