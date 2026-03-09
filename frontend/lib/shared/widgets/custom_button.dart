import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Custom Button Widget
///
/// Reusable button with different variants:
/// - Primary (filled with color)
/// - Secondary (outlined)
/// - Text (no background)
/// - Icon (with icon)

enum ButtonVariant { primary, secondary, text, icon }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final double? height;
  final EdgeInsetsGeometry? padding;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.height,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingButton();
    }

    switch (variant) {
      case ButtonVariant.primary:
        return _buildPrimaryButton();
      case ButtonVariant.secondary:
        return _buildSecondaryButton();
      case ButtonVariant.text:
        return _buildTextButton();
      case ButtonVariant.icon:
        return _buildIconButton();
    }
  }

  // ========== PRIMARY BUTTON ==========
  Widget _buildPrimaryButton() {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: height ?? 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.primary,
          foregroundColor: textColor ?? AppColors.white,
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: icon != null
            ? Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(
              text,
              style: AppTextStyles.button.copyWith(
                color: textColor ?? AppColors.white,
              ),
            ),
          ],
        )
            : Text(
          text,
          style: AppTextStyles.button.copyWith(
            color: textColor ?? AppColors.white,
          ),
        ),
      ),
    );
  }

  // ========== SECONDARY BUTTON ==========
  Widget _buildSecondaryButton() {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: height ?? 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: backgroundColor ?? AppColors.primary,
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(
            color: backgroundColor ?? AppColors.primary,
            width: 1.5,
          ),
        ),
        child: icon != null
            ? Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(
              text,
              style: AppTextStyles.button.copyWith(
                color: backgroundColor ?? AppColors.primary,
              ),
            ),
          ],
        )
            : Text(
          text,
          style: AppTextStyles.button.copyWith(
            color: backgroundColor ?? AppColors.primary,
          ),
        ),
      ),
    );
  }

  // ========== TEXT BUTTON ==========
  Widget _buildTextButton() {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: height ?? 50,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: backgroundColor ?? AppColors.primary,
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: icon != null
            ? Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(
              text,
              style: AppTextStyles.button.copyWith(
                color: backgroundColor ?? AppColors.primary,
              ),
            ),
          ],
        )
            : Text(
          text,
          style: AppTextStyles.button.copyWith(
            color: backgroundColor ?? AppColors.primary,
          ),
        ),
      ),
    );
  }

  // ========== ICON BUTTON ==========
  Widget _buildIconButton() {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: height ?? 50,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(
          text,
          style: AppTextStyles.button.copyWith(
            color: textColor ?? AppColors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.primary,
          foregroundColor: textColor ?? AppColors.white,
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  // ========== LOADING BUTTON ==========
  Widget _buildLoadingButton() {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: height ?? 50,
      child: ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.primary,
          disabledBackgroundColor:
          (backgroundColor ?? AppColors.primary).withOpacity(0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
          ),
        ),
      ),
    );
  }
}

/// Small Custom Button (for compact spaces)
class SmallButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? backgroundColor;

  const SmallButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? AppColors.primary,
        foregroundColor: AppColors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minimumSize: const Size(0, 36),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: icon != null
          ? Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTextStyles.buttonSmall,
          ),
        ],
      )
          : Text(
        text,
        style: AppTextStyles.buttonSmall,
      ),
    );
  }
}