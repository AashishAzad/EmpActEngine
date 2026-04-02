import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';

/// Letter Remote Data Source
///
/// All letter request API calls against the Jmix backend.
///
/// Endpoint shapes:
/// POST /letters/request           → LetterRequestResponse (201)
/// GET  /letters/my-requests       → List<LetterRequestResponse> (plain list, no pagination)
/// GET  /letters/{id}/download     → PDF bytes (streamed, auth required)

abstract class LetterDataSource {
  Future<Map<String, dynamic>> requestLetter({
    required String letterType,
    String? remarks,
  });

  Future<List<dynamic>> getMyLetterRequests();
  Future<List<int>> downloadLetter(String id);
}

class LetterRemoteDataSource implements LetterDataSource {
  final DioClient dioClient;

  LetterRemoteDataSource({required this.dioClient});

  // ── Request Letter ─────────────────────────────────────────────────────────

  /// POST /letters/request
  /// RequestLetterRequest fields: letterType (LetterType enum), remarks (optional)
  Future<Map<String, dynamic>> requestLetter({
    required String letterType,
    String? remarks,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'letterType': letterType, // e.g. "EMPLOYMENT", "EXPERIENCE", "APPRAISAL", "FORM_16"
      };
      if (remarks != null && remarks.isNotEmpty) {
        data['remarks'] = remarks;
      }

      final response = await dioClient.dio.post(
        ApiConstants.requestLetter, // → /letters/request
        data: data,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('Failed to request letter: ${e.message}');
    }
  }

  // ── Get My Letter Requests ─────────────────────────────────────────────────

  /// GET /letters/my-requests
  /// Returns List<LetterRequestResponse> directly — no pagination wrapper.
  Future<List<dynamic>> getMyLetterRequests() async {
    try {
      final response = await dioClient.dio.get(
        ApiConstants.myLetterRequests, // → /letters/my-requests
      );
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw Exception('Failed to get letter requests: ${e.message}');
    }
  }

  // ── Download Letter ────────────────────────────────────────────────────────

  /// GET /letters/{id}/download
  /// Streams PDF — returns raw bytes.
  /// Backend checks that only the requestor can download their own letter.
  Future<List<int>> downloadLetter(String id) async {
    try {
      final response = await dioClient.dio.get(
        ApiConstants.downloadLetter(id), // → /letters/{id}/download
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data as List<int>;
    } on DioException catch (e) {
      throw Exception('Failed to download letter: ${e.message}');
    }
  }
}
