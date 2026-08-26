import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/widgets/main_shell.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Material(
      color: isDark ? const Color(0xFF141B3A) : const Color(0xFFF4EFE3),
      child: Stack(
        children: [
          SafeArea(
            // Edge-to-edge: content runs under the gesture bar so scrolling fills
            // the screen. Trailing padding keeps the last item reachable.
            bottom: false,
            child: Column(
              children: [
                _buildHeader(context, isDark),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        _buildProfileCard(user, isDark),
                        const SizedBox(height: 32),
                        _SectionTitle(title: 'FAMILY', isDark: isDark),
                        const SizedBox(height: 12),
                        _buildFamilySection(user, isDark),
                        const SizedBox(height: 32),
                        _SectionTitle(
                          title: 'PROPERTY SERVICES',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),
                        _buildPropertyServices(context, isDark),
                        const SizedBox(height: 32),
                        _SectionTitle(
                          title: 'MANAGEMENT & SUPPORT',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),
                        _buildManagementSupport(context, isDark),
                        const SizedBox(height: 32),
                        _buildLogoutButton(context, ref),
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'MY PROFILE',
            style: GoogleFonts.gelasio(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Color(0xFF0C312B),
              letterSpacing: -0.5,
            ),
          ),
          _IconButton(
            icon: LucideIcons.settings,
            isDark: isDark,
            onTap: () => context.push('/profile/settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(dynamic user, bool isDark) {
    final String fullName =
        user['fullName'] ??
        '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();
    final String? avatarUrl = user['avatarUrl'];
    final String email = user['email'] ?? 'No email provided';
    final String phone = user['phone'] ?? 'No phone provided';
    // Web parity: rewardWalletBalance preferred, comma-grouped.
    final num pointsVal =
        user['rewardWalletBalance'] ?? user['loyaltyPoints'] ?? 0;
    final String points = NumberFormat.decimalPattern(
      'en_IN',
    ).format(pointsVal);
    final String address = (user['address'] ?? 'No address provided')
        .toString();
    final String born = user['dob'] != null
        ? _formatDate(user['dob'].toString())
        : 'Not provided';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141B3A) : const Color(0xFFF4EFE3),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(28),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Image
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white10
                        : Color(0xFF163A2C).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(24),
                    image: avatarUrl != null
                        ? DecorationImage(
                            image: CachedNetworkImageProvider(
                              ref.read(apiClientProvider).resolveUrl(avatarUrl),
                            ),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: avatarUrl == null
                      ? Icon(
                          LucideIcons.user,
                          color: isDark ? Colors.white38 : Color(0xFF155A4F),
                          size: 32,
                        )
                      : null,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName.toUpperCase(),
                        style: GoogleFonts.gelasio(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Color(0xFF0C312B),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white38 : Color(0x730C312B),
                        ),
                      ),
                      Text(
                        phone,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white38 : Color(0x730C312B),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Location Pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.black.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.mapPin,
                              size: 12,
                              color: isDark
                                  ? Colors.white54
                                  : Color(0xFF155A4F),
                            ),
                            const SizedBox(width: 6),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 150),
                              child: Text(
                                address.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? Colors.white70
                                      : Color(0xFF0C312B),
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Born Row
                      Row(
                        children: [
                          Icon(
                            LucideIcons.calendar,
                            size: 12,
                            color: isDark ? Colors.white38 : Color(0xFF155A4F),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'BORN: ${born.toUpperCase()}',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white38
                                  : Color(0x730C312B),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Points Divider & Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.05),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'POINTS',
                  style: GoogleFonts.gelasio(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Color(0xFF0C312B),
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  points,
                  style: GoogleFonts.gelasio(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Color(0xFF0C312B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Web parity: single "My Family" card with a subtitle.
  Widget _buildFamilySection(dynamic user, bool isDark) {
    return _SupportTile(
      label: 'MY FAMILY',
      subtitle: 'MANAGE YOUR FAMILY DETAILS',
      icon: LucideIcons.users,
      isDark: isDark,
      onTap: () => context.push('/profile/family'),
    );
  }

  // Web parity: a single full-width "My Properties" card (no "Visits").
  Widget _buildPropertyServices(BuildContext context, bool isDark) {
    return _SupportTile(
      label: 'MY PROPERTIES',
      subtitle: 'VIEW YOUR PURCHASED UNITS & DOCUMENTS',
      icon: LucideIcons.building,
      isDark: isDark,
      onTap: () => context.push('/profile/my-property'),
    );
  }

  // Web parity: only My Custom Views + M4 Referral Program.
  Widget _buildManagementSupport(BuildContext context, bool isDark) {
    return Column(
      children: [
        _SupportTile(
          label: 'MY CUSTOM VIEWS',
          subtitle: 'PERSONALISE YOUR PURCHASED UNITS',
          icon: LucideIcons.palette,
          isDark: isDark,
          onTap: () => ref.read(navigationProvider.notifier).state = 7,
        ),
        const SizedBox(height: 12),
        _SupportTile(
          label: 'M4 REFERRAL PROGRAM',
          subtitle: 'SHARE & EARN REWARDS',
          icon: LucideIcons.users,
          isDark: isDark,
          onTap: () => context.push('/profile/referral'),
        ),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      height: 64,
      child: OutlinedButton(
        onPressed: () {
          ref.read(authProvider.notifier).logout();
          // Web parity: after logout, drop into guest mode (browse-as-guest
          // home), not the login/onboarding selection screen.
          context.go('/home');
        },
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.red.withOpacity(0.1)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
          backgroundColor: const Color(0xFFF4EFE3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.logOut, color: Colors.redAccent, size: 20),
            const SizedBox(width: 12),
            Text(
              'LOG OUT',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.redAccent,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('d MMM yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final bool isDark;
  const _SectionTitle({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Text(
        title,
        style: GoogleFonts.gelasio(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isDark
              ? Colors.white.withOpacity(0.72)
              : const Color(0xFF0C312B).withOpacity(0.72),
          letterSpacing: 2,
        ),
      ),
    );
  }
}

class _SupportTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;
  const _SupportTile({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141B3A) : const Color(0xFFF4EFE3),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.04),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isDark ? Colors.white38 : Color(0x730C312B),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Color(0xFF155A4F),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : Color(0x8A0C312B),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: isDark ? Colors.white70 : Color(0x8A0C312B),
            ),
            const SizedBox(width: 8),
          ],
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : const Color(0xFFF4EFE3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05),
          ),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                  ),
                ],
        ),
        child: Icon(
          icon,
          size: 20,
          color: isDark ? Colors.white : Color(0xFF0C312B),
        ),
      ),
    );
  }
}
