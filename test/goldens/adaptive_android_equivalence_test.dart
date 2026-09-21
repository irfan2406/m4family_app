@Tags(['golden'])
library;

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';

import 'golden_harness.dart' show runOnPlatform;

/// The iOS pass moved the app's Material controls to their `.adaptive`
/// constructors (and a spinner's `color:` to `valueColor:`). On Android every
/// one of them must paint exactly what the plain Material control painted —
/// this renders both, side by side, and compares them pixel for pixel.
void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  const green = Color(0xFF0C312B);
  const cream = Color(0xFFF4EFE3);

  final cases = <String, (Widget, Widget)>{
    'spinner, default': (
      const CircularProgressIndicator(),
      const CircularProgressIndicator.adaptive(),
    ),
    'spinner, color + stroke': (
      const CircularProgressIndicator(color: green, strokeWidth: 2),
      const CircularProgressIndicator.adaptive(
        valueColor: AlwaysStoppedAnimation<Color>(green),
        strokeWidth: 2,
      ),
    ),
    'spinner, translucent colour': (
      const CircularProgressIndicator(color: Colors.white24),
      const CircularProgressIndicator.adaptive(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white24),
      ),
    ),
    'checkbox, ticked': (
      Checkbox(
        value: true,
        onChanged: (_) {},
        activeColor: green,
        checkColor: cream,
        side: const BorderSide(color: Colors.black26),
      ),
      Checkbox.adaptive(
        value: true,
        onChanged: (_) {},
        activeColor: green,
        checkColor: cream,
        side: const BorderSide(color: Colors.black26),
      ),
    ),
    'checkbox, empty': (
      Checkbox(
        value: false,
        onChanged: (_) {},
        activeColor: green,
        checkColor: cream,
        side: const BorderSide(color: Colors.black26),
      ),
      Checkbox.adaptive(
        value: false,
        onChanged: (_) {},
        activeColor: green,
        checkColor: cream,
        side: const BorderSide(color: Colors.black26),
      ),
    ),
    'switch, on': (
      Switch(
        value: true,
        onChanged: (_) {},
        activeThumbColor: green,
        activeTrackColor: Colors.black12,
      ),
      Switch.adaptive(
        value: true,
        onChanged: (_) {},
        activeThumbColor: green,
        activeTrackColor: Colors.black12,
      ),
    ),
    'switch, off and disabled': (
      const Switch(
        value: false,
        onChanged: null,
        activeThumbColor: green,
        activeTrackColor: Colors.black12,
      ),
      const Switch.adaptive(
        value: false,
        onChanged: null,
        activeThumbColor: green,
        activeTrackColor: Colors.black12,
      ),
    ),
    'slider': (
      Slider(
        value: 4,
        min: 1,
        max: 10,
        divisions: 9,
        activeColor: const Color(0xFF7C3AED),
        inactiveColor: Colors.black12,
        onChanged: (_) {},
      ),
      Slider.adaptive(
        value: 4,
        min: 1,
        max: 10,
        divisions: 9,
        activeColor: const Color(0xFF7C3AED),
        inactiveColor: Colors.black12,
        onChanged: (_) {},
      ),
    ),
  };

  for (final entry in cases.entries) {
    testWidgets('android: ${entry.key} is unchanged', (tester) async {
      final (plain, adaptive) = entry.value;
      final a = GlobalKey();
      final b = GlobalKey();
      await runOnPlatform(TargetPlatform.android, () async {
        // Side by side in one frame, so a spinner's rotation is in the same
        // phase in both.
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: M4Theme.lightTheme,
            home: Scaffold(
              body: Row(
                children: [
                  _Cell(boundaryKey: a, child: plain),
                  _Cell(boundaryKey: b, child: adaptive),
                ],
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 350));
        _expectSamePixels(await _pixels(tester, a), await _pixels(tester, b));
      });
    });
  }

  testWidgets('android: pull-to-refresh is unchanged', (tester) async {
    Future<Uint8List> pulled(Widget Function(Widget list) refresh) async {
      final key = GlobalKey();
      late Uint8List pixels;
      await runOnPlatform(TargetPlatform.android, () async {
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: M4Theme.lightTheme,
            home: Scaffold(
              body: RepaintBoundary(
                key: key,
                child: refresh(
                  ListView(
                    children: [
                      for (var i = 0; i < 20; i++)
                        SizedBox(height: 60, child: Text('row $i')),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.fling(find.text('row 0'), const Offset(0, 300), 1000);
        // Mid-refresh: the indicator is out and spinning.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 150));
        await tester.pump(const Duration(milliseconds: 150));
        pixels = await _pixels(tester, key);
        // Let the (never-completing) refresh unwind before the next pass.
        await tester.pumpWidget(const SizedBox());
      });
      return pixels;
    }

    Future<void> neverEnds() => Completer<void>().future;
    final plain = await pulled(
      (list) => RefreshIndicator(
        onRefresh: neverEnds,
        color: green,
        backgroundColor: Colors.white,
        child: list,
      ),
    );
    final adaptive = await pulled(
      (list) => RefreshIndicator.adaptive(
        onRefresh: neverEnds,
        color: green,
        backgroundColor: Colors.white,
        child: list,
      ),
    );
    _expectSamePixels(plain, adaptive);
  });
}

class _Cell extends StatelessWidget {
  const _Cell({required this.boundaryKey, required this.child});

  final GlobalKey boundaryKey;
  final Widget child;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    key: boundaryKey,
    child: SizedBox(width: 180, height: 80, child: Center(child: child)),
  );
}

Future<Uint8List> _pixels(WidgetTester tester, GlobalKey key) async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final bytes = await tester.runAsync(() async {
    final ui.Image image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    return data!.buffer.asUint8List();
  });
  return bytes!;
}

void _expectSamePixels(Uint8List plain, Uint8List adaptive) {
  expect(adaptive.length, plain.length, reason: 'image sizes differ');
  var differing = 0;
  for (var i = 0; i < plain.length; i++) {
    if (plain[i] != adaptive[i]) differing++;
  }
  expect(differing, 0, reason: '$differing bytes differ from plain Material');
  // Guard against a vacuous pass on a blank capture.
  expect(
    plain.any((byte) => byte != plain.first),
    isTrue,
    reason: 'capture is blank',
  );
}
