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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background ambient effects
          if (isDark) ...[
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.withOpacity(0.05),
                ),
              ).animate().fadeIn(duration: 1000.ms),
            ),
            Positioned(
              bottom: -100,
              left: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.purple.withOpacity(0.05),
                ),
              ).animate().fadeIn(duration: 1000.ms),
            ),
          ],

          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, isDark),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _buildProfileCard(user, isDark),
                        const SizedBox(height: 16),
                        _buildOwnerDetails(user, isDark),
                        const SizedBox(height: 16),
                        _buildFamilySection(user, isDark),
                        if (user['bookings']?.isNotEmpty == true) ...[
                          const SizedBox(height: 16),
                          _buildBookingsSummary(user, isDark),
                        ],
                        if (user['documents']?.isNotEmpty == true) ...[
                          const SizedBox(height: 16),
                          _buildDocumentsSummary(user, isDark),
                        ],
                        const SizedBox(height: 16),
                        _buildPropertyServices(context, isDark),
                        const SizedBox(height: 16),
                        _buildPreferences(context, ref, isDark),
                        const SizedBox(height: 24),
                        _buildLogoutButton(context, ref),
                        const SizedBox(height: 100),
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

  Widget _buildBookingsSummary(dynamic user, bool isDark) {
    final List<dynamic> bookings = user['bookings'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: 'RECENT BOOKINGS', isDark: isDark),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05)),
          ),
          child: Column(
            children: bookings.take(3).map((b) {
              final String id = b['bookingId'] ?? 'BOOKING';
              final String title = b['projectTitle'] ?? b['type'] ?? 'PROPERTY';
              final String status = (b['status'] ?? 'PENDING').toString().toUpperCase();
              final int? payment = b['paymentPercent'];

              return Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Row(
                  children: [
                    _IconBox(icon: LucideIcons.building2, isDark: isDark),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            id,
                            style: GoogleFonts.montserrat(textStyle: const TextStyle(inherit: true), 
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white24 : Colors.black26,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            title,
                            style: GoogleFonts.montserrat(textStyle: const TextStyle(inherit: true), 
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            payment != null ? '$status · $payment% PAID' : status,
                            style: GoogleFonts.montserrat(textStyle: const TextStyle(inherit: true), 
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white38 : Colors.black38,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentsSummary(dynamic user, bool isDark) {
    final List<dynamic> documents = user['documents'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: 'RECENT DOCUMENTS', isDark: isDark),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05)),
          ),
          child: Column(
            children: documents.take(3).map((doc) {
              final String name = doc['name'] ?? 'DOCUMENT';
              final String subtitle = [doc['category'], doc['status']].where((s) => s != null).join(' · ').toUpperCase();

              return Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: InkWell(
                  onTap: () => context.push('/profile/legal-vault'),
                  child: Row(
                    children: [
                      _IconBox(icon: LucideIcons.fileText, isDark: isDark),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: GoogleFonts.montserrat(textStyle: const TextStyle(inherit: true), 
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle.isEmpty ? 'SECURE FILE' : subtitle,
                              style: GoogleFonts.montserrat(textStyle: const TextStyle(inherit: true), 
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white38 : Colors.black38,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(LucideIcons.chevronRight, size: 14, color: isDark ? Colors.white24 : Colors.black26),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'MY PROFILE',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
              letterSpacing: 1,
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
    final String dor = user['createdAt'] != null ? _formatDate(user['createdAt']) : 'JAN 2024';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05)),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
                  ),
                  child: avatarUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: CachedNetworkImage(
                            imageUrl: ref.read(apiClientProvider).resolveUrl(avatarUrl),
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: Colors.black12),
                            errorWidget: (context, url, error) => Icon(LucideIcons.user, color: isDark ? Colors.white38 : Colors.black38),
                          ),
                        )
                      : Icon(LucideIcons.user, color: isDark ? Colors.white38 : Colors.black38),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName.toUpperCase(),
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email.toUpperCase(),
                        style: GoogleFonts.montserrat(textStyle: const TextStyle(inherit: true), 
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white38 : Colors.black38,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        phone.toUpperCase(),
                        style: GoogleFonts.montserrat(textStyle: const TextStyle(inherit: true), 
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white38 : Colors.black38,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (user['dob'] != null)
                        Text(
                          'DOB: ${_formatDate(user['dob'])}'.toUpperCase(),
                          style: GoogleFonts.montserrat(textStyle: const TextStyle(inherit: true), 
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white38 : Colors.black38,
                            letterSpacing: 0.5,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.01),
              border: Border(top: BorderSide(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05))),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildStatusItem('STATUS', (user['status'] ?? 'ACTIVE').toUpperCase(), isDark, color: const Color(0xFF22C55E)),
                    _buildDivider(isDark),
                    _buildStatusItem('POINTS', (user['loyaltyPoints'] ?? 0).toString(), isDark),
                  ],
                ),
                if (user['paymentStatus'] != null && user['paymentStatus'].toString().isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Container(width: double.infinity, height: 1, color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'PAYMENT STATUS',
                    style: GoogleFonts.montserrat(textStyle: const TextStyle(inherit: true), 
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white24 : Colors.black26,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user['paymentStatus'].toString().toUpperCase(),
                    style: GoogleFonts.montserrat(textStyle: const TextStyle(inherit: true), 
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, bool isDark, {Color? color}) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.montserrat(textStyle: const TextStyle(inherit: true), 
              fontSize: 8,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white24 : Colors.black26,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.montserrat(textStyle: const TextStyle(inherit: true), 
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color ?? (isDark ? Colors.white : Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(width: 1, height: 24, color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05));
  }

  Widget _buildOwnerDetails(dynamic user, bool isDark) {
    final rawOwnerDetails = user['ownerDetails'];
    
    // Normalize keys just like web
    String pan = "";
    String aadhar = "";
    
    if (rawOwnerDetails is Map) {
      pan = (rawOwnerDetails['PAN'] ?? rawOwnerDetails['pan'] ?? "").toString();
      aadhar = (rawOwnerDetails['AADHAR'] ?? rawOwnerDetails['aadhaar'] ?? rawOwnerDetails['aadhar'] ?? "").toString();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: 'OWNER DETAILS', isDark: isDark),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05)),
          ),
          child: Column(
            children: [
              _InfoTile(label: 'PAN', value: pan.isEmpty ? 'NOT LINKED' : pan.toUpperCase(), isDark: isDark),
              const SizedBox(height: 24),
              _InfoTile(label: 'AADHAR', value: aadhar.isEmpty ? 'NOT LINKED' : aadhar, isDark: isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFamilySection(dynamic user, bool isDark) {
    final List<dynamic> family = user['familyMembers'] ?? user['familyDetails'] ?? [];
    if (family.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: 'FAMILY', isDark: isDark),
        const SizedBox(height: 12),
        Column(
          children: family.map((member) {
            final String name = member['name'] ?? 'UNKNOWN';
            final String relation = (member['relation'] ?? 'MEMBER').toUpperCase();
            final String? dobRaw = member['dob'];
            String dobFormatted = "";
            
            if (dobRaw != null && dobRaw.isNotEmpty) {
              try {
                final date = DateTime.parse(dobRaw);
                dobFormatted = "DOB: ${DateFormat('d MMM yyyy').format(date).toUpperCase()}";
              } catch (e) {
                dobFormatted = "DOB: ${dobRaw.toUpperCase()}";
              }
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05)),
              ),
              child: Row(
                children: [
                  _IconBox(icon: LucideIcons.users, isDark: isDark),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          relation,
                          style: GoogleFonts.montserrat(textStyle: const TextStyle(inherit: true), 
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white24 : Colors.black26,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          name,
                          style: GoogleFonts.montserrat(textStyle: const TextStyle(inherit: true), 
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        if (dobFormatted.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            dobFormatted,
                            style: GoogleFonts.montserrat(textStyle: const TextStyle(inherit: true), 
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white38 : Colors.black38,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPropertyServices(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: 'PROPERTY SERVICES', isDark: isDark),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _ServiceIconButton(label: 'MY PROPERTY', icon: LucideIcons.building2, isDark: isDark, onTap: () => context.push('/profile/my-property')),
            _ServiceIconButton(label: 'VISITS', icon: LucideIcons.calendar, isDark: isDark, onTap: () => context.push('/support/schedule-visit')),
            _ServiceIconButton(label: 'DOCUMENTS', icon: LucideIcons.fileText, isDark: isDark, onTap: () => context.push('/profile/legal-vault')),
          ],
        ),
        const SizedBox(height: 16),
        _ListActionTile(
          label: 'MY CUSTOM VIEWS',
          subtitle: 'PERSONALISE YOUR PURCHASED UNITS',
          icon: LucideIcons.palette,
          isDark: isDark,
          onTap: () => ref.read(navigationProvider.notifier).state = 7,
        ),
        const SizedBox(height: 12),
        _ListActionTile(
          label: 'PERSONALISATION LOGS',
          subtitle: 'VIEW YOUR SAVED DESIGN HISTORY',
          icon: LucideIcons.clipboardList,
          isDark: isDark,
          onTap: () => ref.read(navigationProvider.notifier).state = 5,
        ),
        const SizedBox(height: 12),
        _ListActionTile(
          label: 'CONCIERGE TICKET LOGS',
          subtitle: 'SERVICE & SUPPORT HISTORY',
          icon: LucideIcons.fileText,
          isDark: isDark,
          onTap: () => context.push('/support/logs'),
        ),
        const SizedBox(height: 12),
        _ListActionTile(
          label: 'M4 REFERRAL PROGRAM',
          subtitle: 'SHARE & EARN REWARDS',
          icon: LucideIcons.users,
          isDark: isDark,
          onTap: () => context.push('/profile/referral'),
        ),
        const SizedBox(height: 12),
        _ListActionTile(
          label: 'SUPPORT & CONTACT',
          subtitle: '24/7 CONCIERGE SERVICE',
          icon: LucideIcons.phone,
          isDark: isDark,
          onTap: () => context.push('/support'),
        ),
      ],
    );
  }

  Widget _buildPreferences(BuildContext context, WidgetRef ref, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: 'PREFERENCES', isDark: isDark),
        const SizedBox(height: 12),

        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              _IconBox(icon: LucideIcons.moon, isDark: isDark),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DARK MODE',
                      style: GoogleFonts.montserrat(textStyle: const TextStyle(inherit: true), 
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      isDark ? 'ENABLED' : 'DISABLED',
                      style: GoogleFonts.montserrat(textStyle: const TextStyle(inherit: true), 
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white38 : Colors.black38,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isDark,
                onChanged: (val) {
                  ref.read(themeProvider.notifier).setTheme(val ? ThemeMode.dark : ThemeMode.light);
                },
                activeColor: Colors.white,
                activeTrackColor: Colors.white24,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF18181B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('Logout', style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
              content: Text('Are you sure you want to logout?', style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 14)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('CANCEL', style: GoogleFonts.montserrat(color: const Color(0xFF60A5FA), fontWeight: FontWeight.w600, fontSize: 13)),
                ),
                TextButton(
                  onPressed: () {
                    ref.read(authProvider.notifier).logout();
                    Navigator.pop(context);
                    context.go('/login');
                  },
                  child: Text('LOGOUT', style: GoogleFonts.montserrat(color: const Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF18181B),
          foregroundColor: const Color(0xFFEF4444),
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
            side: BorderSide(color: Colors.red.withOpacity(0.1)),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.logOut, size: 18),
            const SizedBox(width: 12),
            Text(
              'LOG OUT',
              style: GoogleFonts.montserrat(textStyle: const TextStyle(inherit: true), 
                fontSize: 10,
                fontWeight: FontWeight.w800,
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
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: GoogleFonts.montserrat(textStyle: const TextStyle(inherit: true), 
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: isDark ? Colors.white.withOpacity(0.4) : Colors.black.withOpacity(0.45),
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final IconData icon;
  const _InfoTile({required this.label, required this.value, required this.isDark, this.icon = LucideIcons.user});

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
                style: GoogleFonts.montserrat(textStyle: const TextStyle(inherit: true), 
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white24 : Colors.black26,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.montserrat(textStyle: const TextStyle(inherit: true), 
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

class _IconBox extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  const _IconBox({required this.icon, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: isDark ? Colors.white38 : Colors.black38, size: 18),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF18181B) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
        ),
        child: Icon(icon, color: isDark ? Colors.white54 : Colors.black54, size: 20),
      ),
    );
  }
}

class _ServiceIconButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;
  const _ServiceIconButton({required this.label, required this.icon, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF18181B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
            ),
            child: Icon(icon, color: isDark ? Colors.white54 : Colors.black54, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.montserrat(textStyle: const TextStyle(inherit: true), 
              fontSize: 8,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white38 : Colors.black38,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ListActionTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;
  const _ListActionTile({required this.label, required this.subtitle, required this.icon, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF18181B) : Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            _IconBox(icon: icon, isDark: isDark),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.montserrat(textStyle: const TextStyle(inherit: true), 
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.montserrat(textStyle: const TextStyle(inherit: true), 
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white38 : Colors.black38,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, color: isDark ? Colors.white24 : Colors.black26, size: 16),
          ],
        ),
      ),
    );
  }
}
