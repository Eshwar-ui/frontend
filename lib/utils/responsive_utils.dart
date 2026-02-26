import 'package:flutter/material.dart';

/// Breakpoints for responsive layout.
/// - xsmall: very narrow phones / flip phones
/// - mobile: < 600
/// - tablet: 600–900
/// - desktop: > 900
class ResponsiveBreakpoints {
  const ResponsiveBreakpoints._();

  /// Extra small phones and very narrow devices.
  static const double xsmall = 360;

  static const double mobile = 600;
  static const double tablet = 900;

  /// Very wide layouts (large tablets / desktops).
  static const double xlarge = 1200;
}

/// Centralized responsive helpers for consistent breakpoints and spacing.
class ResponsiveUtils {
  const ResponsiveUtils._();

  /// Reference design width for proportional scaling (matches ScreenUtilInit).
  static const double _designWidth = 390.0;

  static double _width(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  /// Returns true if width < 360.
  static bool isXSmall(BuildContext context) =>
      _width(context) < ResponsiveBreakpoints.xsmall;

  /// Returns true if width < 600.
  static bool isSmallScreen(BuildContext context) =>
      _width(context) < ResponsiveBreakpoints.mobile;

  /// Returns true if width >= 600 and < 900.
  static bool isTablet(BuildContext context) {
    final w = _width(context);
    return w >= ResponsiveBreakpoints.mobile &&
        w < ResponsiveBreakpoints.tablet;
  }

  /// Returns true if width >= 900 and < 1200.
  static bool isDesktop(BuildContext context) {
    final w = _width(context);
    return w >= ResponsiveBreakpoints.tablet &&
        w < ResponsiveBreakpoints.xlarge;
  }

  /// Returns true if width >= 1200.
  static bool isXLarge(BuildContext context) =>
      _width(context) >= ResponsiveBreakpoints.xlarge;

  /// Cross-axis count for grids (e.g. GridView). Prefer 1–2 on mobile, 2–3 on tablet, 3+ on desktop.
  static int columns(BuildContext context, {int? maxColumns}) {
    final w = _width(context);
    int count;
    if (w < ResponsiveBreakpoints.mobile) {
      count = 1;
    } else if (w < ResponsiveBreakpoints.tablet) {
      count = 2;
    } else {
      count = 3;
    }
    if (maxColumns != null && count > maxColumns) count = maxColumns;
    return count;
  }

  /// Horizontal padding that scales with screen size. Clamped for very small/large screens.
  static EdgeInsets paddingHorizontal(BuildContext context, {double scale = 1.0}) {
    final w = _width(context);
    final base = w < 400 ? 12.0 : (w < 600 ? 16.0 : (w < 900 ? 24.0 : 32.0));
    return EdgeInsets.symmetric(horizontal: (base * scale).clamp(8.0, 48.0));
  }

  /// General padding that scales with screen size.
  static EdgeInsets padding(BuildContext context, {double scale = 1.0}) {
    final w = _width(context);
    final base = w < 400 ? 12.0 : (w < 600 ? 16.0 : (w < 900 ? 20.0 : 24.0));
    final value = (base * scale).clamp(8.0, 32.0);
    return EdgeInsets.all(value);
  }

  /// Spacing value (for SizedBox height/width) that scales with screen size.
  static double spacing(BuildContext context, {double base = 16.0}) {
    final w = _width(context);
    final scale = w < 400 ? 0.85 : (w < 600 ? 1.0 : (w < 900 ? 1.1 : 1.2));
    return (base * scale).clamp(4.0, 48.0);
  }

  /// Generic proportional scale based on screen width and a design width.
  ///
  /// This keeps UI ratios similar across devices while clamping extremes:
  /// - very small screens get a slight downscale
  /// - very large screens don't blow up too much
  static double scale(
    BuildContext context,
    double value, {
    double minScale = 0.85,
    double maxScale = 1.3,
    double maxReferenceWidth = 600,
  }) {
    final w = _width(context).clamp(320.0, maxReferenceWidth);
    final rawScale = w / _designWidth;
    final clampedScale = rawScale.clamp(minScale, maxScale);
    return value * clampedScale;
  }

  /// Font size scaled by screen width with sensible clamps.
  ///
  /// This is independent of the OS text scaler (which the app already clamps
  /// globally) so that we keep visual ratios consistent across devices.
  static double responsiveFontSize(
    BuildContext context,
    double base, {
    double? min,
    double? max,
  }) {
    final scaled = scale(context, base);
    final effectiveMin = min ?? base * 0.85;
    final effectiveMax = max ?? base * 1.2;
    return scaled.clamp(effectiveMin, effectiveMax);
  }

  /// Border radius that scales gently with width.
  static double responsiveRadius(
    BuildContext context,
    double base, {
    double min = 4.0,
    double max = 24.0,
  }) {
    final scaled = scale(context, base, minScale: 0.9, maxScale: 1.2);
    return scaled.clamp(min, max);
  }

  /// Icon size that scales with width but keeps a usable tap target.
  static double responsiveIconSize(
    BuildContext context,
    double base, {
    double min = 16.0,
    double max = 32.0,
  }) {
    final scaled = scale(context, base, minScale: 0.9, maxScale: 1.2);
    return scaled.clamp(min, max);
  }

  /// Recommended max content width for centering main content on wide screens.
  static double maxContentWidth(BuildContext context) {
    final w = _width(context);

    if (w < ResponsiveBreakpoints.mobile) {
      // On phones just use full width.
      return w;
    } else if (w < ResponsiveBreakpoints.tablet) {
      // Small tablets / large phones in landscape.
      return 700;
    } else if (w < ResponsiveBreakpoints.xlarge) {
      // Regular desktop layouts.
      return 900;
    }

    // Very large screens.
    return 1200;
  }

  /// Font size scaled by current text scale factor (already clamped in app), for critical text.
  static double scaledFontSize(BuildContext context, double base) {
    final scale = MediaQuery.textScalerOf(context).scale(1.0);
    return (base * scale).clamp(base, base * 1.3);
  }
}
