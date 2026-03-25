import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/core/utils/support_handlers.dart';


class ContactSupportScreen extends ConsumerStatefulWidget {
  const ContactSupportScreen({super.key});

  @override
  ConsumerState<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends ConsumerState<ContactSupportScreen> {
  Map<String, dynamic>? _configData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchConfig();
  }

  Future<void> _fetchConfig() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.getSystemConfig();
      if (response.data['status'] == true) {
        setState(() {
          _configData = response.data['data'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CONTACT US', 
                style: GoogleFonts.montserrat(
                  color: Colors.white, 
                  fontWeight: FontWeight.bold, 
                  fontSize: 20, 
                  letterSpacing: 1
                )),
            Text('INSTITUTIONAL SUPPORT', 
                style: GoogleFonts.montserrat(
                  color: Colors.white54, 
                  fontWeight: FontWeight.w900, 
                  fontSize: 10, 
                  letterSpacing: 4
                )),
          ],
        ),
        backgroundColor: Colors.black.withOpacity(0.8),
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.black,
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 2.0,
            colors: [Color(0xFF0F1115), Colors.black],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white24))
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildOffices(),
                      const SizedBox(height: 32),
                      _buildDirectContact(),
                      const SizedBox(height: 48),

                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildOffices() {
    final offices = (_configData?['offices'] as List?) ?? [];
    if (offices.isEmpty) {
      // Fallback office
      return _buildOfficeCard(
        title: 'CORPORATE HEAD OFFICE',
        address: '604, 6th Floor, M4 Aura Heights, Maulana Shaukat Ali Road, Grant Road, Mumbai - 400007',
        phone: '+91 99308 50993',
        mapLink: 'https://maps.google.com/?q=M4+Aura+Heights',
      );
    }

    return Column(
      children: offices.map((o) => Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: _buildOfficeCard(
          title: o['title'] ?? 'HEAD OFFICE',
          address: o['address'] ?? '',
          phone: o['phone'] ?? '',
          mapLink: o['mapLink'] ?? '',
        ),
      )).toList(),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildOfficeCard({
    required String title,
    required String address,
    required String phone,
    required String mapLink,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
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
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 20,
                        )
                      ],
                    ),
                    child: const Icon(LucideIcons.mapPin, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title.toUpperCase(),
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          address,
                          style: GoogleFonts.montserrat(
                            color: Colors.white54,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
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
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => SupportHandlers.openMap(address),
                      icon: const Icon(LucideIcons.externalLink, size: 14),
                      label: const Text('DIRECTIONS'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.white.withOpacity(0.1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: GoogleFonts.montserrat(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => SupportHandlers.launchCall(phone),

                      icon: const Icon(LucideIcons.phone, size: 14),
                      label: const Text('CALL NOW'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.black,
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 10,
                        textStyle: GoogleFonts.montserrat(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDirectContact() {
    final contactEmail = _configData?['contact_email'] ?? 'sales@m4group.in';
    final contactPhone = _configData?['contact_phone'] ?? '+91 99308 50993';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'GET IN TOUCH',
            style: GoogleFonts.montserrat(
              color: Colors.white38,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                children: [
                  _ContactRowItem(
                    icon: LucideIcons.mail,
                    title: contactEmail,
                    subtitle: 'SALES & ENQUIRIES',
                    onTap: () => SupportHandlers.launchEmail(contactEmail),
                  ),
                  Divider(color: Colors.white.withOpacity(0.05), height: 1),
                  _ContactRowItem(
                    icon: LucideIcons.phone,
                    title: contactPhone,
                    subtitle: 'DIRECT LINE',
                    onTap: () => SupportHandlers.launchCall(contactPhone),
                  ),

                ],
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }


}

class _ContactRowItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ContactRowItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.white.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: GoogleFonts.montserrat(
                      color: Colors.white38,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
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
}


