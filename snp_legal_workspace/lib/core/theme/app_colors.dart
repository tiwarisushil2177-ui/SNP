import 'package:flutter/material.dart';

/// SNP Legal Workspace Design System
/// Main application colors. Gold is reserved for login branding only.
class AppColors {
  AppColors._();

  // Primary Navy family
  static const Color deepNavy = Color(0xFF102A43);
  static const Color darkNavy = Color(0xFF0B1F33);
  static const Color navyMid = Color(0xFF1B3A5F);

  // Accent — Saffron / Orange (restrained use)
  static const Color saffron = Color(0xFFE87524);
  static const Color saffronLight = Color(0xFFF4A261);

  // Surfaces
  static const Color ivory = Color(0xFFF8F7F3);
  static const Color white = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF5F4F0);
  static const Color card = Color(0xFFFFFFFF);

  // Text
  static const Color textPrimary = Color(0xFF172B3A);
  static const Color textSecondary = Color(0xFF627486);
  static const Color textMuted = Color(0xFF8B9AAB);
  static const Color textOnDark = Color(0xFFF8F7F3);
  static const Color textOnNavy = Color(0xFFFFFFFF);

  // Semantic
  static const Color success = Color(0xFF2D6A4F);
  static const Color warning = Color(0xFFE9C46A);
  static const Color error = Color(0xFFC1121F);
  static const Color info = Color(0xFF1D4E89);

  // Borders & dividers
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFEDF2F7);

  // Login-specific gold (do not use elsewhere in main app)
  static const Color loginGold = Color(0xFFC9A227);
  static const Color loginGoldDark = Color(0xFFA88B1E);
}
