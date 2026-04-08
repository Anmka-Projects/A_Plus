import 'package:flutter/material.dart';

/// App Colors - Extracted from A Plus app logo
class AppColors {
  AppColors._();

  // Core brand palette
  static const Color brandBlue =
      Color(0xFF2474E8); // Left stroke of "A" - primary blue
  static const Color brandPurple =
      Color(0xFF8B35D6); // Right stroke of "A" - purple accent
  static const Color brandGreen =
      Color(0xFF4DC85A); // Plus (+) sign - green highlight
  static const Color brandDark = Color(0xFF3D4A5C); // "A Plus" wordmark text
  static const Color pureWhite = Color(0xFFFFFFFF); // Background / surfaces

  // Base surfaces & text
  static const Color background = pureWhite;
  static const Color foreground = brandDark;
  static const Color card = pureWhite;
  static const Color cardForeground = brandDark;

  // Primary colors (Purple)
  static const Color primary = brandPurple;
  static const Color primaryForeground = pureWhite;
  static const Color primaryDark =
      Color(0xFF5E1FA0); // Darker shade of brandPurple
  static const Color primaryLight =
      Color(0xFFAB65EE); // Lighter shade of brandPurple

  // Secondary colors (Blue)
  static const Color secondary = brandBlue;
  static const Color secondaryForeground = pureWhite;
  static const Color secondaryLight = Color(0xFF5B9EF5); // Lighter blue

  /// Legacy alias used across the app (`AppColors.purple`).
  static const Color purple = brandPurple;

  // Accent colors (Green - plus sign)
  static const Color accent = brandGreen;
  static const Color accentForeground = pureWhite;
  static const Color accentDark = Color(0xFF2E9E3A); // Darker green
  static const Color accentLight = Color(0xFF80DC88); // Lighter green

  // Muted colors
  static const Color muted = Color(0xFFE4E7EC);
  static const Color mutedForeground = Color(0xFF667085);

  // Border & Input
  static const Color border = Color(0xFFD0D5DD);
  static const Color input = pureWhite;
  static const Color ring = brandPurple;

  // Surface variants
  /// Dark theme scaffold background (pairs with [darkCard]).
  static const Color dark = Color(0xFF0F172A);
  static const Color darkCard = Color(0xFF111827);
  static const Color beige = pureWhite;
  static const Color beigeDark = Color(0xFFF3F4F6);

  // Gradient helpers (brand blue -> purple)
  static const Color gradientStart = brandBlue;
  static const Color gradientEnd = brandPurple;
  static const List<Color> brandGradient = [
    gradientStart,
    gradientEnd,
  ];

  /// Purple-only gradient (depth), for surfaces that should not mix in logo blue.
  static const List<Color> primaryShadeGradient = [
    primaryDark,
    primaryLight,
  ];

  // Semantic colors
  static const Color destructive = Color(0xFFE53E3E);
  static const Color destructiveForeground = pureWhite;
  static const Color success = brandGreen; // reuse logo green
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = brandBlue; // reuse logo blue

  // Bottom navigation
  static const Color bottomNavBackground = Color(0xFF1A1A1A);
  static const Color bottomNavActive = pureWhite;
  static const Color bottomNavInactive = Color(0xFF9CA3AF);

  // Overlay colors
  static const Color whiteOverlay10 = Color(0x1AFFFFFF);
  static const Color whiteOverlay20 = Color(0x33FFFFFF);
  static const Color whiteOverlay40 = Color(0x66FFFFFF);
  static const Color blackOverlay20 = Color(0x33000000);

  // ---------------------------------------------------------------------------
  // Legacy names still referenced across the codebase (must be const Colors).
  // ---------------------------------------------------------------------------
  static const Color berkeleyBlue = brandBlue;
  static const Color fireEngineRed = Color(0xFFCE2029);
  static const Color orange = Color(0xFFEA580C);
  static const Color orangeLight = Color(0xFFFFEDD5);
  static const Color lavenderLight = Color(0xFFF5F3FF);
  static const Color purpleLight = Color(0xFFEDE9FE);
}
