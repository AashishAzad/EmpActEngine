import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Loading Indicator Widget
///
/// Variants:
/// - Circular (default)
/// - Linear
/// - Overlay (full screen with background)
/// - Small (for buttons)

enum LoadingVariant { circular, linear, overlay, small }

class LoadingIndicator extends StatelessWidget {
  final LoadingVariant variant;
  final String? message;
  final Color? color;
  final double? size;

  const LoadingIndicator({
    super.key,
    this.variant = LoadingVariant.circular,
    this.message,
    this.color,
    this.size,
  });

  const LoadingIndicator.overlay({
    super.key,
    this.message,
  })  : variant = LoadingVariant.overlay,
        color = null,
        size = null;

  const LoadingIndicator.small({
    super.key,
    this.color,
  })  : variant = LoadingVariant.small,
        message = null,
        size = 20;

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case LoadingVariant.circular:
        return _buildCircular();
      case LoadingVariant.linear:
        return _buildLinear();
      case LoadingVariant.overlay:
        return _buildOverlay();
      case LoadingVariant.small:
        return _buildSmall();
    }
  }

  Widget _buildCircular() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size ?? 40,
            height: size ?? 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                color ?? AppColors.primary,
              ),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLinear() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        LinearProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            color ?? AppColors.primary,
          ),
          backgroundColor: AppColors.primaryLight.withOpacity(0.2),
        ),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildOverlay() {
    return Container(
      color: AppColors.overlay,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(
                  message!,
                  style: AppTextStyles.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmall() {
    return SizedBox(
      width: size ?? 20,
      height: size ?? 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? AppColors.primary,
        ),
      ),
    );
  }
}

/// Loading Overlay
///
/// Shows a loading overlay over the entire screen
/// Usage: showLoadingOverlay(context, message: 'Please wait...');

void showLoadingOverlay(
    BuildContext context, {
      String? message,
    }) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => LoadingIndicator.overlay(message: message),
  );
}

void hideLoadingOverlay(BuildContext context) {
  Navigator.of(context).pop();
}