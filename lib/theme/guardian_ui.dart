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

/// Surfaces that follow **App Settings → Dark Appearance** (`ThemeProvider` / `MaterialApp.themeMode`).
/// Use `GuardianTheme.of(context)` on Help, reviews, and Guardian-style screens.
class GuardianTheme {
  GuardianTheme._(this.isDark);

  final bool isDark;

  factory GuardianTheme.of(BuildContext context) {
    return GuardianTheme._(
      Theme.of(context).brightness == Brightness.dark,
    );
  }

  Color get scaffoldBg =>
      isDark ? const Color(0xFF0F0F13) : GuardianUi.surface;

  /// Main raised panel (was white in light mode).
  Color get panelBg => isDark ? const Color(0xFF1B1B22) : Colors.white;

  Color get listItemBg =>
      isDark ? const Color(0xFF23232B) : GuardianUi.surfaceMuted;

  /// Scroll/list area inside a rounded panel (below tab bar).
  Color get panelListBg =>
      isDark ? const Color(0xFF16161C) : GuardianUi.surface;

  Color get textPrimary => isDark ? Colors.white : GuardianUi.textPrimary;

  Color get textSecondary =>
      isDark ? const Color(0xFFB7BBC6) : GuardianUi.textSecondary;

  Color get divider => isDark ? const Color(0xFF34343F) : GuardianUi.divider;

  Color get chipUnselectedFill =>
      isDark ? const Color(0xFF2A2A33) : const Color(0xFFF1F3F7);

  Color get figmaFieldFill =>
      isDark ? const Color(0xFF23232B) : const Color(0xFFF5F5F5);

  Color get figmaFieldBorder =>
      isDark ? const Color(0xFF3A3A45) : const Color(0xFFE0E0E0);

  Color get captionGrey =>
      isDark ? const Color(0xFFB7BBC6) : const Color(0xFF747A86);

  Color get chipBorder =>
      isDark ? const Color(0xFF3A3A45) : const Color(0xFFE8EAF0);

  Color get chipBgSoft =>
      isDark ? const Color(0xFF2A2A33) : const Color(0xFFF9FAFC);

  Color get bodyTextMuted =>
      isDark ? const Color(0xFFD0D0D8) : const Color(0xFF424242);

  Color get ink =>
      isDark ? const Color(0xFFF0F0F5) : const Color(0xFF212121);

  Color get starEmpty =>
      isDark ? const Color(0xFF4A4A55) : const Color(0xFFE0E0E0);

  LinearGradient get headerGradient => isDark
      ? const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFF3B3B),
            Color(0xFFE10613),
            Color(0xFFB30012),
            Color(0xFF140910),
          ],
          stops: [0.0, 0.35, 0.72, 1.0],
        )
      : GuardianUi.headerGradient;

  LinearGradient get pageBackgroundWash => isDark
      ? const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF2A1518),
            Color(0xFF15151A),
            Color(0xFF0F0F13),
          ],
          stops: [0.0, 0.45, 1.0],
        )
      : GuardianUi.pageBackgroundWash;

  List<BoxShadow> get cardShadow => isDark
      ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ]
      : GuardianUi.cardShadow;
}
