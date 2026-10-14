import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Flutter port of the web `components/shared/LuxuryAmenityIcon.tsx`, built to
/// the backend team's amenity spec. Three tiers, in order:
///  1. a backend-uploaded icon (SVG or raster), gold-tinted when it is line art;
///  2. otherwise a hand-vectored thin-line luxury SVG mapped from the name;
///  3. otherwise a gold sparkle.
///
/// Luxury gold accent, per the spec.
const Color kAmenityGold = Color(0xFFDFBA6B);

/// The icon the backend attached to an amenity, or null when it has none.
///
/// An amenity arrives either as a map (`{name, icon, category, …}`) or as a
/// bare name. The icons are served from the file host as absolute URLs.
String? amenityIconUrl(dynamic amenity) {
  if (amenity is! Map) return null;
  final url = amenity['icon']?.toString().trim() ?? '';
  return url.isEmpty ? null : url;
}

/// True for formats that carry their own transparency, where the spec's
/// `BlendMode.srcIn` gold tint does the right thing: it repaints the opaque
/// (drawn) pixels gold and leaves the transparent ones alone.
bool _hasOwnAlpha(String url) {
  final path = (Uri.tryParse(url)?.path ?? url).toLowerCase();
  return path.endsWith('.svg') || path.endsWith('.png');
}

bool _isSvgIcon(String url) =>
    (Uri.tryParse(url)?.path ?? url).toLowerCase().endsWith('.svg');

/// Memory-cache width of a raster amenity icon. [precacheAmenityIcons] must use
/// the same value as [LuxuryAmenityIcon], or the warmed image is a cache miss.
/// 192 keeps the larger amenity icons (up to ~56pt at 3x) sharp: a smaller
/// decode thinned the line art into faint grey.
const int kAmenityIconCacheWidth = 192;

/// How strongly an emphasised (amenity-grid) icon is drawn: 0.9 = 10% lighter
/// than the full bold-and-dark treatment.
const double kAmenityEmphasisOpacity = 0.9;

/// The emphasised icon's darkening, tuned on the live amenity drawings: dense
/// art (Jacuzzi, Kid Play Area, Barbeque) must keep its detail. A stronger 1.5
/// with heavier strokes filled them into dark blobs; 1.25 with a light stroke
/// reads clearly without losing the drawing.
const double _kEmphasisAlphaGain = 1.25;

/// Stroke thickening as a fraction of the icon size (see `_embolden`).
const double _kEmphasisStroke = 0.005;

/// One size and colour for the amenity grid in every portal (guest, customer,
/// CP, investor), so the same amenity looks identical everywhere.
const double kAmenityGridIconSize = 52;

/// Dark green on the cream surface; gold on the dark (navy) one, where it
/// reads well and dark green would vanish.
Color amenityGridIconColor(bool isDark) =>
    isDark ? kAmenityGold : const Color(0xFF0C312B);

/// Downloads and decodes amenity icons into Flutter's memory image cache ahead
/// of time. An image already in memory skips the placeholder entirely, so the
/// Amenities grid draws every icon in its first frame instead of popping them
/// in one by one as each download finishes. SVG icons are left to the widget.
void precacheAmenityIcons(BuildContext context, Iterable<String?> urls) {
  for (final url in urls.whereType<String>().toSet()) {
    if (!url.startsWith('http') || _isSvgIcon(url)) continue;
    unawaited(
      precacheImage(
        ResizeImage.resizeIfNeeded(
          kAmenityIconCacheWidth,
          null,
          CachedNetworkImageProvider(url),
        ),
        context,
        // Best-effort: a failed icon falls back to its glyph in the widget.
        onError: (_, _) {},
      ),
    );
  }
}

