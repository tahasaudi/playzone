import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bgBase,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.accentPrimary,
        secondary: AppColors.accentSecondary,
        surface: AppColors.bgElevated,
        error: AppColors.danger,
      ),
      // Arabic-first font, bundled as an asset so it is the same on every
      // machine with or without a network.
      textTheme: base.textTheme.apply(
        fontFamily: 'Tajawal',
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      dividerColor: AppColors.glassBorder,
      iconTheme: const IconThemeData(color: AppColors.textSecondary, size: 20),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(AppColors.glassBorder),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  /// Standard hover/press animation durations (section 36 of the spec).
  static const Duration hoverDuration = Duration(milliseconds: 180);
  static const Duration pressDuration = Duration(milliseconds: 120);
  static const Duration panelDuration = Duration(milliseconds: 260);
  static const Duration modalDuration = Duration(milliseconds: 220);
}
