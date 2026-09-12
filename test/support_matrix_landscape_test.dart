import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/screens/support/support_screen.dart';

/// Support Hub > SUPPORT MATRIX.
///
/// The grid was pinned to crossAxisCount: 2 with childAspectRatio: 1.05, which
/// ties each cell's height to its width. Rotated to landscape the grid's ~750dp
/// gave every tile ~370dp of width and the same again of height, so the icon
/// sat alone at the top of a huge card and the title and subtitle were pushed
/// out of sight.
///
/// The column count now follows the width and the height is capped. These pin
/// both ends: landscape stays readable, and portrait is untouched.
void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async => null,
    );
  });

  Future<void> pumpAt(WidgetTester tester, Size size) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(
            ApiClient(baseUrl: 'http://localhost'),
          ),
        ],
        child: const MaterialApp(home: SupportScreen()),
      ),
    );
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  /// Every tile's copy, so "rendered" means the text is really laid out.
  void expectAllTilesReadable() {
    expect(find.text('WhatsApp Support'), findsOneWidget);
    expect(find.text('Schedule Visit'), findsOneWidget);
    expect(find.text('Call Us'), findsOneWidget);
    expect(find.text('Help Center'), findsOneWidget);
  }

  testWidgets('landscape: the tiles stay cards, not full-height panels', (
    tester,
  ) async {
    await pumpAt(tester, const Size(915, 411));
    expect(tester.takeException(), isNull);
    expectAllTilesReadable();

    // The reported bug: a cell as tall as it is wide, ~370 on this width.
    final tile = tester.getSize(
      find
          .ancestor(
            of: find.text('WhatsApp Support'),
            matching: find.byType(GestureDetector),
          )
          .first,
    );
    expect(
      tile.height,
      lessThanOrEqualTo(200.0),
      reason: 'a wide cell must stay a card',
    );
    // ...and wider than it is tall now, because more columns share the row.
    expect(tile.width, lessThan(320.0));
  });

  testWidgets('portrait: unchanged — two columns, same proportions', (
    tester,
  ) async {
    await pumpAt(tester, const Size(411, 915));
    expect(tester.takeException(), isNull);
    expectAllTilesReadable();

    final tile = tester.getSize(
      find
          .ancestor(
            of: find.text('WhatsApp Support'),
            matching: find.byType(GestureDetector),
          )
          .first,
    );
    // Two columns on a phone: each tile is a little under half the width.
    expect(tile.width, greaterThan(140.0));
    expect(tile.width, lessThan(205.0));
    // The design ratio still applies below the cap.
    expect(tile.height, closeTo(tile.width / 1.05, 1.0));
  });

  for (final size in <Size>[
    Size(320, 700),
    Size(360, 800),
    Size(411, 915),
    Size(700, 400),
    Size(915, 411),
    Size(1280, 800),
  ]) {
    testWidgets(
      '${size.width.toInt()}x${size.height.toInt()} lays out cleanly',
      (tester) async {
        await pumpAt(tester, size);
        expect(tester.takeException(), isNull);
        expectAllTilesReadable();
      },
    );
  }
}
