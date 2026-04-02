import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../admin/data/datasources/admin_employee_data_source.dart';
import '../../../admin/data/datasources/admin_payroll_data_source.dart';

class SelectedPdfFile {
  const SelectedPdfFile({
    required this.path,
    required this.name,
  });

  final String path;
  final String name;
}

/// Generator Screen
///
/// Two tabs:
/// 1. Generate Payslip — POST /payroll/generate-payslip
/// 2. Upload Letters   — POST /letters/{id}/upload (multipart PDF)

class GeneratorScreen extends StatefulWidget {
  GeneratorScreen({
    super.key,
    AdminEmployeeSource? employeeDataSource,
    AdminPayrollSource? payrollDataSource,
    Future<SelectedPdfFile?> Function()? pickPdfFile,
  })  : employeeDataSource =
            employeeDataSource ?? AdminEmployeeDataSource(dioClient: DioClient()),
        payrollDataSource =
            payrollDataSource ?? AdminPayrollDataSource(dioClient: DioClient()),
        pickPdfFile = pickPdfFile ?? _defaultPickPdfFile;

  final AdminEmployeeSource employeeDataSource;
  final AdminPayrollSource payrollDataSource;
  final Future<SelectedPdfFile?> Function() pickPdfFile;

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
  State<GeneratorScreen> createState() => _GeneratorScreenState();
}

