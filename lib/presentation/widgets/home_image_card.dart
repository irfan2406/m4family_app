import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// The app's image card, in every portal: the homes' Communities / Properties
/// / Media tabs, the Properties list (Ongoing / Upcoming / Completed), the
/// Communities list and a community's Projects. The picture is clean —
/// nothing drawn over it — and beneath it a separate cream panel carries the
/// name, an optional detail line and the round arrow.
///
/// Purely visual: each screen passes its own [image] builder (so its image
/// loading and placeholders stay as they were) and wraps the card in its own
/// tap handling.
class HomeImageCard extends StatelessWidget {
  const HomeImageCard({
    super.key,
    required this.image,
    required this.title,
    this.caption,
    this.tags = const [],
    this.imageBadge,
    this.width = defaultWidth,
    this.margin = const EdgeInsets.only(right: 16, bottom: 10),
  });

  /// Builds the picture at a given [BoxFit]. The card draws it twice: whole
  /// ([BoxFit.contain], never cropped) and, behind it, blurred and filling the
  /// frame ([BoxFit.cover]) so the sides carry the photo's own colours instead
  /// of empty strips. Same URL, so one download.
  final Widget Function(BoxFit fit) image;

  /// The name in the panel (community, project or media title).
  final String title;

  /// A detail line under the name, with a location pin — a project's
  /// locality. Hidden when null or blank.
  final String? caption;

  /// Small pills beside the caption (e.g. the status, a starting price).
  /// Blank entries are skipped.
  final List<String> tags;

  /// An optional mark in the picture's top-right corner. Only for the Admin
  /// Panel's image-overlay label ("Artistic Impression"), which the admin
  /// switches on and off; nothing else is drawn on the picture.
  final Widget? imageBadge;

  /// The card's width; null fills the available width (list screens).
  final double? width;

  final EdgeInsets margin;

  /// Landscape width of the cards in the homes' horizontal rows.
  static const double defaultWidth = 320;

  /// The slim name panel under the picture.
  static const double panelHeight = 52;

  /// The YouTube layout: the picture is a full-width 16:9 frame (so a 16:9
  /// photo touches both edges with nothing cut off) and the slim panel sits
  /// below it. A [defaultWidth] card's picture is 320 x 180.
  static const double imageHeight = defaultWidth * 9 / 16;
  static const double cardHeight = imageHeight + panelHeight;

  /// The height a home's horizontal list needs: the card plus its 10 bottom
  /// margin (shadow room).
  static const double rowHeight = cardHeight + 10;

  /// The height of a card [cardWidth] wide: its 16:9 picture plus the panel.
  static double heightFor(double cardWidth) => cardWidth * 9 / 16 + panelHeight;

  // App palette.
  static const Color _cream = Color(0xFFF4EFE3);
  static const Color _deepGreen = Color(0xFF0C312B);
  static const Color _green = Color(0xFF155A4F);

  @override
  Widget build(BuildContext context) {
    final fixed = width;
    final card = fixed != null
        ? _card(fixed)
        : LayoutBuilder(
            builder: (context, constraints) => _card(constraints.maxWidth),
          );
    return Container(
      width: fixed,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: card,
    );
  }

  Widget _card(double cardWidth) {
    final captionText = caption?.trim() ?? '';
    final pills = tags.map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
    final hasDetails = captionText.isNotEmpty || pills.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: cardWidth,
            // A 16:9 frame, full width.
            height: cardWidth * 9 / 16,
            // The whole photo, never cropped. A 16:9 photo fills the frame
            // edge to edge; one of another shape is still shown whole, over a
            // blurred, filling copy of itself instead of empty strips.
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRect(
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(
                      sigmaX: 18,
                      sigmaY: 18,
                      tileMode: TileMode.mirror,
                    ),
                    child: image(BoxFit.cover),
                  ),
                ),
                // A light shade so the sharp photo stands off the blur.
                const ColoredBox(color: Color(0x26000000)),
                image(BoxFit.contain),
                if (imageBadge != null)
                  Positioned(top: 14, right: 14, child: imageBadge!),
              ],
            ),
          ),
          Container(
            height: panelHeight,
            // Translucent cream so the name strip reads clearly softer against
            // the page behind it (same in every portal — one shared card). The
            // dark-green title/caption stay legible.
            color: _cream.withValues(alpha: 0.8),
            padding: const EdgeInsets.only(left: 18, right: 9),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.gelasio(
                          color: _deepGreen,
                          fontSize: hasDetails ? 15.5 : 18,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.3,
                          height: 1.15,
                        ),
                      ),
                      if (hasDetails) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            if (captionText.isNotEmpty)
                              Flexible(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      LucideIcons.mapPin,
                                      size: 10,
                                      color: _green,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        captionText.toUpperCase(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          color: _green,
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            for (var i = 0; i < pills.length; i++) ...[
                              if (captionText.isNotEmpty || i > 0)
                                const SizedBox(width: 8),
                              Flexible(child: _pill(pills[i])),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: _deepGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.arrowRight,
                    color: _cream,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: _green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          color: _deepGreen,
          fontSize: 7.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
