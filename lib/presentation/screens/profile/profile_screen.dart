import 'package:flutter/material.dart';
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

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildHeader(context, ref, user, themeMode),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          _buildTopNavigationGrid(context, ref, themeMode),
                          const SizedBox(height: 25),
                          _buildMembershipStats(user, isDark),
                          const SizedBox(height: 25),
                          _buildPersonalInfoSection(user, isDark),
                          const SizedBox(height: 25),
                          _buildFamilySection(user, isDark),
                          const SizedBox(height: 30),
                          _buildMenuSection(context, ref, themeMode),
                          const SizedBox(height: 30),
                          _buildPreferencesSection(context, ref, themeMode),
                          const SizedBox(height: 25),
                          _buildLogoutButton(ref, context),
                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 20,
                right: 20,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfileSettingsScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                      shape: BoxShape.circle,
                      border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
                    ),
                    child: Icon(
                      LucideIcons.settings, 
                      color: isDark ? Colors.white38 : Colors.black38, 
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, dynamic user, ThemeMode themeMode) {
    final isDark = themeMode == ThemeMode.dark;
    final String firstName = user?['firstName'] ?? '';
    final String lastName = user?['lastName'] ?? '';
    final String name = firstName.isNotEmpty ? '$firstName $lastName' : (user?['name'] ?? 'GUEST');
    final String? avatarUrl = user?['avatarUrl'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05), width: 1),
                image: avatarUrl != null
                    ? DecorationImage(
                        image: NetworkImage(ref.read(apiClientProvider).resolveUrl(avatarUrl)),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.03),
              ),
              child: avatarUrl == null
                  ? Center(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'G',
                        style: GoogleFonts.montserrat(
                          color: isDark ? Colors.white24 : Colors.black26, 
                          fontSize: 32, 
                          fontWeight: FontWeight.w300
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 15),
            Text(
              name.toUpperCase(),
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'PLATINUM MEMBER',
              style: GoogleFonts.montserrat(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white38 : Colors.black38,
                letterSpacing: 3,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  Widget _buildMembershipStats(dynamic user, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF080A0E) : Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('STATUS', (user?['status'] ?? 'PENDING').toString().toUpperCase(), Colors.orange, isDark),
          _buildStatItem('POINTS', (user?['points'] ?? '0').toString(), isDark ? Colors.white : Colors.black, isDark),
          _buildStatItem('TIER', (user?['tier'] ?? 'BRONZE').toString().toUpperCase(), Colors.orange, isDark),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color valueColor, bool isDark) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w900, color: isDark ? Colors.white24 : Colors.black26, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w900, color: valueColor, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildPersonalInfoSection(dynamic user, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 15, bottom: 12),
          child: Text('PERSONAL INFORMATION', style: GoogleFonts.montserrat(color: isDark ? Colors.white24 : Colors.black26, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF080A0E) : Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
          ),
          child: Column(
            children: [
              _buildInfoRow(LucideIcons.mapPin, 'CURRENT ADDRESS', user?['address'] ?? 'Not provided', isDark),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: Divider(height: 1, color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
              ),
              _buildInfoRow(LucideIcons.calendar, 'DATE OF BIRTH', _formatDate(user?['dob']), isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05), shape: BoxShape.circle),
          child: Icon(icon, color: isDark ? Colors.white38 : Colors.black38, size: 16),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.montserrat(color: isDark ? Colors.white24 : Colors.black26, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
              const SizedBox(height: 4),
              Text(value, style: GoogleFonts.montserrat(color: isDark ? Colors.white : Colors.black87, fontSize: 13, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFamilySection(dynamic user, bool isDark) {
    final List<dynamic> family = user?['familyDetails'] ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 15, bottom: 12),
          child: Text('FAMILY DETAILS', style: GoogleFonts.montserrat(color: isDark ? Colors.white24 : Colors.black26, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
        ),
        if (family.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF080A0E) : Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
            ),
            child: Center(child: Text('No family details added', style: GoogleFonts.montserrat(color: isDark ? Colors.white24 : Colors.black26, fontSize: 10, fontWeight: FontWeight.w700))),
          )
        else
          ...family.map((member) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF080A0E) : Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05), shape: BoxShape.circle),
                      child: Icon(LucideIcons.users, color: isDark ? Colors.white38 : Colors.black38, size: 20),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text((member['relation'] ?? 'MEMBER').toString().toUpperCase(), style: GoogleFonts.montserrat(color: isDark ? Colors.white24 : Colors.black26, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
                          const SizedBox(height: 4),
                          Text(member['name'] ?? 'Unknown', style: GoogleFonts.montserrat(color: isDark ? Colors.white : Colors.black, fontSize: 14, fontWeight: FontWeight.w900)),
                          Text('DOB: ${_formatDate(member['dob'])}', style: GoogleFonts.montserrat(color: isDark ? Colors.white38 : Colors.black38, fontSize: 10, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
      ],
    );
  }

  Widget _buildTopNavigationGrid(BuildContext context, WidgetRef ref, ThemeMode themeMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildTopNavItem(context, LucideIcons.home, 'BOOKINGS', themeMode, () {
          ref.read(navigationProvider.notifier).state = 0;
        }),
        _buildTopNavItem(context, LucideIcons.building2, 'VISITS', themeMode, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const ScheduleVisitScreen()));
        }),
        _buildTopNavItem(context, LucideIcons.fileText, 'DOCUMENTS', themeMode, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const SupportLogsScreen(initialIndex: 1)));
        }),
      ],
    );
  }

  Widget _buildTopNavItem(BuildContext context, IconData icon, String label, ThemeMode themeMode, VoidCallback onTap) {
    final isDark = themeMode == ThemeMode.dark;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 85,
            height: 85,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0A0C10) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.04)),
              boxShadow: isDark ? null : [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Center(
              child: Icon(icon, color: isDark ? Colors.white.withOpacity(0.7) : Colors.black87, size: 26),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: GoogleFonts.montserrat(
              color: isDark ? Colors.white38 : Colors.black45,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, WidgetRef ref, ThemeMode themeMode) {
    return Column(
      children: [
        _buildWebStyleListItem(
          context, 
          LucideIcons.clipboardList, 
          'CONCIERGE TICKET LOGS', 
          'SERVICE & SUPPORT HISTORY', 
          themeMode,
          () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SupportLogsScreen(initialIndex: 0))),
        ),
        const SizedBox(height: 12),
        _buildWebStyleListItem(
          context, 
          LucideIcons.users, 
          'M4 REFERRAL PROGRAM', 
          'SHARE & EARN REWARDS', 
          themeMode,
          () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ReferralScreen())),
        ),
        const SizedBox(height: 12),
        _buildWebStyleListItem(
          context, 
          LucideIcons.phoneCall, 
          'SUPPORT & CONTACT', 
          '24/7 CONCIERGE SERVICE', 
          themeMode,
          () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SupportScreen())),
        ),
      ],
    );
  }

  Widget _buildPreferencesSection(BuildContext context, WidgetRef ref, ThemeMode themeMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 15, bottom: 12),
          child: Text(
            'PREFERENCES',
            style: GoogleFonts.montserrat(
              color: themeMode == ThemeMode.dark ? Colors.white24 : Colors.black26,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ),
        _buildWebStyleListItem(
          context, 
          LucideIcons.globe, 
          'LANGUAGE SETTINGS', 
          'SELECTED: ENGLISH', 
          themeMode,
          () => _showLanguageSelector(context, themeMode == ThemeMode.dark),
        ),
        const SizedBox(height: 12),
        _buildDarkThemeItem(ref, themeMode),
      ],
    );
  }

  Widget _buildWebStyleListItem(BuildContext context, IconData icon, String title, String subtitle, ThemeMode themeMode, VoidCallback onTap) {
    final isDark = themeMode == ThemeMode.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF080A0E) : Colors.white,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.03)),
          boxShadow: isDark ? null : [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.04),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isDark ? Colors.white60 : Colors.black54, size: 18),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.toUpperCase(),
                    style: GoogleFonts.montserrat(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle.toUpperCase(),
                    style: GoogleFonts.montserrat(
                      color: isDark ? Colors.white24 : Colors.black38,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, color: (isDark ? Colors.white : Colors.black).withOpacity(0.1), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDarkThemeItem(WidgetRef ref, ThemeMode themeMode) {
    final isDark = themeMode == ThemeMode.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF080A0E) : Colors.white,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.03)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.moon, color: isDark ? Colors.white70 : Colors.black54, size: 18),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DARK MODE',
                  style: GoogleFonts.montserrat(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  isDark ? 'ENABLED' : 'DISABLED',
                  style: GoogleFonts.montserrat(
                    color: isDark ? Colors.white24 : Colors.black38,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isDark, 
            onChanged: (val) async {
              final newTheme = val ? ThemeMode.dark : ThemeMode.light;
              ref.read(themeProvider.notifier).setTheme(newTheme);
              try {
                await ref.read(apiClientProvider).updateTheme(val ? 'dark' : 'light');
              } catch (e) {
                // Background update, fail silently or log
              }
            },
            activeColor: Colors.white,
            activeTrackColor: Colors.white24,
            inactiveThumbColor: Colors.blueGrey,
            inactiveTrackColor: Colors.blueGrey.withOpacity(0.1),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(WidgetRef ref, BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await ref.read(authProvider.notifier).logout();
        if (context.mounted) {
          GoRouter.of(context).go('/login');
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFFF4B4B).withOpacity(0.03),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: const Color(0xFFFF4B4B).withOpacity(0.05)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.logOut, color: Color(0xFFFF4B4B), size: 18),
            const SizedBox(width: 12),
            Text(
              'LOG OUT',
              style: GoogleFonts.montserrat(
                color: const Color(0xFFFF4B4B),
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageSelector(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0E1116) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 15),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 25),
              Text('SELECT LANGUAGE', style: GoogleFonts.montserrat(color: isDark ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.w900)),
              const SizedBox(height: 20),
              _buildLanguageOption(context, 'ENGLISH', true, isDark),
              _buildLanguageOption(context, 'HINDI', false, isDark),
              _buildLanguageOption(context, 'MARATHI', false, isDark),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(BuildContext context, String label, bool isSelected, bool isDark) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 30),
      title: Text(label, style: GoogleFonts.montserrat(color: isSelected ? (isDark ? Colors.white : Colors.black) : (isDark ? Colors.white38 : Colors.black38), fontSize: 14, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500)),
      trailing: isSelected ? Icon(LucideIcons.check, color: isDark ? Colors.white : Colors.black, size: 20) : null,
      onTap: () => Navigator.pop(context),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr == 'Not provided' || dateStr == 'N/A' || dateStr.isEmpty) {
      return dateStr ?? 'Not provided';
    }
    try {
      // Handle formatting if it looks like an ISO string
      if (dateStr.contains('T')) {
        final dateTime = DateTime.parse(dateStr);
        return DateFormat('dd MMM yyyy').format(dateTime); // e.g., 06 Jul 2003
      }
      return dateStr;
    } catch (e) {
      return dateStr;
    }
  }
}
