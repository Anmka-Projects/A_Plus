import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_radius.dart';
import '../../models/app_config.dart';

/// App Theme Configuration
class AppTheme {
  AppTheme._();

  static ThemeData lightTheme([ThemeConfig? themeConfig]) {
    // Use API config colors if provided, otherwise use default AppColors
    final primaryColor = themeConfig?.getPrimaryColor() ?? AppColors.primary;
    final secondaryColor =
        themeConfig?.getSecondaryColor() ?? AppColors.secondary;
    final cardColor = themeConfig?.getCardColor() ?? AppColors.card;
    final backgroundColor =
        themeConfig?.getBackgroundColor() ?? AppColors.background;
    final errorColor = themeConfig?.getErrorColor() ?? AppColors.destructive;
    final textColor = themeConfig?.getTextColor() ?? AppColors.foreground;

    return ThemeData(
      useMaterial3: true,
      fontFamily: AppTextStyles.indigoFamily,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: cardColor,
        onPrimary: AppColors.primaryForeground,
        onSecondary: AppColors.secondaryForeground,
        onSurface: textColor,
        error: errorColor,
        onError: AppColors.destructiveForeground,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: secondaryColor,
        foregroundColor: AppColors.secondaryForeground,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.secondaryForeground),
        titleTextStyle: const TextStyle(
          fontFamily: AppTextStyles.indigoFamily,
          color: AppColors.secondaryForeground,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      scaffoldBackgroundColor: backgroundColor,
      textTheme: GoogleFonts.cairoTextTheme(
        AppTextStyles.themed(
          AppTextStyles.textTheme,
          color: textColor,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardBorderRadius,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.primaryForeground,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.buttonBorderRadius,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.primaryForeground,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.buttonBorderRadius,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.input,
        border: OutlineInputBorder(
          borderRadius: AppRadius.inputBorderRadius,
          borderSide: BorderSide(color: secondaryColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputBorderRadius,
          borderSide: BorderSide(color: secondaryColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputBorderRadius,
          borderSide: BorderSide(
            color: secondaryColor,
            width: 2,
          ),
        ),
      ),
    );
  }

  static ThemeData darkTheme([ThemeConfig? themeConfig]) {
    // Use API config colors if provided, otherwise use default AppColors
    final primaryColor = themeConfig?.getPrimaryColor() ?? AppColors.primary;
    final secondaryColor =
        themeConfig?.getSecondaryColor() ?? AppColors.secondary;
    final cardColor = themeConfig?.getCardColor() ?? AppColors.darkCard;
    final backgroundColor = themeConfig?.getBackgroundColor() ?? AppColors.dark;
    final errorColor = themeConfig?.getErrorColor() ?? AppColors.destructive;
    final textColor = themeConfig?.getTextColor() ?? Colors.white;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: AppTextStyles.indigoFamily,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: cardColor,
        onPrimary: AppColors.primaryForeground,
        onSecondary: AppColors.secondaryForeground,
        onSurface: textColor,
        error: errorColor,
        onError: AppColors.destructiveForeground,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: secondaryColor,
        foregroundColor: AppColors.secondaryForeground,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.secondaryForeground),
        titleTextStyle: const TextStyle(
          fontFamily: AppTextStyles.indigoFamily,
          color: AppColors.secondaryForeground,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      scaffoldBackgroundColor: backgroundColor,
      textTheme: GoogleFonts.cairoTextTheme(
        AppTextStyles.themed(
          AppTextStyles.textTheme,
          color: textColor,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardBorderRadius,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.primaryForeground,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.buttonBorderRadius,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.primaryForeground,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.buttonBorderRadius,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: AppRadius.inputBorderRadius,
          borderSide: BorderSide(color: secondaryColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputBorderRadius,
          borderSide: BorderSide(color: secondaryColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputBorderRadius,
          borderSide: BorderSide(
            color: secondaryColor,
            width: 2,
          ),
        ),
      ),
    );
  }
}
