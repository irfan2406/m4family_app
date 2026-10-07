import 'dart:async';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Warms the shared image disk cache for the given [urls] in the background.
///
/// The backend serves multi-MB original photos, so the download is the slow
/// part of showing a card — not the decode. [CachedNetworkImage] uses
/// [DefaultCacheManager], so fetching the same URLs here means a card finds its
/// file already on disk and paints immediately when scrolled into view.
///
/// Fetches run one at a time on purpose: several parallel multi-MB downloads
/// starve each other (and the image the user is actually looking at). Only
/// http(s) URLs are fetched — bundled assets and inline `data:` URIs load
/// locally and are skipped. Failures are swallowed; each card still shows its
/// own placeholder/error state if its image never arrives.
void prewarmImages(Iterable<String> urls) {
  final queue = urls
      .where((u) => u.startsWith('http'))
      .toSet() // de-dupe: heroImage often repeats across cards
      .toList();
  if (queue.isEmpty) return;
  unawaited(() async {
    for (final url in queue) {
      try {
        await DefaultCacheManager().getSingleFile(url);
      } catch (_) {
        // Best-effort prewarm; never surface to the UI.
      }
    }
  }());
}
