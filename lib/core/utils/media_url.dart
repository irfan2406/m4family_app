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
