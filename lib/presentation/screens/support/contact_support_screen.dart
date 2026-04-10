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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CONTACT US', 
                style: GoogleFonts.montserrat(
                  color: Theme.of(context).colorScheme.onSurface, 
                  fontWeight: FontWeight.bold, 
                  fontSize: 20, 
                  letterSpacing: 1
                )),
            Text('INSTITUTIONAL SUPPORT', 
                style: GoogleFonts.montserrat(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), 
                  fontWeight: FontWeight.w900, 
                  fontSize: 10, 
                  letterSpacing: 4
                )),
          ],
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.black26))
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildOffices(),
                        const SizedBox(height: 48),
                        _buildMapHeader(),
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

  Widget _buildMapHeader() {
    const mainAddress = '604, 6th Floor, M4 Aura Heights, Maulana Shaukat Ali Road, Grant Road, Mumbai - 400007';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            'GLOBAL HEADQUARTERS',
            style: GoogleFonts.montserrat(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.35),
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.5,
            ),
          ),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () => SupportHandlers.openMap(mainAddress),
          child: Container(
            height: 320,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              image: const DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1524661135-423995f22d0b?auto=format&fit=crop&q=80'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black45, BlendMode.saturation),
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 30, offset: const Offset(0, 15)),
              ],
            ),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black.withOpacity(0.2), Colors.black.withOpacity(0.7)],
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.navigation, color: Colors.white, size: 16),
                        const SizedBox(width: 12),
                        Text(
                          'OPEN MAP',
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ).animate().fadeIn().slideY(begin: 0.1);
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
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.04),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05)),
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
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                        )
                      ],
                    ),
                    child: Icon(LucideIcons.mapPin, color: Theme.of(context).colorScheme.onSurface, size: 20),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title.toUpperCase(),
                          style: GoogleFonts.montserrat(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          address,
                          style: GoogleFonts.montserrat(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54),
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
                        foregroundColor: Theme.of(context).colorScheme.onSurface,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
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
                        foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                        backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
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
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.38),
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
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.04),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05)),
              ),
              child: Column(
                children: [
                  _ContactRowItem(
                    icon: LucideIcons.mail,
                    title: contactEmail,
                    subtitle: 'SALES & ENQUIRIES',
                    onTap: () => SupportHandlers.launchEmail(contactEmail),
                  ),
                  Divider(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05), height: 1),
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
      splashColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05)),
              ),
              child: Icon(icon, color: Theme.of(context).colorScheme.onSurface, size: 20),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.montserrat(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: GoogleFonts.montserrat(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.38),
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


