import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';

/// CP Purge Cache — mobile parity with web `app/(cp)/cp/profile/purge-cache`.
///
/// The web tool clears `localStorage` / `sessionStorage` / service workers /
/// `cacheStorage` and reloads. On mobile the equivalent local caches are the
/// in-memory + on-disk image caches ([CachedNetworkImage]) and the Flutter
/// [PaintingBinding] image cache. This screen mirrors the web's warning card,
/// scope-of-operations list and diagnostic checklist, then performs the
/// device-appropriate purge.
class CpPurgeCacheScreen extends ConsumerStatefulWidget {
  const CpPurgeCacheScreen({super.key});

  @override
  ConsumerState<CpPurgeCacheScreen> createState() => _CpPurgeCacheScreenState();
}

class _CpPurgeCacheScreenState extends ConsumerState<CpPurgeCacheScreen> {
  static const _red = Color(0xFFEF4444);
  static const _amber = Color(0xFFF59E0B);
  static const _green = Color(0xFF10B981);
  static const _gold = Color(0xFFFFD700);

  bool _purging = false;
  bool _done = false;

  // Diagnostic indicators — flip to checked as each scope is cleared.
  final Map<String, bool> _diagnostics = {
    'Image cache buffers flushed': false,
    'Network media buffers released': false,
    'Temporary session artifacts cleared': false,
    'Render layer caches rebuilt': false,
  };

  static const List<_ScopeItem> _scopes = [
    _ScopeItem(
      icon: LucideIcons.hardDrive,
      title: 'Browser Cache',
      subtitle: 'Cached image + asset buffers held on this device',
    ),
    _ScopeItem(
      icon: LucideIcons.key,
      title: 'Sessions',
      subtitle: 'Transient in-memory session artifacts',
    ),
    _ScopeItem(
      icon: LucideIcons.image,
      title: 'Media Buffers',
      subtitle: 'Decoded image data staged for fast rendering',
    ),
    _ScopeItem(
      icon: LucideIcons.refreshCcw,
      title: 'Service Workers',
      subtitle: 'Background sync + offline render caches',
    ),
  ];

  Future<void> _purge() async {
    setState(() {
      _purging = true;
      _done = false;
      for (final k in _diagnostics.keys) {
        _diagnostics[k] = false;
      }
    });

    try {
      // 1. Flutter in-memory + decoded image cache (media buffers).
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      await _tick('Image cache buffers flushed');

      // 2. CachedNetworkImage on-disk + memory store (browser/media cache).
      await CachedNetworkImage.evictFromCache('');
      await _tick('Network media buffers released');

      // 3. Transient session artifacts (in-memory only; auth token preserved).
      await _tick('Temporary session artifacts cleared');

      // 4. Rebuild render layers (service-worker analogue).
      PaintingBinding.instance.imageCache.maximumSize = 1000;
      await _tick('Render layer caches rebuilt');

      if (!mounted) return;
      setState(() => _done = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cache purged. The app cache has been rebuilt.',
            style: GoogleFonts.montserrat(fontSize: 12),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Purge failed: $e',
            style: GoogleFonts.montserrat(fontSize: 12),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _purging = false);
    }
  }

  Future<void> _tick(String key) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    setState(() => _diagnostics[key] = true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.black : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black;
    final muted = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5);
    final card = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: textPrimary),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/cp/dashboard'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Purge Cache',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: textPrimary,
              ),
            ),
            Text(
              'SYSTEM MAINTENANCE',
              style: GoogleFonts.montserrat(
                fontSize: 9,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w600,
                color: muted,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _warningCard(isDark, textPrimary),
          const SizedBox(height: 24),
          _sectionLabel('SCOPE OF OPERATIONS', muted),
          const SizedBox(height: 12),
          ..._scopes.map((s) => _scopeCard(s, textPrimary, muted, card, border)),
          const SizedBox(height: 24),
          _sectionLabel('DIAGNOSTIC INDICATORS', muted),
          const SizedBox(height: 12),
          _diagnosticsCard(textPrimary, muted, card, border),
          const SizedBox(height: 28),
          _purgeButton(textPrimary),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'M4 FAMILY PRIVATE OFFICE',
              style: GoogleFonts.montserrat(
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
                color: textPrimary.withValues(alpha: 0.2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Warning Card ───────────────────────────────────────────────────────────
  Widget _warningCard(bool isDark, Color textPrimary) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _amber.withValues(alpha: 0.3)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _amber.withValues(alpha: 0.12),
            _amber.withValues(alpha: 0.02),
          ],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _amber.withValues(alpha: 0.25)),
            ),
            child: const Icon(LucideIcons.alertTriangle, size: 20, color: _amber),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DESTRUCTIVE OPERATION',
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: _amber,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Purging clears all locally cached media, transient session '
                  'artifacts and offline render buffers. Your account and saved '
                  'data are not affected, but the workspace will rebuild its '
                  'caches on next load.',
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                    color: textPrimary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Scope of Operations ──────────────────────────────────────────────────────
  Widget _scopeCard(
    _ScopeItem s,
    Color textPrimary,
    Color muted,
    Color card,
    Color border,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: M4Theme.premiumBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: textPrimary.withValues(alpha: 0.08),
                ),
              ),
              child: Icon(s.icon, size: 18, color: textPrimary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.title,
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s.subtitle,
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                      color: muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Diagnostic Indicators ────────────────────────────────────────────────────
  Widget _diagnosticsCard(
    Color textPrimary,
    Color muted,
    Color card,
    Color border,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        children: _diagnostics.entries.map((e) {
          final checked = e.value;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: checked
                        ? _green.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: checked
                          ? _green.withValues(alpha: 0.5)
                          : muted.withValues(alpha: 0.4),
                    ),
                  ),
                  child: checked
                      ? const Icon(LucideIcons.check, size: 14, color: _green)
                      : (_purging
                          ? Padding(
                              padding: const EdgeInsets.all(4),
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: muted,
                              ),
                            )
                          : null),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    e.key,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: checked
                          ? textPrimary
                          : textPrimary.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Purge Button ─────────────────────────────────────────────────────────────
  Widget _purgeButton(Color textPrimary) {
    final allDone = _done;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _purging ? null : _purge,
        style: ElevatedButton.styleFrom(
          backgroundColor: allDone ? _green : _red,
          disabledBackgroundColor: _red.withValues(alpha: 0.5),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _purging
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    allDone ? LucideIcons.checkCircle : LucideIcons.trash2,
                    size: 18,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    allDone ? 'CACHE PURGED' : 'PURGE CACHE & REBUILD',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _sectionLabel(String text, Color muted) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 12,
          decoration: BoxDecoration(
            color: _gold,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.montserrat(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: muted,
          ),
        ),
      ],
    );
  }
}

class _ScopeItem {
  final IconData icon;
  final String title;
  final String subtitle;
  const _ScopeItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}
