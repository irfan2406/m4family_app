import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// M4 Family design system — aligned 1:1 with the Figma "M4 Web Screen".
///
/// Palette:
///   • DARK  theme  = deep forest green surfaces, warm cream text, gold accent.
///   • LIGHT theme  = warm cream surfaces, dark-green text, gold accent.
/// Typography:
///   • Primary  (headings / display) = Georgia  → rendered with Gelasio
///     (metrically identical Google font).
///   • Secondary (body / labels)     = Garamond → rendered with EB Garamond.
class M4Theme {
  // ===================================================================
  // BRAND ACCENTS (shared by both themes)
  // ===================================================================
  /// M4 signature gold — logo, active states, hairline accents, wordmark.
  static const Color gold = Color(0xFFC5A35B);
  static const Color goldSoft = Color(0xFFD8BE86);
  static const Color goldDeep = Color(0xFFA8863F);

  /// Warm cream used for text / surfaces on the green theme.
  /// "Living the" in the wordmark — sampled from the web (#65AEA0).
  static const Color taglineAccent = Color(0xFF65AEA0);

  static const Color cream = Color(0xFFF4EFE3);
  static const Color creamMuted = Color(0xFFFBF7EF);

  /// Deep forest greens.
  static const Color deepGreen = Color(0xFF0C312B); // Figma: #0C312B
  static const Color forestGreen = Color(0xFF163A2C);
  static const Color midGreen = Color(0xFF1C4535);

  /// Coral / terracotta — destructive & the "EXIT APP" action.
  static const Color coral = Color(0xFFC65B46);

  // ===================================================================
  // LIGHT (:root) — CREAM
  // ===================================================================
  static const Color lightBackground = Color(0xFFD4CFBC); // Figma cream page #D4CFBC
  static const Color lightForeground = Color(0xFF0C312B); // Figma green ink

  /// Figma typography colours (M4 Web reference). Headings sit at [figmaHeading]
  /// and body copy at [figmaBody] on the light / cream surfaces. Dark and green
  /// "showcase" surfaces keep their own cream / white text — those are correct
  /// by design and #155A4F would be unreadable on them.
  static const Color figmaHeading = Color(0xFF0C312B);
  static const Color figmaBody = Color(0xFF155A4F);
  static const Color lightCard = Color(0xFFF4EFE3); // warm cream card (never white)
  static const Color lightPrimary = Color(0xFF15271E); // dark green fill
  static const Color lightPrimaryFg = Color(0xFFF6F1E7); // cream on dark fill
  static const Color lightSecondary = Color(0xFFEAE1D0); // cream secondary
  static const Color lightMuted = Color(0xFFEAE1D0);
  static const Color lightMutedFg = Color(0xFF155A4F); // muted green-gray
  static const Color lightAccent = Color(0xFFEDE5D6);
  static const Color lightDestructive = coral;
  static const Color lightBorder = Color(0xFFD4CFBC); // Figma: 1px input border

  // ===================================================================
  // DARK (.dark) — GREEN
  // ===================================================================
  static const Color darkBackground = deepGreen; // deepest green
  static const Color darkForeground = cream; // warm cream text
  static const Color darkCard = forestGreen; // lifted green surface
  static const Color darkPrimary = cream; // cream fill
  static const Color darkPrimaryFg = deepGreen; // green on cream fill
  static const Color darkSecondary = midGreen; // green secondary surface
  static const Color darkMuted = midGreen;
  static const Color darkMutedFg = Color(0xFFB2C1B4); // sage muted text
  static const Color darkAccent = midGreen;
  static const Color darkDestructive = coral;
  static const Color darkBorder = Color(0xFF2C5344); // green hairline

  // ===================================================================
  // Legacy aliases used across the app — mapped to the green (dark) palette
  // so existing fixed-surface references stay on-brand.
  // ===================================================================
  static const Color background = darkBackground;
  static const Color surface = darkCard;
  static const Color institutionalBlack = darkCard;
  static const Color premiumBlue = gold; // legacy name → M4 gold accent
  static const Color textPrimary = darkForeground;
  static const Color textSecondary = darkMutedFg;
  static const Color border = darkBorder;

