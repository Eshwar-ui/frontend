import 'package:flutter/material.dart';

/// Breakpoints for responsive layout.
/// - mobile: < 600
/// - tablet: 600–900
/// - desktop: > 900
class ResponsiveBreakpoints {
  const ResponsiveBreakpoints._();

  static const double mobile = 600;
  static const double tablet = 900;
}

/// Centralized responsive helpers for consistent breakpoints and spacing.
class ResponsiveUtils {
  const ResponsiveUtils._();

  static double _width(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  /// Returns true if width < 600.
  static bool isSmallScreen(BuildContext context) =>
      _width(context) < ResponsiveBreakpoints.mobile;

  /// Returns true if width >= 600 and < 900.
  static bool isTablet(BuildContext context) {
    final w = _width(context);
    return w >= ResponsiveBreakpoints.mobile &&
        w < ResponsiveBreakpoints.tablet;
  }

  /// Returns true if width >= 900.
  static bool isDesktop(BuildContext context) =>
      _width(context) >= ResponsiveBreakpoints.tablet;

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

  /// Font size scaled by current text scale factor (already clamped in app), for critical text.
  static double scaledFontSize(BuildContext context, double base) {
    final scale = MediaQuery.textScalerOf(context).scale(1.0);
    return (base * scale).clamp(base, base * 1.3);
  }
}
