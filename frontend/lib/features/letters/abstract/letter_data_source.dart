abstract class LetterDataSource {
  Future<Map<String, dynamic>> requestLetter({
    required String letterType,
    String? remarks,
  });

  Future<List<dynamic>> getMyLetterRequests();
  Future<List<int>> downloadLetter(String id);
}
