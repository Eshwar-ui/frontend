import 'package:flutter/material.dart';

/// Design tokens and theme-based helpers so the app uses one source of truth
/// and avoids scattered `isDark ? ... : ...` and hardcoded Colors.
class AppDesignSystem {
  const AppDesignSystem._();

  // --- Spacing (consistent padding/margins) ---
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;

  // --- Border radius ---
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;

  // --- Elevation ---
  static const double elevationCard = 2.0;
  static const double elevationDialog = 6.0;
}

/// Theme-based colors and styles. Use these instead of checking brightness
/// or using Colors.white/black so light and dark stay consistent.
extension AppThemeExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;

  /// Card/surface background (replaces isDark ? surfaceContainerHighest : Colors.white)
  Color get surfaceContainerColor => colorScheme.surfaceContainerHighest;

  /// Slightly elevated surface (inputs, dropdowns)
  Color get surfaceElevated => colorScheme.surfaceContainer;

  /// Subtle divider or border (replaces Colors.black.withOpacity(0.05) etc.)
  Color get dividerSubtle => colorScheme.outline.withValues(
        alpha: theme.brightness == Brightness.dark ? 0.2 : 0.08,
      );

  /// Theme-aware shadow for cards (replaces Colors.black.withOpacity(0.05))
  Color get cardShadow => colorScheme.outline.withValues(
        alpha: theme.brightness == Brightness.dark ? 0.15 : 0.08,
      );

  /// App bar background (primary in light, surface in dark for contrast)
  Color get appBarBackground => theme.appBarTheme.backgroundColor ?? colorScheme.surface;

  /// Content that must contrast on primary (e.g. icons on primary app bar)
  Color get onAppBar => theme.appBarTheme.iconTheme?.color ?? colorScheme.onSurface;

  bool get isDark => theme.brightness == Brightness.dark;
}
