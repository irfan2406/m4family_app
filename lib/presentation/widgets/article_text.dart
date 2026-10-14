import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Long-form body copy for the app's articles — community/project overviews,
/// Who We Are, and the like.
///
/// Two things every article gets, consistently:
///  1. Clean, left-aligned body copy with even single spacing between words.
///     (Plain justify was tried but, on a narrow phone column, it stretched
///     the spaces to reach the right edge and left big gaps between words.
///     [ArticleText.balancedJustify] is the opt-in alternative: edge to edge
///     without the gaps.)
///  2. A **Read more / Read less** toggle whenever the copy is taller than
///     [collapsedLines] (default 4). Short copy shows in full with no toggle.
///
/// Measuring with a [TextPainter] against the real width is what decides
/// whether the toggle is needed, so it never appears on text that already fits.
///
/// The copy is normalised first: soft line breaks (a single `\n` the admin
/// typed mid-sentence) become spaces so each justified line fills with words,
/// while blank-line paragraph breaks are kept. Without this, a forced short
/// line — e.g. "…it's experienced." on its own — gets stretched to full width
/// and leaves large gaps between the words.
String _normalizeArticle(String raw) {
  return raw
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      // Split on blank-line paragraph breaks.
      .split(RegExp(r'\n[ \t]*\n+'))
      // Inside a paragraph, collapse every run of whitespace to one space.
      .map((p) => p.replaceAll(RegExp(r'\s+'), ' ').trim())
      .where((p) => p.isNotEmpty)
      .join('\n\n');
}

/// Balanced justification: the most a line may add between two letters, and
/// on top of a normal space. Every line spends the same share of both
/// (see `_balancedLines`), so all lines keep one even texture: letter spacing
/// moves by a fraction of a point, word spacing carries the rest. A line that
/// would need more than these allow is filled only as far as they go.
const double _kMaxExtraLetterSpacing = 0.4;
const double _kMaxExtraWordSpacing = 2.5;

/// …and the most a line may tighten, so it can take one more word when that
/// lands nearer the edge than breaking early would (the lines are broken
/// here, not by the plain wrapper, for exactly this choice).
const double _kMaxShrinkLetterSpacing = 0.15;
const double _kMaxShrinkWordSpacing = 1.0;

/// One laid-out line of a [ArticleText.balancedJustify] paragraph.
class _ArticleLine {
  const _ArticleLine({
    required this.text,
    required this.rest,
    required this.letterSpacing,
    required this.wordSpacing,
    required this.paragraph,
    this.fits = true,
  });

  /// The words on this line.
  final String text;

  /// This line and everything after it in the paragraph, for the collapsed
  /// view's ellipsis.
  final String rest;

  /// Extra spacing that fills this line to the right edge.
  final double letterSpacing;
  final double wordSpacing;

  /// Index of the paragraph the line belongs to.
  final int paragraph;

  /// False for a single word wider than the column even when tightened (a
  /// long link): that line wraps normally instead of running off the edge.
  final bool fits;
}

class ArticleText extends StatefulWidget {
  const ArticleText({
    super.key,
    required this.text,
    required this.style,
    required this.linkColor,
    this.collapsedLines = 4,
    this.textAlign = TextAlign.start,
    this.paragraphGap,
    this.balancedJustify = false,
  });

  /// The article copy (may contain its own paragraph breaks).
  final String text;

  /// The body text style.
  final TextStyle style;

  /// The "Read more" / "Read less" colour.
  final Color linkColor;

  /// How many lines to show before the toggle collapses the rest.
  final int collapsedLines;

  /// Start-aligned by default. [TextAlign.justify] runs each line edge to
  /// edge; the last line of every paragraph stays start-aligned.
  final TextAlign textAlign;

  /// Height of the space between paragraphs. Null keeps a full blank text
  /// line (one line-height); a value draws that blank line at this height
  /// instead, for a tighter gap.
  final double? paragraphGap;

  /// Lines run edge to edge without widening the gaps between words: each
  /// line is filled mostly with fractional letter spacing and only a little
  /// word spacing (see [_kMaxExtraLetterSpacing] / [_kMaxExtraWordSpacing]).
  /// The last line of every paragraph keeps its natural spacing. Overrides
  /// [textAlign].
  final bool balancedJustify;

  @override
  State<ArticleText> createState() => _ArticleTextState();
}

class _ArticleTextState extends State<ArticleText> {
  bool _expanded = false;

