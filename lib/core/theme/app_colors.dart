import 'package:flutter/material.dart';

/// Central color palette — Aurora / Space system with refined solid
/// surfaces. Near-black void with a deep-purple aurora gradient,
/// clean solid panels (no glass, no mirror), violet/magenta accents.
class AppColors {
  AppColors._();

  // Backgrounds — Aurora gradient: rgb(10,10,20) -> rgb(21,17,43).
  static const Color bgBase = Color(0xFF0A0A14); // deep void start
  static const Color bgElevated = Color(0xFF15112B); // sidebar / topbar base
  static const Color bgGlow = Color(0xFF8B5CF6); // ambient violet glow

  /// Full-screen base background: 135° aurora gradient.
  static const LinearGradient appBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [bgBase, bgEnd],
  );

  /// Top-right of the aurora gradient — used by [appBackground].
  static const Color bgStart = Color(0xFF0A0A14);

  /// Bottom-left of the aurora gradient — used by [appBackground].
  static const Color bgEnd = Color(0xFF15112B);

  // Aurora nebula accents — the "space glow" palette.
  static const Color auroraPink = Color(0xFFEC4899); // magenta glow
  static const Color auroraPurple = Color(0xFFA855F7); // bright violet
  static const Color infoBlue = Color(0xFF3B82F6); // cosmic blue
  static const Color infoBlueLight = Color(0xFF60A5FA); // soft blue

  // Solid surface fills — clean, refined panels over the gradient.
  static const Color glassFill = Color(0xFF1A1333); // base panel
  static const Color glassFillStrong = Color(0xFF231B47); // hover/elevated
  static const Color glassBorder = Color(0xFF2C2448); // subtle hairline border
  static const Color glassBorderPurple =
      Color(0x55A855F7); // violet hover border

  // Brand / accent — electric violet + soft lavender + magenta gradient.
  static const Color accentPrimary = Color(0xFF8B5CF6); // electric violet
  static const Color accentSecondary = Color(0xFFD8B4FE); // lavender
  static const Color accentGradientStart = Color(0xFF8B5CF6);
  static const Color accentGradientEnd = Color(0xFFEC4899); // violet -> pink

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF); // pure white
  static const Color textSecondary = Color(0xFF9CA3AF); // cool gray
  static const Color textTertiary = Color(0xFF6B7280); // dim gray

  // Status colors (always paired with icon + text, never color alone)
  static const Color statusAvailable = Color(0xFF22C55E); // green
  static const Color statusActive = Color(0xFFEF4444); // red (in-use)
  static const Color statusPaused = Color(0xFFF59E0B); // yellow/orange
  static const Color statusMaintenance = Color(0xFF6B7280); // muted gray

  // Semantic
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  static const LinearGradient primaryButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentGradientStart, accentGradientEnd],
  );

  /// Aurora nebula glow (top of the screen): magenta core melting into
  /// violet, then fading to transparent — like a nebula in deep space.
  static RadialGradient auroraGlow({double opacity = 0.30}) => RadialGradient(
        colors: [
          auroraPink.withOpacity(opacity),
          accentPrimary.withOpacity(opacity * 0.70),
          bgGlow.withOpacity(0.0),
        ],
        stops: const [0.05, 0.35, 1.0],
      );

  /// Cosmic nebula glow (bottom of the screen): violet melting into soft
  /// blue, then fading to transparent — depth at the base of the view.
  static RadialGradient nebulaGlow({double opacity = 0.22}) => RadialGradient(
        colors: [
          accentPrimary.withOpacity(opacity),
          infoBlue.withOpacity(opacity * 0.65),
          bgGlow.withOpacity(0.0),
        ],
        stops: const [0.05, 0.40, 1.0],
      );

  /// Radial ambient glow used behind hero/important cards.
  static RadialGradient ambientGlow({double opacity = 0.35}) => RadialGradient(
        colors: [
          bgGlow.withOpacity(opacity),
          bgGlow.withOpacity(0.0),
        ],
      );
}
