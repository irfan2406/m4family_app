import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class M4Theme {
  // Premium Zinc Palette (Web Match)
  static const Color background = Color(0xFF000000); // Pitch Black
  static const Color surface = Color(0xFF09090B);    // Deep Zinc
  static const Color premiumBlue = Color(0xFF3B82F6); // Blue-500
  
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFFA1A1AA); // Zinc-400
  static const Color border = Color(0xFF27272A);      // Zinc-800

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,
    colorScheme: const ColorScheme.light(
      primary: premiumBlue,
      secondary: premiumBlue,
      surface: Colors.white,
      background: Color(0xFFF8FAFC),
      onPrimary: Colors.white,
      onSurface: Color(0xFF09090B),
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
      primary: premiumBlue,
      secondary: premiumBlue,
      surface: surface,
      background: background,
      onPrimary: background,
      onSurface: textPrimary,
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
        backgroundColor: premiumBlue,
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
