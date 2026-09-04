import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The guest / CP home "connect" grid cells clipped their description on a
/// narrow phone: BOTTOM OVERFLOWED BY 15 / 30 PIXELS on a Realme GT 60, whose
/// logical width is 361dp against the 411dp the layout was drawn for.
///
/// This mirrors the production cell — 48px icon, 16 gap, a 13pt title, 6 gap,
/// an 11pt description, 20px padding all round, in a two-column
/// GridView.count — and pins the sizing rule that replaced the fixed
/// childAspectRatio: below ~178px of content the cell gets taller instead of
/// clipping. It is the rule under test, not the screens themselves.
void main() {
  // The four labels the grid actually carries.
  const items = <List<String>>[
    ['EXPLORE PROJECTS', 'Browse our portfolio of properties'],
    ['BOOK A VIEWING', 'Schedule a visit to our show apartment'],
    ['MEDIA GALLERY', 'Watch films and view property renders'],
    ['REGISTER INTEREST', 'Register your interest in our properties'],
  ];

  Widget cell(String title, String desc) => Padding(
    padding: const EdgeInsets.all(20),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(width: 48, height: 48, color: Colors.black12),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        Flexible(
          child: Text(
            desc,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, height: 1.4),
          ),
        ),
      ],
    ),
  );

  /// The cell as it was: nothing stops the two Texts growing.
  Widget oldCell(String title, String desc) => Padding(
    padding: const EdgeInsets.all(20),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(width: 48, height: 48, color: Colors.black12),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          desc,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, height: 1.4),
        ),
      ],
    ),
  );

  /// [ratio] null = the new rule, otherwise the old fixed value.
  Widget grid({double? ratio, bool old = false}) => MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        // The card the grid sits in: 24px page margin each side.
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cellWidth = (constraints.maxWidth - 1) / 2;
              final designHeight = cellWidth / 0.95;
              final cellHeight = designHeight < 178 ? 178.0 : designHeight;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 1,
                crossAxisSpacing: 1,
                childAspectRatio: ratio ?? (cellWidth / cellHeight),
                children: [
                  for (final i in items)
                    old ? oldCell(i[0], i[1]) : cell(i[0], i[1]),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );

  Future<void> atWidth(WidgetTester tester, double dp) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = Size(dp, 900);
    addTearDown(tester.view.reset);
  }

  testWidgets('361dp (Realme GT 60): the old cell overflowed', (
    tester,
  ) async {
    await atWidth(tester, 361);
    await tester.pumpWidget(grid(ratio: 0.95, old: true));
    expect(
      tester.takeException(),
      isNotNull,
      reason:
          'unbounded text in a cell fixed at width x 0.95 is the reported bug',
    );
  });

  testWidgets('361dp: bounding the text alone already fits', (tester) async {
    // Belt and braces: even on the old ratio the cell can no longer overflow,
    // because the description gives way instead.
    await atWidth(tester, 361);
    await tester.pumpWidget(grid(ratio: 0.95));
    expect(tester.takeException(), isNull);
  });

  testWidgets('361dp (Realme GT 60): the height rule fits', (tester) async {
    await atWidth(tester, 361);
    await tester.pumpWidget(grid());
    expect(tester.takeException(), isNull);
  });

  testWidgets('411dp (Moto G45 / emulator): still fits, ratio untouched', (
    tester,
  ) async {
    await atWidth(tester, 411);
    await tester.pumpWidget(grid());
    expect(tester.takeException(), isNull);

    // At this width the cell is already taller than the 178 floor, so the
    // design ratio is what gets used.
    final cellWidth = (411 - 48 - 1) / 2;
    expect(cellWidth / 0.95, greaterThan(178));
  });

  testWidgets('320dp (a small phone): still fits', (tester) async {
    await atWidth(tester, 320);
    await tester.pumpWidget(grid());
    expect(tester.takeException(), isNull);
  });
}
