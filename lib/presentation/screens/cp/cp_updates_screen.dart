import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Web parity for `/cp/updates` (used from CP home "Video" tile).
/// Shows catalog updates (renders/videos/walkthroughs).
class CpUpdatesScreen extends ConsumerStatefulWidget {
  const CpUpdatesScreen({super.key});

  @override
  ConsumerState<CpUpdatesScreen> createState() => _CpUpdatesScreenState();
}

class _CpUpdatesScreenState extends ConsumerState<CpUpdatesScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _items = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  String? _stringUrl(dynamic v) {
    if (v == null) return null;
    if (v is String) return v;
    if (v is Map) {
      return v['url']?.toString() ??
          v['fileUrl']?.toString() ??
          v['src']?.toString() ??
          v['imageUrl']?.toString() ??
          v['image']?.toString() ??
          v['thumbnail']?.toString() ??
          v['cover']?.toString() ??
          v['path']?.toString();
    }
    return v.toString();
  }

  String? _thumb(dynamic it) {
    return _stringUrl(it['thumbnail']) ??
        _stringUrl(it['coverImage']) ??
        _stringUrl(it['cover']) ??
        _stringUrl(it['image']) ??
        _stringUrl(it['heroImage']);
  }

  String? _video(dynamic it) {
    return _stringUrl(it['videoUrl']) ?? _stringUrl(it['video']) ?? _stringUrl(it['url']);
  }

  Future<void> _openExternal(String url) async {
    final resolved = ref.read(apiClientProvider).resolveUrl(url);
    await launchUrl(Uri.parse(resolved), mode: LaunchMode.externalApplication);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ref.read(apiClientProvider).getGlobalUpdates();
      final body = res.data;
      if (body is Map && body['status'] == true && body['data'] is List) {
        _items = List<dynamic>.from(body['data'] as List);
      } else if (body is List) {
        _items = List<dynamic>.from(body);
      } else {
        _items = const [];
      }
    } on DioException catch (e) {
      _error = e.response?.data is Map ? (e.response!.data as Map)['message']?.toString() : e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLight = scheme.brightness == Brightness.light;
    final accent = isLight ? Colors.black : scheme.primary;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        elevation: 0,
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft), onPressed: () => context.pop()),
        title: Text('UPDATES', style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, letterSpacing: 2)),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: accent))
          : _error != null
              ? Center(child: Text(_error!, style: GoogleFonts.montserrat(color: scheme.onSurfaceVariant)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final it = _items[i];
                      if (it is! Map) return const SizedBox.shrink();
                      final m = Map<String, dynamic>.from(it);
                      final title = (m['title'] ?? m['name'] ?? 'Update').toString();
                      final thumb = _thumb(m);
                      final video = _video(m);
                      final projectId = (m['project']?['_id'] ?? m['projectId'] ?? '').toString();

                      return Material(
                        color: scheme.surfaceContainerHighest.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(22),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(22),
                          onTap: () async {
                            if (projectId.isNotEmpty) {
                              context.push('/cp/projects/$projectId');
                              return;
                            }
                            if (video != null && video.isNotEmpty) {
                              await _openExternal(video);
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                AspectRatio(
                                  aspectRatio: 16 / 9,
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        if (thumb != null && thumb.isNotEmpty)
                                          CachedNetworkImage(
                                            imageUrl: ref.read(apiClientProvider).resolveUrl(thumb),
                                            fit: BoxFit.cover,
                                            errorWidget: (_, __, ___) => Container(color: scheme.surfaceContainerHighest),
                                          )
                                        else
                                          Container(color: scheme.surfaceContainerHighest),
                                        Container(color: Colors.black.withValues(alpha: 0.25)),
                                        Center(
                                          child: Container(
                                            width: 56,
                                            height: 56,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.white.withValues(alpha: 0.15),
                                              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                                            ),
                                            child: const Icon(LucideIcons.play, color: Colors.white, size: 24),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          title.toUpperCase(),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Icon(LucideIcons.chevronRight, color: scheme.onSurfaceVariant.withValues(alpha: 0.7)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

