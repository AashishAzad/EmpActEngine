import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../abstracts/payroll_data_source.dart';
import '../../data/datasources/payroll_remote_data_source.dart';

/// Payslip Detail Screen
///
/// Shows full breakdown of a single payslip.
/// Data from GET /payroll/payslips/{id} → PayslipResponse
///
/// PayslipResponse fields used here:
/// id, month, year, employee (employeeId, firstName, lastName, designation, department)
/// basicPay, hra, specialAllowance, otherAllowances
/// pf, professionalTax, otherDeductions
/// grossPay, netPay
/// totalWorkingDays, daysPresent, daysAbsent, daysOnLeave
/// isGenerated, generatedAt, pdfUrl

class PayslipDetailScreen extends StatefulWidget {
  final String payslipId;

  PayslipDetailScreen({
    super.key,
    required this.payslipId,
    PayrollDataSource? dataSource,
  }) : dataSource = dataSource ??
            PayrollRemoteDataSource(dioClient: DioClient());

  final PayrollDataSource dataSource;

  @override
  State<PayslipDetailScreen> createState() => _PayslipDetailScreenState();
}

class _PayslipDetailScreenState extends State<PayslipDetailScreen> {
  bool _isLoading = false;
  bool _isDownloading = false;
  Map<String, dynamic>? _payslip;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPayslip();
  }

  Future<void> _loadPayslip() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await widget.dataSource.getPayslipById(widget.payslipId);
      setState(() {
        _payslip = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _downloadPayslip() async {
    setState(() => _isDownloading = true);
    try {
      final bytes = await widget.dataSource.downloadPayslip(widget.payslipId);
      final dir = await getApplicationDocumentsDirectory();
      final month = _getInt('month');
      final year = _getInt('year');
      final file = File(
          '${dir.path}/payslip_${_getMonthName(month)}_$year.pdf');
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
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  // ── Safe getters ───────────────────────────────────────────────────────────

  double _getDouble(String key) =>
      (_payslip?[key] as num?)?.toDouble() ?? 0.0;

  int _getInt(String key) =>
      (_payslip?[key] as num?)?.toInt() ?? 0;

  String _getString(String key) =>
      _payslip?[key]?.toString() ?? '';

  Map<String, dynamic> get _employee =>
      (_payslip?['employee'] as Map<String, dynamic>?) ?? {};

  bool get _isGenerated => _payslip?['isGenerated'] as bool? ?? false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Payslip Details'),
        backgroundColor: AppColors.success,
        foregroundColor: AppColors.white,
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading payslip...')
          : _errorMessage != null
          ? _buildErrorState()
          : _payslip == null
          ? const Center(child: Text('Payslip not found'))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header Card ────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.successGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    '${_getMonthName(_getInt('month'))} ${_getInt('year')}',
                    style: AppTextStyles.titleLarge.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_employee['firstName'] ?? ''} ${_employee['lastName'] ?? ''}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.white.withOpacity(0.9),
                    ),
                  ),
                  if (_employee['designation'] != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${_employee['designation']}${_employee['department'] != null ? ' · ${_employee['department']}' : ''}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    '₹${_formatAmount(_getDouble('netPay'))}',
                    style: AppTextStyles.statNumber.copyWith(
                      color: AppColors.white,
                      fontSize: 42,
                    ),
                  ),
                  Text(
                    'Net Pay',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _isGenerated ? 'GENERATED' : 'PENDING',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Attendance Summary ─────────────────────────────
            if (_getInt('totalWorkingDays') > 0) ...[
              Text('Attendance Summary',
                  style: AppTextStyles.titleLarge),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceAround,
                  children: [
                    _buildAttendanceStat(
                      'Working Days',
                      _getInt('totalWorkingDays'),
                      AppColors.primary,
                    ),
                    _buildAttendanceStat(
                      'Present',
                      _getInt('daysPresent'),
                      AppColors.success,
                    ),
                    _buildAttendanceStat(
                      'Absent',
                      _getInt('daysAbsent'),
                      AppColors.error,
                    ),
                    _buildAttendanceStat(
                      'On Leave',
                      _getInt('daysOnLeave'),
                      AppColors.warning,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ── Earnings ───────────────────────────────────────
            Text('Earnings', style: AppTextStyles.titleLarge),
            const SizedBox(height: 12),
            _buildRow('Basic Pay', _getDouble('basicPay')),
            _buildRow('House Rent Allowance (HRA)',
                _getDouble('hra')),
            _buildRow('Special Allowance',
                _getDouble('specialAllowance')),
            if (_getDouble('otherAllowances') > 0)
              _buildRow('Other Allowances',
                  _getDouble('otherAllowances')),
            const Divider(height: 24),
            _buildRow('Gross Pay', _getDouble('grossPay'),
                isBold: true, color: AppColors.primary),
            const SizedBox(height: 24),

            // ── Deductions ─────────────────────────────────────
            Text('Deductions', style: AppTextStyles.titleLarge),
            const SizedBox(height: 12),
            _buildRow('Provident Fund (PF)', _getDouble('pf'),
                isDeduction: true),
            _buildRow('Professional Tax',
                _getDouble('professionalTax'),
                isDeduction: true),
            if (_getDouble('otherDeductions') > 0)
              _buildRow('Other Deductions',
                  _getDouble('otherDeductions'),
                  isDeduction: true),
            const Divider(height: 24),
            _buildRow(
              'Total Deductions',
              _getDouble('grossPay') - _getDouble('netPay'),
              isBold: true,
              isDeduction: true,
              color: AppColors.error,
            ),
            const SizedBox(height: 24),

            // ── Net Pay ────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.success.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Net Pay',
                    style: AppTextStyles.titleLarge.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                  Text(
                    '₹${_formatAmount(_getDouble('netPay'))}',
                    style: AppTextStyles.titleLarge.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Download Button ────────────────────────────────
            if (_isGenerated)
              CustomButton(
                text: _isDownloading
                    ? 'Downloading...'
                    : 'Download Payslip PDF',
                onPressed:
                _isDownloading ? null : _downloadPayslip,
                isLoading: _isDownloading,
                icon: Icons.download,
                isFullWidth: true,
                variant: ButtonVariant.primary,
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.warning.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: AppColors.warning),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This payslip has not been generated yet. '
                            'Contact HR for more information.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceStat(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: AppTextStyles.headlineMedium.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildRow(
      String label,
      double amount, {
        bool isBold = false,
        bool isDeduction = false,
        Color? color,
      }) {
    final displayColor = color ??
        (isDeduction ? AppColors.error : AppColors.textPrimary);
    final style = isBold
        ? AppTextStyles.titleMedium.copyWith(color: displayColor)
        : AppTextStyles.bodyMedium.copyWith(color: displayColor);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(
            '${isDeduction ? '-' : ''}₹${_formatAmount(amount)}',
            style: style.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Failed to load payslip', style: AppTextStyles.titleLarge),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadPayslip,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    if (month < 1 || month > 12) return 'Unknown';
    return months[month - 1];
  }

  String _formatAmount(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  }
}