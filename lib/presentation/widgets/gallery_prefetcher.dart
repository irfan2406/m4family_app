import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';

/// Keeps a full-screen photo gallery ready ahead of the swipe.
///
/// Gallery pages are [CachedNetworkImage]s of /uploads originals, several MB
/// each, and a PageView only builds the page on screen. So every swipe started
/// the download and the decode of the picture being swiped to, which is the
/// pause between pictures. This fetches the pictures around the current page
/// in the background — the current one, then outward in both directions — so
/// the next one is already on disk and decoded when it is reached.
///
/// Pictures are fetched one at a time on purpose: parallel multi-MB downloads
/// starve the picture the user is looking at. A page change re-aims the fetch
/// at the new page.
class GalleryPrefetcher {
  GalleryPrefetcher({
    required this.urls,
    required this.memCacheWidth,
    @visibleForTesting
    Future<void> Function(ImageProvider, BuildContext)? precache,
  }) : _precache = precache ?? _precacheQuietly;

  /// The gallery, as the URLs its pages load. Entries that are not http(s) —
  /// bundled assets, inline data URIs — load locally and are skipped.
  final List<String> urls;

  /// The pages' `memCacheWidth`. It is part of the image-cache key, so it has
  /// to match for a precached picture to be the one the page draws.
  final int memCacheWidth;

  /// Pages kept ready on each side of the one on screen.
  static const int reach = 3;

  /// Image-cache room while a gallery is open. Seven decoded pictures at 1600
  /// wide come to ~105MB, over Flutter's 100MB default, and the rest of the app
  /// is still in the cache too.
  static const int _openCacheBytes = 256 << 20;

  final Future<void> Function(ImageProvider, BuildContext) _precache;
  int _walk = 0;
  int? _savedCacheBytes;

  /// The provider a `CachedNetworkImage(imageUrl: url, memCacheWidth: w)` page
  /// actually draws through: the network provider wrapped in a [ResizeImage].
  /// Precaching the bare network provider instead fills a different cache
  /// entry — a full-size decode the page never uses.
  ImageProvider provider(String url) => ResizeImage.resizeIfNeeded(
    memCacheWidth,
    null,
    CachedNetworkImageProvider(url),
  );

  /// Call as the gallery opens on [index].
  void open(BuildContext context, int index) {
    final cache = PaintingBinding.instance.imageCache;
    if (_savedCacheBytes == null && cache.maximumSizeBytes < _openCacheBytes) {
      _savedCacheBytes = cache.maximumSizeBytes;
      cache.maximumSizeBytes = _openCacheBytes;
    }
    warm(context, index);
  }

  /// Re-aims the background fetch at [index]. Call from `onPageChanged`.
  Future<void> warm(BuildContext context, int index) async {
    final walk = ++_walk;
    for (final i in visitOrder(index, urls.length)) {
      if (walk != _walk || !context.mounted) return;
      final url = urls[i];
      if (!url.startsWith('http')) continue;
      await _precache(provider(url), context);
    }
  }

  /// Call as the gallery closes: stops the fetch and hands the image-cache
  /// budget back to the rest of the app.
  void close() {
    _walk++;
    final saved = _savedCacheBytes;
    if (saved != null) {
      PaintingBinding.instance.imageCache.maximumSizeBytes = saved;
      _savedCacheBytes = null;
    }
  }

  /// The page on screen, then outward alternating ahead and behind:
  /// i, i+1, i-1, i+2, i-2, … as far as [reach], within the gallery.
  @visibleForTesting
  static Iterable<int> visitOrder(int index, int length) sync* {
    if (index >= 0 && index < length) yield index;
    for (var d = 1; d <= reach; d++) {
      if (index + d < length) yield index + d;
      if (index - d >= 0 && index - d < length) yield index - d;
    }
  }

  // One unreachable picture must not stop the rest, nor surface as an error:
  // its page shows its own error state when the user gets there.
  static Future<void> _precacheQuietly(
    ImageProvider provider,
    BuildContext context,
  ) => precacheImage(provider, context, onError: (_, __) {});
}
