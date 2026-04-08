abstract class AttendanceDataSource {
  Future<Map<String, dynamic>> markAttendance({
    required double latitude,
    required double longitude,
    required String address,
  });

  Future<Map<String, dynamic>> getTodayAttendance();

  Future<List<dynamic>> getAttendanceHistory({
    int? month,
    int? year,
  });

  Future<Map<String, dynamic>> getAttendanceSummary({
    required int month,
    required int year,
  });

  Future<Map<String, dynamic>> requestManualAttendance({
    required DateTime date,
    required String reason,
  });
}
