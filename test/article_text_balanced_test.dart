import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m4_mobile/presentation/widgets/article_text.dart';

/// Community > About the community: both edges aligned without the wide word
/// gaps plain justify opened on a phone ("Rooted   in   the"), and a tight
/// gap between paragraphs. [ArticleText.balancedJustify] breaks the lines
/// itself and nudges each one to the edge with small letter / word spacing.
const _text =
    'Rooted in the heritage and evolving skyline of Mazgaon, the M4 Mazgaon '
    'Community brings together a growing portfolio of thoughtfully designed '
    'residences, delivered homes and future landmarks.\n\n'
    'Our journey in the neighbourhood began with Ocean View — delivered with '
    'Occupation Certificate in approximately 24 months, bringing together '
    'contemporary residences, expansive sea views and a lifestyle designed '
    'around South Mumbai living.';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    double width = 411,
    int collapsedLines = 100,
  }) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = Size(width, 1600);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Align(
              alignment: Alignment.topLeft,
              child: ArticleText(
                text: _text,
                style: const TextStyle(fontSize: 14, height: 1.55),
                linkColor: Colors.green,
                collapsedLines: collapsedLines,
                balancedJustify: true,
                paragraphGap: 4,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Text> lines(WidgetTester tester) => tester
      .widgetList<Text>(find.byType(Text))
      .where((t) => t.data != 'Read more' && t.data != 'Read less')
      .toList();

  double widthOf(WidgetTester tester, Text t) => tester
      .renderObject<RenderParagraph>(
        find.descendant(of: find.byWidget(t), matching: find.byType(RichText)),
      )
      .getMaxIntrinsicWidth(double.infinity);

  for (final width in [320.0, 360.0, 411.0]) {
    testWidgets('${width.toInt()}dp: every word, no line past the edge', (
      tester,
    ) async {
      await pump(tester, width: width);
      final shown = lines(tester);
      final maxWidth = width - 48;

      // Nothing is lost or reordered by breaking the lines ourselves.
      final words = shown.map((t) => t.data!).join(' ').split(' ');
      expect(words.join(' '), _text.replaceAll('\n\n', ' '));

      for (final line in shown) {
        expect(
          widthOf(tester, line),
          lessThanOrEqualTo(maxWidth + 0.5),
          reason: '"${line.data}" runs past the edge',
        );
        // Word gaps stay close to normal: never the wide gaps of justify.
        expect(line.style?.wordSpacing ?? 0, lessThanOrEqualTo(2.5));
        expect(line.style?.letterSpacing ?? 0, lessThanOrEqualTo(0.4));
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a paragraph ends on its natural spacing', (tester) async {
    await pump(tester);
    final ends = lines(tester).where(
      (t) => t.data!.endsWith('landmarks.') || t.data!.endsWith('living.'),
    );
    expect(ends, hasLength(2));
    for (final end in ends) {
      // A last line is never stretched (it may only be tightened to fit).
      expect(end.style?.wordSpacing ?? 0, lessThanOrEqualTo(0));
      expect(end.style?.letterSpacing ?? 0, lessThanOrEqualTo(0));
    }
  });

  testWidgets('the paragraph gap is the tight one asked for', (tester) async {
    await pump(tester);
    final gaps = tester
        .widgetList<SizedBox>(find.byType(SizedBox))
        .where((b) => b.height == 4);
    expect(gaps, hasLength(1), reason: 'one gap between the two paragraphs');
  });

  testWidgets('Read more still collapses and expands', (tester) async {
    await pump(tester, collapsedLines: 4);
    expect(lines(tester), hasLength(4));
    expect(find.text('Read more'), findsOneWidget);

    await tester.tap(find.text('Read more'));
    await tester.pump();
    expect(lines(tester).length, greaterThan(4));
    expect(find.text('Read less'), findsOneWidget);
  });
}
