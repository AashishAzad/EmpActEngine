import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Base text style with Poppins font
  static TextStyle _baseTextStyle = GoogleFonts.poppins();

  // Display Styles (Large headings)
  static TextStyle displayLarge = _baseTextStyle.copyWith(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static TextStyle displayMedium = _baseTextStyle.copyWith(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static TextStyle displaySmall = _baseTextStyle.copyWith(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  // Headline Styles (Section headers)
  static TextStyle headlineLarge = _baseTextStyle.copyWith(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static TextStyle headlineMedium = _baseTextStyle.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static TextStyle headlineSmall = _baseTextStyle.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  // Title Styles (Card headers, list items)
  static TextStyle titleLarge = _baseTextStyle.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static TextStyle titleMedium = _baseTextStyle.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static TextStyle titleSmall = _baseTextStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  // Body Styles (Regular text)
  static TextStyle bodyLarge = _baseTextStyle.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static TextStyle bodyMedium = _baseTextStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static TextStyle bodySmall = _baseTextStyle.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  // Label Styles (Buttons, chips, badges)
  static TextStyle labelLarge = _baseTextStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.4,
    letterSpacing: 0.1,
  );

  static TextStyle labelMedium = _baseTextStyle.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.4,
    letterSpacing: 0.5,
  );

  static TextStyle labelSmall = _baseTextStyle.copyWith(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.4,
    letterSpacing: 0.5,
  );

  // Caption Styles (Helper text, metadata)
  static TextStyle caption = _baseTextStyle.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static TextStyle captionSmall = _baseTextStyle.copyWith(
    fontSize: 10,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  // Button Styles
  static TextStyle button = _baseTextStyle.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
    height: 1.2,
    letterSpacing: 0.5,
  );

  static TextStyle buttonSmall = _baseTextStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
    height: 1.2,
    letterSpacing: 0.5,
  );

  // Special Styles
  static TextStyle overline = _baseTextStyle.copyWith(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.6,
    letterSpacing: 1.5,
  );

  static TextStyle subtitle = _baseTextStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  // Input Field Styles
  static TextStyle inputText = _baseTextStyle.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static TextStyle inputLabel = _baseTextStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static TextStyle inputHint = _baseTextStyle.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textHint,
    height: 1.5,
  );

  static TextStyle inputError = _baseTextStyle.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.error,
    height: 1.4,
  );

  // Number/Stat Styles
  static TextStyle statNumber = _baseTextStyle.copyWith(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
    height: 1.2,
  );

  static TextStyle statLabel = _baseTextStyle.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  // Link Style
  static TextStyle link = _baseTextStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.primary,
    height: 1.4,
    decoration: TextDecoration.underline,
  );

  // Error Style
  static TextStyle error = _baseTextStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.error,
    height: 1.4,
  );

  // Success Style
  static TextStyle success = _baseTextStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.success,
    height: 1.4,
  );

  // Warning Style
  static TextStyle warning = _baseTextStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.warning,
    height: 1.4,
  );

  // Dark Theme Variants (for use in dark mode)
  static TextStyle get displayLargeDark => displayLarge.copyWith(
    color: AppColors.textPrimaryDark,
  );

  static TextStyle get headlineLargeDark => headlineLarge.copyWith(
    color: AppColors.textPrimaryDark,
  );

  static TextStyle get titleLargeDark => titleLarge.copyWith(
    color: AppColors.textPrimaryDark,
  );

  static TextStyle get bodyLargeDark => bodyLarge.copyWith(
    color: AppColors.textPrimaryDark,
  );

  static TextStyle get bodyMediumDark => bodyMedium.copyWith(
    color: AppColors.textPrimaryDark,
  );

  static TextStyle get captionDark => caption.copyWith(
    color: AppColors.textSecondaryDark,
  );
}