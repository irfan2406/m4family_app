import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:m4_mobile/core/providers/theme_provider.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/screens/profile/profile_settings_screen.dart';
import 'package:m4_mobile/presentation/screens/profile/referral_screen.dart';
import 'package:m4_mobile/presentation/screens/support/schedule_visit_screen.dart';
import 'package:m4_mobile/presentation/screens/support/support_logs_screen.dart';
import 'package:m4_mobile/presentation/screens/support/support_screen.dart';
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
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Material(
      color: isDark ? const Color(0xFF09090B) : const Color(0xFFF8FAFC),
      child: Stack(
        children: [
          SafeArea(
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
                        _SectionTitle(title: 'OWNER DETAILS', isDark: isDark),
                        const SizedBox(height: 12),
                        _buildOwnerDetails(user, isDark),
                        const SizedBox(height: 32),
                        _SectionTitle(title: 'FAMILY', isDark: isDark),
                        const SizedBox(height: 12),
                        _buildFamilySection(user, isDark),
                        const SizedBox(height: 32),
                        _SectionTitle(title: 'PROPERTY SERVICES', isDark: isDark),
                        const SizedBox(height: 16),
                        _buildPropertyServices(context, isDark),
                        const SizedBox(height: 32),
                        _SectionTitle(title: 'MANAGEMENT & SUPPORT', isDark: isDark),
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
            style: GoogleFonts.montserrat(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : Colors.black,
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
    final String fullName = user['fullName'] ?? '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();
    final String? avatarUrl = user['avatarUrl'];
    final String email = user['email'] ?? 'No email provided';
    final String phone = user['phone'] ?? 'No phone provided';
    final int points = user['loyaltyPoints'] ?? 500;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 30,
            offset: const Offset(0, 15),
          )
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
                    color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(24),
                    image: avatarUrl != null
                        ? DecorationImage(
                            image: CachedNetworkImageProvider(ref.read(apiClientProvider).resolveUrl(avatarUrl)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: avatarUrl == null ? Icon(LucideIcons.user, color: isDark ? Colors.white38 : Colors.black38, size: 32) : null,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName.toUpperCase(),
                        style: GoogleFonts.montserrat(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : Colors.black,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white38 : Colors.black45,
                        ),
                      ),
                      Text(
                        phone,
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white38 : Colors.black45,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Location Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.mapPin, size: 12, color: isDark ? Colors.white54 : Colors.black54),
                            const SizedBox(width: 6),
                            Text(
                              'SAKINAKA',
                              style: GoogleFonts.montserrat(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white70 : Colors.black87,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Born Row
                      Row(
                        children: [
                          Icon(LucideIcons.calendar, size: 12, color: isDark ? Colors.white38 : Colors.black38),
                          const SizedBox(width: 6),
                          Text(
                            'BORN: 5 JUL 2003',
                            style: GoogleFonts.montserrat(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white38 : Colors.black45,
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
              border: Border(top: BorderSide(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'POINTS',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : Colors.black,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  points.toString(),
                  style: GoogleFonts.montserrat(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerDetails(dynamic user, bool isDark) {
    final rawOwnerDetails = user['ownerDetails'];
    String pan = "IJKLM0000J";
    String aadhar = "111122223333";
    
    if (rawOwnerDetails is Map) {
      pan = (rawOwnerDetails['PAN'] ?? rawOwnerDetails['pan'] ?? pan).toString();
      aadhar = (rawOwnerDetails['AADHAR'] ?? rawOwnerDetails['aadhaar'] ?? rawOwnerDetails['aadhar'] ?? aadhar).toString();
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [
          _InfoRow(label: 'PAN', value: pan, icon: LucideIcons.user, isDark: isDark),
          const SizedBox(height: 20),
          Container(height: 1, color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)),
          const SizedBox(height: 20),
          _InfoRow(label: 'AADHAR', value: aadhar, icon: LucideIcons.user, isDark: isDark),
        ],
      ),
    );
  }

  Widget _buildFamilySection(dynamic user, bool isDark) {
    return GestureDetector(
      onTap: () => context.push('/profile/family'),
      child: Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Row(
        children: [
          _IconBox(icon: LucideIcons.users, isDark: isDark, color: Colors.blueAccent),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'MY FAMILY',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          Icon(LucideIcons.chevronRight, size: 16, color: isDark ? Colors.white24 : Colors.black26),
        ],
      ),
      ),
    );
  }

  Widget _buildPropertyServices(BuildContext context, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _ServiceCard(
            label: 'MY PROPERTIES',
            icon: LucideIcons.building,
            isDark: isDark,
            onTap: () => context.push('/profile/my-property'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _ServiceCard(
            label: 'VISITS',
            icon: LucideIcons.calendar,
            isDark: isDark,
            onTap: () => context.push('/support/schedule-visit'),
          ),
        ),
      ],
    );
  }

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
        const SizedBox(height: 12),
        _SupportTile(
          label: 'CONCIERGE TICKET LOGS',
          subtitle: 'SERVICE & SUPPORT HISTORY',
          icon: LucideIcons.fileText,
          isDark: isDark,
          onTap: () => context.push('/support/logs'),
        ),
        const SizedBox(height: 12),
        _SupportTile(
          label: 'SUPPORT & CONTACT',
          subtitle: '24/7 CONCIERGE SERVICE',
          icon: LucideIcons.phone,
          isDark: isDark,
          onTap: () => context.push('/support/contact'),
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
          context.go('/login');
        },
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.red.withOpacity(0.1)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
          backgroundColor: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.logOut, color: Colors.redAccent, size: 20),
            const SizedBox(width: 12),
            Text(
              'LOG OUT',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w900,
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
        style: GoogleFonts.montserrat(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: isDark ? Colors.white.withOpacity(0.25) : Colors.black.withOpacity(0.4),
          letterSpacing: 2,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isDark;
  const _InfoRow({required this.label, required this.value, required this.icon, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _IconBox(icon: icon, isDark: isDark),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.montserrat(
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white24 : Colors.black38,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;
  const _ServiceCard({required this.label, required this.icon, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(32),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF18181B) : Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
              blurRadius: 24,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: isDark ? Colors.white38 : Colors.black45),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white54 : Colors.black54,
                letterSpacing: 1,
              ),
            ),
          ],
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
  const _SupportTile({required this.label, required this.subtitle, required this.icon, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(32),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF18181B) : Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
              blurRadius: 24,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, size: 20, color: isDark ? Colors.white38 : Colors.black45),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.montserrat(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white24 : Colors.black45,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 16, color: isDark ? Colors.white24 : Colors.black26),
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
  const _IconButton({required this.icon, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
          boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
        ),
        child: Icon(icon, size: 20, color: isDark ? Colors.white : Colors.black),
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final Color? color;
  const _IconBox({required this.icon, required this.isDark, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: (color ?? (isDark ? Colors.white : Colors.black)).withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, size: 20, color: color ?? (isDark ? Colors.white38 : Colors.black54)),
    );
  }
}
