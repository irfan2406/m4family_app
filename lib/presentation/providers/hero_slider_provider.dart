import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

/// The home hero slider the Admin Panel controls.
///
/// The web reads `GET /api/config` -> `data.heroSliderImages` and shows those
/// images at the top of the home page, so swapping a slide in the Admin Panel
/// changes what every client shows. The app used to build its hero out of the
/// project catalog plus a bundled asset, so an admin's edit never reached it.
/// The dashboards now lead with these slides and keep their catalog/asset
/// slides as the fallback for an empty config or an offline start.
class HeroSlide {
  /// Already resolved against the API host, so it is ready to hand to an
  /// image widget.
  final String url;

  /// The admin's caption for the slide. Carried through the cache so it is
  /// available to anything that wants to show it; nothing renders it today.
  final String label;

  const HeroSlide({required this.url, this.label = ''});

  factory HeroSlide.fromCache(dynamic json) => HeroSlide(
    url: (json is Map ? json['url'] : null)?.toString() ?? '',
    label: (json is Map ? json['label'] : null)?.toString() ?? '',
  );

  Map<String, dynamic> toJson() => {'url': url, 'label': label};
}

/// Pulls `data.heroSliderImages` out of a `/api/config` payload.
///
/// [resolveUrl] turns the backend's relative `/uploads/...` paths into absolute
/// ones. Entries without a usable url are dropped rather than rendering as a
/// broken tile, which is also what keeps a half-filled admin row harmless.
List<HeroSlide> parseHeroSlides(
  dynamic payload,
  String Function(String?) resolveUrl,
) {
  final data = payload is Map ? payload['data'] : null;
  final raw = data is Map ? data['heroSliderImages'] : null;
  if (raw is! List) return const <HeroSlide>[];

  final slides = <HeroSlide>[];
  for (final item in raw) {
    // The admin panel posts objects; tolerate a bare string too, since the
    // same field is a plain url list in older config documents.
    final url = item is Map
        ? (item['url'] ?? item['image'] ?? '').toString()
        : item?.toString() ?? '';
    if (url.trim().isEmpty) continue;
    slides.add(
      HeroSlide(
        url: resolveUrl(url),
        label: item is Map ? (item['label'] ?? '').toString() : '',
      ),
    );
  }
  return slides;
}

/// Session-scoped fetch of the admin hero slider.
///
/// Returns an empty list rather than an error when the config call fails: a
/// dead config endpoint must leave the home page on its fallback slides, not
/// break it. Guest additionally persists the result to its disk cache so a
/// cold start still opens on the admin's slides.
final heroSliderProvider = FutureProvider<List<HeroSlide>>((ref) async {
  final apiClient = ref.read(apiClientProvider);
  try {
    final response = await apiClient.getPublicConfig();
    return parseHeroSlides(response.data, apiClient.resolveUrl);
  } catch (_) {
    return const <HeroSlide>[];
  }
});