  // ===================================================================
  // TYPOGRAPHY HELPERS
  // ===================================================================
  /// Primary display / heading face — Georgia (Gelasio).
  static TextStyle heading({
    double? fontSize,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
    double? letterSpacing,
    double? height,
  }) => GoogleFonts.gelasio(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
  );

  /// Secondary body / label face — Garamond (EB Garamond).
  static TextStyle body({
    double? fontSize,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double? letterSpacing,
    double? height,
  }) => GoogleFonts.inter(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
  );

  /// Stage 1 — CRUSH: invert + boost the grayscale artwork so the plate (and
  /// any exported transparency-checker / noise baked into it) saturates to a
  /// clean, uniform black, and the wordmark becomes pure white.
  static const ColorFilter _taglineCrush = ColorFilter.matrix(<double>[
    -6, 0, 0, 0, 255,
    0, -6, 0, 0, 255,
    0, 0, -6, 0, 255,
    0, 0, 0, 1, 0,
  ]);

  /// The "Living the M4 Life" wordmark, recoloured to blend with the CURRENT
  /// theme: the crushed black plate → the live scaffold background (cream /
  /// green / navy), the white wordmark → the theme foreground. The recolour
  /// matrix is computed from the actual scaffold colour so the plate always
  /// blends — no green band on navy, no navy band on green.
  static Widget taglineWordmark(
    BuildContext context, {
    double? width,
    required double height,
    BoxFit fit = BoxFit.fitWidth,
  }) {
    // Text-rendered "Living the M4 Life" wordmark (replaces the old bitmap
    // asset): "Living the" regular + "M4 Life" bold, in the Georgia face.
    // It hugs its own text height instead of reserving the old bitmap's box
    // (which left ~45px of dead space above and below the line). The
    // `height`/`width` params are kept so every existing caller compiles
    // unchanged; `height` now only caps the line, it no longer pads it out.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? cream : lightForeground;
    return SizedBox(
      width: double.infinity,
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Living the ',
                  style: GoogleFonts.gelasio(
                    fontSize: 26,
                    height: 1.15,
                    fontWeight: FontWeight.w400,
                    // Web colour, not a tint of the foreground — every portal
                    // renders this on the green showcase surface.
                    color: taglineAccent,
                  ),
                ),
                TextSpan(
                  text: 'M4 Life',
                  style: GoogleFonts.gelasio(
                    fontSize: 26,
                    height: 1.15,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===================================================================
  // THEMES
  // ===================================================================
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: lightBackground,
    // No default Material blue: text selection, switches, checks, radios,
    // sliders and progress indicators all resolve to the M4 green palette.
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: forestGreen,
      selectionColor: Color(0x3D163A2C),
      selectionHandleColor: forestGreen,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? cream : lightMutedFg,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? forestGreen
            : const Color(0x33163A2C),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? forestGreen : Colors.transparent,
      ),
      checkColor: const WidgetStatePropertyAll(cream),
      side: const BorderSide(color: forestGreen, width: 1.5),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? forestGreen : lightMutedFg,
      ),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: forestGreen,
      thumbColor: forestGreen,
      inactiveTrackColor: Color(0x33163A2C),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: forestGreen),
    colorScheme:
        const ColorScheme.light(
          primary: lightPrimary,
          onPrimary: lightPrimaryFg,
          secondary: gold,
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
    textTheme: GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.gelasio(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: figmaHeading,
        letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.gelasio(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: figmaHeading,
        letterSpacing: -0.5,
      ),
      headlineMedium: GoogleFonts.gelasio(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: figmaHeading,
      ),
      titleLarge: GoogleFonts.gelasio(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: figmaHeading,
      ),
      bodyLarge: GoogleFonts.inter(fontSize: 17, color: figmaBody, height: 1.42),
      bodyMedium: GoogleFonts.inter(fontSize: 15, color: figmaBody, height: 1.42),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: lightForeground,
        letterSpacing: 1.2,
      ),
      iconTheme: IconThemeData(color: lightForeground),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: lightPrimary,
        foregroundColor: lightPrimaryFg,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: lightForeground,
        side: const BorderSide(color: lightBorder),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: goldDeep),
    ),
    cardTheme: CardThemeData(
      color: lightCard,
      elevation: 0,
      shadowColor: Colors.black.withOpacity(0.06),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: lightBorder),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: lightBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: forestGreen, width: 1),
      ),
      hintStyle: TextStyle(color: lightMutedFg.withOpacity(0.8)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: lightCard,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: GoogleFonts.gelasio(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: lightForeground,
      ),
      contentTextStyle: GoogleFonts.inter(
        fontSize: 15,
        color: lightMutedFg,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: lightCard,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: lightForeground,
      contentTextStyle: GoogleFonts.inter(
        color: lightPrimaryFg,
        fontSize: 14,
      ),
      actionTextColor: goldSoft,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dividerTheme: const DividerThemeData(color: lightBorder, thickness: 1),
    // Centralised overlay styling so popup menus, dropdowns, menus, tooltips
    // and tab bars all share the Figma cream design language.
    popupMenuTheme: PopupMenuThemeData(
      color: lightCard,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: lightBorder),
      ),
      textStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: lightForeground,
      ),
    ),
    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(lightCard),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(8),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: lightBorder),
          ),
        ),
      ),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      menuStyle: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(lightCard),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: lightBorder),
          ),
        ),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: lightForeground,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: GoogleFonts.inter(color: lightPrimaryFg, fontSize: 12),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: lightForeground,
      unselectedLabelColor: lightMutedFg,
      indicatorColor: gold,
      dividerColor: Colors.transparent,
      labelStyle: GoogleFonts.inter(
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
      ),
      unselectedLabelStyle: GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBackground,
    // No default Material blue in dark mode either - cream/gold interactions.
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: cream,
      selectionColor: Color(0x3DF4EFE3),
      selectionHandleColor: cream,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? cream : Colors.white54,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? gold
            : const Color(0x33FFFFFF),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? gold : Colors.transparent,
      ),
      checkColor: const WidgetStatePropertyAll(Color(0xFF0B1026)),
      side: const BorderSide(color: cream, width: 1.5),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? gold : Colors.white54,
      ),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: gold,
      thumbColor: gold,
      inactiveTrackColor: Color(0x33FFFFFF),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: cream),
    colorScheme:
        const ColorScheme.dark(
          primary: darkPrimary,
          onPrimary: darkPrimaryFg,
          secondary: gold,
          onSecondary: deepGreen,
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
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme)
        .copyWith(
          displayLarge: GoogleFonts.gelasio(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: darkForeground,
            letterSpacing: -0.5,
          ),
          displayMedium: GoogleFonts.gelasio(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: darkForeground,
            letterSpacing: -0.5,
          ),
          headlineMedium: GoogleFonts.gelasio(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: darkForeground,
          ),
          titleLarge: GoogleFonts.gelasio(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: darkForeground,
          ),
          bodyLarge: GoogleFonts.inter(fontSize: 17, color: darkForeground),
          bodyMedium: GoogleFonts.inter(fontSize: 15, color: darkMutedFg),
        ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: darkForeground,
        letterSpacing: 1.2,
      ),
      iconTheme: IconThemeData(color: darkForeground),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: darkPrimary,
        foregroundColor: darkPrimaryFg,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: darkForeground,
        side: const BorderSide(color: darkBorder),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: goldSoft),
    ),
    cardTheme: CardThemeData(
      color: darkCard,
      elevation: 0,
      shadowColor: Colors.black.withOpacity(0.4),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: darkBorder),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: cream, width: 1.5),
      ),
      hintStyle: TextStyle(color: darkMutedFg.withOpacity(0.8)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: darkCard,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: GoogleFonts.gelasio(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: darkForeground,
      ),
      contentTextStyle: GoogleFonts.inter(
        fontSize: 15,
        color: darkMutedFg,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: darkCard,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: darkCard,
      contentTextStyle: GoogleFonts.inter(
        color: darkForeground,
        fontSize: 14,
      ),
      actionTextColor: gold,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dividerTheme: const DividerThemeData(color: darkBorder, thickness: 1),
  );

  /// Kept as a palette colour only: the navigation pill uses it for the active
  /// glyph on the green showcase surfaces. The navy DARK theme it belonged to
  /// was removed when dark mode was dropped — the app is light-only.
  static const Color navyBackground = Color(0xFF0B1026);
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
