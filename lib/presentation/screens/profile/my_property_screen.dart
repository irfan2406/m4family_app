import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

class MyPropertyScreen extends ConsumerStatefulWidget {
  const MyPropertyScreen({super.key});

  @override
  ConsumerState<MyPropertyScreen> createState() => _MyPropertyScreenState();
}

class _MyPropertyScreenState extends ConsumerState<MyPropertyScreen> {
  bool _isLoading = true;
  List<dynamic> _bookings = [];

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    try {
      final res = await ref.read(apiClientProvider).getUserBookings();
      if (res.data['status'] == true) {
        setState(() => _bookings = res.data['data'] ?? []);
      }
    } catch (e) {
      debugPrint('Error fetching bookings: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF141B3A)
          : const Color(0xFFF4EFE3),
      body: SafeArea(
        // Edge-to-edge: content runs under the gesture bar so scrolling fills
        // the screen. Trailing padding keeps the last item reachable.
        bottom: false,
        child: Column(
          children: [
            _buildHeader(isDark),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _fetchBookings,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            // Web parity: a small "MY PROPERTIES" eyebrow above
                            // the list — the web has no portfolio summary card.
                            _buildSectionLabel(isDark),
                            const SizedBox(height: 20),
                            if (_bookings.isEmpty)
                              _buildEmptyState(isDark)
                            else
                              ..._bookings
                                  .map(
                                    (booking) =>
                                        _buildBookingCard(booking, isDark),
                                  )
                                  .toList(),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          _IconButton(
            icon: LucideIcons.chevronLeft,
            isDark: isDark,
            onTap: () => Navigator.pop(context),
          ),
          Expanded(
            child: Center(
              child: Text(
                'MY PROPERTIES',
                style: GoogleFonts.gelasio(
                  textStyle: const TextStyle(inherit: true),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Color(0xFF0C312B),
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  // Web parity: the list is introduced by a small letterspaced eyebrow rather
  // than a portfolio summary card (the web page has no such card).
  Widget _buildSectionLabel(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        'MY PROPERTIES',
        style: GoogleFonts.gelasio(
          textStyle: const TextStyle(inherit: true),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white38 : const Color(0xFF155A4F),
          letterSpacing: 2,
        ),
      ),
    ).animate().fadeIn();
  }

  /// First non-empty value in [candidates], else [fallback].
  static String _pick(List<dynamic> candidates, [String fallback = '']) {
    for (final c in candidates) {
      if (c == null) continue;
      final s = c.toString().trim();
      if (s.isNotEmpty && s.toLowerCase() != 'null') return s;
    }
    return fallback;
  }

  static int _paidPercent(dynamic booking) {
    final raw = booking['paymentPercent'] ?? booking['paymentProgress'] ?? 0;
    if (raw is num) return raw.round().clamp(0, 100);
    return (int.tryParse(raw.toString()) ?? 0).clamp(0, 100);
  }

  // Web parity ("MY PROPERTIES" page): an identity header (reference code +
  // project name + status pill), a hairline, a three-column detail grid
  // (project/area/unit, config/floor/type, documents/pay status/open), then the
  // CUSTOMISE UNIT action.
  Widget _buildBookingCard(dynamic booking, bool isDark) {
    final project = booking['project'] is Map
        ? booking['project'] as Map
        : const {};
    final rawLocation = project['location'];
    final category = project['category'];

    final ink = isDark ? Colors.white : const Color(0xFF0C312B);
    final muted = isDark ? Colors.white38 : const Color(0xFF155A4F);

    final code = _pick([
      booking['bookingId'],
      booking['_id'],
      booking['id'],
    ]).toUpperCase();
    final title = _pick([project['title']], 'Unknown Project').toUpperCase();
    final area = _pick([
      rawLocation is Map ? rawLocation['name'] : rawLocation,
    ], 'N/A').toUpperCase();
    final unitNo = _pick([
      booking['unitNumber'],
      booking['unitNo'],
    ], 'N/A').toUpperCase();
    final config = _pick([booking['configuration']], 'N/A').toUpperCase();
    final floor = _pick([booking['floor']], 'PENDING').toUpperCase();
    // Web: projectType = project.category.name || project.type || "Residential".
    final type = _pick([
      category is Map ? category['name'] : null,
      project['type'],
    ], 'Residential').toUpperCase();

    final docs = booking['documents'] is List
        ? booking['documents'] as List
        : const [];
    final docLabel = docs.isEmpty
        ? 'NO DOCS'
        : '${docs.length} DOC${docs.length == 1 ? '' : 'S'}';

    final paid = _paidPercent(booking);
    final payStatus = _pick(
      [booking['paymentStatus']],
      paid >= 100
          ? 'PAID'
          : paid > 0
          ? 'PARTIAL'
          : 'PENDING',
    ).toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141B3A) : const Color(0xFFF4EFE3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ink.withOpacity(0.05)),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: const Color(0xFF0C312B).withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: Column(
        children: [
          // Identity: icon, reference code + project name, status pill.
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: ink.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    LucideIcons.building2,
                    color: isDark ? Colors.white54 : const Color(0xFF155A4F),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (code.isNotEmpty) ...[
                        Text(
                          code,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            textStyle: const TextStyle(inherit: true),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: muted,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                      ],
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.gelasio(
                          textStyle: const TextStyle(inherit: true),
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: ink,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _StatusBadge(
                  status: booking['status']?.toString() ?? 'Unknown',
                ),
              ],
            ),
          ),
          // Detail grid.
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: ink.withOpacity(0.06))),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoItem(label: 'PROJECT', value: title, isDark: isDark),
                    _InfoItem(
                      label: 'AREA',
                      value: area,
                      isDark: isDark,
                      crossAlign: CrossAxisAlignment.center,
                    ),
                    _InfoItem(
                      label: 'UNIT NO.',
                      value: unitNo,
                      isDark: isDark,
                      crossAlign: CrossAxisAlignment.end,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoItem(label: 'CONFIG', value: config, isDark: isDark),
                    _InfoItem(
                      label: 'FLOOR',
                      value: floor,
                      isDark: isDark,
                      crossAlign: CrossAxisAlignment.center,
                    ),
                    _InfoItem(
                      label: 'TYPE',
                      value: type,
                      isDark: isDark,
                      crossAlign: CrossAxisAlignment.end,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _InfoItem(
                      label: 'DOCUMENTS',
                      value: docLabel,
                      isDark: isDark,
                      valueColor: muted.withOpacity(isDark ? 1.0 : 0.65),
                    ),
                    _InfoItem(
                      label: 'PAY STATUS',
                      value: payStatus,
                      isDark: isDark,
                      crossAlign: CrossAxisAlignment.center,
                      // Web flags an unsettled balance in amber; amber/gold is
                      // off-palette here, so the M4 coral accent carries it.
                      valueColor: payStatus == 'PAID'
                          ? null
                          : const Color(0xFFC65B46),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: _RoundChevron(
                          isDark: isDark,
                          onTap: () => context.push('/my-custom-views'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/custom-views'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? const Color(0xFF1C4535)
                          : const Color(0xFF0C312B),
                      foregroundColor: const Color(0xFFF6F1E7),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(27),
                      ),
                    ),
                    icon: const Icon(LucideIcons.palette, size: 18),
                    label: Text(
                      'CUSTOMISE UNIT',
                      style: GoogleFonts.gelasio(
                        textStyle: const TextStyle(inherit: true),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2);
  }

  Widget _buildEmptyState(bool isDark) {
    return Column(
      children: [
        const SizedBox(height: 60),
        Icon(
          LucideIcons.building2,
          size: 64,
          color: (isDark ? Colors.white : Color(0xFF0C312B)).withOpacity(0.1),
        ),
        const SizedBox(height: 24),
        Text(
          'NO PROPERTY RECORDS FOUND',
          style: GoogleFonts.gelasio(
            textStyle: const TextStyle(inherit: true),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: (isDark ? Colors.white : Color(0xFF0C312B)).withOpacity(
              0.72,
            ),
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = status.toLowerCase();
    // Web parity: a confirmed booking is labelled "ALLOTTED" on the web page.
    final label = (s == 'confirmed' ? 'Allotted' : status).toUpperCase();
    final color = (s == 'confirmed' || s == 'allotted')
        ? const Color(0xFF163A2C)
        : const Color(0xFFC65B46);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(isDark ? 0.35 : 0.20)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          textStyle: const TextStyle(inherit: true),
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: isDark ? const Color(0xFFB2C1B4) : color,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

/// One label/value pair in the web's three-column detail grid. Returns an
/// [Expanded] so three of them split a row into equal thirds.
class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final CrossAxisAlignment crossAlign;
  final Color? valueColor;
  const _InfoItem({
    required this.label,
    required this.value,
    required this.isDark,
    this.crossAlign = CrossAxisAlignment.start,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final align = crossAlign == CrossAxisAlignment.end
        ? TextAlign.right
        : crossAlign == CrossAxisAlignment.center
        ? TextAlign.center
        : TextAlign.left;
    return Expanded(
      child: Column(
        crossAxisAlignment: crossAlign,
        children: [
          Text(
            label,
            textAlign: align,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              textStyle: const TextStyle(inherit: true),
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white38 : const Color(0xFF155A4F),
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            textAlign: align,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              textStyle: const TextStyle(inherit: true),
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color:
                  valueColor ??
                  (isDark ? Colors.white : const Color(0xFF0C312B)),
            ),
          ),
        ],
      ),
    );
  }
}

/// The circular "open" affordance in the last grid row (web parity).
class _RoundChevron extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;
  const _RoundChevron({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? Colors.white : const Color(0xFF0C312B);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: ink.withOpacity(0.04),
          border: Border.all(color: ink.withOpacity(0.12)),
        ),
        child: Icon(
          LucideIcons.chevronRight,
          size: 18,
          color: isDark ? Colors.white70 : const Color(0xFF155A4F),
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;
  const _IconButton({
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141B3A) : const Color(0xFFF4EFE3),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: (isDark ? Colors.white : Color(0xFF0C312B)).withOpacity(
              0.05,
            ),
          ),
        ),
        child: Icon(
          icon,
          color: isDark ? Colors.white54 : Color(0xFF155A4F),
          size: 20,
        ),
      ),
    );
  }
}
