import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/widgets/youtube_embed.dart';

/// A content post's date as the app shows it everywhere — on the Content Hub
/// cards and on the post itself: "21/10/26" (day/month/year), in the phone's
/// time zone (the API sends UTC). Empty when the post carries no date, rather
/// than showing today's.
String contentPostDate(dynamic createdAt) {
  final created = DateTime.tryParse(createdAt?.toString() ?? '');
  return created == null
      ? ''
      : DateFormat('dd/MM/yy').format(created.toLocal());
}

/// One post in the CONTENT HUB lists — Media, Highlights, Events and Blog —
/// the same card in every portal.
///
/// YouTube layout: a 16:9 picture across the card's full width, which the
/// uploaded photo fills edge to edge (no bands, no blur, nothing drawn over
/// it). All of the post's text
/// sits beneath it in one thin strip — the title, then the type chip, date
/// and description on a single line — with the round arrow on the right. A
/// post with no uploaded picture but a YouTube video shows that video's still.
class ContentHubCard extends ConsumerWidget {
  const ContentHubCard({
    super.key,
    required this.item,
    required this.typeLabel,
    required this.placeholderIcon,
    required this.onTap,
  });

  /// The post as the content API returns it.
  final dynamic item;

  /// Shown in the chip when the post names no type of its own.
  final String typeLabel;

  /// Shown in the picture's place when there is no picture at all.
  final IconData placeholderIcon;

  final VoidCallback onTap;

  // App palette (as HomeImageCard's arrow).
  static const Color _cream = Color(0xFFF4EFE3);
  static const Color _deepGreen = Color(0xFF0C312B);

  static bool _has(dynamic v) => v != null && v.toString().trim().isNotEmpty;

  String _pictureUrl(WidgetRef ref) {
    final raw = _has(item['image'])
        ? item['image']
        : _has(item['thumbnail'])
        ? item['thumbnail']
        : item['coverImage'];
    final url = ref.read(apiClientProvider).resolveUrl(raw);
    if (url.isNotEmpty) return url;
    final videoId = youTubeVideoId(item['videoUrl']?.toString());
    return videoId == null ? '' : youTubeThumbnailUrl(videoId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pictureUrl = _pictureUrl(ref);
    // A post with a YouTube video opens straight into the player: fetch the
    // video's still now, so the player shows it instantly.
    precacheYouTubeStill(context, item['videoUrl']?.toString());
    // ...and warm the in-app player, so the video starts almost at once.
    warmUpYouTubePlayer(item['videoUrl']?.toString());
    final formattedDate = contentPostDate(item['createdAt']);
    final description = (item['description'] ?? '').toString().trim();
    final type = (_has(item['type']) ? item['type'] : typeLabel)
        .toString()
        .toUpperCase();

    final placeholder = ColoredBox(
      color: scheme.onSurface.withValues(alpha: 0.05),
      child: Center(
        child: Icon(
          placeholderIcon,
          color: scheme.onSurface.withValues(alpha: 0.1),
          size: 40,
        ),
      ),
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.onSurface.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 🖼️ Full-width 16:9 picture — the YouTube card ratio — that the
              // photo fills edge to edge: no bands, no blur, nothing over it.
              // A 16:9 upload (every Media and Blog picture) shows whole; a
              // photo of another shape (the Cledor site photo is a 960x1280
              // portrait) is centred and loses only what overflows the frame.
              AspectRatio(
                aspectRatio: 16 / 9,
                child: pictureUrl.isEmpty
                    ? placeholder
                    : CachedNetworkImage(
                        imageUrl: pictureUrl,
                        fit: BoxFit.cover,
                        memCacheWidth: 1080,
                        fadeInDuration: Duration.zero,
                        fadeOutDuration: Duration.zero,
                        placeholder: (_, __) => placeholder,
                        errorWidget: (_, __, ___) => placeholder,
                      ),
              ),

              // 📄 The thin strip: every line of text, below the picture.
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            (item['title'] ?? '').toString().toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface,
                              letterSpacing: -0.3,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: scheme.onSurface.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  type,
                                  style: GoogleFonts.inter(
                                    fontSize: 7,
                                    fontWeight: FontWeight.w600,
                                    color: scheme.onSurface,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                              if (formattedDate.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Text(
                                  formattedDate,
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: scheme.onSurface.withValues(
                                      alpha: 0.62,
                                    ),
                                  ),
                                ),
                              ],
                              if (description.isNotEmpty) ...[
                                // A dot keeps the date and the description
                                // apart, so they never read as one run.
                                if (formattedDate.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    child: Text(
                                      '·',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: scheme.onSurface.withValues(
                                          alpha: 0.45,
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    description,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: scheme.onSurface.withValues(
                                        alpha: 0.68,
                                      ),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: isDark ? _cream : _deepGreen,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.arrowRight,
                        size: 16,
                        color: isDark ? _deepGreen : _cream,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

