import 'dart:io';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/screens/careers/job_detail_screen.dart';
import 'package:m4_mobile/presentation/screens/careers/job_apply_screen.dart';
import 'package:m4_mobile/presentation/widgets/conditional_drawer.dart';

class CareersScreen extends ConsumerStatefulWidget {
  const CareersScreen({super.key});

  @override
  ConsumerState<CareersScreen> createState() => _CareersScreenState();
}

class _CareersScreenState extends ConsumerState<CareersScreen> {
  List<dynamic> _jobs = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  
  @override
  void initState() {
    super.initState();
    _fetchJobs();
  }

  Future<void> _fetchJobs() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.getJobs();
      if (response.data['status'] == true) {
        setState(() {
          _jobs = response.data['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _showToast(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 12)),
        backgroundColor: isError ? Colors.redAccent : Colors.teal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CAREERS', 
                style: GoogleFonts.montserrat(
                  color: isDark ? Colors.white : Colors.black, 
                  fontWeight: FontWeight.bold, 
                  fontSize: 20, 
                  letterSpacing: 1
                )),
            Text('JOIN OUR FAMILY', 
                style: GoogleFonts.montserrat(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.5), 
                  fontWeight: FontWeight.w900, 
                  fontSize: 10, 
                  letterSpacing: 4
                )),
          ],
        ),
        backgroundColor: (isDark ? Colors.black : Colors.white).withOpacity(0.8),
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: isDark ? Colors.white70 : Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: Icon(LucideIcons.moreHorizontal, color: isDark ? Colors.white : Colors.black),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ],
      ),
      drawer: const ConditionalDrawer(),
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.black : Colors.white,
          gradient: isDark 
            ? const RadialGradient(
                center: Alignment.topCenter,
                radius: 2.5,
                colors: [Color(0xFF0F1115), Colors.black],
              )
            : null,
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white24))
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: _buildJobList(),
                ),
        ),
      ),
    );
  }

  Widget _buildJobList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Hero Section (Image 1 Parity)
        ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: Container(
            color: isDark ? Colors.white : Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 30),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'BUILD YOUR FUTURE',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        color: isDark ? Colors.black : Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(LucideIcons.sparkles, color: isDark ? Colors.black : Colors.white, size: 28).animate(onPlay: (controller) => controller.repeat(reverse: true)).scaleXY(end: 1.2, duration: 1.seconds),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'EXPLORE OPPORTUNITIES WITH M4 FAMILY',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    color: isDark ? Colors.black54 : Colors.white54,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn().slideY(begin: 0.1),
        const SizedBox(height: 56),

        // Open Positions Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'OPEN POSITIONS',
            style: GoogleFonts.montserrat(
              color: isDark ? Colors.white38 : Colors.black38,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Jobs List
        if (_jobs.isEmpty)
           Padding(
            padding: const EdgeInsets.symmetric(vertical: 80),
            child: Center(
              child: Text('NO OPEN POSITIONS AT THE MOMENT.', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, letterSpacing: 2, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          )
        else
          ..._jobs.map((job) => _buildJobCard(job)).toList(),
      ],
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => JobDetailScreen(job: job)),
            );
          },
          borderRadius: BorderRadius.circular(40),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 32),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.04),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.06)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black).withOpacity(0.04),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.06)),
                      ),
                      child: Icon(LucideIcons.briefcase, color: isDark ? Colors.white70 : Colors.black54, size: 28),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (job['title'] ?? '').toString().toUpperCase(),
                            style: GoogleFonts.montserrat(
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                                  border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  (job['department'] ?? '').toString().toUpperCase(),
                                  style: GoogleFonts.montserrat(
                                    color: isDark ? Colors.white60 : Colors.black54,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(LucideIcons.mapPin, color: (isDark ? Colors.white : Colors.black).withOpacity(0.5), size: 12),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  (job['location'] ?? 'MUMBAI').toString().toUpperCase(),
                                  style: GoogleFonts.montserrat(
                                    color: isDark ? Colors.white38 : Colors.black38,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black).withOpacity(0.04),
                        shape: BoxShape.circle,
                        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.06)),
                      ),
                      child: Icon(LucideIcons.chevronRight, color: isDark ? Colors.white54 : Colors.black54, size: 20),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1, duration: 400.ms);
  }
}
