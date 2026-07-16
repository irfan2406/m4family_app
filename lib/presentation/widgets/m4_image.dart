import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class M4Image extends ConsumerWidget {
  static final Map<String, Uint8List> _base64Cache = {};

  final String? imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;

  const M4Image({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildFallback();
    }

    // Check if the URL is a base64 Data URI
    if (imageUrl!.startsWith('data:image/') && imageUrl!.contains('base64,')) {
      try {
        final commaIndex = imageUrl!.indexOf('base64,');
        if (commaIndex != -1) {
          final bytes = _base64Cache.putIfAbsent(imageUrl!, () {
            final base64Str = imageUrl!
                .substring(commaIndex + 7)
                .replaceAll(RegExp(r'\s'), '');
            return base64Decode(base64Str);
          });
          return Image.memory(
            bytes,
            fit: fit,
            width: width,
            height: height,
            errorBuilder: (context, error, stackTrace) => _buildFallback(),
          );
        }
      } catch (e) {
        return _buildFallback();
      }
    }

    // Resolve relative URL using ApiClient (e.g. /uploads/media/...)
    final apiClient = ref.read(apiClientProvider);
    final resolvedUrl = apiClient.resolveUrl(imageUrl);

    // Decode at roughly the size we actually paint at rather than the source's
    // full resolution, and skip CachedNetworkImage's default 500ms fade — both
    // are why images appeared late. Falls back to the screen width when this
    // image is sized by its parent (width == null / infinite).
    final media = MediaQuery.maybeOf(context);
    final dpr = media?.devicePixelRatio ?? 2.0;
    final logicalWidth = (width != null && width!.isFinite)
        ? width!
        : (media?.size.width ?? 400.0);
    final memWidth = (logicalWidth * dpr).round().clamp(64, 2048);

    return CachedNetworkImage(
      imageUrl: resolvedUrl,
      fit: fit,
      width: width,
      height: height,
      memCacheWidth: memWidth,
      fadeInDuration: Duration.zero,
      placeholder: (context, url) =>
          placeholder ?? Container(color: Colors.black12),
      errorWidget: (context, url, error) => errorWidget ?? _buildFallback(),
    );
  }

  Widget _buildFallback() {
    return Container(
      width: width,
      height: height,
      color: Colors.white.withOpacity(0.05),
      child: Center(
        child: Icon(
          LucideIcons.image,
          color: Colors.white24,
          size: width != null && width! < 100 ? 24 : 40,
        ),
      ),
    );
  }
}
