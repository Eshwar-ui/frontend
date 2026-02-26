import 'package:flutter/material.dart';
import 'package:quantum_dashboard/utils/responsive_utils.dart';

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

/// Responsive helpers that need BuildContext (use MediaQuery.sizeOf / textScaler).
extension AppDesignSystemResponsive on BuildContext {
  /// Font size scaled by current text scaler (respects app clamp). Use for critical text.
  double scaledFontSize(double base) {
    final scale = MediaQuery.textScalerOf(this).scale(1.0);
    return (base * scale).clamp(base, base * 1.3);
  }

  /// Horizontal padding that scales with screen width.
  EdgeInsets get responsivePaddingHorizontal =>
      ResponsiveUtils.paddingHorizontal(this);

  /// General padding that scales with screen size.
  EdgeInsets get responsivePadding => ResponsiveUtils.padding(this);

  /// Spacing value for the current screen size.
  double responsiveSpacing([double base = 16.0]) =>
      ResponsiveUtils.spacing(this, base: base);

  /// Proportional scale for arbitrary dimensions (based on design width).
  double scaleDimension(double value) => ResponsiveUtils.scale(this, value);

  /// Font size scaled by screen width with sensible clamps.
  double responsiveFontSize(
    double base, {
    double? min,
    double? max,
  }) =>
      ResponsiveUtils.responsiveFontSize(this, base, min: min, max: max);

  /// Border radius that scales gently with screen width.
  double responsiveRadius(
    double base, {
    double min = 4.0,
    double max = 24.0,
  }) =>
      ResponsiveUtils.responsiveRadius(this, base, min: min, max: max);

  /// Icon size that scales with width but keeps a usable tap target.
  double responsiveIconSize(
    double base, {
    double min = 16.0,
    double max = 32.0,
  }) =>
      ResponsiveUtils.responsiveIconSize(this, base, min: min, max: max);

  /// Recommended max content width for centering main content on wide screens.
  double get maxContentWidth => ResponsiveUtils.maxContentWidth(this);
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
