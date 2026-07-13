import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ============================================================================
/// M4 FAMILY — CENTRALISED TYPOGRAPHY SYSTEM  (single source of truth)
/// ============================================================================
/// Premium-luxury type scale used across every portal (Guest / Customer / CP /
/// Investor) and every shared component.
///
///  • SERIF DISPLAY  → **DM Serif Display** — the high-contrast Didone used for
///    the flagship headings ("OUR PHILOSOPHY", "FEATURED PROPERTY", card
///    titles). This is the approved luxury heading face.
///  • SANS (everything else) → **Montserrat** — titles, body, labels, buttons.
///
/// Prefer `Theme.of(context).textTheme.*` (wired from [M4Type.textTheme] in
/// `M4Theme`) or the semantic getters below over inline `GoogleFonts.*` calls,
/// so the whole app shares one hierarchy. The getters are colour-agnostic
/// (inherit the ambient text colour) unless you `.copyWith(color: …)`.
class M4Type {
  M4Type._();

  // --- Font-family primitives (use when you must build a one-off style) -------
  /// The approved serif display face.
  static TextStyle serif({
    double? fontSize,
    FontWeight fontWeight = FontWeight.w400,
    double? letterSpacing,
    double? height,
    Color? color,
  }) => GoogleFonts.dmSerifDisplay(
    fontSize: fontSize,
    fontWeight: fontWeight,
    letterSpacing: letterSpacing,
    height: height,
    color: color,
  );

  /// The approved sans face.
  static TextStyle sans({
    double? fontSize,
    FontWeight fontWeight = FontWeight.w400,
    double? letterSpacing,
    double? height,
    Color? color,
  }) => GoogleFonts.dmSerifDisplay(
    fontSize: fontSize,
    fontWeight: fontWeight,
    letterSpacing: letterSpacing,
    height: height,
    color: color,
  );

  // --- SERIF DISPLAY scale (DM Serif Display, w400, tight tracking) ----------
  static TextStyle get displayLarge => serif(fontSize: 40, letterSpacing: -0.5, height: 1.08);
  static TextStyle get displayMedium => serif(fontSize: 32, letterSpacing: -0.5, height: 1.12); // OUR PHILOSOPHY / FEATURED PROPERTY
  static TextStyle get displaySmall => serif(fontSize: 26, letterSpacing: -0.5, height: 1.16);
  static TextStyle get headlineSerif => serif(fontSize: 22, letterSpacing: -0.3, height: 1.2); // card titles

  // --- SANS hierarchy (Montserrat) -------------------------------------------
  static TextStyle get headlineLarge => sans(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5, height: 1.2);
  static TextStyle get headlineMedium => sans(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.3, height: 1.25);
  static TextStyle get titleLarge => sans(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 0.15, height: 1.3);
  static TextStyle get titleMedium => sans(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.1, height: 1.3);
  static TextStyle get titleSmall => sans(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1, height: 1.3);
  static TextStyle get bodyLarge => sans(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5);
  static TextStyle get bodyMedium => sans(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5);
  static TextStyle get bodySmall => sans(fontSize: 12, fontWeight: FontWeight.w400, height: 1.45);
  static TextStyle get labelLarge => sans(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 1.1); // buttons
  static TextStyle get labelMedium => sans(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.5); // uppercase pill labels
  static TextStyle get labelSmall => sans(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2.0); // tiny kickers

  /// Build a Material [TextTheme]. [onColor] colours headings/titles/labels;
  /// [mutedColor] (defaults to [onColor]) colours body copy — matching the
  /// existing app behaviour where body text is slightly muted.
  static TextTheme textTheme(Color onColor, [Color? mutedColor]) {
    final Color body = mutedColor ?? onColor;
    return TextTheme(
      displayLarge: displayLarge.copyWith(color: onColor),
      displayMedium: displayMedium.copyWith(color: onColor),
      displaySmall: displaySmall.copyWith(color: onColor),
      headlineLarge: headlineLarge.copyWith(color: onColor),
      headlineMedium: headlineMedium.copyWith(color: onColor),
      // Sans (not serif) so functional dialogs/sheets that default to
      // headlineSmall stay clean; use [headlineSerif] explicitly for luxury.
      headlineSmall: sans(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.2, height: 1.25).copyWith(color: onColor),
      titleLarge: titleLarge.copyWith(color: onColor),
      titleMedium: titleMedium.copyWith(color: onColor),
      titleSmall: titleSmall.copyWith(color: onColor),
      bodyLarge: bodyLarge.copyWith(color: onColor),
      bodyMedium: bodyMedium.copyWith(color: body),
      bodySmall: bodySmall.copyWith(color: body),
      labelLarge: labelLarge.copyWith(color: onColor),
      labelMedium: labelMedium.copyWith(color: onColor),
      labelSmall: labelSmall.copyWith(color: body),
    );
  }
}
