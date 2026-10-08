import 'package:flutter/material.dart';

/// Central color palette for AgriVision AI.
/// These are the exact colors used across the finalized UI/UX designs.
/// Always reference colors from here (or from Theme.of(context)) —
/// never hardcode hex values directly in screen/widget files.
class AppColors {
  AppColors._();

  // Brand greens (used identically in both light and dark mode —
  // these define the AgriVision identity and don't shift with theme).
  static const Color greenDark = Color(0xFF173404);
  static const Color greenMain = Color(0xFF2E7D32);
  static const Color greenMid = Color(0xFF3B6D11);
  static const Color greenAccent = Color(0xFF639922);
  static const Color greenPale = Color(0xFFC0DD97);
  static const Color greenLightBg = Color(0xFFEAF3DE);

  // Status / semantic colors (consistent across themes).
  static const Color blue = Color(0xFF378ADD);
  static const Color blueLight = Color(0xFF9ED6FF);
  static const Color orange = Color(0xFFEF9F27);
  static const Color red = Color(0xFFE5484D);
  static const Color brown = Color(0xFF854F0B);
  static const Color brownBg = Color(0xFFFBEED4);
  static const Color success = Color(0xFF8FD14F);

  // ---- Light mode surfaces ----
  static const Color lightBg = Color(0xFFFAFAF8);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E2DE);
  static const Color lightTextPrimary = Color(0xFF2C2C2A);
  static const Color lightTextSecondary = Color(0xFF5F5E5A);
  static const Color lightTextMuted = Color(0xFF9A9992);

  // ---- Dark mode surfaces ----
  static const Color darkBg = Color(0xFF14140F);
  static const Color darkSurface = Color(0xFF1E1F19);
  static const Color darkBorder = Color(0xFF33342C);
  static const Color darkTextPrimary = Color(0xFFF2F2EE);
  static const Color darkTextSecondary = Color(0xFFB5B4AC);
  static const Color darkTextMuted = Color(0xFF7C7B72);
}