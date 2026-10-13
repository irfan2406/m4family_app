import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Why admin-uploaded images/icons reflect slowly, and how these helpers fix it.
///
/// Every network image/icon is loaded through `CachedNetworkImage`, which keys
/// its on-disk cache by the image URL (via [DefaultCacheManager]). When the
/// admin REPLACES an image but keeps the same URL/filename, the app sees the
/// same URL, finds the old file already cached, and keeps showing the stale
/// copy — the cache manager's default stale window is ~30 days. SVGs and the
/// in-memory decoded cache behave the same way.
///
/// There are two cures here, both URL-safe (they clear the cache rather than
/// mutate URLs, so nothing breaks for signed/CDN assets):
///   * [clearImageCaches] — an immediate, on-demand purge (the Purge Cache
///     screen). After it runs, the next view of each image re-downloads fresh.
///   * [refreshStaleImageCacheOnLaunch] — an automatic purge at most once per
///     [_autoRefreshInterval] on cold start, so replaced media shows up within
///     that window for every user without anyone tapping Purge.
const Duration _autoRefreshInterval = Duration(hours: 6);
const String _lastRefreshKey = 'image_cache_last_refresh_ms';

/// Empties every image cache the app holds: the on-disk network-image store,
/// the SVG picture cache, and Flutter's in-memory (decoded) image cache. The
/// next time each image is shown it is re-fetched fresh from the server.
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

/// Clears the on-disk image + SVG caches if they have not been refreshed within
/// [_autoRefreshInterval]. Call once during app start-up, before the first
/// frame. Cheap no-op (a single prefs read) when the window has not elapsed, so
/// it does not slow normal launches.
Future<void> refreshStaleImageCacheOnLaunch() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final lastMs = prefs.getInt(_lastRefreshKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (lastMs != 0 && now - lastMs < _autoRefreshInterval.inMilliseconds) {
      return;
    }
    await DefaultCacheManager().emptyCache();
    try {
      svg.cache.clear();
    } catch (_) {}
    await prefs.setInt(_lastRefreshKey, now);
  } catch (_) {
    // Never block startup on a cache purge.
  }
}
