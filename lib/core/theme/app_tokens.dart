import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Spacing scale (8px base grid).
class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  static const double sidebarWidth = 260;
  static const double topBarHeight = 72;
}

/// Border radius scale — tight, precise corners for a refined feel.
class AppRadius {
  AppRadius._();
  static const double small = 8;
  static const double medium = 12;
  static const double large = 16;
  static const double hero = 20;

  static BorderRadius get smallR => BorderRadius.circular(small);
  static BorderRadius get mediumR => BorderRadius.circular(medium);
  static BorderRadius get largeR => BorderRadius.circular(large);
  static BorderRadius get heroR => BorderRadius.circular(hero);
}

/// Soft layered shadows — never hard black shadows. A gentle deep shadow
/// carries the panel, plus a whisper of violet so it sits on the aurora
/// rather than floating over a mirror.
class AppShadows {
  AppShadows._();

  static List<BoxShadow> card = [
    BoxShadow(
      color: Colors.black.withOpacity(0.30),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
    BoxShadow(
      color: AppColors.accentPrimary.withOpacity(0.06),
      blurRadius: 24,
      offset: const Offset(0, 0),
    ),
  ];

  static List<BoxShadow> cardHover = [
    BoxShadow(
      color: Colors.black.withOpacity(0.38),
      blurRadius: 26,
      offset: const Offset(0, 10),
    ),
    BoxShadow(
      color: AppColors.accentPrimary.withOpacity(0.10),
      blurRadius: 32,
      offset: const Offset(0, 0),
    ),
  ];

  /// Hover shadow for cards that deliberately glow on hover.
  static List<BoxShadow> cardHoverGlow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.38),
      blurRadius: 26,
      offset: const Offset(0, 10),
    ),
    BoxShadow(
      color: AppColors.accentPrimary.withOpacity(0.22),
      blurRadius: 38,
      spreadRadius: 2,
      offset: const Offset(0, 0),
    ),
  ];

  static List<BoxShadow> glow = [
    BoxShadow(
      color: AppColors.accentPrimary.withOpacity(0.25),
      blurRadius: 40,
      spreadRadius: 4,
    ),
  ];
}

/// Typography scale. Arabic UI should use Cairo/Tajawal via
/// GoogleFonts at the ThemeData level (see app_theme.dart).
class AppTypography {
  AppTypography._();

  static const TextStyle pageTitle = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const TextStyle secondary = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  /// Large bold numbers — financial totals, KPI values, timers.
  static const TextStyle numberLarge = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.0,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// The live session timer — must be readable from a distance.
  static const TextStyle timer = TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: 1.2,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}
