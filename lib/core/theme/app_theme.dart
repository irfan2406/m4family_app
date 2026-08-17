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
  static const Color cream = Color(0xFFF4EFE3);
  static const Color creamMuted = Color(0xFFE9E1CF);

  /// Deep forest greens.
  static const Color deepGreen = Color(0xFF0F2A20);
  static const Color forestGreen = Color(0xFF163A2C);
  static const Color midGreen = Color(0xFF1C4535);

  /// Coral / terracotta — destructive & the "EXIT APP" action.
  static const Color coral = Color(0xFFC65B46);

  // ===================================================================
  // LIGHT (:root) — CREAM
  // ===================================================================
  static const Color lightBackground = Color(0xFFF3EDE0); // warm cream
  static const Color lightForeground = Color(0xFF15271E); // dark green-black
  static const Color lightCard = Color(0xFFFBF7EF); // near-white cream card
  static const Color lightPrimary = Color(0xFF15271E); // dark green fill
  static const Color lightPrimaryFg = Color(0xFFF6F1E7); // cream on dark fill
  static const Color lightSecondary = Color(0xFFEAE1D0); // cream secondary
  static const Color lightMuted = Color(0xFFEAE1D0);
  static const Color lightMutedFg = Color(0xFF5E6B60); // muted green-gray
  static const Color lightAccent = Color(0xFFEDE5D6);
  static const Color lightDestructive = coral;
  static const Color lightBorder = Color(0xFFDED4BF); // cream hairline

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
  }) => GoogleFonts.ebGaramond(
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
    // asset): flowing script for "Living the" / "Life", serif for "M4". The
    // `height`/`width` params are kept so every existing caller works unchanged;
    // the wordmark is centred inside the same reserved height the bitmap used,
    // so no hero layout shifts and it stays consistent across every portal.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? cream : lightForeground;
    return SizedBox(
      height: height,
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
                    color: fg.withValues(alpha: 0.95),
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
    textTheme: GoogleFonts.ebGaramondTextTheme().copyWith(
      displayLarge: GoogleFonts.gelasio(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: lightForeground,
        letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.gelasio(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: lightForeground,
        letterSpacing: -0.5,
      ),
      headlineMedium: GoogleFonts.gelasio(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: lightForeground,
      ),
      titleLarge: GoogleFonts.gelasio(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: lightForeground,
      ),
      bodyLarge: GoogleFonts.ebGaramond(fontSize: 17, color: lightForeground),
      bodyMedium: GoogleFonts.ebGaramond(fontSize: 15, color: lightMutedFg),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: lightBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: gold, width: 1.5),
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
      contentTextStyle: GoogleFonts.ebGaramond(
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
      contentTextStyle: GoogleFonts.ebGaramond(
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
      textStyle: GoogleFonts.ebGaramond(
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
      textStyle: GoogleFonts.ebGaramond(color: lightPrimaryFg, fontSize: 12),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: lightForeground,
      unselectedLabelColor: lightMutedFg,
      indicatorColor: gold,
      dividerColor: Colors.transparent,
      labelStyle: GoogleFonts.ebGaramond(
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
      ),
      unselectedLabelStyle: GoogleFonts.ebGaramond(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
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
    textTheme: GoogleFonts.ebGaramondTextTheme(ThemeData.dark().textTheme)
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
          bodyLarge: GoogleFonts.ebGaramond(fontSize: 17, color: darkForeground),
          bodyMedium: GoogleFonts.ebGaramond(fontSize: 15, color: darkMutedFg),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
        borderSide: const BorderSide(color: gold, width: 1.5),
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
      contentTextStyle: GoogleFonts.ebGaramond(
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
      contentTextStyle: GoogleFonts.ebGaramond(
        color: darkForeground,
        fontSize: 14,
      ),
      actionTextColor: gold,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dividerTheme: const DividerThemeData(color: darkBorder, thickness: 1),
  );

  // ===================================================================
  // DARK MODE — NAVY (screenshot parity)
  // ===================================================================
  /// The app's DARK theme is a deep navy blue (matches the reference
  /// screenshot). LIGHT mode is unaffected: the guest "showcase" screens
  /// (Home/Properties/Drawer) keep using the green `darkTheme` in LIGHT mode,
  /// while the app's actual dark mode uses THIS navy theme for every section.
  static const Color navyBackground = Color(0xFF0B1026); // deep navy
  static const Color navyCard = Color(0xFF141B3A); // lifted navy surface
  static const Color navyMuted = Color(0xFF1C2547);
  static const Color navyBorder = Color(0xFF2C3866);

  static final ThemeData darkThemeNavy = darkTheme.copyWith(
    scaffoldBackgroundColor: navyBackground,
    canvasColor: navyBackground,
    colorScheme: darkTheme.colorScheme.copyWith(
      surface: navyCard,
      // ignore: deprecated_member_use
      background: navyBackground,
      outline: navyBorder,
      outlineVariant: navyBorder,
      surfaceContainerHighest: navyMuted,
    ),
    cardTheme: darkTheme.cardTheme.copyWith(
      color: navyCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: navyBorder),
      ),
    ),
    inputDecorationTheme: darkTheme.inputDecorationTheme.copyWith(
      fillColor: navyCard,
    ),
    dialogTheme: darkTheme.dialogTheme.copyWith(backgroundColor: navyCard),
    bottomSheetTheme: darkTheme.bottomSheetTheme.copyWith(
      backgroundColor: navyCard,
    ),
    dividerTheme: const DividerThemeData(color: navyBorder, thickness: 1),
    // Navy overlays so popup menus, dropdowns, menus and tabs match the dark
    // navy surfaces (mirrors the light theme's centralised overlay styling).
    popupMenuTheme: PopupMenuThemeData(
      color: navyCard,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: navyBorder),
      ),
      textStyle: GoogleFonts.ebGaramond(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: cream,
      ),
    ),
    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(navyCard),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(8),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: navyBorder),
          ),
        ),
      ),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      menuStyle: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(navyCard),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: navyBorder),
          ),
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
