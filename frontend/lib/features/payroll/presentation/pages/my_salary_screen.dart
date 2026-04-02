import 'package:flutter/material.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../data/datasources/payroll_remote_data_source.dart';

/// My Salary Screen
///
/// Shows detailed salary breakdown.
/// Data from GET /payroll/my-salary → Map<String, Object>
///
/// Backend SalaryResponse fields:
/// basicPay, hra, specialAllowance, otherAllowances,
/// pf, professionalTax, otherDeductions, grossPay, netPay

class MySalaryScreen extends StatefulWidget {
  MySalaryScreen({
    super.key,
    PayrollDataSource? dataSource,
  }) : dataSource = dataSource ??
            PayrollRemoteDataSource(dioClient: DioClient());

  final PayrollDataSource dataSource;

  @override
  State<MySalaryScreen> createState() => _MySalaryScreenState();
}

class _MySalaryScreenState extends State<MySalaryScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _salaryData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSalaryDetails();
  }

  Future<void> _loadSalaryDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await widget.dataSource.getMySalary();
      setState(() {
        _salaryData = data;
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
            content: Text('Failed to load salary: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // ── Safe getters from Map ──────────────────────────────────────────────────

  double _getDouble(String key) =>
      (_salaryData?[key] as num?)?.toDouble() ?? 0.0;

  String _getString(String key) =>
      _salaryData?[key]?.toString() ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Salary'),
        backgroundColor: AppColors.success,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSalaryDetails,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading salary details...')
          : _errorMessage != null
          ? _buildErrorState()
          : _salaryData == null
          ? const Center(child: Text('No salary data available'))
          : RefreshIndicator(
        onRefresh: _loadSalaryDetails,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Net Salary Card ──────────────────────────────
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppColors.successGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      'Net Salary',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '₹${_formatAmount(_getDouble('netPay'))}',
                      style: AppTextStyles.statNumber.copyWith(
                        color: AppColors.white,
                        fontSize: 48,
                      ),
                    ),
                    Text(
                      'Per Month',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Gross / Deductions Summary ───────────────────
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Gross Salary',
                      _getDouble('grossPay'),
                      AppColors.primary,
                      Icons.account_balance_wallet,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      'Deductions',
                      _getDouble('grossPay') -
                          _getDouble('netPay'),
                      AppColors.error,
                      Icons.remove_circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Earnings ─────────────────────────────────────
              Text('Earnings', style: AppTextStyles.titleLarge),
              const SizedBox(height: 12),

              _buildComponentCard(
                'Basic Pay',
                _getDouble('basicPay'),
                Icons.monetization_on,
                AppColors.primary,
              ),
              const SizedBox(height: 8),
              _buildComponentCard(
                'House Rent Allowance (HRA)',
                _getDouble('hra'),
                Icons.home,
                AppColors.primary,
              ),
              const SizedBox(height: 8),
              _buildComponentCard(
                'Special Allowance',
                _getDouble('specialAllowance'),
                Icons.star,
                AppColors.primary,
              ),
              if (_getDouble('otherAllowances') > 0) ...[
                const SizedBox(height: 8),
                _buildComponentCard(
                  'Other Allowances',
                  _getDouble('otherAllowances'),
                  Icons.add_circle_outline,
                  AppColors.primary,
                ),
              ],
              const SizedBox(height: 24),

              // ── Deductions ───────────────────────────────────
              Text('Deductions', style: AppTextStyles.titleLarge),
              const SizedBox(height: 12),

              _buildComponentCard(
                'Provident Fund (PF)',
                _getDouble('pf'),
                Icons.savings,
                AppColors.error,
                isDeduction: true,
              ),
              const SizedBox(height: 8),
              _buildComponentCard(
                'Professional Tax',
                _getDouble('professionalTax'),
                Icons.account_balance,
                AppColors.error,
                isDeduction: true,
              ),
              if (_getDouble('otherDeductions') > 0) ...[
                const SizedBox(height: 8),
                _buildComponentCard(
                  'Other Deductions',
                  _getDouble('otherDeductions'),
                  Icons.remove_circle_outline,
                  AppColors.error,
                  isDeduction: true,
                ),
              ],
              const SizedBox(height: 24),

              // ── Annual CTC ───────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Text(
                      'Annual CTC',
                      style: AppTextStyles.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${_formatAmount(_getDouble('grossPay') * 12)}',
                      style:
                      AppTextStyles.headlineMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Info Note ────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.info.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: AppColors.info, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This is your current salary structure. '
                            'For detailed monthly breakdown, check your payslips.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.info,
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
            Text('Failed to load salary', style: AppTextStyles.titleLarge),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error',
              style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadSalaryDetails,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, double amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            '₹${_formatAmount(amount)}',
            style: AppTextStyles.titleLarge.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(title, style: AppTextStyles.caption, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildComponentCard(
      String title,
      double amount,
      IconData icon,
      Color color, {
        bool isDeduction = false,
      }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: AppTextStyles.bodyMedium)),
          Text(
            '${isDeduction ? '-' : '+'}₹${_formatAmount(amount)}',
            style: AppTextStyles.titleMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  }
}