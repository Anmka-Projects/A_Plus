import 'package:flutter/material.dart';

/// App Text Styles - Indigo & Radlush families
class AppTextStyles {
  AppTextStyles._();

  static const String indigoFamily = 'Indigo';
  static const String radlushFamily = 'Radlush';

  /// Base TextTheme used by the app
  static TextTheme textTheme = const TextTheme(
    displayLarge: TextStyle(
      fontFamily: indigoFamily,
      fontWeight: FontWeight.w400,
    ),
    displayMedium: TextStyle(
      fontFamily: indigoFamily,
      fontWeight: FontWeight.w400,
    ),
    titleLarge: TextStyle(
      fontFamily: radlushFamily,
      fontWeight: FontWeight.w900,
    ),
    titleMedium: TextStyle(
      fontFamily: radlushFamily,
      fontWeight: FontWeight.w700,
    ),
    titleSmall: TextStyle(
      fontFamily: radlushFamily,
      fontWeight: FontWeight.w500,
    ),
    bodyMedium: TextStyle(
      fontFamily: radlushFamily,
      fontWeight: FontWeight.w400,
    ),
    bodySmall: TextStyle(
      fontFamily: radlushFamily,
      fontWeight: FontWeight.w400,
    ),
    labelLarge: TextStyle(
      fontFamily: radlushFamily,
      fontWeight: FontWeight.w700,
    ),
  );

  /// Helper to apply color while keeping the shared structure
  static TextTheme themed(TextTheme base, {Color? color}) {
    if (color == null) return base;
    return base.apply(
      bodyColor: color,
      displayColor: color,
    );
  }

  // Convenience styles for direct usage in widgets

  // Headings (map to Indigo display styles)
  static TextStyle h1({Color? color}) => TextStyle(
        fontFamily: indigoFamily,
        fontWeight: FontWeight.w400,
        fontSize: 32,
        color: color,
      );

  static TextStyle h2({Color? color}) => TextStyle(
        fontFamily: indigoFamily,
        fontWeight: FontWeight.w400,
        fontSize: 24,
        color: color,
      );

  static TextStyle h3({Color? color}) => TextStyle(
        fontFamily: indigoFamily,
        fontWeight: FontWeight.w400,
        fontSize: 20,
        color: color,
      );

  static TextStyle h4({Color? color}) => TextStyle(
        fontFamily: indigoFamily,
        fontWeight: FontWeight.w400,
        fontSize: 18,
        color: color,
      );

  // Body text (Radlush)
  static TextStyle bodyLarge({Color? color}) => TextStyle(
        fontFamily: radlushFamily,
        fontWeight: FontWeight.w400,
        fontSize: 16,
        color: color,
      );

  static TextStyle bodyMedium({Color? color}) => TextStyle(
        fontFamily: radlushFamily,
        fontWeight: FontWeight.w400,
        fontSize: 14,
        color: color,
      );

  static TextStyle bodySmall({Color? color}) => TextStyle(
        fontFamily: radlushFamily,
        fontWeight: FontWeight.w400,
        fontSize: 12,
        color: color,
      );

  // Labels (Radlush)
  static TextStyle labelLarge({Color? color}) => TextStyle(
        fontFamily: radlushFamily,
        fontWeight: FontWeight.w700,
        fontSize: 14,
        color: color,
      );

  static TextStyle labelMedium({Color? color}) => TextStyle(
        fontFamily: radlushFamily,
        fontWeight: FontWeight.w500,
        fontSize: 12,
        color: color,
      );

  static TextStyle labelSmall({Color? color}) => TextStyle(
        fontFamily: radlushFamily,
        fontWeight: FontWeight.w500,
        fontSize: 10,
        color: color,
      );

  // Buttons (Radlush)
  static TextStyle buttonLarge({Color? color}) => TextStyle(
        fontFamily: radlushFamily,
        fontWeight: FontWeight.w700,
        fontSize: 18,
        color: color,
      );

  static TextStyle buttonMedium({Color? color}) => TextStyle(
        fontFamily: radlushFamily,
        fontWeight: FontWeight.w600,
        fontSize: 16,
        color: color,
      );

  static TextStyle buttonSmall({Color? color}) => TextStyle(
        fontFamily: radlushFamily,
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: color,
      );
}