  /// The last balanced layout and what it was computed for: breaking the
  /// lines measures every word, so it is redone only when the copy, width,
  /// style or direction changes — not on every rebuild (e.g. Read more).
  Object? _linesKey;
  List<_ArticleLine> _lines = const [];

  /// The normalised copy as one span. With [ArticleText.paragraphGap] set, the
  /// blank line between paragraphs is drawn from a small, fixed-height newline
  /// (a blank line takes the height of the text on it), so the gap shrinks
  /// while each paragraph keeps the body style and its own line breaks.
  TextSpan _articleSpan(String text) {
    final gap = widget.paragraphGap;
    if (gap == null) return TextSpan(text: text, style: widget.style);
    final paragraphs = text.split('\n\n');
    final gapStyle = widget.style.copyWith(fontSize: gap, height: 1.0);
    return TextSpan(
      style: widget.style,
      children: [
        for (var i = 0; i < paragraphs.length; i++) ...[
          if (i > 0) ...[
            const TextSpan(text: '\n'),
            TextSpan(text: '\n', style: gapStyle),
          ],
          TextSpan(text: paragraphs[i]),
        ],
      ],
    );
  }

  /// Breaks every paragraph into lines and works out the spacing that carries
  /// each line (bar a paragraph's last) exactly to [maxWidth].
  ///
  /// The breaks are chosen for the whole paragraph at once (the Knuth–Plass
  /// idea): of every way to break it, the one whose lines need the smallest
  /// adjustments. Each line then reaches the edge by opening up within
  /// [_kMaxExtraLetterSpacing] / [_kMaxExtraWordSpacing] or tightening within
  /// [_kMaxShrinkLetterSpacing] / [_kMaxShrinkWordSpacing]. Breaking word by
  /// word instead left a line well short whenever a long word came next.
  List<_ArticleLine> _balancedLines(
    List<String> paragraphs,
    double maxWidth,
    TextDirection direction,
  ) {
    double measure(String s) => (TextPainter(
      text: TextSpan(text: s, style: widget.style),
      textDirection: direction,
      maxLines: 1,
    )..layout()).width;
    // A hair of slack so rounding can never push a line past the edge.
    final target = maxWidth - 0.5;
    final space = measure('x x') - measure('xx');

    final lines = <_ArticleLine>[];
    for (var p = 0; p < paragraphs.length; p++) {
      final words = paragraphs[p].split(' ');
      final n = words.length;
      final widths = [for (final w in words) measure(w)];

      // Cost of setting words [i, j) on one line: the squared share of the
      // allowed adjustment it needs. A line that needs more than the limits
      // allow is still possible (it is then only partly filled) but costs
      // heavily, so it is chosen only when nothing better exists.
      double lineCost(int i, int j) {
        var natural = space * (j - i - 1);
        var chars = j - i - 1;
        for (var k = i; k < j; k++) {
          natural += widths[k];
          chars += words[k].length;
        }
        final spaces = j - i - 1;
        final delta = target - natural;
        final isLast = j == n;
        if (delta < 0) {
          final shrink =
              chars * _kMaxShrinkLetterSpacing +
              spaces * _kMaxShrinkWordSpacing;
          final ratio = shrink > 0 ? -delta / shrink : double.infinity;
          // Too wide even when tightened: only a lone word may do that.
          if (ratio > 1) return j - i == 1 ? 1e6 : double.infinity;
          return ratio * ratio;
        }
        if (isLast) return 0; // A paragraph's last line is never stretched.
        final stretch =
            chars * _kMaxExtraLetterSpacing + spaces * _kMaxExtraWordSpacing;
        final ratio = stretch > 0 ? delta / stretch : 1e3;
        return ratio <= 1 ? ratio * ratio : 1e3 * ratio * ratio;
      }

      // best[j] = lowest total cost of setting words [0, j).
      final best = List<double>.filled(n + 1, double.infinity);
      final from = List<int>.filled(n + 1, 0);
      best[0] = 0;
      for (var j = 1; j <= n; j++) {
        for (var i = j - 1; i >= 0; i--) {
          if (best[i] == double.infinity) continue;
          final cost = lineCost(i, j);
          if (cost == double.infinity) break; // Longer lines only get wider.
          final total = best[i] + cost;
          if (total < best[j]) {
            best[j] = total;
            from[j] = i;
          }
        }
      }
      final breaks = <int>[];
      for (var j = n; j > 0; j = from[j]) {
        breaks.add(j);
      }
      final lineWords = <List<String>>[];
      var start = 0;
      for (final end in breaks.reversed) {
        lineWords.add(words.sublist(start, end));
        start = end;
      }

      for (var i = 0; i < lineWords.length; i++) {
        final text = lineWords[i].join(' ');
        final spaces = lineWords[i].length - 1;
        final isLast = i == lineWords.length - 1;
        final delta = target - measure(text);
        final fits =
            delta +
                text.length * _kMaxShrinkLetterSpacing +
                spaces * _kMaxShrinkWordSpacing >=
            0;
        // Letters and spaces take the same share of their limits, so every
        // line keeps the same texture (no airy line next to a tight one).
        var letter = 0.0;
        var word = 0.0;
        if (fits && delta > 0 && !isLast) {
          final capacity =
              text.length * _kMaxExtraLetterSpacing +
              spaces * _kMaxExtraWordSpacing;
          final share = (delta / capacity).clamp(0.0, 1.0);
          letter = share * _kMaxExtraLetterSpacing;
          word = spaces > 0 ? share * _kMaxExtraWordSpacing : 0;
        } else if (fits && delta < 0) {
          // Tighten (any line, the last included) just enough to fit.
          final capacity =
              text.length * _kMaxShrinkLetterSpacing +
              spaces * _kMaxShrinkWordSpacing;
          final share = (-delta / capacity).clamp(0.0, 1.0);
          letter = -share * _kMaxShrinkLetterSpacing;
          word = spaces > 0 ? -share * _kMaxShrinkWordSpacing : 0;
        }
        lines.add(
          _ArticleLine(
            text: text,
            rest: lineWords.sublist(i).expand((w) => w).join(' '),
            letterSpacing: letter,
            wordSpacing: word,
            paragraph: p,
            fits: fits,
          ),
        );
      }
    }
    return lines;
  }