/// Gold tint for an OPAQUE image — black line art on a white background, which
/// is how the backend uploads these icons (the "lobby" amenity is a 1254x1254
/// JPEG of black art on white).
///
/// `BlendMode.srcIn` cannot be used on those: a JPEG has no alpha, so every
/// pixel — the white background included — is opaque and srcIn repaints the
/// whole square solid gold. This matrix instead derives ALPHA from luminance,
/// the way the web's CSS filter behaves:
///
///   * RGB is fixed to the gold accent, so every drawn pixel is gold;
///   * alpha rises with darkness, so black art becomes fully opaque gold and
///     the white background falls away to nothing.
///
/// The alpha curve is `2 × (255 − luminance) − 60`, clamped, rather than a
/// plain `255 − luminance`. A JPEG's background is not pure white — compression
/// leaves it a degree or two off, with ringing along the art's edges — and a
/// plain inversion turned that noise into a faint gold wash and a hairline down
/// the picture's edge. The bias drops anything lighter than ~225 luminance to
/// nothing, and the ×2 keeps the art itself fully solid.
///
/// The result is gold line art with no white block and no edge line behind it,
/// on the cream and the green surfaces alike.
/// Same luminance→alpha curve, but the fill RGB is taken from [c] so the tint
/// follows the caller's colour — gold by default, or a darker accent where the
/// surface is light (cream) and gold would wash out.
///
/// [gain] is the "×2" above; an emphasised icon uses 2.5, which keeps the thin
/// strokes of a scaled-down drawing solid without filling in dense art.
List<double> _tintFromLuminance(Color c, {double gain = 2}) => <double>[
  0, 0, 0, 0, c.r * 255.0, // R -> c.red
  0, 0, 0, 0, c.g * 255.0, // G -> c.green
  0, 0, 0, 0, c.b * 255.0, // B -> c.blue
  // A -> gain*(255 - luminance) - 60
  -0.2126 * gain, -0.7152 * gain, -0.0722 * gain, 0, 255 * gain - 60,
];

/// `BlendMode.srcIn` tint (every drawn pixel becomes [c], keeping the image's
/// own alpha), with that alpha multiplied by [alphaGain] — so faint,
/// anti-aliased strokes of a transparent PNG / SVG come out darker.
List<double> _tintKeepingAlpha(Color c, double alphaGain) => <double>[
  0, 0, 0, 0, c.r * 255.0,
  0, 0, 0, 0, c.g * 255.0,
  0, 0, 0, 0, c.b * 255.0,
  0, 0, 0, alphaGain, 0,
];

class LuxuryAmenityIcon extends StatelessWidget {
  final String name;

  /// Already-resolved URL when the amenity has an uploaded icon, else null.
  final String? iconUrl;
  final double size;
  final Color color;

  /// Bundled image shown when the uploaded icon fails to load (e.g. while the
  /// backend /uploads endpoint is broken). Gold-tinted like the rest.
  final String? fallbackAsset;

  /// Clearly visible: the amenity grids. The drawing is darkened by
  /// [_kEmphasisAlphaGain] (see [_tintFromLuminance] / [_tintKeepingAlpha])
  /// and its strokes are thickened lightly ([_embolden]). Off elsewhere (e.g.
  /// community Benefits), which keep the original weight.
  final bool emphasized;

  const LuxuryAmenityIcon({
    super.key,
    required this.name,
    this.iconUrl,
    this.size = 44,
    this.color = kAmenityGold,
    this.fallbackAsset,
    this.emphasized = false,
  });

  double get _luminanceGain => emphasized ? 2 * _kEmphasisAlphaGain : 2;

  /// Clip hard: a large JPEG inside ColorFiltered otherwise paints a full-
  /// screen gold wash while scrolling (amenities disappear behind mustard).
  Widget _box(Widget child) => SizedBox(
        width: size,
        height: size,
        child: ClipRect(child: child),
      );