class _GeneratorScreenState extends State<GeneratorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Generator'),
        backgroundColor: AppColors.success,
        foregroundColor: AppColors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.white,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.white.withOpacity(0.7),
          tabs: const [
            Tab(text: 'Generate Payslip', icon: Icon(Icons.receipt_long)),
            Tab(text: 'Upload Letters', icon: Icon(Icons.upload_file)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          GeneratePayslipTab(
            employeeDataSource: widget.employeeDataSource,
            payrollDataSource: widget.payrollDataSource,
          ),
          UploadLettersTab(
            payrollDataSource: widget.payrollDataSource,
            pickPdfFile: widget.pickPdfFile,
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Generate Payslip Tab
// POST /payroll/generate-payslip
// GeneratePayslipRequest: employeeId (UUID), month (1-12), year (2020-2100)
// ══════════════════════════════════════════════════════════════════════════════

class GeneratePayslipTab extends StatefulWidget {
  const GeneratePayslipTab({
    super.key,
    required this.employeeDataSource,
    required this.payrollDataSource,
  });

  final AdminEmployeeSource employeeDataSource;
  final AdminPayrollSource payrollDataSource;

  @override
  State<GeneratePayslipTab> createState() => _GeneratePayslipTabState();
}

class _GeneratePayslipTabState extends State<GeneratePayslipTab> {
  bool _isLoading = false;
  bool _isLoadingEmployees = false;
  List<dynamic> _employees = [];
  String? _selectedEmployeeUuid; // The UUID 'id' field — required by backend
  Map<String, dynamic>? _selectedEmployee;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    setState(() => _isLoadingEmployees = true);
    try {
      final employees = await widget.employeeDataSource.getAllEmployees();
      setState(() {
        _employees = employees
            .where((emp) => emp['status'] != 'TERMINATED')
            .toList();
        _isLoadingEmployees = false;
      });
    } catch (e) {
      setState(() => _isLoadingEmployees = false);
    }
  }

  Future<void> _generatePayslip() async {
    if (_selectedEmployeeUuid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an employee'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // POST /payroll/generate-payslip
      // GeneratePayslipRequest: employeeId (UUID), month, year
      // NOTE: must send 'id' (UUID), NOT 'employeeId' (e.g. "EMP001")
      // NOTE: workingDays, presentDays, leaveDays do NOT exist in GeneratePayslipRequest
      await widget.payrollDataSource.generatePayslip(
        employeeId: _selectedEmployeeUuid!,
        month: _selectedMonth,
        year: _selectedYear,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Payslip generated for '
                  '${_selectedEmployee!['firstName']} ${_selectedEmployee!['lastName']} '
                  '(${DateFormat('MMMM yyyy').format(DateTime(_selectedYear, _selectedMonth))})',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate payslip: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoadingEmployees
        ? const LoadingIndicator(message: 'Loading employees...')
        : SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.info.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    color: AppColors.info, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Select employee and month/year to generate payslip PDF',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.info),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Select Employee ───────────────────────────────────
          Text('Select Employee',
              style: AppTextStyles.titleMedium),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedEmployeeUuid,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 16),
              hintText: 'Select employee',
            ),
            items: _employees.map((emp) {
              // Use UUID 'id' as value — GeneratePayslipRequest.employeeId is UUID
              return DropdownMenuItem(
                value: emp['id'].toString(),
                child: Text(
                    '${emp['firstName']} ${emp['lastName']} (${emp['employeeId']})'),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedEmployeeUuid = value;
                _selectedEmployee = _employees
                    .firstWhere((e) => e['id'].toString() == value);
              });
            },
          ),
          const SizedBox(height: 16),

          // ── Month / Year ──────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Month',
                        style: AppTextStyles.titleMedium),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: _selectedMonth,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                            borderRadius:
                            BorderRadius.circular(12)),
                      ),
                      items: List.generate(12, (i) {
                        final m = i + 1;
                        return DropdownMenuItem(
                          value: m,
                          child: Text(DateFormat('MMMM')
                              .format(DateTime(2000, m))),
                        );
                      }),
                      onChanged: (v) =>
                          setState(() => _selectedMonth = v!),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Year',
                        style: AppTextStyles.titleMedium),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: _selectedYear,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                            borderRadius:
                            BorderRadius.circular(12)),
                      ),
                      items: List.generate(5, (i) {
                        final y = DateTime.now().year - i;
                        return DropdownMenuItem(
                          value: y,
                          child: Text(y.toString()),
                        );
                      }),
                      onChanged: (v) =>
                          setState(() => _selectedYear = v!),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          CustomButton(
            text: 'Generate Payslip',
            onPressed: _isLoading ? null : _generatePayslip,
            isLoading: _isLoading,
            isFullWidth: true,
            icon: Icons.picture_as_pdf,
            backgroundColor: AppColors.success,
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Upload Letters Tab
// POST /letters/{id}/upload — multipart/form-data with 'file' field (PDF only)
// ══════════════════════════════════════════════════════════════════════════════

class UploadLettersTab extends StatefulWidget {
  const UploadLettersTab({
    super.key,
    required this.payrollDataSource,
    required this.pickPdfFile,
  });

  final AdminPayrollSource payrollDataSource;
  final Future<SelectedPdfFile?> Function() pickPdfFile;

  @override
  State<UploadLettersTab> createState() => _UploadLettersTabState();
}

class _UploadLettersTabState extends State<UploadLettersTab> {
  bool _isLoading = false;
  bool _isLoadingRequests = false;
  List<dynamic> _pendingLetterRequests = [];
  String? _selectedRequestId;
  Map<String, dynamic>? _selectedRequest;
  String? _selectedFilePath;
  String? _selectedFileName;

  @override
  void initState() {
    super.initState();
    _loadPendingRequests();
  }

  Future<void> _loadPendingRequests() async {
    setState(() => _isLoadingRequests = true);
    try {
      final requests = await widget.payrollDataSource.getPendingLetterRequests();
      setState(() {
        _pendingLetterRequests = requests;
        _isLoadingRequests = false;
      });
    } catch (e) {
      setState(() => _isLoadingRequests = false);
    }
  }

  Future<void> _pickFile() async {
    // Backend serves letters as APPLICATION_PDF — only accept PDF
    final result = await widget.pickPdfFile();
    if (result != null) {
      setState(() {
        _selectedFilePath = result.path;
        _selectedFileName = result.name;
      });
    }
  }

  Future<void> _uploadLetter() async {
    if (_selectedRequestId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a letter request'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (_selectedFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a PDF file to upload'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await widget.payrollDataSource.uploadLetter(
        requestId: _selectedRequestId!,
        filePath: _selectedFilePath!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Letter uploaded successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        setState(() {
          _selectedRequestId = null;
          _selectedRequest = null;
          _selectedFilePath = null;
          _selectedFileName = null;
        });
        _loadPendingRequests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoadingRequests
        ? const LoadingIndicator(message: 'Loading pending requests...')
        : SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.info.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    color: AppColors.info, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Select a pending letter request and upload the PDF document',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.info),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text('Select Letter Request',
              style: AppTextStyles.titleMedium),
          const SizedBox(height: 8),

          if (_pendingLetterRequests.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 48, color: AppColors.success),
                  const SizedBox(height: 12),
                  Text('No Pending Requests',
                      style: AppTextStyles.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'All letter requests have been processed',
                    style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          else
            DropdownButtonFormField<String>(
              value: _selectedRequestId,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 16),
                hintText: 'Select request',
              ),
              items: _pendingLetterRequests.map((req) {
                final firstName =
                    req['employee']?['firstName'] ?? 'Unknown';
                final lastName =
                    req['employee']?['lastName'] ?? '';
                final letterType =
                    req['letterType']?.toString() ?? 'Unknown';
                return DropdownMenuItem(
                  value: req['id'].toString(),
                  child: Text('$firstName $lastName — $letterType'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedRequestId = value;
                  _selectedRequest = _pendingLetterRequests
                      .firstWhere((r) => r['id'].toString() == value);
                  // Reset file selection when request changes
                  _selectedFilePath = null;
                  _selectedFileName = null;
                });
              },
            ),

          if (_selectedRequest != null) ...[
            const SizedBox(height: 16),

            // Request Details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Request Details',
                    style: AppTextStyles.titleMedium
                        .copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    'Employee',
                    '${_selectedRequest!['employee']?['firstName']} '
                        '${_selectedRequest!['employee']?['lastName']}',
                  ),
                  _buildDetailRow(
                    'Employee ID',
                    _selectedRequest!['employee']?['employeeId'] ??
                        'N/A',
                  ),
                  _buildDetailRow(
                    'Letter Type',
                    _selectedRequest!['letterType']?.toString() ??
                        'N/A',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── File Picker ─────────────────────────────────────
            Text('Upload PDF Document',
                style: AppTextStyles.titleMedium),
            const SizedBox(height: 8),
            InkWell(
              onTap: _isLoading ? null : _pickFile,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedFilePath == null
                        ? AppColors.border
                        : AppColors.success,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _selectedFilePath == null
                          ? Icons.upload_file
                          : Icons.check_circle,
                      size: 48,
                      color: _selectedFilePath == null
                          ? AppColors.textSecondary
                          : AppColors.success,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _selectedFilePath == null
                          ? 'Tap to select PDF'
                          : 'PDF selected',
                      style: AppTextStyles.titleMedium,
                    ),
                    if (_selectedFileName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _selectedFileName!,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.success),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Only PDF files accepted',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            CustomButton(
              text: 'Upload Letter',
              onPressed: _isLoading ? null : _uploadLetter,
              isLoading: _isLoading,
              isFullWidth: true,
              icon: Icons.cloud_upload,
              backgroundColor: AppColors.success,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodySmall
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}