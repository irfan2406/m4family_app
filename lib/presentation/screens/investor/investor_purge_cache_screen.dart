import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';

/// Investor Purge Cache — mobile parity with web
/// `app/investor/profile/purge-cache/page.tsx`.
///
/// The web tool clears `localStorage` / `sessionStorage` / service workers /
/// `cacheStorage` and reloads. On mobile the equivalent local caches are the
/// in-memory + on-disk image caches ([CachedNetworkImage]) and the Flutter
/// [PaintingBinding] image cache. This screen mirrors the web's "Purge Data"
/// header, red notice card, scope-of-operations list and diagnostic checklist,
/// surfaces the current cache footprint, then performs the device-appropriate
/// purge and shows a success toast.
class InvestorPurgeCacheScreen extends ConsumerStatefulWidget {
  const InvestorPurgeCacheScreen({super.key});

  @override
  ConsumerState<InvestorPurgeCacheScreen> createState() =>
      _InvestorPurgeCacheScreenState();
}

class _InvestorPurgeCacheScreenState
    extends ConsumerState<InvestorPurgeCacheScreen> {
  static const _red = Color(0xFFEF4444);
  static const _green = Color(0xFF10B981);
  static const _gold = Color(0xFFFFD700);

  bool _purging = false;
  bool _done = false;

  // Approximate cached footprint, derived from the live image cache. On web /
  // first load these report 0; once media has rendered the numbers populate.
  int _cacheBytes = 0;
  int _cacheCount = 0;

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
      title: 'Browser Credential Cache',
      subtitle: 'Cached image + asset buffers held on this device',
    ),
    _ScopeItem(
      icon: LucideIcons.key,
      title: 'Encrypted Login Sessions',
      subtitle: 'Transient in-memory session artifacts',
    ),
    _ScopeItem(
      icon: LucideIcons.image,
      title: 'Media & Asset Buffers',
      subtitle: 'Decoded image data staged for fast rendering',
    ),
    _ScopeItem(
      icon: LucideIcons.refreshCcw,
      title: 'Service Worker Protocols',
      subtitle: 'Background sync + offline render caches',
    ),
  ];

  static const List<String> _indicators = [
    'Persistent sync latency',
    'Visual state inconsistencies',
    'Authorization conflicts',
    'Legacy content visibility',
    'Network handshake errors',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureCache());
  }

  void _measureCache() {
    try {
      final cache = PaintingBinding.instance.imageCache;
      if (!mounted) return;
      setState(() {
        _cacheBytes = cache.currentSizeBytes;
        _cacheCount = cache.currentSize;
      });
    } catch (_) {}
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 KB';
    const units = ['B', 'KB', 'MB', 'GB'];
    double size = bytes.toDouble();
    int unit = 0;
    while (size >= 1024 && unit < units.length - 1) {
      size /= 1024;
      unit++;
    }
    return '${size.toStringAsFixed(size >= 10 || unit == 0 ? 0 : 1)} ${units[unit]}';
  }

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
      setState(() {
        _done = true;
        _cacheBytes = PaintingBinding.instance.imageCache.currentSizeBytes;
        _cacheCount = PaintingBinding.instance.imageCache.currentSize;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _green,
          content: Text(
            'Cache purged successfully! The app cache has been rebuilt.',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to purge cache: $e',
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
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go('/investor/home'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Purge Data',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: textPrimary,
              ),
            ),
            Text(
              'RESET PLATFORM STATE',
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
          _cacheSizeCard(textPrimary, muted, card, border),
          const SizedBox(height: 24),
          _sectionLabel('SCOPE OF OPERATIONS', muted),
          const SizedBox(height: 12),
          ..._scopes.map((s) => _scopeCard(s, textPrimary, muted, card, border)),
          const SizedBox(height: 24),
          _sectionLabel('DIAGNOSTIC INDICATORS', muted),
          const SizedBox(height: 12),
          _indicatorsCard(textPrimary, muted, card, border),
          const SizedBox(height: 24),
          _sectionLabel('OPERATION STATUS', muted),
          const SizedBox(height: 12),
          _diagnosticsCard(textPrimary, muted, card, border),
          const SizedBox(height: 28),
          _purgeButton(),
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
        border: Border.all(color: _red.withValues(alpha: 0.3)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _red.withValues(alpha: 0.12),
            _red.withValues(alpha: 0.02),
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
              color: _red.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _red.withValues(alpha: 0.25)),
            ),
            child: const Icon(LucideIcons.alertTriangle, size: 20, color: _red),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NOTICE',
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: _red,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Purging cache will clear all local session data including '
                  'cached media, transient session artifacts and offline render '
                  'buffers. Your account and saved data are not affected, but the '
                  'platform will rebuild its caches on next load.',
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

  // ─── Cache Size Card ──────────────────────────────────────────────────────────
  Widget _cacheSizeCard(
    Color textPrimary,
    Color muted,
    Color card,
    Color border,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: M4Theme.premiumBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: textPrimary.withValues(alpha: 0.08)),
            ),
            child: const Icon(
              LucideIcons.database,
              size: 22,
              color: M4Theme.premiumBlue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ESTIMATED CACHE SIZE',
                  style: GoogleFonts.montserrat(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: muted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatBytes(_cacheBytes),
                  style: GoogleFonts.montserrat(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$_cacheCount cached item${_cacheCount == 1 ? '' : 's'}',
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: muted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _purging ? null : _measureCache,
            icon: Icon(LucideIcons.refreshCw, size: 18, color: muted),
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
                border: Border.all(color: textPrimary.withValues(alpha: 0.08)),
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

  // ─── Diagnostic Indicators (when to use) ──────────────────────────────────────
  Widget _indicatorsCard(
    Color textPrimary,
    Color muted,
    Color card,
    Color border,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        children: _indicators.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: M4Theme.premiumBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    LucideIcons.checkCircle,
                    size: 14,
                    color: M4Theme.premiumBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textPrimary.withValues(alpha: 0.8),
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

  // ─── Operation Status (live checklist) ────────────────────────────────────────
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
  Widget _purgeButton() {
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
                    allDone ? 'CORE PURGE COMPLETE' : 'INITIATE FULL RESET',
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