  /// Thicker strokes for an [emphasized] icon: the drawing is painted again a
  /// fraction of a point left, right, up and down, which widens every line
  /// evenly without changing the icon's size or shape. Fine line art has no
  /// heavier weight to switch to, so this is how it is made bold.
  ///
  /// [copy] builds one tinted copy with its drawing shifted by the offset.
  /// Only the drawing moves: a white backdrop shifted by a fraction of a pixel
  /// leaves half-covered edge pixels that the luminance tint reads as dark,
  /// which drew a hairline square around the icon.
  Widget _embolden(Widget Function(Offset offset) copy) {
    if (!emphasized) return copy(Offset.zero);
    final d = size * _kEmphasisStroke;
    // The finished bold icon is drawn at 90%: 10% lighter, evenly across
    // every icon type, so it reads dark without looking heavy.
    return Opacity(
      opacity: kAmenityEmphasisOpacity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          for (final o in [
            Offset(-d, 0),
            Offset(d, 0),
            Offset(0, -d),
            Offset(0, d),
            Offset.zero,
          ])
            copy(o),
        ],
      ),
    );
  }

  static Widget _shift(Offset o, Widget child) =>
      o == Offset.zero ? child : Transform.translate(offset: o, child: child);

  /// Luminance-tinted copy of an opaque drawing (see [_tintFromLuminance]).
  /// The white backdrop keeps every pixel defined, so no tinted hairline leaks
  /// down the sub-pixel transparent edge of the scaled image.
  Widget _luminanceCopy(Widget image, Offset o) => ColorFiltered(
    colorFilter: ColorFilter.matrix(
      _tintFromLuminance(color, gain: _luminanceGain),
    ),
    child: ColoredBox(color: Colors.white, child: _shift(o, image)),
  );

  Widget _renderAssetIcon(String asset) {
    final image = Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
    return _box(_embolden((o) => _luminanceCopy(image, o)));
  }

  /// The tint for a drawing that has its own transparency (PNG / SVG).
  ColorFilter get _alphaTint => emphasized
      ? ColorFilter.matrix(_tintKeepingAlpha(color, _kEmphasisAlphaGain))
      : ColorFilter.mode(color, BlendMode.srcIn);

  @override
  Widget build(BuildContext context) {
    // TIER 1 — a backend-uploaded icon.
    final url = iconUrl;
    if (url != null && url.isNotEmpty) {
      final hasAlpha = _hasOwnAlpha(url);

      if (_isSvgIcon(url)) {
        return _box(
          _embolden(
            (o) => _shift(
              o,
              SvgPicture.network(
                url,
                width: size,
                height: size,
                fit: BoxFit.contain,
                colorFilter: _alphaTint,
                // Transparent placeholder (not the fallback glyph) so the icon
                // never visibly morphs from a stand-in glyph into the real one.
                placeholderBuilder: (c) => SizedBox(width: size, height: size),
              ),
            ),
          ),
        );
      }

      return _box(
        CachedNetworkImage(
          memCacheWidth: kAmenityIconCacheWidth,
          imageUrl: url,
          width: size,
          height: size,
          fit: BoxFit.contain,
          // No fade + transparent placeholder: on open the (disk-cached) icon
          // appears directly instead of animating in from a fallback glyph.
          fadeInDuration: Duration.zero,
          fadeOutDuration: Duration.zero,
          placeholderFadeInDuration: Duration.zero,
          placeholder: (c, u) => SizedBox(width: size, height: size),
          imageBuilder: (c, provider) {
            final image = Image(
              image: provider,
              fit: BoxFit.contain,
              width: size,
              height: size,
              alignment: Alignment.center,
            );
            if (hasAlpha) {
              return _embolden(
                (o) => ColorFiltered(
                  colorFilter: _alphaTint,
                  child: _shift(o, image),
                ),
              );
            }
            // JPEG is opaque, so its white background is dissolved by luminance
            // instead — see _luminanceCopy.
            return _embolden((o) => _luminanceCopy(image, o));
          },
          errorWidget: (c, u, e) => fallbackAsset != null
              ? _renderAssetIcon(fallbackAsset!)
              : _fallbackGlyph(),
        ),
      );
    }

    if (fallbackAsset != null) {
      return _renderAssetIcon(fallbackAsset!);
    }

    return _fallbackGlyph();
  }

  // Name -> custom luxury SVG (web parity), else a Lucide fallback.
  Widget _fallbackGlyph() {
    final key = _luxuryKey(name);
    final svg = key != null ? _svgIcons[key] : null;
    if (svg != null) {
      return _box(
        _embolden(
          (o) => _shift(
            o,
            SvgPicture.string(
              svg,
              width: size,
              height: size,
              theme: SvgTheme(currentColor: color),
            ),
          ),
        ),
      );
    }
    return _box(
      _embolden(
        (o) => _shift(o, Icon(_lucideFallback(name), color: color, size: size)),
      ),
    );
  }
}


