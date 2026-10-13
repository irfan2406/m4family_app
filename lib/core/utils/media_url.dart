/// Helpers for reading media URLs out of backend values.
///
/// The backend is inconsistent about how it returns an image/video reference:
/// sometimes a plain string (`"/uploads/media/x.png"`), sometimes an object
/// (`{"url": "...", "caption": ""}`) — e.g. construction phase `images` are now
/// `{url, caption}` objects, where they used to be strings. Reading `list[0]`
/// as a string then produced a broken URL and the card fell back to a bundled
/// placeholder. These helpers accept either shape so new uploads reflect
/// everywhere without each call site re-implementing the parsing.
library;

import 'package:flutter/widgets.dart' show BoxFit;

/// Chooses how an uploaded image should fill a fixed frame, by file type:
/// PNG/SVG are usually transparent logos/graphics, shown in full ([BoxFit.contain]
/// so nothing is cropped); JPEG/other are photos that fill the frame
/// ([BoxFit.cover]). Query strings and asset paths are handled.
BoxFit fitForMediaUrl(String url) {
  final path = (Uri.tryParse(url)?.path ?? url).toLowerCase();
  return (path.endsWith('.png') || path.endsWith('.svg'))
      ? BoxFit.contain
      : BoxFit.cover;
}

/// Appends an asset's version ([version], typically the owning record's
/// `updatedAt`) to [url] as a `?v=` token, so an admin replacing the file — even
/// at the SAME URL — produces a URL the app has never requested before. That
/// makes the replacement reflect immediately: it misses the on-device image
/// cache AND the CDN edge (both key on the full URL), so the new file is fetched
/// the next time the image is shown, instead of the stale copy lingering.
///
/// Safe no-op for empty/`data:` URLs or a missing version. Preserves any
/// existing query string, and strips the version down to a URL-safe token so a
/// timestamp like `2026-10-13T08:15:53.621Z` becomes `v=20261013T081553621Z`.
String cacheBustUrl(String url, Object? version) {
  if (url.isEmpty || url.startsWith('data:')) return url;
  final token = (version?.toString() ?? '').replaceAll(
    RegExp(r'[^0-9A-Za-z]'),
    '',
  );
  if (token.isEmpty) return url;
  final sep = url.contains('?') ? '&' : '?';
  return '$url${sep}v=$token';
}

/// Extracts a URL string from [v], which may be a plain string or an object
/// carrying the URL under one of several common keys. Returns '' when none.
String mediaUrlOf(dynamic v) {
  if (v == null) return '';
  if (v is String) return v.trim();
  if (v is Map) {
    for (final k in const [
      'url',
      'fileUrl',
      'src',
      'imageUrl',
      'image',
      'path',
      'location',
    ]) {
      final s = v[k]?.toString().trim() ?? '';
      if (s.isNotEmpty) return s;
    }
    return '';
  }
  return v.toString().trim();
}

/// First non-empty media URL from [list] (entries may be strings or objects).
String firstMediaUrl(dynamic list) {
  if (list is! List) return '';
  for (final e in list) {
    final s = mediaUrlOf(e);
    if (s.isNotEmpty) return s;
  }
  return '';
}

/// All non-empty media URLs from [list], in order.
List<String> mediaUrlList(dynamic list) {
  if (list is! List) return const [];
  final out = <String>[];
  for (final e in list) {
    final s = mediaUrlOf(e);
    if (s.isNotEmpty) out.add(s);
  }
  return out;
}

/// Hosts that serve stock photography, never the client's own media.
///
/// The catalog is seeded with Unsplash URLs: on every project `thumbnail`,
/// `coverImage` and `heroImages` carry the same stock photo while `heroImage`
/// carries what the admin actually uploaded. Reordering the fields is not
/// enough on its own — a project whose upload is missing would simply fall
/// through to the stock entry again — so a stock URL is refused outright and
/// the caller shows its branded placeholder instead.
const Set<String> _stockImageHosts = {
  'images.unsplash.com',
  'unsplash.com',
  'images.pexels.com',
  'pexels.com',
  'via.placeholder.com',
  'placehold.co',
  'picsum.photos',
};

/// Whether [url] points at stock photography rather than the client's media.
bool isStockImageUrl(String url) {
  if (url.isEmpty) return false;
  final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
  if (host.isEmpty) return false;
  return _stockImageHosts.contains(host) ||
      _stockImageHosts.any((h) => host.endsWith('.$h'));
}

/// The card image for a project, in the one order every portal must agree on.
///
/// `heroImage` (SINGULAR) is what the catalog populates on every project and
/// what the web card shows. `heroImages` (plural) is a gallery that only some
/// projects carry, and when a screen reached for it first it rendered a
/// different photo for the same project than the list did — the same tower
/// showing as a sea view on one tab and a villa on another. The galleries are
/// the fallback, never the first choice.
///
/// Returns '' when the project has no usable image, so the caller can render
/// its branded placeholder rather than stock.
String projectHeroUrl(dynamic project) {
  if (project is! Map) return '';
  final single = mediaUrlOf(project['heroImage']);
  if (single.isNotEmpty && !isStockImageUrl(single)) return single;
  for (final key in const [
    'heroImages',
    'exteriorImages',
    'interiorImages',
    'media',
    'images',
  ]) {
    for (final candidate in mediaUrlList(project[key])) {
      if (!isStockImageUrl(candidate)) return candidate;
    }
  }
  for (final key in const ['image', 'thumbnail', 'coverImage']) {
    final s = mediaUrlOf(project[key]);
    if (s.isNotEmpty && !isStockImageUrl(s)) return s;
  }
  // Nothing the admin uploaded: let the caller draw its branded placeholder
  // rather than dressing the card in a stock photo.
  return '';
}
