import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Manual image-cache purge for the Purge Cache screen.
///
/// The backend now gives every uploaded/replaced image a NEW filename (so a
/// replacement always has a new URL), which means the app fetches changed media
/// fresh on its own — no automatic cache-busting or periodic clearing is
/// needed. This remains only for the user-initiated "Purge Cache" action.
///
/// Empties every image cache the app holds: the on-disk network-image store,
/// the SVG picture cache, and Flutter's in-memory (decoded) image cache.
Future<void> clearImageCaches() async {
  try {
    await DefaultCacheManager().emptyCache();
  } catch (_) {
    // Best-effort; a failed disk purge must not throw to the UI.
  }
  try {
    svg.cache.clear();
  } catch (_) {
    // SVG cache API is best-effort.
  }
  try {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  } catch (_) {
    // In-memory cache clear is best-effort.
  }
}