String _wrap(String inner) =>
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.2" stroke-linecap="round" stroke-linejoin="round">$inner</svg>';

final Map<String, String> _svgIcons = {
  'pool': _wrap(
    '<path d="M2 10c3-1.5 5-1.5 8 0s5 1.5 8 0 5-1.5 8 0"/><path d="M2 14c3-1.5 5-1.5 8 0s5 1.5 8 0 5-1.5 8 0"/><path d="M2 18c3-1.5 5-1.5 8 0s5 1.5 8 0 5-1.5 8 0"/>',
  ),
  'waterfall': _wrap(
    '<path d="M6 3v13c0 1 1 2 2 2s2-1 2-2V3M18 3v13c0 1-1 2-2 2s-2-1-2-2V3M12 4v10c0 0.5 0.5 1 1 1s1-0.5 1-1V4"/><path d="M2 20c2-1 3.5-1 5.5 0s3.5 1 5.5 0 3.5-1 5.5 0 3.5 1 5.5 0"/>',
  ),
  'sky_garden_sitting': _wrap(
    '<path d="M16 12a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v5h12v-5z"/><path d="M6 17v2M14 17v2"/><path d="M18 19c2-2 3-5 1-8M19 10c0-2-1-3-3-3"/><circle cx="18" cy="6" r="1"/>',
  ),
  'garden_sitting': _wrap(
    '<path d="M4 14c0-3 2-4 4-4s4 1 4 4v4H4v-4z"/><path d="M14 12c0-2 1.5-3 3-3s3 .7 3 3v6h-6v-6z"/><path d="M10 18h4"/><path d="M8 18v2M18 18v2M12 18v2"/>',
  ),
  'bean_bag': _wrap(
    '<path d="M12 4c-3.5 0-6 3.5-6 7.5s2.5 8.5 6 8.5 6-4.5 6-8.5S15.5 4 12 4z"/><path d="M8 15c1 1.5 2.5 2 4 2s3-.5 4-2"/>',
  ),
  'bbq': _wrap(
    '<path d="M6 10h12c0 3.3-2.7 6-6 6s-6-2.7-6-6z"/><path d="M7 10c0-2 2-3 5-3s5 1 5 3"/><path d="M12 7V4M10 4h4"/><path d="M9 16l-2 5M15 16l2 5M12 16v5"/>',
  ),
  'sun_lounger': _wrap(
    '<path d="M3 17h4l4-5 6 1 4-4"/><path d="M5 17v2M17 14v5"/><circle cx="18" cy="5" r="2"/><path d="M18 2v1M21 5h-1"/>',
  ),
  'wet_deck': _wrap(
    '<path d="M3 17h4l4-5 6 1 4-4"/><path d="M5 17v2M17 14v5"/><path d="M2 21c2-1 3.5-1 5.5 0s3.5 1 5.5 0 3.5-1 5.5 0 3.5 1 5.5 0"/>',
  ),
  'clubhouse': _wrap(
    '<path d="M3 13v4h18v-4"/><path d="M3 13c0-3 2-4 5-4h8c3 0 5 1 5 4"/><path d="M6 17v2M18 17v2M3 13h18"/>',
  ),
  'playground': _wrap(
    '<path d="M4 20L10 4M20 20L14 4M10 4h4"/><path d="M8 8h8"/><path d="M9 8v6M15 8v6M8 14h8"/>',
  ),
  'sitting': _wrap(
    '<path d="M4 10h16v4H4z"/><path d="M4 14v4M20 14v4"/><path d="M6 10V6M18 10V6"/>',
  ),
  'reading': _wrap(
    '<path d="M4 5h16M4 12h16M4 19h16"/><path d="M7 5v7M11 5v7M16 12v7M12 12v7"/>',
  ),
  'game_area': _wrap(
    '<rect x="4" y="4" width="16" height="16" rx="3"/><circle cx="8" cy="8" r="1.2" fill="currentColor"/><circle cx="16" cy="16" r="1.2" fill="currentColor"/><circle cx="12" cy="12" r="1.2" fill="currentColor"/><circle cx="8" cy="16" r="1.2" fill="currentColor"/><circle cx="16" cy="8" r="1.2" fill="currentColor"/>',
  ),
  'jacuzzi': _wrap(
    '<path d="M4 12c0 4.4 3.6 8 8 8s8-3.6 8-8M2 12h20"/><path d="M8 9c0-2 1-3 1-3M12 9c0-2 1-3 1-3M16 9c0-2 1-3 1-3"/>',
  ),
  'yoga': _wrap(
    '<circle cx="12" cy="6" r="2"/><path d="M12 8c-2 0-4 1-4 3v3h8v-3c0-2-2-2-4-3z"/><path d="M6 18c3-1.5 5-1.5 8 0s5 1.5 8 0"/><path d="M9 14s-2 2-3 4M15 14s2 2 3 4"/>',
  ),
  'gym': _wrap(
    '<path d="M6 6h2v12H6zM16 6h2v12h-2zM2 9h4v6H2zM18 9h4v6h-4zM8 12h8"/>',
  ),
  'shower': _wrap(
    '<path d="M7 4h10M12 4v6"/><path d="M9 10c0-1 1.5-2 3-2s3 1 3 2H9z"/><path d="M10 14v4M12 14v4M14 14v4M8 14v4M16 14v4"/>',
  ),
  'cinema': _wrap(
    '<rect x="3" y="5" width="18" height="12" rx="1"/><path d="M10 9l5 3-5 3V9z"/><path d="M6 17l-2 3M18 17l2 3M12 17v3"/>',
  ),
  'garden': _wrap(
    '<path d="M12 19V9M12 9a3 3 0 0 0-3-3 3 3 0 0 0-3 3v10M12 9a3 3 0 0 1 3-3 3 3 0 0 1 3 3v10"/><path d="M6 19h12"/>',
  ),
  'jogging': _wrap(
    '<path d="M4 12c0-4.4 3.6-8 8-8s8 3.6 8 8-3.6 8-8 8"/><path d="M8 12c0-2.2 1.8-4 4-4s4 1.8 4 4-1.8 4-4 4"/>',
  ),
  'drop_off': _wrap(
    '<path d="M5 17h14v-4H5v4zM7 13l2-5h6l2 5M6 17v2M18 17v2"/>',
  ),
  'fire_pit': _wrap(
    '<path d="M12 7c1 2-2 4-1 6s3-1 2-3M12 7c-1 2 2 4 1 6s-3-1-2-3"/><path d="M8 15h8M6 17h12"/>',
  ),
  'security': _wrap(
    '<path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/><path d="M9 11l2 2 4-4"/>',
  ),
  'cricket': _wrap(
    '<path d="M18.5 5.5L5.5 18.5a1.5 1.5 0 0 0 0 2.1l0 0a1.5 1.5 0 0 0 2.1 0l13-13a1.5 1.5 0 0 0 0-2.1l0 0a1.5 1.5 0 0 0-2.1 0z"/><path d="M4 20l-2 2M6.5 17.5L5 19M16.5 7.5L15 9"/><circle cx="17" cy="17" r="2"/>',
  ),
  'sunroof': _wrap(
    '<rect x="4" y="4" width="16" height="16" rx="2"/><path d="M4 12h16M12 4v16"/><circle cx="12" cy="12" r="3"/>',
  ),
  'parking': _wrap(
    '<circle cx="12" cy="12" r="9"/><path d="M9 17V7h4a3 3 0 0 1 0 6H9"/>',
  ),
};

