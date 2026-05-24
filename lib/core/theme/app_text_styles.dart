import 'package:flutter/material.dart';
import 'package:special_coffee/core/theme/app_colors.dart';

abstract final class AppTextStyles {
  // Display — DM Serif Display (headings, screen titles)
  static const TextStyle displayLarge = TextStyle(
    fontFamily: 'DMSerifDisplay',
    fontSize: 36,
    fontWeight: FontWeight.w400,
    color: AppColors.espresso,
    height: 1.2,
  );
  static const TextStyle displayMedium = TextStyle(
    fontFamily: 'DMSerifDisplay',
    fontSize: 28,
    fontWeight: FontWeight.w400,
    color: AppColors.espresso,
    height: 1.25,
  );
  static const TextStyle displaySmall = TextStyle(
    fontFamily: 'DMSerifDisplay',
    fontSize: 22,
    fontWeight: FontWeight.w400,
    color: AppColors.espresso,
    height: 1.3,
  );

  // Body — Inter (all UI text)
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurface,
    height: 1.5,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurface,
    height: 1.5,
  );
  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurfaceVariant,
    height: 1.4,
  );
  static const TextStyle labelLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
    letterSpacing: 0.1,
  );
  static const TextStyle labelMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.onSurfaceVariant,
    letterSpacing: 0.5,
  );
  static const TextStyle labelSmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.onSurfaceVariant,
    letterSpacing: 0.5,
  );

  // Numeric data — JetBrains Mono (pH, TDS, Brix, temperature)
  static const TextStyle numericLarge = TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: 32,
    fontWeight: FontWeight.w500,
    color: AppColors.onSurface,
  );
  static const TextStyle numericMedium = TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: 20,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurface,
  );
  static const TextStyle numericSmall = TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurfaceVariant,
  );

  // AI-specific text styles (always paired with aiBlue color)
  static const TextStyle aiRecommendation = TextStyle(
    fontFamily: 'Inter',
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.aiBlue,
    height: 1.5,
  );
  static const TextStyle aiCaption = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.aiBlue,
  );

  // CTA / Buttons
  static const TextStyle buttonLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );
  static const TextStyle buttonMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );
}
