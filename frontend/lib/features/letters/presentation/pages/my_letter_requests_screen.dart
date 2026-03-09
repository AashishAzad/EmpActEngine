import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../data/datasources/letter_remote_data_source.dart';

/// My Letter Requests Screen
///
/// Shows employee's letter requests with status and download option.
/// Data from GET /letters/my-requests → List<LetterRequestResponse>
///
/// LetterRequestResponse fields:
/// id, employeeId, employee, letterType (enum), status (enum),
/// remarks, fileUrl, createdAt, updatedAt, completedAt

class MyLetterRequestsScreen extends StatefulWidget {
  const MyLetterRequestsScreen({super.key});

  @override
  State<MyLetterRequestsScreen> createState() => _MyLetterRequestsScreenState();
}

class _MyLetterRequestsScreenState extends State<MyLetterRequestsScreen> {
  final _dataSource = LetterRemoteDataSource(dioClient: DioClient());

  bool _isLoading = false;
  List<Map<String, dynamic>> _letters = [];
  String? _downloadingId; // tracks which letter is being downloaded

  @override
  void initState() {
    super.initState();
    _loadLetters();
  }

  Future<void> _loadLetters() async {
    setState(() => _isLoading = true);
    try {
      final raw = await _dataSource.getMyLetterRequests();
      setState(() {
        _letters = raw.cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // ── Download Letter PDF ────────────────────────────────────────────────────

  /// GET /letters/{id}/download → PDF bytes → save → open
  Future<void> _downloadLetter(String id, String letterType) async {
    setState(() => _downloadingId = id);
    try {
      final bytes = await _dataSource.downloadLetter(id);
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/letter_${letterType}_$id.pdf');
      await file.writeAsBytes(bytes);
      await OpenFile.open(file.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _downloadingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Letter Requests'),
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.white,
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading letters...')
          : _letters.isEmpty
          ? const EmptyState(
        icon: Icons.description_outlined,
        title: 'No Letter Requests',
        message: 'You haven\'t requested any letters yet',
      )
          : RefreshIndicator(
        onRefresh: _loadLetters,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _letters.length,
          itemBuilder: (context, index) =>
              _buildLetterCard(_letters[index]),
        ),
      ),
    );
  }

  Widget _buildLetterCard(Map<String, dynamic> letter) {
    final id = letter['id']?.toString() ?? '';
    // letterType is a LetterType enum — serializes as "EMPLOYMENT", "EXPERIENCE" etc.
    final letterType = letter['letterType']?.toString() ?? 'N/A';
    // status is LetterRequestStatus enum — PENDING, COMPLETED, REJECTED
    final status = letter['status']?.toString() ?? AppConstants.letterPending;
    final fileUrl = letter['fileUrl']?.toString();
    final remarks = letter['remarks']?.toString();
    final createdAt = letter['createdAt']?.toString();

    DateTime? requestDate;
    try {
      if (createdAt != null) requestDate = DateTime.parse(createdAt);
    } catch (_) {}

    // Status colors — matches LetterRequestStatus enum values
    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case AppConstants.letterCompleted: // "COMPLETED"
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
        break;
      case AppConstants.letterRejected: // "REJECTED"
        statusColor = AppColors.error;
        statusIcon = Icons.cancel;
        break;
      default: // "PENDING"
        statusColor = AppColors.warning;
        statusIcon = Icons.pending;
    }

    final isDownloading = _downloadingId == id;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.description,
                      color: AppColors.secondary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getLetterTypeLabel(letterType),
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (requestDate != null)
                        Text(
                          'Requested: ${requestDate.day}/${requestDate.month}/${requestDate.year}',
                          style: AppTextStyles.caption,
                        ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        status,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ── Remarks (if any) ──────────────────────────────────────────
            if (remarks != null && remarks.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.comment_outlined,
                        size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        remarks,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── COMPLETED — show download button ──────────────────────────
            if (status == AppConstants.letterCompleted && fileUrl != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border:
                  Border.all(color: AppColors.success.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle,
                        color: AppColors.success, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your letter is ready!',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // Real download button
                    isDownloading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : TextButton.icon(
                      onPressed: () =>
                          _downloadLetter(id, letterType),
                      icon: Icon(Icons.download,
                          color: AppColors.success, size: 20),
                      label: Text(
                        'Download',
                        style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── PENDING ───────────────────────────────────────────────────
            if (status == AppConstants.letterPending) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.pending, color: AppColors.warning, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Waiting for admin to process your request',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── REJECTED ──────────────────────────────────────────────────
            if (status == AppConstants.letterRejected) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.cancel, color: AppColors.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your request was rejected',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Convert enum string to human-readable label
  String _getLetterTypeLabel(String type) {
    switch (type) {
      case AppConstants.letterEmployment:
        return 'Employment Letter';
      case AppConstants.letterExperience:
        return 'Experience Letter';
      case AppConstants.letterAppraisal:
        return 'Appraisal Letter';
      case AppConstants.letterForm16:
        return 'Form 16';
      default:
        return type;
    }
  }
}