// Map descriptive names to their respective vectors (ported from getLuxuryIconKey).
String? _luxuryKey(String name) {
  final n = name.toLowerCase();
  if (n.contains('duplex') && n.contains('pool')) return 'pool';
  if (n.contains('water fall') || n.contains('waterfall')) return 'waterfall';
  if (n.contains('sky garden sitting') || n.contains('sky garden'))
    return 'sky_garden_sitting';
  if (n.contains('multiple garden') || n.contains('mixed garden'))
    return 'garden';
  if (n.contains('bean bag')) return 'bean_bag';
  if (n.contains('bbq')) return 'bbq';
  if (n.contains('sun lounge') || n.contains('sun lounger'))
    return 'sun_lounger';
  if (n.contains('wet deck')) return 'wet_deck';
  if (n.contains('deck') || n.contains('lounge')) return 'sun_lounger';
  if (n.contains('clubhouse') || n.contains('pavilion') || n.contains('lobby') || n.contains('reception') || n.contains('foyer')) return 'clubhouse';
  if (n.contains('playground') || n.contains('kids')) return 'playground';
  if (n.contains('reading') || n.contains('book')) return 'reading';
  if (n.contains('game')) return 'game_area';
  if (n.contains('jacuzzi')) return 'jacuzzi';
  if (n.contains('yoga') || n.contains('meditation')) return 'yoga';
  if (n.contains('gym') || n.contains('fitness')) return 'gym';
  if (n.contains('shower')) return 'shower';
  if (n.contains('pool')) return 'pool';
  if (n.contains('cinema') || n.contains('theater')) return 'cinema';
  if (n.contains('garden') ||
      n.contains('lawn') ||
      (n.contains('park') && !n.contains('parking')))
    return 'garden';
  if (n.contains('parking') || n.contains('car')) return 'parking';
  if (n.contains('jogging') || n.contains('track')) return 'jogging';
  if (n.contains('drop off') || n.contains('vip drop')) return 'drop_off';
  if (n.contains('fire pit') || n.contains('campfire')) return 'fire_pit';
  if (n.contains('sitting') || n.contains('seating') || n.contains('courtyard'))
    return 'sitting';
  if (n.contains('security') ||
      n.contains('guard') ||
      n.contains('safe') ||
      n.contains('24/7'))
    return 'security';
  if (n.contains('cricket') ||
      n.contains('ground') ||
      n.contains('sports') ||
      n.contains('field') ||
      n.contains('court'))
    return 'cricket';
  if (n.contains('sunroof') || n.contains('skylight') || n.contains('roof'))
    return 'sunroof';
  return null;
}

