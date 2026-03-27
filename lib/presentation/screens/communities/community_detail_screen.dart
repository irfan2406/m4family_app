import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

class CommunityDetailScreen extends ConsumerWidget {
  final dynamic community;
  const CommunityDetailScreen({super.key, required this.community});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apiClient = ref.watch(apiClientProvider);
    final heroImageUrl = apiClient.resolveUrl(community['heroImage'] ?? community['image']);
    final amenities = community['amenities'] as List? ?? [];
    final highlights = community['highlights'] as List? ?? [];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // 🔝 Stage 1: Hero Section
          SliverAppBar(
            expandedHeight: 450,
            pinned: true,
            stretch: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            leading: IconButton(
              icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                   Image.network(
                    heroImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.black.withOpacity(0.1),
                      child: const Center(child: Icon(LucideIcons.image, color: Colors.white24, size: 50)),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.4),
                          Colors.transparent,
                          Colors.black.withOpacity(0.9),
                        ],
                        stops: const [0, 0.5, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 40,
                    left: 25,
                    right: 25,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          community['title']?.toString().toUpperCase() ?? 'COMMUNITY',
                          style: GoogleFonts.montserrat(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -1,
                          ),
                        ).animate().fadeIn().slideY(begin: 0.2),
                        const SizedBox(height: 8),
                        if (community['location'] != null)
                          Row(
                            children: [
                              const Icon(LucideIcons.mapPin, color: Colors.white70, size: 14),
                              const SizedBox(width: 8),
                              Text(
                                community['location'].toString().toUpperCase(),
                                style: GoogleFonts.montserrat(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ).animate().fadeIn(delay: 200.ms),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 🏗️ Stage 2: Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overview
                  _buildSectionTitle(context, 'OVERVIEW'),
                  const SizedBox(height: 15),
                  Text(
                    community['description'] ?? 'No description available for this community.',
                    style: GoogleFonts.montserrat(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.8,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // The Experience (Amenities)
                  if (amenities.isNotEmpty) ...[
                    _buildSectionTitle(context, 'THE EXPERIENCE'),
                    const SizedBox(height: 20),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 15,
                        crossAxisSpacing: 15,
                        childAspectRatio: 2.5,
                      ),
                      itemCount: amenities.length,
                      itemBuilder: (context, index) {
                        final amenity = amenities[index];
                        return _buildAmenityCard(context, amenity);
                      },
                    ),
                    const SizedBox(height: 40),
                  ],

                  // Master Plan Highlights
                  if (highlights.isNotEmpty) ...[
                    _buildSectionTitle(context, 'MASTER PLAN HIGHLIGHTS'),
                    const SizedBox(height: 20),
                    ...highlights.map((h) => _buildHighlightRow(h)).toList(),
                    const SizedBox(height: 40),
                  ],

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () => _showInterestForm(context, ref),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Text(
                        'EXPRESS INTEREST',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInterestForm(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final countryController = TextEditingController(text: 'UNITED ARAB EMIRATES');
    bool isSubmitting = false;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
            border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1)),
          ),
          padding: EdgeInsets.fromLTRB(25, 20, 25, MediaQuery.of(context).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  'EXPRESS INTEREST',
                  style: GoogleFonts.montserrat(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  community['title']?.toString().toUpperCase() ?? '',
                  style: GoogleFonts.montserrat(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 40),
                _buildTextField(context, nameController, 'FULL NAME', LucideIcons.user),
                const SizedBox(height: 16),
                _buildTextField(context, emailController, 'EMAIL ADDRESS', LucideIcons.mail, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 16),
                _buildTextField(context, phoneController, 'PHONE NUMBER', LucideIcons.phone, keyboardType: TextInputType.phone),
                const SizedBox(height: 16),
                _buildTextField(context, countryController, 'COUNTRY OF RESIDENCE', LucideIcons.globe),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 65,
                  child: ElevatedButton(
                    onPressed: isSubmitting ? null : () async {
                      if (nameController.text.isEmpty || phoneController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please fill all required fields')),
                        );
                        return;
                      }

                      setState(() => isSubmitting = true);
                      try {
                        final apiClient = ref.read(apiClientProvider);
                        await apiClient.submitLead({
                          'name': nameController.text,
                          'email': emailController.text,
                          'phone': phoneController.text,
                          'interest': 'Community Interest',
                          'message': 'Country: ${countryController.text}. Inquiry for ${community['title']}',
                          'source': 'Mobile App',
                        });

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Inquiry submitted successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                         if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Submission failed: $e')),
                          );
                        }
                      } finally {
                        if (context.mounted) setState(() => isSubmitting = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.onBackground,
                      foregroundColor: Theme.of(context).colorScheme.background,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      disabledBackgroundColor: Theme.of(context).colorScheme.onBackground.withOpacity(0.24),
                    ),
                    child: isSubmitting
                      ? const CircularProgressIndicator(color: Colors.black)
                      : Text(
                          'SUBMIT REQUEST',
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            fontSize: 14,
                          ),
                        ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(BuildContext context, TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.04),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.montserrat(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.montserrat(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.38), fontSize: 12, fontWeight: FontWeight.w600),
          prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.24), size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.montserrat(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 2,
          color: Colors.white24,
        ),
      ],
    );
  }

  Widget _buildAmenityCard(BuildContext context, dynamic amenity) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(
            _getAmenityIcon(amenity['icon']),
            color: Colors.white70,
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              amenity['label'] ?? '',
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(LucideIcons.check, color: Colors.white38, size: 14),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.montserrat(
                color: Colors.white70,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getAmenityIcon(String? iconName) {
    switch (iconName?.toLowerCase()) {
      case 'parking': return LucideIcons.car;
      case 'park': return LucideIcons.trees;
      case 'plaza': return LucideIcons.layoutGrid;
      case 'commercial': return LucideIcons.building2;
      case 'retail': return LucideIcons.shoppingBag;
      case 'gym': return LucideIcons.dumbbell;
      case 'pool': return LucideIcons.waves;
      default: return LucideIcons.sparkles;
    }
  }
}
