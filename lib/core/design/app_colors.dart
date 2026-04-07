import 'package:flutter/material.dart';

/// App Colors - Exact match to React CSS variables
/// Source: app/globals.css
class AppColors {
  AppColors._();

  // Core brand palette
  static const Color berkeleyBlue =
      Color(0xFF1E385C); // Primary - app bars, buttons, headers
  static const Color fireEngineRed =
      Color(0xFFC42127); // CTAs, badges, highlights, errors
  static const Color pureWhite = Color(0xFFFFFFFF); // Background / surfaces

  // Base surfaces & text
  static const Color background = pureWhite;
  static const Color foreground = berkeleyBlue;
  static const Color card = pureWhite;
  static const Color cardForeground = berkeleyBlue;

  // Primary colors
  static const Color primary = berkeleyBlue;
  static const Color primaryForeground = pureWhite;
  static const Color primaryDark = Color(0xFF162743);
  static const Color primaryLight = Color(0xFF36507A);

  // Secondary colors
  static const Color secondary = fireEngineRed;
  static const Color secondaryForeground = pureWhite;
  static const Color secondaryLight = Color(0xFFD74A4F);

  // Muted colors
  static const Color muted = Color(0xFFE4E7EC);
  static const Color mutedForeground = Color(0xFF667085);

  // Accent colors
  static const Color accent = berkeleyBlue;
  static const Color accentForeground = pureWhite;
  static const Color darkCard = Color(0xFF111827);

  // Border & Input
  static const Color border = Color(0xFFD0D5DD);
  static const Color input = pureWhite;
  static const Color ring = berkeleyBlue;

  // Custom app colors
  static const Color beige = pureWhite;
  static const Color beigeDark = Color(0xFFF3F4F6);
  static const Color orange = fireEngineRed;
  static const Color orangeLight = secondaryLight;
  static const Color purple = berkeleyBlue;
  static const Color purpleLight = primaryLight;
  static const Color purpleDark = primaryDark;
  static const Color dark = Color(0xFF020617);
  static const Color lavender = Color(0xFFE5E7EB);
  static const Color lavenderLight = Color(0xFFF3F4F6);

  // Semantic colors
  static const Color destructive = fireEngineRed;
  static const Color destructiveForeground = pureWhite;
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Bottom navigation
  static const Color bottomNavBackground = Color(0xFF1A1A1A);
  static const Color bottomNavActive = Color(0xFFFFFFFF);
  static const Color bottomNavInactive = Color(0xFF9CA3AF);

  // Overlay colors
  static const Color whiteOverlay20 = Color(0x33FFFFFF);
  static const Color whiteOverlay40 = Color(0x66FFFFFF);
  static const Color whiteOverlay10 = Color(0x1AFFFFFF);
  static const Color blackOverlay20 = Color(0x33000000);
}
