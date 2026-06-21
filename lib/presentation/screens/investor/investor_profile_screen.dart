import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

/// Investor profile — parity with web `app/investor/profile/page.tsx`
/// (profile card, points, property services, referral, logout). Follows M4 conventions.
class InvestorProfileScreen extends ConsumerStatefulWidget {
  const InvestorProfileScreen({super.key});

  @override
  ConsumerState<InvestorProfileScreen> createState() => _InvestorProfileScreenState();
}

class _InvestorProfileScreenState extends ConsumerState<InvestorProfileScreen> {
  static const _gold = Color(0xFFFFD700);

  bool _loading = true;
  Map<String, dynamic>? _me;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchUser());
  }

  Future<void> _fetchUser() async {
    setState(() => _loading = true);
    try {
      final res = await ref.read(apiClientProvider).getCurrentUser();
      final body = res.data;
      if (body is Map && body['status'] == true && body['data'] is Map) {
        setState(() => _me = Map<String, dynamic>.from(body['data'] as Map));
      } else if (body is Map && body['data'] is Map) {
        setState(() => _me = Map<String, dynamic>.from(body['data'] as Map));
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Map<String, dynamic> _user() {
    if (_me != null) return _me!;
    final u = ref.read(authProvider).user;
    if (u != null) return Map<String, dynamic>.from(u);
    return {};
  }

  String _name(Map<String, dynamic> u) {
    final fn = u['fullName']?.toString().trim();
    if (fn != null && fn.isNotEmpty) return fn;
    final combined = '${u['firstName'] ?? ''} ${u['lastName'] ?? ''}'.trim();
    if (combined.isNotEmpty) return combined;
    return u['phone']?.toString() ?? 'Member';
  }

  String _avatarUrl(Map<String, dynamic> u) {
    final raw = u['avatar'] ?? u['avatarUrl'];
    final resolved = ref.read(apiClientProvider).resolveUrl(raw?.toString());
    if (resolved.isNotEmpty) return resolved;
    return 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(_name(u))}&background=random';
  }

  String? _born(Map<String, dynamic> u) {
    final raw = u['dob'];
    if (raw == null || raw.toString().isEmpty) return null;
    try {
      return DateFormat('d MMM y').format(DateTime.parse(raw.toString()));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.black : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black;
    final muted = textPrimary.withValues(alpha: 0.5);

    if (_loading) {
      return Scaffold(
        backgroundColor: bg,
        body: const Center(child: CircularProgressIndicator(color: M4Theme.premiumBlue)),
      );
    }

    final u = _user();
    final name = _name(u);
    final email = u['email']?.toString() ?? 'no email provided';
    final phone = u['phone']?.toString().isNotEmpty == true ? u['phone'].toString() : 'Not provided';
    final address = u['address']?.toString().isNotEmpty == true ? u['address'].toString() : 'No address provided';
    final points = u['loyaltyPoints'] ?? 0;
    final born = _born(u);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
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
                      color: textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Material(
                    color: textPrimary.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () => context.push('/investor/settings'),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: textPrimary.withValues(alpha: 0.08)),
                        ),
                        child: Icon(LucideIcons.settings, size: 20, color: muted),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _profileCard(isDark, textPrimary, muted, name: name, email: email, phone: phone, address: address, born: born, points: points, avatarUrl: _avatarUrl(u)),
              const SizedBox(height: 28),
              _sectionLabel('PROPERTY SERVICES', muted),
              const SizedBox(height: 12),
              _linkRow(textPrimary, muted, isDark, title: 'My Properties', subtitle: 'View your purchased units & documents', icon: LucideIcons.building2, onTap: () => context.push('/investor/portfolio')),
              const SizedBox(height: 10),
              _linkRow(textPrimary, muted, isDark, title: 'Installments', subtitle: 'Track upcoming payments', icon: LucideIcons.calendar, onTap: () => context.push('/investor/installments')),
              const SizedBox(height: 10),
              _linkRow(textPrimary, muted, isDark, title: 'Tax Reports', subtitle: 'Download your statements', icon: LucideIcons.fileText, onTap: () => context.push('/investor/tax-reports')),
              const SizedBox(height: 24),
              _sectionLabel('MANAGEMENT & SUPPORT', muted),
              const SizedBox(height: 12),
              _linkRow(textPrimary, muted, isDark, title: 'M4 Referral Program', subtitle: 'Share & Earn rewards', icon: LucideIcons.users, onTap: () => context.push('/investor/referral')),
              const SizedBox(height: 10),
              _linkRow(textPrimary, muted, isDark, title: 'Support & Contact', subtitle: '24/7 Concierge service', icon: LucideIcons.phone, onTap: () => context.push('/investor/support')),
              const SizedBox(height: 28),
              _logoutButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileCard(
    bool isDark,
    Color textPrimary,
    Color muted, {
    required String name,
    required String email,
    required String phone,
    required String address,
    required String? born,
    required dynamic points,
    required String avatarUrl,
  }) {
    final card = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;
    final border = (isDark ? Colors.white : Colors.black).withValues(alpha: isDark ? 0.08 : 0.06);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: border),
        color: card,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  padding: const EdgeInsets.all(1.5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _gold.withValues(alpha: 0.4)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: avatarUrl,
                      fit: BoxFit.cover,
                      memCacheWidth: 160,
                      errorWidget: (_, __, ___) => Icon(LucideIcons.user, color: muted, size: 36),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.toUpperCase(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w700, color: muted),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        phone,
                        style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w700, color: muted, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: textPrimary.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.mapPin, size: 12, color: muted),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                address.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w900, color: muted, letterSpacing: 1),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (born != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(LucideIcons.calendar, size: 12, color: _gold),
                            const SizedBox(width: 6),
                            Text(
                              'BORN: $born',
                              style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w800, color: _gold, letterSpacing: 0.8),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: border)),
              color: textPrimary.withValues(alpha: 0.02),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'POINTS',
                  style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w900, color: textPrimary, letterSpacing: 2),
                ),
                Text(
                  '$points',
                  style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.w900, color: _gold, letterSpacing: -0.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text, Color muted) {
    return Text(
      text,
      style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w900, color: muted, letterSpacing: 2.5),
    );
  }

  Widget _linkRow(
    Color textPrimary,
    Color muted,
    bool isDark, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final border = (isDark ? Colors.white : Colors.black).withValues(alpha: isDark ? 0.08 : 0.06);
    return Material(
      color: textPrimary.withValues(alpha: 0.03),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: _gold.withValues(alpha: 0.1),
                ),
                child: Icon(icon, size: 20, color: _gold),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w700, color: textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle.toUpperCase(),
                      style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w800, color: muted, letterSpacing: 1),
                    ),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight, size: 18, color: muted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _logoutButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          final go = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text('Log out', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700)),
              content: const Text('Sign out of your investor account?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Log out', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
          if (go == true && context.mounted) {
            await ref.read(authProvider.notifier).logout();
            if (!context.mounted) return;
            context.go('/investor/login');
          }
        },
        borderRadius: BorderRadius.circular(28),
        child: Container(
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.red.withValues(alpha: 0.35)),
            color: Colors.red.withValues(alpha: 0.08),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.logOut, size: 18, color: Colors.red),
              const SizedBox(width: 8),
              Text(
                'LOG OUT',
                style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.red, letterSpacing: 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
