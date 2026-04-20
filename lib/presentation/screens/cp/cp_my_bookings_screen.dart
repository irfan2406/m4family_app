import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/providers/cp_shell_provider.dart';
import 'package:m4_mobile/presentation/widgets/cp_bottom_nav.dart';
import 'package:m4_mobile/presentation/widgets/cp_sidebar_menu.dart';
import 'package:url_launcher/url_launcher.dart';

/// Web `/cp/booking/my-bookings` — `GET /api/bookings/my` (CP sees `cp` bookings).
class CpMyBookingsScreen extends ConsumerStatefulWidget {
  const CpMyBookingsScreen({super.key});

  @override
  ConsumerState<CpMyBookingsScreen> createState() => _CpMyBookingsScreenState();
}

class _CpMyBookingsScreenState extends ConsumerState<CpMyBookingsScreen> {
  List<dynamic> _list = [];
  bool _loading = true;

  static String _s(dynamic v, [String fallback = '']) {
    if (v == null) return fallback;
    final out = v.toString().trim();
    return out.isEmpty ? fallback : out;
  }

  static int _i(dynamic v, [int fallback = 0]) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.round();
    return int.tryParse(v.toString()) ?? fallback;
  }

  static DateTime? _dt(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }

  static Map<String, dynamic>? _m(dynamic v) => v is Map ? v.cast<String, dynamic>() : null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ref.read(apiClientProvider).getCpBookings();
      if (!mounted) return;
      if (res.statusCode == 200 && res.data['status'] == true) {
        final d = res.data['data'];
        if (d is List) _list = List<dynamic>.from(d);
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _openExternal(String url) async {
    final u = Uri.tryParse(url);
    if (u == null) return;
    await launchUrl(u, mode: LaunchMode.externalApplication);
  }

  ({Color bg, Color border, Color fg}) _statusColors(ColorScheme scheme, String status) {
    final s = status.toLowerCase();
    if (s.contains('confirmed') || s.contains('allotted')) {
      const fg = Color(0xFF10B981);
      return (bg: fg.withValues(alpha: 0.10), border: fg.withValues(alpha: 0.20), fg: fg);
    }
    if (s.contains('pending')) {
      const fg = Color(0xFF9333EA);
      return (bg: fg.withValues(alpha: 0.10), border: fg.withValues(alpha: 0.20), fg: fg);
    }
    return (
      bg: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
      border: scheme.outline.withValues(alpha: 0.18),
      fg: scheme.onSurface.withValues(alpha: 0.60),
    );
  }

  Widget _glassCard({
    required Widget child,
    required bool isDark,
    EdgeInsets padding = const EdgeInsets.all(22),
  }) {
    final border = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08);
    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: isDark ? 0.06 : 0.03),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                blurRadius: 40,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _pillButton({
    required IconData icon,
    required VoidCallback? onTap,
    required ColorScheme scheme,
    required bool isDark,
  }) {
    final border = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: scheme.surface.withValues(alpha: isDark ? 0.06 : 0.8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: Icon(icon, size: 18, color: scheme.primary.withValues(alpha: 0.7)),
      ),
    );
  }

  Widget _bookingCard(Map<String, dynamic> b) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final proj = _m(b['project']) ?? const <String, dynamic>{};
    final loc = _m(proj['location']);

    final id = _s(b['bookingId'], _s(b['_id'], _s(b['id'], '')));
    final projectName = _s(proj['title'], 'M4 Project');
    final location = _s(loc?['name'], _s(proj['location'], 'Mumbai'));
    final unitNo = _s(b['unitNumber'], _s(b['unitNo'], 'N/A'));
    final configuration = _s(b['configuration'], 'Standard');

    final created = _dt(b['createdAt']) ?? _dt(b['bookingDate']) ?? _dt(b['scheduledDate']);
    final bookingDate = created != null ? DateFormat.yMMMd().format(created.toLocal()) : 'N/A';

    final status = _s(b['status'], 'Pending');
    final paymentProgress = _i(b['paymentProgress'], 0).clamp(0, 100);

    final clientName = _s(b['name'], 'N/A');
    final clientEmail = _s(b['email'], 'N/A');
    final clientPhone = _s(b['phone'], 'N/A');
    final employee = _m(b['employeeId']);
    final employeeName = _s(employee?['name'], _s(b['employeeName'], 'Global'));

    final st = _statusColors(scheme, status);
    final onSurf = scheme.onSurface;
    final muted = onSurf.withValues(alpha: isDark ? 0.55 : 0.6);

    return _glassCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: scheme.primary.withValues(alpha: 0.20)),
                ),
                child: Icon(LucideIcons.building2, size: 22, color: scheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      projectName.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                        color: onSurf,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(LucideIcons.mapPin, size: 14, color: scheme.primary.withValues(alpha: 0.55)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.montserrat(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: st.bg,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: st.border),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: GoogleFonts.montserrat(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.8,
                    color: st.fg,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(height: 1, color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _kv(
                  label: 'LEAD IDENTITY',
                  value: clientName.toUpperCase(),
                  icon: LucideIcons.user,
                  scheme: scheme,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _kv(
                    label: 'UNIT SPECS',
                    value: '#$unitNo • $configuration'.toUpperCase(),
                    icon: null,
                    scheme: scheme,
                    rightAlign: true,
                    italic: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _kv(
                  label: 'LOCK-IN DATE',
                  value: bookingDate.toUpperCase(),
                  icon: LucideIcons.calendar,
                  scheme: scheme,
                  iconAlpha: 0.55,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _kv(
                    label: 'RELATIONSHIP MGR',
                    value: employeeName.toUpperCase(),
                    icon: LucideIcons.userCheck,
                    scheme: scheme,
                    rightAlign: true,
                    iconAfter: true,
                    iconAlpha: 0.55,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(height: 1, color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: onSurf.withValues(alpha: isDark ? 0.06 : 0.035),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: scheme.primary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'MILESTONE PAYMENT PROGRESSION',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                          color: muted.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '$paymentProgress%',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.10)),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: paymentProgress / 100.0),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCirc,
                      builder: (_, v, __) {
                        return FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: v.clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  scheme.primary.withValues(alpha: 0.65),
                                  scheme.primary,
                                  scheme.primary.withValues(alpha: 0.9),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _pillButton(
                icon: LucideIcons.phone,
                onTap: (clientPhone.isNotEmpty && clientPhone != 'N/A')
                    ? () => _openExternal('tel:$clientPhone')
                    : null,
                scheme: scheme,
                isDark: isDark,
              ),
              const SizedBox(width: 10),
              _pillButton(
                icon: LucideIcons.mail,
                onTap: (clientEmail.isNotEmpty && clientEmail != 'N/A')
                    ? () => _openExternal('mailto:$clientEmail')
                    : null,
                scheme: scheme,
                isDark: isDark,
              ),
              const Spacer(),
              if (id.isNotEmpty)
                Text(
                  'CP-TRK / ${id.substring(id.length - (id.length >= 8 ? 8 : id.length)).toUpperCase()}',
                  style: GoogleFonts.montserrat(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.6,
                    fontStyle: FontStyle.italic,
                    color: muted.withValues(alpha: 0.35),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kv({
    required String label,
    required String value,
    required ColorScheme scheme,
    IconData? icon,
    bool rightAlign = false,
    bool italic = false,
    bool iconAfter = false,
    double iconAlpha = 1.0,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurf = scheme.onSurface;
    final muted = onSurf.withValues(alpha: isDark ? 0.55 : 0.55);

    final labelW = Text(
      label,
      style: GoogleFonts.montserrat(
        fontSize: 9,
        fontWeight: FontWeight.w900,
        letterSpacing: 2.4,
        color: muted.withValues(alpha: 0.55),
      ),
    );

    final valueW = Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: rightAlign ? TextAlign.right : TextAlign.left,
      style: GoogleFonts.montserrat(
        fontSize: 13,
        fontWeight: FontWeight.w900,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
        letterSpacing: -0.1,
        color: onSurf.withValues(alpha: 0.82),
      ),
    );

    final iconW = icon == null
        ? const SizedBox.shrink()
        : Icon(icon, size: 16, color: scheme.primary.withValues(alpha: iconAlpha));

    Widget row;
    if (icon == null) {
      row = valueW;
    } else if (iconAfter) {
      row = Row(
        mainAxisAlignment: rightAlign ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(child: valueW),
          const SizedBox(width: 8),
          iconW,
        ],
      );
    } else {
      row = Row(
        mainAxisAlignment: rightAlign ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          iconW,
          const SizedBox(width: 8),
          Flexible(child: valueW),
        ],
      );
    }

    return Column(
      crossAxisAlignment: rightAlign ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        labelW,
        const SizedBox(height: 6),
        row,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cpIdx = ref.watch(cpNavigationIndexProvider);

    return Scaffold(
      extendBody: true,
      drawer: const CpSidebarMenu(),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    scheme.primary.withValues(alpha: isDark ? 0.08 : 0.05),
                    scheme.surface,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => context.pop(),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: scheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.10),
                            ),
                          ),
                          child: Icon(LucideIcons.chevronLeft, color: scheme.onSurface.withValues(alpha: 0.65)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CLIENT BOOKINGS',
                              style: GoogleFonts.montserrat(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.2,
                                color: scheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'STATUS: ACTIVE TRACKING',
                              style: GoogleFonts.montserrat(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.8,
                                fontStyle: FontStyle.italic,
                                color: scheme.onSurface.withValues(alpha: 0.35),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _loading
                      ? Center(
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(color: scheme.primary, strokeWidth: 3.5),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: _list.isEmpty
                              ? ListView(
                                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
                                  children: [
                                    _glassCard(
                                      isDark: isDark,
                                      child: Column(
                                        children: [
                                          Icon(LucideIcons.clock, size: 34, color: scheme.onSurface.withValues(alpha: 0.18)),
                                          const SizedBox(height: 14),
                                          Text(
                                            'NO ACTIVE BOOKINGS DISCOVERED YET',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.montserrat(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 2.8,
                                              color: scheme.onSurface.withValues(alpha: 0.55),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          TextButton(
                                            onPressed: () => context.push('/cp/visits'),
                                            child: Text(
                                              'CHECK SCHEDULED VISITS',
                                              style: GoogleFonts.montserrat(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 2.4,
                                                color: scheme.primary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
                                  itemCount: _list.length,
                                  itemBuilder: (_, i) {
                                    final raw = _list[i];
                                    final b = _m(raw) ?? const <String, dynamic>{};
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 16),
                                      child: _bookingCard(b),
                                    );
                                  },
                                ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: CpBottomNav(
        currentIndex: cpIdx,
        onTap: (i) {
          context.go('/home');
          ref.read(cpNavigationIndexProvider.notifier).state = i;
        },
      ),
    );
  }
}
