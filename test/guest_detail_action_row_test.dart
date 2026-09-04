import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guest project detail > the VIDEO CALL / COMPLETION / SITE VISIT row.
///
/// The row was given `crossAxisAlignment: CrossAxisAlignment.stretch` so the
/// three cards would match the tallest one. Inside the page's vertical
/// SingleChildScrollView the row has an UNBOUNDED height, and stretch then
/// hands its children `h=Infinity`:
///
///     BoxConstraints forces an infinite height.
///     The offending constraints were: BoxConstraints(0.0<=w<=Infinity, h=Infinity)
///
/// That assertion aborts performLayout for the row, and because the failure
/// propagates up the scroll view every ancestor is left `size: MISSING` — so
/// the entire page rendered blank, with no visible error.
///
/// IntrinsicHeight measures the tallest child first, which gives the row a
/// bounded height and lets stretch do what it was added for. This pins both
/// halves: the original combination throws, the fixed one does not.
void main() {
  Widget cards({required bool intrinsic}) {
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final label in ['VIDEO CALL', 'COMPLETION', 'SITE VISIT'])
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black12,
              child: Text(label),
            ),
          ),
      ],
    );

    return MaterialApp(
      home: Scaffold(
        // The page's own scroll view: vertical, so its child's height is
        // unbounded — which is the whole point of the trap.
        body: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: intrinsic ? IntrinsicHeight(child: row) : row,
              ),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('stretch in an unbounded row throws — the reported blank page', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(411, 900);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(cards(intrinsic: false));
    // The first failure is "BoxConstraints forces an infinite height", and it
    // cascades into a dozen more "RenderBox was not laid out" as every
    // ancestor is left without a size — which is why the real page went blank
    // rather than showing one red error box.
    expect(tester.takeException(), isNotNull);
  });

  testWidgets('IntrinsicHeight bounds it, and the cards still match', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(411, 900);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(cards(intrinsic: true));
    expect(tester.takeException(), isNull);

    // All three cards render, and share one height — what stretch was for.
    expect(find.text('VIDEO CALL'), findsOneWidget);
    expect(find.text('COMPLETION'), findsOneWidget);
    expect(find.text('SITE VISIT'), findsOneWidget);

    final heights = ['VIDEO CALL', 'COMPLETION', 'SITE VISIT']
        .map((l) => tester.getSize(find.ancestor(
              of: find.text(l),
              matching: find.byType(Container),
            ).first).height)
        .toSet();
    expect(heights, hasLength(1));
  });

  for (final dp in <double>[320, 360, 411]) {
    testWidgets('${dp.toInt()}dp lays out without overflow', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = Size(dp, 900);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(cards(intrinsic: true));
      expect(tester.takeException(), isNull);
    });
  }
}
