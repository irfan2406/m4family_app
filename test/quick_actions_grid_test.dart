import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// CP profile > QUICK ACTIONS.
///
/// Each of the four tiles reported BOTTOM OVERFLOWED BY 5.6 PIXELS on a 360dp
/// phone. The row is four columns inside 28px page padding with 8px gaps, so a
/// cell is (360 - 56 - 24) / 4 = 70 wide and, at childAspectRatio 0.82, 85.4
/// tall — while the tile asked for an icon box of
///     (70 * 0.58).clamp(72, 100) -> 72
/// because the clamp floors it at 72, larger than the cell can hold, and then
/// added the gap, the label and its padding on top.
///
/// This mirrors the production tile and pins the rule that replaced it: the
/// icon box is capped by the height the cell actually has, so it shrinks
/// instead of pushing the label out. It is the sizing rule under test, not the
/// screen itself.
void main() {
  const labels = ['VISIT', 'BOOKING', 'TRACKER', 'BOOK VISIT'];
  const pagePadding = 28.0;
  const spacing = 8.0;
  const ratio = 0.82;

  /// [capByHeight] false reproduces the original tile.
  Widget tile(String label, {required bool capByHeight}) => LayoutBuilder(
    builder: (context, constraints) {
      final desired = (constraints.maxWidth * 0.58).clamp(72.0, 100.0);
      final labelRoom =
          4 + 6 + MediaQuery.textScalerOf(context).scale(9.5) * 1.15;
      final available = constraints.maxHeight - labelRoom;
      final side = (capByHeight &&
              available.isFinite &&
              available > 0 &&
              available < desired)
          ? available
          : desired;

      final text = Text(
        label,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          height: 1.15,
        ),
      );

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: side, height: side, child: const ColoredBox(color: Colors.black12)),
            const SizedBox(height: 6),
            capByHeight ? Flexible(child: text) : text,
          ],
        ),
      );
    },
  );

  Widget grid({required bool capByHeight}) => MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: pagePadding),
          child: GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: ratio,
            children: [
              for (final l in labels) tile(l, capByHeight: capByHeight),
            ],
          ),
        ),
      ),
    ),
  );

  Future<void> at(WidgetTester tester, double dp, double scale) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = Size(dp, 1200);
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(() {
      tester.view.reset();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
  }

  testWidgets('360dp: the original tile overflowed — the reported bug', (
    tester,
  ) async {
    await at(tester, 360, 1.0);
    await tester.pumpWidget(grid(capByHeight: false));
    expect(
      tester.takeException(),
      isNotNull,
      reason: 'a 72px icon box in a 70px-wide cell is what drew the stripe',
    );
  });

  testWidgets('360dp: capping the box by the cell height fits', (tester) async {
    await at(tester, 360, 1.0);
    await tester.pumpWidget(grid(capByHeight: true));
    expect(tester.takeException(), isNull);
  });

  for (final dp in <double>[320, 360, 411, 480]) {
    for (final scale in <double>[0.86, 1.0, 1.3, 1.5]) {
      testWidgets('${dp.toInt()}dp @ ${scale}x fits', (tester) async {
        await at(tester, dp, scale);
        await tester.pumpWidget(grid(capByHeight: true));
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('411dp: the Moto G45 baseline keeps the full 72px box', (
    tester,
  ) async {
    // The cap must not shrink the box on the width the design was drawn for,
    // or the fix would change a layout that was already correct.
    const cellWidth = (411 - pagePadding * 2 - spacing * 3) / 4;
    const cellHeight = cellWidth / ratio;
    final labelRoom = 4 + 6 + 9.5 * 1.15;
    expect(cellHeight - labelRoom, greaterThan(72.0));
  });
}
