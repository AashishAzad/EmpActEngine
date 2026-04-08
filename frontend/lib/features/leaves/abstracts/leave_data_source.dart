abstract class LeaveDataSource {
  Future<Map<String, dynamic>> applyLeave({
    required String leaveType,
    required String startDate,
    required String endDate,
    required String contactNumber,
    required String contactEmail,
    String? remarks,
  });

  Future<List<dynamic>> getMyLeaves();
  Future<List<dynamic>> getPendingLeaves();
  Future<void> approveLeave({required String leaveId});
  Future<void> rejectLeave({
    required String leaveId,
    required String actionRemarks,
  });
}