  Widget _readMoreToggle() {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        padding: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: widget.linkColor.withValues(alpha: 0.4)),
          ),
        ),
        child: Text(
          _expanded ? 'Read less' : 'Read more',
          style: GoogleFonts.inter(
            color: widget.linkColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildBalanced(String text, TextDirection direction) {
    final paragraphs = text.split('\n\n');
    final lineHeight =
        (widget.style.fontSize ?? 14) * (widget.style.height ?? 1.0);
    final gap = widget.paragraphGap ?? lineHeight;
    final baseLetter = widget.style.letterSpacing ?? 0;
    final baseWord = widget.style.wordSpacing ?? 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final key = Object.hash(
          text,
          constraints.maxWidth,
          widget.style,
          direction,
        );
        if (key != _linesKey) {
          _lines = _balancedLines(paragraphs, constraints.maxWidth, direction);
          _linesKey = key;
        }
        final lines = _lines;
        final overflows = lines.length > widget.collapsedLines;
        final shown = (_expanded || !overflows)
            ? lines.length
            : widget.collapsedLines;

        final children = <Widget>[];
        for (var i = 0; i < shown; i++) {
          final line = lines[i];
          if (i > 0 && line.paragraph != lines[i - 1].paragraph) {
            children.add(SizedBox(height: gap));
          }
          final truncated = !_expanded && overflows && i == shown - 1;
          children.add(
            !line.fits
                ? Text(line.text, style: widget.style)
                : truncated
                // The collapsed view's last line: natural spacing, cut with
                // an ellipsis like the plain layout.
                ? Text(
                    line.rest,
                    style: widget.style,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : Text(
                    line.text,
                    style: widget.style.copyWith(
                      letterSpacing: baseLetter + line.letterSpacing,
                      wordSpacing: baseWord + line.wordSpacing,
                    ),
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.visible,
                  ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Read as one passage by screen readers, not line by line.
            Semantics(
              label: text.replaceAll('\n\n', '\n'),
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children,
                ),
              ),
            ),
            if (overflows) ...[const SizedBox(height: 12), _readMoreToggle()],
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = _normalizeArticle(widget.text);
    if (text.isEmpty) return const SizedBox.shrink();

    final direction = Directionality.of(context);
    if (widget.balancedJustify) return _buildBalanced(text, direction);

    final span = _articleSpan(text);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Does the copy exceed the collapsed height at this width?
        final painter = TextPainter(
          text: span,
          maxLines: widget.collapsedLines,
          textAlign: widget.textAlign,
          textDirection: direction,
        )..layout(maxWidth: constraints.maxWidth);
        final overflows = painter.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              span,
              textAlign: widget.textAlign,
              maxLines: _expanded ? null : widget.collapsedLines,
              overflow: _expanded
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
            ),
            if (overflows) ...[const SizedBox(height: 12), _readMoreToggle()],
          ],
        );
      },
    );
  }
}
