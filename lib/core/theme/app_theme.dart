import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class M4Theme {
  // Web-matched "Ultra Deep Slate" dark palette (globals.css .dark tokens).
  static const Color background = Color(0xFF04060B); // hsl(222 47% 3%) deep slate
  static const Color surface = Color(0xFF0B111E);    // hsl(222 47% 8%) card
  static const Color institutionalBlack = Color(0xFF0B111E);
  // Accent used for section labels/highlights. Was near-black (invisible on dark);
  // now the M4 gold so it reads on both light and dark surfaces.
  static const Color premiumBlue = Color(0xFFC5A358); // M4 gold accent

  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFFCFD7E2); // hsl(215 25% 85%) bright muted (web)
  static const Color border = Color(0xFF10192D);        // hsl(222 47% 12%)

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF09090B),    // Institutional Black
      secondary: Color(0xFF18181B),  // Zinc-900
      surface: Colors.white,
      background: Colors.white,      // Pure Neutral
      onPrimary: Colors.white,
      onSurface: Color(0xFF09090B),
      outline: Color(0xFFE4E4E7),    // Zinc-200
      surfaceTint: Colors.transparent,
    ),
    textTheme: GoogleFonts.montserratTextTheme().copyWith(
      displayLarge: GoogleFonts.montserrat(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF09090B),
        letterSpacing: -0.5,
      ),
      headlineMedium: GoogleFonts.montserrat(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF09090B),
      ),
      bodyLarge: GoogleFonts.montserrat(
        fontSize: 16,
        color: const Color(0xFF09090B),
      ),
      bodyMedium: GoogleFonts.montserrat(
        fontSize: 14,
        color: const Color(0xFF71717A), // Zinc-500
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF09090B),
        letterSpacing: 1.2,
      ),
      iconTheme: IconThemeData(color: Color(0xFF09090B)),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFF8FAFC),   // High contrast white for dark mode
      secondary: Color(0xFFF8FAFC),
      surface: surface,
      background: background,
      onPrimary: background,
      onSurface: textPrimary,
      surfaceTint: Colors.transparent, // no M3 elevation tint (kills the muddy cast)
    ),
    textTheme: GoogleFonts.montserratTextTheme().copyWith(
      displayLarge: GoogleFonts.montserrat(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textPrimary,
        letterSpacing: -0.5,
      ),
      headlineMedium: GoogleFonts.montserrat(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      bodyLarge: GoogleFonts.montserrat(
        fontSize: 16,
        color: textPrimary,
      ),
      bodyMedium: GoogleFonts.montserrat(
        fontSize: 14,
        color: textSecondary,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: textPrimary,
        foregroundColor: background,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
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
          border: Border.all(
            color: color.withOpacity(0.1),
            width: 1,
          ),
        );
}
