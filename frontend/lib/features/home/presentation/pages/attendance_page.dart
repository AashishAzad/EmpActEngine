import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/custom_button.dart';

/// Attendance Page
///
/// Shows attendance status and mark attendance option

class AttendancePage extends StatelessWidget {
  const AttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Attendance'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_on,
                size: 80,
                color: AppColors.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Mark Your Attendance',
                style: AppTextStyles.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Use GPS location to mark your attendance for today',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: 'Mark Attendance',
                onPressed: () {
                  context.push('/attendance/mark');
                },
                icon: Icons.location_on,
                isFullWidth: true,
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: 'View History',
                onPressed: () {
                  context.push('/attendance/history');
                },
                variant: ButtonVariant.secondary,
                icon: Icons.history,
                isFullWidth: true,
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: 'Manual Request',
                onPressed: () {
                  context.push('/attendance/manual-request');
                },
                variant: ButtonVariant.text,
                icon: Icons.edit_calendar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}