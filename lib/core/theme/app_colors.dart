import 'package:flutter/material.dart';

/// Centralized app color palette.
abstract class AppColors {
  AppColors._();

  // Primary
  static const Color primary = Color(0xFF2962FF);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFF3B82F6);

  // Splash & onboarding (design)
  static const Color splashBackground = Color(0xFF4A567D);
  static const Color onboardingCardBackground = Color(0xFFFFFFFF);
  static const Color onboardingScaffoldBackground = Color(0xFF2D3548);

  // Secondary
  static const Color secondary = Color(0xFF64748B);
  static const Color secondaryDark = Color(0xFF475569);
  static const Color secondaryLight = Color(0xFF94A3B8);

  // Background
  static const Color background = Color(0xFFF8FAFC);
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E293B);

  // Text
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnPrimaryDark = Color(0xFFE2E8F0);

  // Status
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Border & divider
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF334155);

  // Terms & plan
  static const Color bulletRed = Color(0xFFE53935);
  static const Color highlightOrange = Color(0xFFFFF3E0);
  static const Color highlightOrangeText = Color(0xFFE65100);

  // Profile & chat
  static const Color logoutRed = Color(0xFFEF5350);
  static const Color logoutRedBg = Color(0xFFFFEBEE);
  static const Color premiumYellow = Color(0xFFFFF8E1);
  static const Color premiumOrange = Color(0xFFE65100);
}
