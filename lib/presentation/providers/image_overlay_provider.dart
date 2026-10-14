import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

/// Label used when the setting is on but the admin left its text blank.
const String kDefaultImageOverlayText = 'Artistic Impression';

/// Admin Panel "Settings > Image Overlay": whether project images carry the
/// "Artistic Impression" label, and what that label says.
///
/// Saved on the backend as `GET /api/config` -> `data.overlayEnabled` and
/// `data.overlayText`.
class ImageOverlaySetting {
  final bool enabled;
  final String text;

  const ImageOverlaySetting({
    required this.enabled,
    this.text = kDefaultImageOverlayText,
  });

  /// What every screen falls back to until the saved setting is known: the
  /// label is shown only once the admin has explicitly switched it on.
  static const off = ImageOverlaySetting(enabled: false);

  /// The badges render the label in capitals.
  String get label => text.toUpperCase();
}

/// Pulls the image overlay setting out of a `/api/config` payload.
///
/// Anything other than an explicit `true` (missing, null, malformed) counts as
/// off, so the label never appears without the admin turning it on.
ImageOverlaySetting parseImageOverlay(dynamic payload) {
  final data = payload is Map ? payload['data'] : null;
  if (data is! Map) return ImageOverlaySetting.off;

  final raw = data['overlayEnabled'];
  final enabled =
      raw == true || (raw is String && raw.trim().toLowerCase() == 'true');
  final text = (data['overlayText'] ?? '').toString().trim();

  return ImageOverlaySetting(
    enabled: enabled,
    text: text.isEmpty ? kDefaultImageOverlayText : text,
  );
}

/// Session-scoped read of the image overlay setting. A failed config call
/// leaves the label off rather than guessing. [LiveSyncScope] invalidates it
/// when the admin saves the config, so a change shows without a restart.
final imageOverlayProvider = FutureProvider<ImageOverlaySetting>((ref) async {
  try {
    final response = await ref.read(apiClientProvider).getPublicConfig();
    return parseImageOverlay(response.data);
  } catch (_) {
    return ImageOverlaySetting.off;
  }
});