// Lucide fallback (ported from getLucideFallback).
IconData _lucideFallback(String name) {
  final n = name.toLowerCase();
  if (n.contains('lobby') || n.contains('reception') || n.contains('foyer') || n.contains('concierge'))
    return LucideIcons.building2;
  if (n.contains('lounge') || n.contains('sun lounge')) return LucideIcons.sofa;
  if (n.contains('reading') || n.contains('corner'))
    return LucideIcons.bookOpen;
  if (n.contains('bean bag')) return LucideIcons.circleDot;
  if (n.contains('jogging') || n.contains('track')) return LucideIcons.wind;
  if (n.contains('gym')) return LucideIcons.dumbbell;
  if (n.contains('pool')) return LucideIcons.waves;
  if (n.contains('fire pit') || n.contains('bbq')) return LucideIcons.flame;
  if (n.contains('sitting') || n.contains('seating') || n.contains('courtyard'))
    return LucideIcons.armchair;
  if (n.contains('garden')) return LucideIcons.trees;
  if (n.contains('wet deck') || n.contains('deck')) return LucideIcons.droplets;
  if (n.contains('clubhouse') || n.contains('pavilion'))
    return LucideIcons.building2;
  if (n.contains('playground') || n.contains('kids'))
    return LucideIcons.toyBrick;
  if (n.contains('game')) return LucideIcons.dice5;
  if (n.contains('park') || n.contains('sun')) return LucideIcons.umbrella;
  // Spec's tier 3: the luxury sparkle, not a puzzle piece.
  return LucideIcons.sparkles;
}
