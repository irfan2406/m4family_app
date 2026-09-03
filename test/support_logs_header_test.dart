import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Help Center > OPERATIONAL LOGS header: a heading on the left and a
/// "VIEW ALL LOGS" action on the right, with nothing flexible between them.
/// On a narrow screen — or with the system font turned up — the two labels
/// together are wider than the row and it overflows on the right.
///
/// This mirrors the production row (support_screen.dart _buildOperationalLogsHeader)
/// and pins the shape that replaced it: the heading in a Flexible, the action
/// shrinking to fit.
void main() {
  Widget row({required bool fixed}) {
    const heading = 'OPERATIONAL LOGS';
    const action = 'VIEW ALL LOGS';
    const headingStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 2,
    );
    const actionStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.2,
    );

    final Widget left = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        fixed
            ? const Text(heading, style: headingStyle)
            : const Text(
                heading,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: headingStyle,
              ),
        const SizedBox(height: 4),
        Container(width: 32, height: 2, color: Colors.black),
      ],
    );

    return MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: fixed
                ? [left, const Text(action, style: actionStyle)]
                : [
                    Flexible(child: left),
                    const SizedBox(width: 12),
                    const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(action, maxLines: 1, style: actionStyle),
                    ),
                  ],
          ),
        ),
      ),
    );
  }

  Future<void> at(WidgetTester tester, double dp, double textScale) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = Size(dp, 800);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(() {
      tester.view.reset();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
  }

  testWidgets('the old row overflowed on a narrow screen at 1.5x', (
    tester,
  ) async {
    await at(tester, 320, 1.5);
    await tester.pumpWidget(row(fixed: true));
    expect(
      tester.takeException(),
      isNotNull,
      reason: 'two unflexed labels are wider than a 320dp row at 1.5x',
    );
  });

  for (final dp in <double>[320, 360, 411]) {
    for (final scale in <double>[1.0, 1.5]) {
      testWidgets('${dp.toInt()}dp @ ${scale}x fits', (tester) async {
        await at(tester, dp, scale);
        await tester.pumpWidget(row(fixed: false));
        expect(tester.takeException(), isNull);
      });
    }
  }
}
