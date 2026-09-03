import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:m4_mobile/presentation/screens/support/support_tickets_screen.dart';

/// Help Center > VIEW ALL LOGS (the OPERATIONAL LOGS screen).
///
/// This pumps the real screen, not a mirror of it. It seeds itself from its
/// mock log set and only replaces that if GET /api/logs comes back with rows,
/// so with no network it renders exactly what a user sees before the fetch
/// lands — header, search bar and log cards.
///
/// The header title sat between a back button and a balancing spacer with no
/// flex, and the card footer put the date and VIEW DETAILS in a spaceBetween
/// row with no flex either; both ran off the right at a larger system font.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> pumpAt(
    WidgetTester tester,
    double dp,
    double textScale,
  ) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = Size(dp, 900);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(() {
      tester.view.reset();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: SupportTicketsScreen()),
      ),
    );
    // Not pumpAndSettle: the cards carry entrance animations that would keep
    // the scheduler busy. A few frames is enough for layout to run.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 600));
  }

  for (final dp in <double>[320, 360, 411]) {
    for (final scale in <double>[1.0, 1.3, 1.5]) {
      testWidgets('${dp.toInt()}dp @ ${scale}x lays out without overflow', (
        tester,
      ) async {
        await pumpAt(tester, dp, scale);
        expect(tester.takeException(), isNull);
        // The screen really did build — the heading is on it.
        expect(find.text('OPERATIONAL LOGS'), findsOneWidget);
      });
    }
  }
}
