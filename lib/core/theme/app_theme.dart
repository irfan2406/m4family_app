import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:m4_mobile/core/theme/app_typography.dart';

class M4Theme {
  // ===== Web palette — 1:1 with Flutter Web (app/globals.css tokens) =====
  // LIGHT (:root)
  static const Color lightBackground = Color(
    0xFFF9FAFB,
  ); // --background 210 20% 98%
  static const Color lightForeground = Color(
    0xFF080C16,
  ); // --foreground 222 47% 6%
  static const Color lightCard = Color(0xFFFFFFFF); // --card 0 0% 100%
  static const Color lightPrimary = Color(0xFF080C16); // --primary
  static const Color lightPrimaryFg = Color(0xFFF8FAFC); // --primary-foreground
  static const Color lightSecondary = Color(
    0xFFEAF0F6,
  ); // --secondary 210 40% 94%
  static const Color lightMuted = Color(0xFFEAF0F6); // --muted
  static const Color lightMutedFg = Color(
    0xFF435670,
  ); // --muted-foreground 215 25% 35%
  static const Color lightAccent = Color(0xFFE2EBF3); // --accent 210 40% 92%
  static const Color lightDestructive = Color(0xFFEF4444); // --destructive
  static const Color lightBorder = Color(0xFFD7DFEA); // --border / --input

  // DARK (.dark) — cohesive navy system (222° hue). Two tiers that never clash:
  //  • PAGE BASE (#0A0E16) → both `background` AND `surface`, so every screen's
  //    page reads identically whether it uses scaffoldBackgroundColor or
  //    scheme.surface as its backdrop (this was the source of the mismatch).
  //  • ELEVATED CARD (#181F2D) → surfaceContainerHighest; every card lifts off
  //    the page by the same amount everywhere. Border is one step lighter again.
  static const Color darkBackground = Color(0xFF0A0E16); // page base
  static const Color darkForeground = Color(0xFFF8FAFC); // --foreground
  static const Color darkCard = Color(0xFF0A0E16); // == page base (see note)
  static const Color darkPrimary = Color(0xFFF8FAFC); // --primary
  static const Color darkPrimaryFg = Color(0xFF0F172A); // --primary-foreground
  static const Color darkSecondary = Color(0xFF181F2D); // elevated card
  static const Color darkMuted = Color(
    0xFF181F2D,
  ); // elevated card (cards use this)
  static const Color darkMutedFg = Color(
    0xFFCFD7E2,
  ); // --muted-foreground 215 25% 85%
  static const Color darkAccent = Color(0xFF202A3B); // accent surface
  static const Color darkDestructive = Color(0xFF7F1D1D); // --destructive
  static const Color darkBorder = Color(0xFF2B3648); // hairline (lifts on card)

  // Legacy aliases used across the app — mapped to the exact web palette.
  static const Color background = darkBackground;
  static const Color surface = darkCard;
  static const Color institutionalBlack = darkCard;
  static const Color premiumBlue = Color(0xFFC5A358); // legacy gold accent
  static const Color textPrimary = darkForeground;
  static const Color textSecondary = darkMutedFg;
  static const Color border = darkBorder;

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: lightBackground,
    colorScheme:
        const ColorScheme.light(
          primary: lightPrimary,
          onPrimary: lightPrimaryFg,
          secondary: lightSecondary,
          onSecondary: lightForeground,
          tertiary: lightAccent,
          onTertiary: lightForeground,
          error: lightDestructive,
          onError: lightPrimaryFg,
          surface: lightCard,
          onSurface: lightForeground,
          // ignore: deprecated_member_use
          background: lightBackground,
          // ignore: deprecated_member_use
          onBackground: lightForeground,
          outline: lightBorder,
          surfaceTint: Colors.transparent,
        ).copyWith(
          outlineVariant: lightBorder,
          surfaceContainerHighest: lightMuted,
          onSurfaceVariant: lightMutedFg,
        ),
    // Centralised type scale — single source of truth (app_typography.dart).
    textTheme: M4Type.textTheme(lightForeground, lightMutedFg),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: M4Type.sans(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: lightForeground,
      ),
      iconTheme: const IconThemeData(color: lightForeground),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBackground,
    colorScheme:
        const ColorScheme.dark(
          primary: darkPrimary,
          onPrimary: darkPrimaryFg,
          secondary: darkSecondary,
          onSecondary: darkForeground,
          tertiary: darkAccent,
          onTertiary: darkForeground,
          error: darkDestructive,
          onError: darkForeground,
          surface: darkCard,
          onSurface: darkForeground,
          // ignore: deprecated_member_use
          background: darkBackground,
          // ignore: deprecated_member_use
          onBackground: darkForeground,
          outline: darkBorder,
          surfaceTint: Colors.transparent,
        ).copyWith(
          outlineVariant: darkBorder,
          surfaceContainerHighest: darkMuted,
          onSurfaceVariant: darkMutedFg,
        ),
    textTheme: M4Type.textTheme(darkForeground, darkMutedFg),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: M4Type.sans(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: darkForeground,
      ),
      iconTheme: const IconThemeData(color: darkForeground),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: darkForeground,
        foregroundColor: darkBackground,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    ),
  );
}

// Glassmorphism helper
class GlassDecoration extends BoxDecoration {
  GlassDecoration({
    Color color = Colors.white,
    double opacity = 0.05,
    double blur = 10.0,
    BorderRadius? borderRadius,
  }) : super(
         color: color.withOpacity(opacity),
         borderRadius: borderRadius ?? BorderRadius.circular(24),
         border: Border.all(color: color.withOpacity(0.1), width: 1),
       );
}
