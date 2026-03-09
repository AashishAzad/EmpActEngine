import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../data/datasources/payroll_remote_data_source.dart';

/// Payslips Screen
///
/// List of all monthly payslips.
/// Data from GET /payroll/my-payslips → PagedResponse<PayslipResponse>
///
/// PayslipResponse fields:
/// id, employeeId, employee, month, year,
/// basicPay, hra, specialAllowance, otherAllowances,
/// pf, professionalTax, otherDeductions,
/// grossPay, netPay,
/// totalWorkingDays, daysPresent, daysAbsent, daysOnLeave,
/// pdfUrl, isGenerated, generatedAt, createdAt, updatedAt

class PayslipsScreen extends StatefulWidget {
  const PayslipsScreen({super.key});

  @override
  State<PayslipsScreen> createState() => _PayslipsScreenState();
}

class _PayslipsScreenState extends State<PayslipsScreen> {
  final _dataSource = PayrollRemoteDataSource(dioClient: DioClient());

  bool _isLoading = false;
  List<Map<String, dynamic>> _payslips = [];
  String? _errorMessage;

  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoadingMore = false;

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadPayslips();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _currentPage < _totalPages) {
      _loadMorePayslips();
    }
  }

  Future<void> _loadPayslips() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentPage = 1;
    });

    try {
      // GET /payroll/my-payslips → PagedResponse<PayslipResponse>
      final result = await _dataSource.getMyPayslips(page: 1);

      final data = result['data'] as List<dynamic>? ?? [];
      final totalPages = (result['totalPages'] as num?)?.toInt() ?? 1;

      setState(() {
        _payslips = data.cast<Map<String, dynamic>>();
        _totalPages = totalPages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load payslips: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _loadMorePayslips() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);

    try {
      final nextPage = _currentPage + 1;
      final result = await _dataSource.getMyPayslips(page: nextPage);
      final data = result['data'] as List<dynamic>? ?? [];

      setState(() {
        _payslips.addAll(data.cast<Map<String, dynamic>>());
        _currentPage = nextPage;
        _isLoadingMore = false;
      });
    } catch (_) {
      setState(() => _isLoadingMore = false);
    }
  }

  // ── Safe getters from Map ──────────────────────────────────────────────────

  double _getDouble(Map<String, dynamic> map, String key) =>
      (map[key] as num?)?.toDouble() ?? 0.0;

  int _getInt(Map<String, dynamic> map, String key) =>
      (map[key] as num?)?.toInt() ?? 0;

  String _getString(Map<String, dynamic> map, String key) =>
      map[key]?.toString() ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Payslips'),
        backgroundColor: AppColors.success,
        foregroundColor: AppColors.white,
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading payslips...')
          : _errorMessage != null
          ? _buildErrorState()
          : _payslips.isEmpty
          ? const EmptyState(
        icon: Icons.receipt_long,
        title: 'No Payslips',
        message: 'No payslips available yet',
      )
          : RefreshIndicator(
        onRefresh: _loadPayslips,
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount:
          _payslips.length + (_isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _payslips.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                    child: CircularProgressIndicator()),
              );
            }
            return _buildPayslipCard(_payslips[index]);
          },
        ),
      ),
    );
  }

  Widget _buildPayslipCard(Map<String, dynamic> payslip) {
    final isGenerated = payslip['isGenerated'] as bool? ?? false;
    final statusColor = isGenerated ? AppColors.success : AppColors.warning;
    final statusText = isGenerated ? 'GENERATED' : 'PENDING';

    final month = _getInt(payslip, 'month');
    final year = _getInt(payslip, 'year');
    final grossPay = _getDouble(payslip, 'grossPay');
    final netPay = _getDouble(payslip, 'netPay');
    final deductions = grossPay - netPay;
    final payslipId = _getString(payslip, 'id');
    final generatedAt = payslip['generatedAt'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/payroll/payslips/$payslipId'),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ────────────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.receipt_long,
                          color: AppColors.success, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getMonthName(month),
                            style: AppTextStyles.titleMedium,
                          ),
                          Text(
                            year.toString(),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusText,
                        style: AppTextStyles.caption.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Salary amounts ─────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem(
                          'Gross', grossPay, AppColors.primary),
                    ),
                    Expanded(
                      child: _buildDetailItem(
                          'Deductions', deductions, AppColors.error),
                    ),
                    Expanded(
                      child: _buildDetailItem(
                          'Net', netPay, AppColors.success),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Footer ─────────────────────────────────────────────────
                Row(
                  children: [
                    if (generatedAt != null) ...[
                      Icon(Icons.check_circle,
                          size: 14, color: AppColors.success),
                      const SizedBox(width: 4),
                      Text(
                        'Generated ${_formatDateString(generatedAt)}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.success,
                        ),
                      ),
                    ] else ...[
                      Icon(Icons.pending, size: 14, color: AppColors.warning),
                      const SizedBox(width: 4),
                      Text(
                        'Not yet generated',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      'View Details',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios,
                        size: 12, color: AppColors.primary),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, double amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: 4),
        Text(
          '₹${_formatAmount(amount)}',
          style: AppTextStyles.bodyMedium.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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
            Text('Failed to load payslips', style: AppTextStyles.titleLarge),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadPayslips,
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

  /// Backend sends LocalDateTime as "2026-01-28T00:00:00" — format for display
  String _formatDateString(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }

  String _formatAmount(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  }
}