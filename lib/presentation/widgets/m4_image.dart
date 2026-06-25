import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class M4Image extends ConsumerWidget {
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
          final base64Str = imageUrl!.substring(commaIndex + 7).trim();
          final bytes = base64Decode(base64Str);
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

    return CachedNetworkImage(
      imageUrl: resolvedUrl,
      fit: fit,
      width: width,
      height: height,
      placeholder: (context, url) => placeholder ?? Container(color: Colors.black12),
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
