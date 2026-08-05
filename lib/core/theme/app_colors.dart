import 'package:flutter/material.dart';

/// Color tokens extracted from the Al Masar Fleet App design HTML.
abstract final class AppColors {
  // Brand — matches assets/logo.png gradient
  static const Color primary = Color(0xFF11B2F3);
  static const Color primaryDark = Color(0xFF0E57C1);

  // Text
  static const Color ink = Color(0xFF0F1728);
  static const Color navy = Color(0xFF101828);
  static const Color body = Color(0xFF334155);
  static const Color muted = Color(0xFF64748B);
  static const Color mutedLight = Color(0xFF98A2B3);

  // Surfaces
  static const Color bg = Color(0xFFF4F6F9);
  static const Color border = Color(0xFFE5E9F0);
  static const Color white = Color(0xFFFFFFFF);
  static const Color rowHover = Color(0xFFF8FAFC);
  static const Color neutralChipBg = Color(0xFFEEF1F6);

  // Status: info / selected (primary tint)
  static const Color chipBg = Color(0xFFEFF4FE);

  // Status: success
  static const Color success = Color(0xFF16A34A);
  static const Color successText = Color(0xFF16803C);
  static const Color successBg = Color(0xFFE9F9EF);

  // Status: danger
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerDark = Color(0xFFB91C1C);
  static const Color dangerBg = Color(0xFFFDECEC);

  // Status: warning
  static const Color warning = Color(0xFFB45309);
  static const Color warningDark = Color(0xFF92400E);
  static const Color warningBg = Color(0xFFFEF3E2);
}
