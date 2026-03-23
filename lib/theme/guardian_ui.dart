import 'package:flutter/material.dart';

/// Shared palette for Guardian Map, Help request flow, and home hero cards
/// (reds, surface, typography-friendly neutrals).
abstract final class GuardianUi {
  static const Color surface = Color(0xFFF6F7FB);
  static const Color surfaceMuted = Color(0xFFF8F9FC);
  static const Color textPrimary = Color(0xFF1B1B22);
  static const Color textSecondary = Color(0xFF49454F);
  static const Color divider = Color(0xFFE5E7EE);
  static const Color outline = Color(0xFFCAC4D0);

  static const Color redAccent = Color(0xFFFF4B4B);
  static const Color redPrimary = Color(0xFFB31217);
  static const Color redDark = Color(0xFF1B1B1B);

  /// Soft tint for icon circles / chips (matches empty-state accents).
  static const Color redTint = Color(0xFFFFE3E3);

  /// Soft wash behind forms (red tint → surface) — keeps pages on-brand without clutter.
  static const LinearGradient pageBackgroundWash = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFF0F0),
      Color(0xFFF6F7FB),
      surface,
    ],
    stops: [0.0, 0.38, 1.0],
  );

  /// Header band (Guardian Map / Request help).
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [redAccent, redPrimary, redDark],
    stops: [0.0, 0.62, 1.0],
  );

  /// Home-style primary CTA / category pill (SOS card buttons).
  static const LinearGradient ctaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF4E5B), Color(0xFFD3192A)],
  );

  /// Decorative glow (home_screen hero).
  static const Color orbWarm = Color(0xFFFF8A80);
  static const Color orbCool = Color(0xFF3D0008);

  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x12000000),
      blurRadius: 18,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> headerCardShadow = [
    BoxShadow(
      color: Color(0x22000000),
      blurRadius: 28,
      offset: Offset(0, 12),
    ),
  ];

  static const List<BoxShadow> footerBarShadow = [
    BoxShadow(
      color: Color(0x38000000),
      blurRadius: 20,
      offset: Offset(0, -8),
    ),
  ];
}
