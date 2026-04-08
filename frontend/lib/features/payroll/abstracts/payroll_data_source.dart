abstract class PayrollDataSource {
  Future<Map<String, dynamic>> getMySalary();
  Future<Map<String, dynamic>> getMyPayslips({
    int? month,
    int? year,
    int page = 1,
    int limit = 10,
  });
  Future<List<dynamic>> getMyRecentPayslips();
  Future<Map<String, dynamic>> getPayslipById(String id);
  Future<List<int>> downloadPayslip(String id);
}
