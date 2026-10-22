import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/core/utils/media_url.dart';

/// One month of one construction phase: the photos posted for it.
class ConstructionMonth {
  ConstructionMonth({
    required this.phase,
    required this.month,
    required this.images,
    this.progressPercent,
  });

  /// The phase record as the progress API returns it.
  final Map<String, dynamic> phase;

  /// First day of the month these photos belong to; null when nothing dates
  /// them (a phase with no photo and no timestamps).
  final DateTime? month;

  /// Raw media paths of this month's photos, newest upload first. Empty for a
  /// phase that has no photo yet.
  final List<String> images;

  /// This month's own progress, from the phase's matching `updates` entry
  /// (`updates[].progressPercent` for `updates[].month`). Null when the phase
  /// carries no per-month update for this month — the card then falls back to
  /// the phase-level `progressPercent`.
  final int? progressPercent;
}

/// The month a phase photo belongs to, from the best information the record
/// carries:
///
/// 1. an explicit date on the image — `month` ("2026-01"), `date`, `takenAt`,
///    `uploadedAt` or `createdAt` (what the backend should add, see below);
/// 2. a month written in its caption ("January 2026", "Jan 2026", "01/2026",
///    "2026-01") — the admin panel's existing caption field;
/// 3. the upload time the backend stamps into every file name
///    (`/uploads/media/med-<epoch ms>-…`).
///
/// Null when none of these is present.
DateTime? constructionPhotoMonth(dynamic image) {
  if (image is Map) {
    for (final key in const ['month', 'date', 'takenAt', 'uploadedAt']) {
      final m = _parseMonth(image[key]);
      if (m != null) return m;
    }
    final fromCaption = _parseMonth(image['caption']);
    if (fromCaption != null) return fromCaption;
    final created = _parseMonth(image['createdAt']);
    if (created != null) return created;
  }
  return _uploadMonth(mediaUrlOf(image));
}

/// Groups each phase's photos by month: one [ConstructionMonth] per phase per
/// month. Phase by phase in their own order, and within a phase month by month
/// from the earliest (Sep, then Oct, …) — every card of one phase, then the
/// next phase's. A phase with no photo yet still gets one entry, dated by its
/// own last update.
List<ConstructionMonth> constructionMonths(List<Map<String, dynamic>> phases) {
  final out = <ConstructionMonth>[];
  for (final phase in phases) {
    // The phase's per-month progress, keyed by month: `updates[].progressPercent`
    // for `updates[].month`. Lets each month card show that month's own progress
    // instead of the phase's single latest value.
    final pctByMonth = _updateProgressByMonth(phase);
    int? pctFor(DateTime? month) => month == null ? null : pctByMonth[month];

    // A stand-in phase the app built itself (no records yet) carries no real
    // dates: show it without a month rather than the hero photo's upload one.
    if (phase['undated'] == true || phase['_fallback'] == true) {
      out.add(
        ConstructionMonth(
          phase: phase,
          month: null,
          images: [
            for (final img
                in (phase['images'] is List
                    ? phase['images'] as List
                    : const []))
              if (mediaUrlOf(img).trim().isNotEmpty) mediaUrlOf(img).trim(),
          ],
        ),
      );
      continue;
    }
    final images = phase['images'] is List ? phase['images'] as List : const [];
    final byMonth = <DateTime?, List<_DatedPhoto>>{};
    for (final img in images) {
      final url = mediaUrlOf(img).trim();
      if (url.isEmpty) continue;
      final month = constructionPhotoMonth(img);
      byMonth
          .putIfAbsent(month, () => [])
          .add(_DatedPhoto(url, _uploadTime(url)));
    }
    final single = mediaUrlOf(phase['image']).trim();
    if (byMonth.isEmpty && single.isNotEmpty) {
      byMonth[_uploadMonth(single) ?? _phaseMonth(phase)] = [
        _DatedPhoto(single, _uploadTime(single)),
      ];
    }
    if (byMonth.isEmpty) {
      final month = _phaseMonth(phase);
      out.add(
        ConstructionMonth(
          phase: phase,
          month: month,
          images: const [],
          progressPercent: pctFor(month),
        ),
      );
      continue;
    }
    byMonth.forEach((month, photos) {
      photos.sort((a, b) => (b.time ?? 0).compareTo(a.time ?? 0));
      final resolved = month ?? _phaseMonth(phase);
      out.add(
        ConstructionMonth(
          phase: phase,
          month: resolved,
          images: [for (final p in photos) p.url],
          progressPercent: pctFor(resolved),
        ),
      );
    });
  }
  // Stable sort: entries of one phase keep their phase together.
  final indexed = out.asMap().entries.toList()
    ..sort((x, y) {
      final a = x.value, b = y.value;
      final byPhase = _order(a.phase).compareTo(_order(b.phase));
      if (byPhase != 0) return byPhase;
      if (!identical(a.phase, b.phase)) return x.key.compareTo(y.key);
      final am = a.month, bm = b.month;
      if (am != bm) {
        if (am == null) return 1;
        if (bm == null) return -1;
        return am.compareTo(bm);
      }
      return x.key.compareTo(y.key);
    });
  out
    ..clear()
    ..addAll(indexed.map((e) => e.value));
  return out;
}

