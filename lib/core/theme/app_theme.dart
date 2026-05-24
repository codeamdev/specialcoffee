import 'package:flutter/material.dart';
import 'package:special_coffee/core/theme/app_colors.dart';
import 'package:special_coffee/core/theme/app_text_styles.dart';

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: AppColors.caramel,
          onPrimary: Colors.white,
          primaryContainer: AppColors.parchment,
          onPrimaryContainer: AppColors.espresso,
          secondary: AppColors.espresso,
          onSecondary: Colors.white,
          secondaryContainer: AppColors.espressoLight,
          onSecondaryContainer: AppColors.cream,
          tertiary: AppColors.aiBlue,
          onTertiary: Colors.white,
          tertiaryContainer: AppColors.aiBlueContainer,
          onTertiaryContainer: AppColors.aiBlue,
          error: AppColors.error,
          onError: Colors.white,
          errorContainer: AppColors.errorContainer,
          surface: AppColors.surface,
          onSurface: AppColors.onSurface,
          onSurfaceVariant: AppColors.onSurfaceVariant,
          outline: AppColors.outline,
          outlineVariant: AppColors.outlineVariant,
        ),
        scaffoldBackgroundColor: AppColors.surface,
        fontFamily: 'Inter',
        textTheme: const TextTheme(
          displayLarge: AppTextStyles.displayLarge,
          displayMedium: AppTextStyles.displayMedium,
          displaySmall: AppTextStyles.displaySmall,
          bodyLarge: AppTextStyles.bodyLarge,
          bodyMedium: AppTextStyles.bodyMedium,
          bodySmall: AppTextStyles.bodySmall,
          labelLarge: AppTextStyles.labelLarge,
          labelMedium: AppTextStyles.labelMedium,
          labelSmall: AppTextStyles.labelSmall,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.onSurface,
          elevation: 0,
          scrolledUnderElevation: 1,
          titleTextStyle: AppTextStyles.displaySmall,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.outlineVariant),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.caramel,
            foregroundColor: Colors.white,
            textStyle: AppTextStyles.buttonLarge,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.caramel,
            textStyle: AppTextStyles.buttonLarge,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            side: const BorderSide(color: AppColors.caramel),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.caramel,
            textStyle: AppTextStyles.buttonMedium,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.outlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.caramel, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.disabled,
          ),
          labelStyle: AppTextStyles.labelMedium,
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.divider,
          thickness: 1,
          space: 1,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.caramel,
          unselectedItemColor: AppColors.outline,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: AppColors.parchment,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: AppColors.caramel);
            }
            return const IconThemeData(color: AppColors.outline);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppTextStyles.labelSmall.copyWith(color: AppColors.caramel);
            }
            return AppTextStyles.labelSmall;
          }),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.surfaceVariant,
          selectedColor: AppColors.parchment,
          labelStyle: AppTextStyles.labelMedium,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: AppColors.espresso,
          contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
        ),
      );

  static ThemeData get dark => light.copyWith(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.espresso,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.caramel,
          onPrimary: AppColors.espresso,
          secondary: AppColors.cream,
          surface: AppColors.espressoLight,
          onSurface: AppColors.cream,
        ),
      );
}
