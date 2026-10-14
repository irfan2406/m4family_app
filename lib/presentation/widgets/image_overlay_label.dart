import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m4_mobile/presentation/providers/image_overlay_provider.dart';

/// The "Artistic Impression" label on project images, shown only while the
/// Admin Panel's Settings > Image Overlay is switched on.
///
/// Each screen keeps its own badge styling in [builder], which receives the
/// configured label already in capitals. While the setting is off (or not yet
/// known) nothing is drawn.
class ImageOverlayLabel extends ConsumerWidget {
  const ImageOverlayLabel({super.key, required this.builder});

  final Widget Function(String label) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overlay =
        ref.watch(imageOverlayProvider).valueOrNull ?? ImageOverlaySetting.off;
    if (!overlay.enabled) return const SizedBox.shrink();
    return builder(overlay.label);
  }
}