class _DatedPhoto {
  _DatedPhoto(this.url, this.time);
  final String url;
  final int? time;
}

int _order(Map<String, dynamic> phase) {
  final o = phase['phaseOrder'];
  return o is num ? o.toInt() : int.tryParse('$o') ?? 0;
}

/// Builds a month → progressPercent map from a phase's `updates` array
/// (`[{ month: "YYYY-MM", progressPercent, ... }]`). Empty when the phase has
/// no updates (older backend), so callers fall back to the phase-level value.
Map<DateTime, int> _updateProgressByMonth(Map<String, dynamic> phase) {
  final updates = phase['updates'];
  if (updates is! List) return const {};
  final out = <DateTime, int>{};
  for (final u in updates) {
    if (u is! Map) continue;
    final month = _parseMonth(u['month']);
    if (month == null) continue;
    final raw = u['progressPercent'] ?? u['progress'];
    final pct = raw is num ? raw.toInt() : int.tryParse('${raw ?? ''}');
    if (pct != null) out[month] = pct.clamp(0, 100);
  }
  return out;
}

DateTime? _phaseMonth(Map<String, dynamic> phase) =>
    _parseMonth(phase['updatedAt']) ?? _parseMonth(phase['createdAt']);

int? _uploadTime(String url) {
  final m = RegExp(r'med-(\d{12,14})-').firstMatch(url);
  return m == null ? null : int.tryParse(m.group(1)!);
}

DateTime? _uploadMonth(String url) {
  final ms = _uploadTime(url);
  if (ms == null) return null;
  final d = DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
  return DateTime(d.year, d.month);
}

const _monthNames = [
  'jan',
  'feb',
  'mar',
  'apr',
  'may',
  'jun',
  'jul',
  'aug',
  'sep',
  'oct',
  'nov',
  'dec',
];

DateTime? _parseMonth(dynamic raw) {
  final s = raw?.toString().trim() ?? '';
  if (s.isEmpty) return null;
  // Full timestamps ("2026-01-15T…") — the API sends UTC.
  final full = DateTime.tryParse(s);
  if (full != null) {
    final d = full.toLocal();
    return DateTime(d.year, d.month);
  }
  // "2026-01" / "2026/01".
  var m = RegExp(r'\b(20\d{2})[-/.](\d{1,2})\b').firstMatch(s);
  if (m != null) {
    final mo = int.parse(m.group(2)!);
    if (mo >= 1 && mo <= 12) return DateTime(int.parse(m.group(1)!), mo);
  }
  // "01/2026" / "1-2026".
  m = RegExp(r'\b(\d{1,2})[-/.](20\d{2})\b').firstMatch(s);
  if (m != null) {
    final mo = int.parse(m.group(1)!);
    if (mo >= 1 && mo <= 12) return DateTime(int.parse(m.group(2)!), mo);
  }
  // "January 2026", "Jan 2026", "JAN-26".
  m = RegExp(
    r'\b(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*[\s,.\-/]*(\d{2,4})\b',
    caseSensitive: false,
  ).firstMatch(s);
  if (m != null) {
    final mo = _monthNames.indexOf(m.group(1)!.toLowerCase()) + 1;
    var y = int.parse(m.group(2)!);
    if (y < 100) y += 2000;
    return DateTime(y, mo);
  }
  return null;
}

