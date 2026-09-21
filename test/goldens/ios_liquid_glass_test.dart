@Tags(['golden'])
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_harness.dart';

/// The same scenes as the Android baseline, rendered on iOS: the Liquid Glass
/// presentation layer, captured so any change to it is a visible diff.
void main() {
  setUpAll(setUpGoldenHarness);

  for (final scene in goldenScenes) {
    testWidgets('ios: ${scene.name}', (tester) async {
      await renderGolden(
        tester,
        platform: TargetPlatform.iOS,
        scene: scene,
        goldenPath: 'ios/${scene.name}.png',
      );
    });
  }
}
