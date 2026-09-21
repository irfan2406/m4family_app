import 'package:flutter/foundation.dart';

/// The one place that decides whether the iOS presentation layer is on.
///
/// Everything iOS-only — the Liquid Glass surfaces, native Cupertino controls,
/// iOS theme tweaks — branches on [isIOS], and every Android code path stays
/// exactly as it was.
///
/// This reads [defaultTargetPlatform] rather than `dart:io`'s
/// `Platform.isIOS`. On a phone the two always agree; unlike `dart:io`, this
/// one follows `debugDefaultTargetPlatformOverride`, so tests can render both
/// platforms, and it does not throw on web.
abstract final class M4Platform {
  /// True on iPhone and iPad only — not macOS, not web.
  static bool get isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
}