/// CONSTRUCTION PROGRESS, month by month — the same in every portal.
///
/// A row of years (each with its dot on a rail) picks the year; below it the
/// year's updates swipe one at a time, newest first: one card per phase per
/// month, its photo with a gallery button, the month as the card's heading
/// ("JANUARY 2026"), the project name, and the phase's progress ring beside its
/// name. A phase with several months of photos therefore has several cards.
///
/// Purely visual: each project page passes its own image loader and gallery,
/// so data: URIs, uploads and caching keep working as they did.
class ConstructionUpdates extends StatefulWidget {
  const ConstructionUpdates({
    super.key,
    required this.projectTitle,
    required this.phases,
    required this.resolveUrl,
    required this.onOpenGallery,
    this.fallbackAsset = 'assets/cledor_phase_demolition.jpg',
  });

  final String projectTitle;

  /// The progress API's phase records.
  final List<Map<String, dynamic>> phases;

  /// Turns a raw media path into the URL to load (the page's API client).
  final String Function(String rawUrl) resolveUrl;

  /// Opens the page's photo gallery on these raw media paths.
  final void Function(List<String> rawUrls) onOpenGallery;

  /// Shown for a phase with no photo yet (not opened in the gallery).
  final String fallbackAsset;

  @override
  State<ConstructionUpdates> createState() => _ConstructionUpdatesState();
}

