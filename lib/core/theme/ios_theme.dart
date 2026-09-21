import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// iOS presentation tweaks layered over an M4 theme.
///
/// [M4Theme.lightTheme] and [M4Theme.darkTheme] pass themselves through
/// [adapt] only when running on iOS; Android keeps the original theme object,
/// untouched. Nothing here changes a colour, a font or a size of the M4
/// design — only how the platform behaves around it.
abstract final class M4IosTheme {
  static ThemeData adapt(ThemeData base) {
    final ColorScheme scheme = base.colorScheme;

    return base.copyWith(
      // iOS has no ink ripple. A tapped control dims or scales instead (see
      // the Liquid Glass controls), so Material's splash goes; a tapped row
      // shows the soft press shade iOS lists use, in the M4 ink.
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: scheme.onSurface.withValues(alpha: 0.06),
      hoverColor: Colors.transparent,

      // The native push: the new page slides in from the right over a
      // parallax of the old one, and the left-edge swipe pops it.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),

      // Cupertino controls — activity indicators, switches, alert dialogs,
      // pickers — drawn in M4's own colours rather than iOS blue.
      cupertinoOverrideTheme: CupertinoThemeData(
        brightness: base.brightness,
        primaryColor: scheme.primary,
        primaryContrastingColor: scheme.onPrimary,
        scaffoldBackgroundColor: base.scaffoldBackgroundColor,
        barBackgroundColor: base.scaffoldBackgroundColor.withValues(
          alpha: 0.72,
        ),
        textTheme: CupertinoTextThemeData(primaryColor: scheme.primary),
      ),

      // iOS title bars centre their title and never tint on scroll.
      appBarTheme: base.appBarTheme.copyWith(
        centerTitle: true,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}
