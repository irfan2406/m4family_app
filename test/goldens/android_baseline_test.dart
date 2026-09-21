@Tags(['golden'])
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_harness.dart';

/// Android must not change by a single pixel while the iOS presentation layer
/// is built. These goldens were recorded on Android *before* any iOS work;
/// every scene is rendered on Android again here, so a pixel that moved fails.
void main() {
  setUpAll(setUpGoldenHarness);

  for (final scene in goldenScenes) {
    testWidgets('android: ${scene.name}', (tester) async {
      await renderGolden(
        tester,
        platform: TargetPlatform.android,
        scene: scene,
        goldenPath: 'android/${scene.name}.png',
      );
    });
  }
}
