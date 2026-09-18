import 'package:flutter/material.dart';
import 'package:m4_mobile/presentation/widgets/m4_image.dart';

/// Standardized YouTube-style thumbnail component used across all portals
/// (Investor, CP, Customer, Guest) for complete visual consistency.
///
/// Features:
/// - Exact 16:9 YouTube aspect ratio (16 / 9)
/// - Exact YouTube mobile border radius (16px)
class M4Thumbnail extends StatelessWidget {
  static const double borderRadiusValue = 16.0;
  static const double aspectRatioValue = 16 / 9;
  static const BorderRadius borderRadius =
      BorderRadius.all(Radius.circular(borderRadiusValue));

  final String? imageUrl;
  final Widget? child;
  final BoxFit fit;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final List<Widget>? overlays;

  const M4Thumbnail({
    super.key,
    this.imageUrl,
    this.child,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.onTap,
    this.overlays,
  });

  @override
  Widget build(BuildContext context) {
    Widget contentWidget = child ??
        M4Image(
          imageUrl: imageUrl,
          fit: fit,
          width: width ?? double.infinity,
          height: height ?? double.infinity,
        );

    if (overlays != null && overlays!.isNotEmpty) {
      contentWidget = Stack(
        fit: StackFit.expand,
        children: [
          contentWidget,
          ...overlays!,
        ],
      );
    }

    Widget imageWidget = ClipRRect(
      borderRadius: borderRadius,
      child: AspectRatio(
        aspectRatio: aspectRatioValue,
        child: contentWidget,
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}
