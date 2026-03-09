import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../data/datasources/letter_remote_data_source.dart';

/// Request Letter Screen
///
/// Employee submits a letter request.
/// Calls POST /letters/request with { letterType, remarks? }
///
/// LetterType enum values (from app_constants.dart):
/// EXPERIENCE, EMPLOYMENT, FORM_16, APPRAISAL

class RequestLetterScreen extends StatefulWidget {
  const RequestLetterScreen({super.key});

  @override
  State<RequestLetterScreen> createState() => _RequestLetterScreenState();
}

class _RequestLetterScreenState extends State<RequestLetterScreen> {
  final _dataSource = LetterRemoteDataSource(dioClient: DioClient());
  final _remarksController = TextEditingController();

  String? _selectedLetterType;
  bool _isLoading = false;

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  // Letter types — IDs match LetterType enum values exactly
  final List<_LetterTypeOption> _letterTypes = [
    _LetterTypeOption(
      id: AppConstants.letterEmployment, // "EMPLOYMENT"
      title: 'Employment Letter',
      description: 'Proof of employment with company details',
      icon: Icons.work,
      color: AppColors.primary,
    ),
    _LetterTypeOption(
      id: AppConstants.letterExperience, // "EXPERIENCE"
      title: 'Experience Letter',
      description: 'Certificate of work experience and skills',
      icon: Icons.verified,
      color: AppColors.success,
    ),
    _LetterTypeOption(
      id: AppConstants.letterAppraisal, // "APPRAISAL"
      title: 'Appraisal Letter',
      description: 'Performance appraisal and review letter',
      icon: Icons.star,
      color: AppColors.warning,
    ),
    _LetterTypeOption(
      id: AppConstants.letterForm16, // "FORM_16"
      title: 'Form 16',
      description: 'TDS certificate for tax filing',
      icon: Icons.receipt_long,
      color: AppColors.secondary,
    ),
  ];

  Future<void> _submitRequest() async {
    if (_selectedLetterType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a letter type'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // POST /letters/request
      // RequestLetterRequest: { letterType (LetterType enum), remarks? }
      await _dataSource.requestLetter(
        letterType: _selectedLetterType!,
        remarks: _remarksController.text.trim().isEmpty
            ? null
            : _remarksController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Letter request submitted successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit: ${e.toString()}'),
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Request Letter'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border:
                Border.all(color: AppColors.info.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: AppColors.info, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Select the type of letter you need. Your request will '
                          'be processed by HR within 2-3 business days.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.info,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Letter type selection
            Text('Select Letter Type', style: AppTextStyles.titleLarge),
            const SizedBox(height: 16),

            ..._letterTypes.map((type) => _buildLetterTypeCard(type)),
            const SizedBox(height: 24),

            // Optional remarks
            Text('Additional Remarks (Optional)',
                style: AppTextStyles.titleMedium),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _remarksController,
              label: 'Remarks',
              hint: 'Any specific requirements or notes for HR...',
              maxLines: 3,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 32),

            CustomButton(
              text: 'Submit Request',
              onPressed: _isLoading ? null : _submitRequest,
              isLoading: _isLoading,
              isFullWidth: true,
              icon: Icons.send,
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: 'Cancel',
              onPressed: _isLoading ? null : () => context.pop(),
              variant: ButtonVariant.secondary,
              isFullWidth: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLetterTypeCard(_LetterTypeOption type) {
    final isSelected = _selectedLetterType == type.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? type.color.withOpacity(0.1)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? type.color : AppColors.border,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedLetterType = type.id),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: type.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(type.icon, color: type.color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(type.title, style: AppTextStyles.titleMedium),
                      const SizedBox(height: 2),
                      Text(type.description, style: AppTextStyles.caption),
                    ],
                  ),
                ),
                isSelected
                    ? Icon(Icons.check_circle,
                    color: type.color, size: 24)
                    : Icon(Icons.circle_outlined,
                    color: AppColors.border, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LetterTypeOption {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _LetterTypeOption({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}