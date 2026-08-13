import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:m4_mobile/presentation/widgets/navigation_pill.dart';
import 'package:m4_mobile/presentation/widgets/main_shell.dart';

/// Web `/contact` (`app/(user)/contact/page.tsx`) — "Contact Us / Institutional
/// Support": office cards (address + Directions/Call Now), a grayscale map
/// preview with an "Open Map" pill, and a "Get in Touch" email/phone card.
class ContactScreen extends ConsumerStatefulWidget {
  const ContactScreen({super.key});

  @override
  ConsumerState<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends ConsumerState<ContactScreen> {
  Map<String, dynamic>? _config;
  bool _isLoading = true;
  late final WebViewController _mapController;

  @override
  void initState() {
    super.initState();
    _initMapController();
    _fetchData();
  }

  void _initMapController() {
    _mapController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..loadHtmlString('''
        <!DOCTYPE html>
        <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <style>
            body { margin: 0; padding: 0; overflow: hidden; }
            iframe {
              width: 100vw;
              height: 100vh;
              border: 0;
              filter: grayscale(1) contrast(1.1);
            }
          </style>
        </head>
        <body>
          <iframe
            src="https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d3773.743144883176!2d72.812627!3d18.960416!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x3be7ce0e2634354b%3A0x67399a9b3a3a3a3a!2sM4+Aura+Heights!5e0!3m2!1sen!2sin!4v1711234567890!5m2!1sen!2sin"
            allowfullscreen=""
            loading="lazy"
            referrerpolicy="no-referrer-when-downgrade">
          </iframe>
        </body>
        </html>
      ''');
  }

  Future<void> _fetchData() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.getSystemConfig();
      if (res.data['status'] == true || res.data['status'] == 'true') {
        setState(() => _config = res.data['data']);
      }
    } catch (e) {
      debugPrint("Error fetching contact config: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _launchUrl(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mapConfig = _config?['map_config'] as Map? ?? {};
    final contactEmail = _config?['contact_email'] ?? "sales@m4group.in";
    final contactPhone = _config?['contact_phone'] ?? "+91 99308 50993";

    // Web maps over config.offices; fall back to the head office so the screen
    // is never empty.
    final rawOffices = (_config?['offices'] as List?) ?? [];
    final offices = rawOffices.isNotEmpty
        ? rawOffices
        : [
            {
              'title': 'Corporate Head Office',
              'address':
                  '604, 6th Floor, M4 Aura Heights, Maulana Shaukat Ali Road, Grant Road, Mumbai - 400007',
              'phone': contactPhone,
              'mapLink':
                  mapConfig['google_maps_url'] ??
                  'https://maps.google.com/?q=M4+Aura+Heights',
            },
          ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      // Bottom nav — shown only when pushed standalone (from the menu), not
      // when embedded as a shell tab (the shell provides its own nav, so
      // rendering this one too would stack two nav bars).
      bottomNavigationBar: Navigator.of(context).canPop()
          ? NavigationPill(
              currentIndex: -1,
              onTap: (i) {
                ref.read(navigationProvider.notifier).state = i;
                Navigator.of(context).popUntil((r) => r.isFirst);
              },
            )
          : null,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: isDark ? Colors.white24 : Colors.black12,
              ),
            )
          : SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(isDark),
                    const SizedBox(height: 32),
                    // Office cards
                    ...offices.map(
                      (o) => Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: _officeCard(o as Map, isDark),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Map preview
                    _sectionLabel('GLOBAL HEADQUARTERS', isDark),
                    const SizedBox(height: 16),
                    _buildMapSection(mapConfig, isDark),
                    const SizedBox(height: 40),
                    // Get in touch
                    _sectionLabel('GET IN TOUCH', isDark),
                    const SizedBox(height: 16),
                    _buildDirectContact(contactEmail, contactPhone, isDark),
                  ],
                ),
              ),
            ),
    );
  }

  // Web parity: circular back button + "Contact Us" / "Institutional Support".
  Widget _buildHeader(bool isDark) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
              ),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
            ),
            child: Icon(
              LucideIcons.arrowLeft,
              size: 18,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CONTACT US',
              style: GoogleFonts.ebGaramond(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'INSTITUTIONAL SUPPORT',
              style: GoogleFonts.ebGaramond(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.68),
                letterSpacing: 3.5,
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn().slideX(begin: -0.1);
  }

  Widget _sectionLabel(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Text(
        text,
        style: GoogleFonts.ebGaramond(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.68),
          letterSpacing: 2,
        ),
      ),
    );
  }

  // Web parity: glass card (rounded-[2.5rem]) with a MapPin icon box, title +
  // address, and Directions (outline) / Call Now (filled) buttons.
  Widget _officeCard(Map office, bool isDark) {
    final title = (office['title'] ?? 'Corporate Head Office').toString();
    final address = (office['address'] ?? '').toString();
    final phone = (office['phone'] ?? '').toString();
    final mapLink = (office['mapLink'] ?? '').toString();

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(36),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 30,
                  offset: const Offset(0, 14),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: (isDark ? Colors.white : Colors.black).withOpacity(
                      0.08,
                    ),
                  ),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                ),
                child: Icon(
                  LucideIcons.mapPin,
                  color: isDark ? Colors.white : Colors.black,
                  size: 20,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: GoogleFonts.ebGaramond(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black,
                        letterSpacing: -0.2,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      address,
                      style: GoogleFonts.ebGaramond(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: (isDark ? Colors.white : Colors.black)
                            .withOpacity(0.6),
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              // Directions (outline)
              Expanded(
                child: GestureDetector(
                  onTap: () => _launchUrl(mapLink),
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.03)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: (isDark ? Colors.white : Colors.black)
                            .withOpacity(0.12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.externalLink,
                          size: 15,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'DIRECTIONS',
                          style: GoogleFonts.ebGaramond(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Call Now (filled)
              Expanded(
                child: GestureDetector(
                  onTap: () => _launchUrl('tel:$phone'),
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white : Colors.black,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.phone,
                          size: 15,
                          color: isDark ? Colors.black : Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'CALL NOW',
                          style: GoogleFonts.ebGaramond(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            color: isDark ? Colors.black : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildMapSection(Map mapConfig, bool isDark) {
    final mapsUrl =
        mapConfig['google_maps_url'] ??
        'https://maps.google.com/?q=M4+Aura+Heights';
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.03),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 30,
                  offset: const Offset(0, 14),
                ),
              ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          WebViewWidget(controller: _mapController),
          // Web parity: "Open in Maps" link top-left.
          Positioned(
            top: 16,
            left: 16,
            child: GestureDetector(
              onTap: () => _launchUrl(mapsUrl),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.black : Colors.white).withOpacity(
                    0.8,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Open in Maps',
                      style: GoogleFonts.ebGaramond(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      LucideIcons.externalLink,
                      size: 12,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // "OPEN MAP" pill bottom-center.
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () => _launchUrl(mapsUrl),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.black : Colors.white).withOpacity(
                      0.92,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: (isDark ? Colors.white : Colors.black).withOpacity(
                        0.1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.mapPin,
                        color: isDark ? Colors.white : Colors.black,
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'OPEN MAP',
                        style: GoogleFonts.ebGaramond(
                          color: isDark ? Colors.white : Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  // Web parity: one card with email + phone rows separated by a divider.
  Widget _buildDirectContact(String email, String phone, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 30,
                  offset: const Offset(0, 14),
                ),
              ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _contactRow(
            icon: LucideIcons.mail,
            value: email,
            label: 'SALES & ENQUIRIES',
            onTap: () => _launchUrl('mailto:$email'),
            isDark: isDark,
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
          ),
          _contactRow(
            icon: LucideIcons.phone,
            value: phone,
            label: 'DIRECT LINE',
            onTap: () => _launchUrl('tel:$phone'),
            isDark: isDark,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _contactRow({
    required IconData icon,
    required String value,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: (isDark ? Colors.white : Colors.black).withOpacity(
                      0.08,
                    ),
                  ),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                ),
                child: Icon(
                  icon,
                  color: isDark ? Colors.white : Colors.black,
                  size: 18,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: GoogleFonts.ebGaramond(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      label,
                      style: GoogleFonts.ebGaramond(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: (isDark ? Colors.white : Colors.black)
                            .withOpacity(0.68),
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
