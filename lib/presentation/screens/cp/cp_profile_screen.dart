import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

/// CP profile — parity with web `app/(cp)/cp/profile/page.tsx`. The web page
/// only links out to `/cp/profile/employees` for team management (handled by
/// the dedicated CpEmployeesScreen) rather than inlining a payment tracker,
/// employee list, or extra link rows — this screen mirrors that exactly.
class CpProfileScreen extends ConsumerStatefulWidget {
  const CpProfileScreen({super.key});

  @override
  ConsumerState<CpProfileScreen> createState() => _CpProfileScreenState();
}

class _CpProfileScreenState extends ConsumerState<CpProfileScreen> {
  static const _defaultAvatar =
      'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?auto=format&fit=crop&w=200&q=80';

  bool _loading = true;
  Map<String, dynamic>? _me;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchUser();
    });
  }

  Future<void> _fetchUser() async {
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.getCurrentUser();
      final body = res.data;
      if (body is Map && body['status'] == true && body['data'] is Map) {
        setState(() => _me = Map<String, dynamic>.from(body['data'] as Map));
      }
    } catch (e) {
      debugPrint('CP profile /auth/me: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Map<String, dynamic> _effectiveUser() {
    if (_me != null) return _me!;
    final u = ref.read(authProvider).user;
    if (u != null) return Map<String, dynamic>.from(u);
    return {};
  }

  String _name(Map<String, dynamic> u) {
    final fn = u['fullName']?.toString().trim();
    if (fn != null && fn.isNotEmpty) return fn;
    final first = u['firstName']?.toString() ?? '';
    final last = u['lastName']?.toString() ?? '';
    final combined = '$first $last'.trim();
    if (combined.isNotEmpty) return combined;
    final company = u['companyName']?.toString().trim();
    if (company != null && company.isNotEmpty) return company;
    return 'Partner';
  }

  String _avatarUrl(Map<String, dynamic> u) {
    final raw = u['avatar'] ?? u['avatarUrl'];
    if (raw == null || raw.toString().isEmpty) return _defaultAvatar;
    return ref.read(apiClientProvider).resolveUrl(raw.toString());
  }

  String? _bornLine(Map<String, dynamic> u) {
    final raw = u['dob'];
    if (raw == null || raw.toString().isEmpty) return null;
    try {
      final d = DateTime.parse(raw.toString());
      return DateFormat('d MMM y').format(d);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_loading) {
      return Scaffold(
        backgroundColor: scheme.surface,
        body: Center(
          child: SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: scheme.primary,
            ),
          ),
        ),
      );
    }

    final u = _effectiveUser();
    final name = _name(u);
    final email = u['email']?.toString() ?? '';
    final phone = u['phone']?.toString().isNotEmpty == true
        ? u['phone'].toString()
        : 'Not provided';
    final born = _bornLine(u);
    final avatarUrl = _avatarUrl(u);
    final firm = u['companyName']?.toString().trim();
    final rera = u['reraNumber']?.toString().trim();

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 280,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.8, -1),
                    radius: 1.2,
                    colors: [
                      scheme.primary.withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'MY PROFILE',
                        style: GoogleFonts.montserrat(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Material(
                        color: scheme.surfaceContainerHighest.withValues(
                          alpha: 0.85,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () => context.push('/cp/settings'),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: scheme.outlineVariant.withValues(
                                  alpha: 0.55,
                                ),
                              ),
                            ),
                            child: Icon(
                              LucideIcons.settings,
                              size: 20,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: scheme.outlineVariant.withValues(alpha: 0.45),
                  ),
                  const SizedBox(height: 16),
                  _profileCard(
                    context,
                    name: name,
                    email: email,
                    phone: phone,
                    born: born,
                    avatarUrl: avatarUrl,
                    scheme: scheme,
                    firm: firm,
                    rera: rera,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'TEAM & ACCESS',
                    style: GoogleFonts.montserrat(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurfaceVariant,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _teamAccessRow(
                    context,
                    onTap: () => context.push('/cp/profile/employees'),
                    scheme: scheme,
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'QUICK ACTIONS',
                    style: GoogleFonts.montserrat(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    // Web parity: `grid-cols-4` — one row of four, not 2x2.
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.82,
                    children: [
                      _serviceTile(
                        context,
                        label: 'Visit',
                        icon: LucideIcons.building2,
                        onTap: () => context.push('/cp/visits'),
                        scheme: scheme,
                      ),
                      _serviceTile(
                        context,
                        label: 'Booking',
                        icon: LucideIcons.calendar,
                        onTap: () => context.push('/cp/booking/my-bookings'),
                        scheme: scheme,
                      ),
                      _serviceTile(
                        context,
                        label: 'Tracker',
                        icon: LucideIcons.clipboardList,
                        onTap: () => context.push('/cp/visits'),
                        scheme: scheme,
                      ),
                      _serviceTile(
                        context,
                        label: 'Book Visit',
                        icon: LucideIcons.mapPin,
                        onTap: () => context.push('/cp/booking/schedule-visit'),
                        scheme: scheme,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        final go = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(
                              'Log out',
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            content: const Text(
                              'Sign out of your partner account?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: Text(
                                  'Log out',
                                  style: TextStyle(color: scheme.error),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (go == true && context.mounted) {
                          await ref.read(authProvider.notifier).logout();
                          if (!context.mounted) return;
                          context.go('/auth/cp/login');
                        }
                      },
                      borderRadius: BorderRadius.circular(28),
                      child: Container(
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: scheme.error.withValues(alpha: 0.35),
                          ),
                          color: scheme.error.withValues(alpha: 0.08),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.logOut,
                              size: 18,
                              color: scheme.error,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'LOG OUT',
                              style: GoogleFonts.montserrat(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: scheme.error,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileCard(
    BuildContext context, {
    required String name,
    required String email,
    required String phone,
    required String? born,
    required String avatarUrl,
    required ColorScheme scheme,
    String? firm,
    String? rera,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.45),
        ),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: scheme.brightness == Brightness.dark ? 0.35 : 0.08,
            ),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(32),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 116,
                      height: 116,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        // Web parity: `rounded-full` — circular, not squared.
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: scheme.outlineVariant.withValues(alpha: 0.6),
                        ),
                        color: scheme.surfaceContainerHigh.withValues(
                          alpha: 0.35,
                        ),
                      ),
                      child: ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: avatarUrl,
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                          memCacheWidth: 160,
                          memCacheHeight: 160,
                          fadeInDuration: Duration.zero,
                          errorWidget: (_, __, ___) => Icon(
                            LucideIcons.user,
                            color: scheme.outline,
                            size: 54,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 22),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.toUpperCase(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Web parity: phone (accent-colored) comes before email
                      // (muted, lowercase) — not the other way around.
                      Text(
                        phone.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: scheme.primary.withValues(alpha: 0.8),
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        email.toLowerCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface.withValues(alpha: 0.6),
                          letterSpacing: 0.2,
                        ),
                      ),
                      if ((firm != null && firm.isNotEmpty) ||
                          (rera != null && rera.isNotEmpty)) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            if (firm != null && firm.isNotEmpty)
                              _firmReraBadge(scheme, 'Firm: $firm'),
                            if (rera != null && rera.isNotEmpty)
                              _firmReraBadge(scheme, 'RERA: $rera'),
                          ],
                        ),
                      ],
                      if (born != null) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(
                              LucideIcons.calendar,
                              size: 14,
                              color: scheme.primary,
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                'BORN: $born',
                                style: GoogleFonts.montserrat(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: scheme.primary,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _firmReraBadge(ColorScheme scheme, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.22)),
      ),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.montserrat(
          fontSize: 8,
          fontWeight: FontWeight.w900,
          color: scheme.primary,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _serviceTile(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required ColorScheme scheme,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final side = (maxW * 0.58).clamp(72.0, 100.0);
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: side,
                    height: side,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: scheme.outlineVariant.withValues(alpha: 0.45),
                        ),
                        color: scheme.surfaceContainerHigh.withValues(
                          alpha: 0.4,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        icon,
                        size: 20,
                        color: scheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label.toUpperCase(),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      color: scheme.onSurface,
                      letterSpacing: 1.2,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Web parity: a single "Employee Management" row (icon + title only, no
  // subtitle) linking out to the dedicated CpEmployeesScreen — the web page
  // doesn't inline the employee list/add-employee UI on this screen either.
  Widget _teamAccessRow(
    BuildContext context, {
    required VoidCallback onTap,
    required ColorScheme scheme,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.35),
            ),
            color: scheme.onSurface.withValues(alpha: 0.03),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                  color: scheme.surfaceContainerHigh.withValues(alpha: 0.5),
                ),
                child: Icon(
                  LucideIcons.users,
                  size: 20,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'EMPLOYEE MANAGEMENT',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