class _ConstructionUpdatesState extends State<ConstructionUpdates> {
  final PageController _pages = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    if (!_pages.hasClients) return;
    _pages.animateToPage(
      page,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  /// The year of the card on screen (an undated card takes the year of the
  /// nearest dated card before it).
  int? _yearAt(List<ConstructionMonth> cards, int page) {
    for (var i = page.clamp(0, cards.length - 1); i >= 0; i--) {
      final m = cards[i].month;
      if (m != null) return m.year;
    }
    for (final c in cards) {
      if (c.month != null) return c.month!.year;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? Colors.white : const Color(0xFF0C312B);
    final cards = constructionMonths(widget.phases);
    if (cards.isEmpty) return const SizedBox.shrink();
    final page = _page.clamp(0, cards.length - 1);

    final years = {
      for (final m in cards)
        if (m.month != null) m.month!.year,
    }.toList()..sort();
    final year = _yearAt(cards, page);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (years.isNotEmpty && year != null)
          _YearRail(years, year, accent, (y) {
            // Jump to that year's first card.
            final i = cards.indexWhere((c) => c.month?.year == y);
            if (i >= 0) _goTo(i);
          }),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            // Full width, edge to edge with the content above: the 16:9 photo
            // + the footer (month heading, project, ring row), plus room under
            // the card for its shadow.
            final cardWidth = constraints.maxWidth;
            final height = cardWidth * 9 / 16 + 152 + 18;
            return SizedBox(
              height: height,
              child: PageView.builder(
                controller: _pages,
                physics: const BouncingScrollPhysics(),
                itemCount: cards.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: _monthCard(context, cards[i], isDark, accent),
                ),
              ),
            );
          },
        ),
        if (cards.length > 1) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              _ArrowButton(
                icon: LucideIcons.chevronLeft,
                accent: accent,
                enabled: page > 0,
                onTap: () => _goTo(page - 1),
              ),
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < cards.length; i++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: i == page ? 18 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: accent.withValues(
                                alpha: i == page ? 1 : 0.25,
                              ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              _ArrowButton(
                icon: LucideIcons.chevronRight,
                accent: accent,
                enabled: page < cards.length - 1,
                onTap: () => _goTo(page + 1),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _monthCard(
    BuildContext context,
    ConstructionMonth entry,
    bool isDark,
    Color accent,
  ) {
    final phase = entry.phase;
    final scheme = Theme.of(context).colorScheme;
    final status = (phase['status'] ?? 'Upcoming').toString();
    // This month's own progress when the phase carries a matching update,
    // otherwise the phase-level value (older backend / phases without updates).
    final pctRaw =
        entry.progressPercent ??
        phase['progressPercent'] ??
        phase['progress'] ??
        0;
    final pct = (pctRaw is num ? pctRaw.toInt() : int.tryParse('$pctRaw') ?? 0)
        .clamp(0, 100);
    final phaseName = (phase['name'] ?? phase['phaseName'] ?? 'Phase')
        .toString();
    final heading = entry.month == null
        ? phaseName.toUpperCase()
        : DateFormat('MMMM yyyy').format(entry.month!).toUpperCase();
    final hasPhotos = entry.images.isNotEmpty;

    final Color badgeBg;
    final Color badgeFg;
    if (status == 'Completed') {
      badgeBg = const Color(0xFF2E7D32);
      badgeFg = Colors.white;
    } else if (status == 'In Progress') {
      badgeBg = isDark ? Colors.white : const Color(0xFF0C312B);
      badgeFg = isDark ? const Color(0xFF0C312B) : Colors.white;
    } else {
      badgeBg = const Color(0xFFF4EFE3);
      badgeFg = const Color(0xFF0C312B);
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : scheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.07),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: GestureDetector(
              onTap: hasPhotos
                  ? () => widget.onOpenGallery(entry.images)
                  : null,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const ColoredBox(color: Color(0xFF0C312B)),
                  if (phase['_fallback'] == true)
                    // No backend phases at all: say so, not a dummy photo.
                    ColoredBox(
                      color: isDark
                          ? const Color(0xFF141B3A)
                          : const Color(0xFFF4EFE3),
                      child: Center(
                        child: Text(
                          'NO PHASES RECORDED',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            color: accent.withValues(alpha: 0.35),
                          ),
                        ),
                      ),
                    )
                  else if (hasPhotos)
                    // The photo fills the whole frame, edge to edge.
                    CachedNetworkImage(
                      imageUrl: widget.resolveUrl(entry.images.first),
                      fit: BoxFit.cover,
                      memCacheWidth: 1080,
                      fadeInDuration: Duration.zero,
                      fadeOutDuration: Duration.zero,
                      placeholder: (_, __) => const SizedBox.shrink(),
                      errorWidget: (_, __, ___) =>
                          Image.asset(widget.fallbackAsset, fit: BoxFit.cover),
                    )
                  else
                    Image.asset(widget.fallbackAsset, fit: BoxFit.cover),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                          color: badgeFg,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  heading,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.gelasio(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: accent,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.projectTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: accent.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    SizedBox(
                      width: 46,
                      height: 46,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: pct / 100.0,
                            strokeWidth: 3,
                            color: accent,
                            backgroundColor: accent.withValues(alpha: 0.12),
                          ),
                          Center(
                            child: Text(
                              '$pct%',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        phaseName.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                          color: accent.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The years, left to right, each over its dot on one rail; the selected one
/// is bold with a ringed dot. Tap a year to show its months.
class _YearRail extends StatelessWidget {
  const _YearRail(this.years, this.selected, this.accent, this.onSelect);

  final List<int> years;
  final int selected;
  final Color accent;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Stack(
        children: [
          // The rail, under the dots.
          Positioned(
            left: 0,
            right: 0,
            top: 47,
            child: Container(height: 1, color: accent.withValues(alpha: 0.2)),
          ),
          Row(
            children: [
              for (final y in years)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onSelect(y),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '$y',
                          style: GoogleFonts.gelasio(
                            fontSize: 20,
                            fontWeight: y == selected
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: y == selected
                                ? accent
                                : accent.withValues(alpha: 0.55),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: 14,
                          height: 14,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).scaffoldBackgroundColor,
                            border: Border.all(
                              color: y == selected
                                  ? accent
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A round ‹ / › button that slides the cards one step; faded at either end.
class _ArrowButton extends StatelessWidget {
  const _ArrowButton({
    required this.icon,
    required this.accent,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final Color accent;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1 : 0.3,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accent.withValues(alpha: 0.06),
            border: Border.all(color: accent.withValues(alpha: 0.15)),
          ),
          child: Icon(icon, size: 18, color: accent),
        ),
      ),
    );
  }
}
