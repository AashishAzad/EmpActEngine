import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../admin/data/datasources/admin_payroll_data_source.dart';

class SelectedPdfFile {
  const SelectedPdfFile({
    required this.path,
    required this.name,
  });

  final String path;
  final String name;
}

typedef PickPdfFile = Future<SelectedPdfFile?> Function();

/// Admin Pending Letters Screen
///
/// Shows pending letter requests with PDF upload option.
/// GET  /letters/pending          → List<LetterRequestResponse>
/// POST /letters/{id}/upload      → multipart/form-data with 'file' field

class AdminPendingLettersScreen extends StatefulWidget {
  AdminPendingLettersScreen({
    super.key,
    AdminPayrollSource? dataSource,
    PickPdfFile? pickPdfFile,
  })  : dataSource = dataSource ?? AdminPayrollDataSource(dioClient: DioClient()),
        pickPdfFile = pickPdfFile ?? _defaultPickPdfFile;

  final AdminPayrollSource dataSource;
  final PickPdfFile pickPdfFile;

  static Future<SelectedPdfFile?> _defaultPickPdfFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null || result.files.single.path == null) {
      return null;
    }

    return SelectedPdfFile(
      path: result.files.single.path!,
      name: result.files.single.name,
    );
  }

  @override
  State<AdminPendingLettersScreen> createState() =>
      _AdminPendingLettersScreenState();
}

class _AdminPendingLettersScreenState
    extends State<AdminPendingLettersScreen> {
  bool _isLoading = false;
  List<dynamic> _pendingLetters = [];

  @override
  void initState() {
    super.initState();
    _loadPendingLetters();
  }

  Future<void> _loadPendingLetters() async {
    setState(() => _isLoading = true);
    try {
      final letters = await widget.dataSource.getPendingLetterRequests();
      setState(() {
        _pendingLetters = letters;
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

  Future<void> _uploadLetter(
      String requestId, String employeeName) async {
    // Backend POST /letters/{id}/upload expects multipart PDF
    // Only allow PDF — backend serves with APPLICATION_PDF content type
    final selectedFile = await widget.pickPdfFile();
    if (selectedFile == null) return;

    final filePath = selectedFile.path;
    final fileName = selectedFile.name;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Letter'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Upload letter for $employeeName?'),
            const SizedBox(height: 8),
            Text(
              'File: $fileName',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Upload'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
        const LoadingIndicator(message: 'Uploading...'),
      );
    }

    try {
      await widget.dataSource.uploadLetter(
        requestId: requestId,
        filePath: filePath,
      );
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Letter uploaded successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadPendingLetters();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pending Letters'),
            Text(
              '${_pendingLetters.length} requests',
              style: AppTextStyles.caption.copyWith(
                  color: AppColors.white.withOpacity(0.9)),
            ),
          ],
        ),
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.white,
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading letter requests...')
          : _pendingLetters.isEmpty
          ? const EmptyState(
        icon: Icons.check_circle_outline,
        title: 'No Pending Requests',
        message: 'All letter requests have been processed',
      )
          : RefreshIndicator(
        onRefresh: _loadPendingLetters,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _pendingLetters.length,
          itemBuilder: (context, index) =>
              _buildLetterCard(_pendingLetters[index]),
        ),
      ),
    );
  }

  Widget _buildLetterCard(Map<String, dynamic> letter) {
    final id = letter['id'].toString();
    final employee =
        letter['employee'] as Map<String, dynamic>? ?? {};
    final firstName = employee['firstName']?.toString() ?? 'Unknown';
    final lastName = employee['lastName']?.toString() ?? '';
    final employeeName = '$firstName $lastName';
    final employeeId = employee['employeeId']?.toString() ?? 'N/A';
    final letterType = letter['letterType']?.toString() ?? 'N/A';

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
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor:
                  AppColors.secondary.withOpacity(0.1),
                  child: Text(
                    firstName.isNotEmpty ? firstName[0] : '?',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(employeeName,
                          style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.bold)),
                      Text(employeeId,
                          style: AppTextStyles.caption),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.description,
                      color: AppColors.secondary, size: 20),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Letter Type',
                        style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary),
                      ),
                      Text(
                        letterType,
                        style: AppTextStyles.titleMedium
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // PDF only — backend serves APPLICATION_PDF
            CustomButton(
              text: 'Upload PDF',
              onPressed: () => _uploadLetter(id, employeeName),
              isFullWidth: true,
              icon: Icons.upload_file,
              backgroundColor: AppColors.secondary,
            ),
          ],
        ),
      ),
    );
  }
}