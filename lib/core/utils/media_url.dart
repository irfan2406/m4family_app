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

/// The public media bucket the website loads uploads from. The API host's
/// `/uploads/media/<file>` answers with a 302 redirect to `<bucket>/<file>`,
/// so loading from here directly skips that round trip (backend guidance).
const String kMediaBucketBase =
    'https://pub-5a1384bd1cd04b29bc2523807d384a92.r2.dev/m4/';

/// The direct bucket URL for an `/uploads/media/<file>` path, or '' for any
/// other value (the caller then resolves it against the API host as before).
String directUploadUrl(String path) {
  const prefix = '/uploads/media/';
  if (!path.startsWith(prefix)) return '';
  final file = path.substring(prefix.length);
  return file.isEmpty ? '' : '$kMediaBucketBase$file';
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

/// The card and banner image for a project, in the one order every portal
/// must agree on.
///
/// `heroImage` is the Project Master Image the admin picks, and it is what
/// project cards and banners show (backend). The old `bannerImage`,
/// `coverImage`, `thumbnail` and `heroImages` fields held demo stock photos and
/// have been removed from every project, so they are no longer read. The
/// project's own galleries are only a fallback for a project with no master
/// image.
///
/// Returns '' when the project has no usable image, so the caller can render
/// its branded placeholder rather than stock.
String projectHeroUrl(dynamic project) {
  if (project is! Map) return '';
  final single = mediaUrlOf(project['heroImage']);
  if (single.isNotEmpty && !isStockImageUrl(single)) return single;
  for (final key in const [
    'exteriorImages',
    'interiorImages',
    'media',
    'images',
  ]) {
    for (final candidate in mediaUrlList(project[key])) {
      if (!isStockImageUrl(candidate)) return candidate;
    }
  }
  final image = mediaUrlOf(project['image']);
  if (image.isNotEmpty && !isStockImageUrl(image)) return image;
  // Nothing the admin uploaded: let the caller draw its branded placeholder
  // rather than dressing the card in a stock photo.
  return '';
}
