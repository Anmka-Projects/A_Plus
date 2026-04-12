import 'package:flutter/material.dart';

/// App colors — A Plus brand (teal palette from splash / marketing).
class AppColors {
  AppColors._();

  // --- Brand teal (from splash screen reference) ---
  /// Primary brand teal (logo / key actions).
  static const Color brandTeal = Color(0xFF139487);
  /// Bright cyan top of splash gradient.
  static const Color brandTealLight = Color(0xFF21D4C3);
  /// Deep teal bottom of splash gradient.
  static const Color brandTealDark = Color(0xFF083B3E);
  /// Deep shadow tone used behind logo / dark accents.
  static const Color brandTealShadow = Color(0xFF042D30);

  /// Legacy duo used across screens for two-tone gradients and tints.
  /// Maps to light + mid teal (replaces former blue / purple pair).
  static const Color brandBlue = brandTealLight;
  static const Color brandPurple = brandTeal;

  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color brandDark = brandTealShadow;

  // Base surfaces & text
  static const Color background = Color(0xFFF5FBFA);
  static const Color foreground = brandTealShadow;
  static const Color card = pureWhite;
  static const Color cardForeground = brandTealShadow;

  // Primary / secondary (theme + components)
  static const Color primary = brandTeal;
  static const Color primaryForeground = pureWhite;
  static const Color primaryDark = Color(0xFF0E6B61);
  static const Color primaryLight = Color(0xFF3EC4B6);

  /// App bars, strong headers — deep teal on white icons/text.
  static const Color secondary = brandTealDark;
  static const Color secondaryForeground = pureWhite;
  static const Color secondaryLight = Color(0xFF0F8A7D);

  /// Legacy alias (`AppColors.purple`).
  static const Color purple = brandTeal;

  // Accent (highlights; still readable on white)
  static const Color accent = brandTealLight;
  static const Color accentForeground = brandTealShadow;
  static const Color accentDark = Color(0xFF1BA99A);
  static const Color accentLight = Color(0xFF5FD4C8);

  // Muted
  static const Color muted = Color(0xFFE8F3F1);
  static const Color mutedForeground = Color(0xFF5C7A76);

  // Border & input
  static const Color border = Color(0xFFC5DDD8);
  static const Color input = pureWhite;
  static const Color ring = brandTeal;

  // Dark theme surfaces (teal-tinted, not blue-gray)
  static const Color dark = Color(0xFF052429);
  static const Color darkCard = Color(0xFF083B3E);
  static const Color beige = pureWhite;
  static const Color beigeDark = Color(0xFFECF8F6);

  // Gradients (splash + shared marketing headers)
  static const Color gradientStart = brandTealLight;
  static const Color gradientEnd = brandTealDark;
  static const List<Color> brandGradient = [
    gradientStart,
    gradientEnd,
  ];

  /// Same as [brandGradient]; vertical splash background.
  static const List<Color> splashGradient = brandGradient;

  static const List<Color> primaryShadeGradient = [
    primaryDark,
    primaryLight,
  ];

  // Semantic
  static const Color destructive = Color(0xFFE53E3E);
  static const Color destructiveForeground = pureWhite;
  static const Color success = Color(0xFF0D9488);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = brandTealLight;

  // Bottom navigation
  static const Color bottomNavBackground = brandTealShadow;
  static const Color bottomNavActive = pureWhite;
  static const Color bottomNavInactive = Color(0xFF9CA3AF);

  // Overlays
  static const Color whiteOverlay10 = Color(0x1AFFFFFF);
  static const Color whiteOverlay20 = Color(0x33FFFFFF);
  static const Color whiteOverlay40 = Color(0x66FFFFFF);
  static const Color blackOverlay20 = Color(0x33000000);

  // Legacy names (const, still referenced)
  static const Color berkeleyBlue = brandTealLight;
  static const Color fireEngineRed = Color(0xFFCE2029);
  static const Color orange = Color(0xFFEA580C);
  static const Color orangeLight = Color(0xFFFFEDD5);
  static const Color lavenderLight = Color(0xFFECFDFB);
  static const Color purpleLight = Color(0xFFE0F7F4);
}
