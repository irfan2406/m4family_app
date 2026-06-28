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
import 'package:m4_mobile/presentation/widgets/guest_main_shell.dart';
import 'package:go_router/go_router.dart';

class CareersScreen extends ConsumerStatefulWidget {
  const CareersScreen({super.key});

  @override
  ConsumerState<CareersScreen> createState() => _CareersScreenState();
}

class _CareersScreenState extends ConsumerState<CareersScreen> {
  List<dynamic> _jobs = [];
  Map<String, dynamic>? _cmsData;
  bool _isLoading = true;
  String _activeCategory = 'ALL';
  final List<String> _categories = ["ALL", "SALES", "HR", "MARKETING", "PROJECT MANAGEMENT", "OPERATIONS"];
  
  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      
      debugPrint("--- START FETCHING CAREERS ---");
      
      // 1. Jobs
      final jRes = await apiClient.getJobs();
      debugPrint("JOBS STATUS CODE: ${jRes.statusCode}");
      debugPrint("JOBS DATA TYPE: ${jRes.data.runtimeType}");
      
      if (jRes.data is Map) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(jRes.data);
        if (data['status'] == true || data['status'] == 'true') {
          _jobs = data['data'] ?? [];
          debugPrint("SUCCESS: FETCHED ${_jobs.length} JOBS");
        } else {
          debugPrint("FAILED: JOBS API RETURNED STATUS FALSE: ${data['message']}");
        }
      }

      // 2. CMS
      final cRes = await apiClient.getCmsPage('careers');
      if (cRes.data is Map) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(cRes.data);
        if (data['status'] == true || data['status'] == 'true') {
          _cmsData = data['data'];
          debugPrint("SUCCESS: FETCHED CMS DATA: ${_cmsData?['title']}");
        }
      }

      debugPrint("--- END FETCHING CAREERS ---");
      
    } catch (e) {
      debugPrint("CAREERS FETCH ERROR: $e");
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        centerTitle: true,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('CAREERS', 
                style: GoogleFonts.montserrat(
                  color: isDark ? Colors.white : Colors.black, 
                  fontWeight: FontWeight.bold, 
                  fontSize: 14, 
                  letterSpacing: 2
                )),
            Text('JOIN OUR ARCHITECTURAL LEGACY', 
                style: GoogleFonts.montserrat(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.5), 
                  fontWeight: FontWeight.w400, 
                  fontSize: 8, 
                  letterSpacing: 2
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
        leadingWidth: 56,
        leading: Center(
          child: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: InkWell(
              onTap: () {
                ref.read(guestNavigationProvider.notifier).state = 0;
                context.go('/home');
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.08)),
                ),
                child: Icon(LucideIcons.arrowLeft, color: isDark ? Colors.white : Colors.black, size: 16),
              ),
            ),
          ),
        ),
        actions: [
          Builder(
            builder: (context) => Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: InkWell(
                  onTap: () => Scaffold.of(context).openDrawer(),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 40,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white : Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(LucideIcons.moreHorizontal, size: 18, color: isDark ? Colors.black : Colors.white),
                  ),
                ),
              ),
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
              ? Center(child: CircularProgressIndicator(color: isDark ? Colors.white24 : Colors.black12))
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHero(),
                      const SizedBox(height: 48),
                      _buildCategoryFilter(),
                      const SizedBox(height: 40),
                      _buildJobList(),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildHero() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = _cmsData?['title'] ?? 'BUILD YOUR\nLEGACY';
    final content = _cmsData?['content'] ?? 'Explore opportunities to join M4 Family. We create spaces that redefine living.';

    // Clean title: Ensure it says "CAREERS AT M4" to match web
    String displayTitle = title.toString().toUpperCase();
    if (!displayTitle.contains('M4')) {
      displayTitle = 'CAREERS AT\nM4';
    }

    // Clean content: Remove the <h1> title if it exists to avoid redundancy
    String displayContent = content.toString();
    if (displayContent.contains('</h1>')) {
      displayContent = displayContent.split('</h1>').last;
    }
    displayContent = displayContent.replaceAll(RegExp(r'<[^>]*>'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          displayTitle,
          style: GoogleFonts.montserrat(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 40,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.5,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          displayContent,
          style: GoogleFonts.inter(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.6),
            fontSize: 16,
            fontWeight: FontWeight.w500,
            height: 1.6,
          ),
        ),
      ],
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildCategoryFilter() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isActive = _activeCategory == cat;
          return GestureDetector(
            onTap: () => setState(() => _activeCategory = cat),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: isActive ? (isDark ? Colors.white : Colors.black) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isActive ? Colors.transparent : (isDark ? Colors.white : Colors.black).withOpacity(0.1)),
              ),
              alignment: Alignment.center,
              child: Text(
                cat,
                style: GoogleFonts.montserrat(
                  color: isActive ? (isDark ? Colors.black : Colors.white) : (isDark ? Colors.white60 : Colors.black54),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildJobList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    debugPrint("TOTAL JOBS IN LIST: ${_jobs.length}");
    debugPrint("ACTIVE CATEGORY: $_activeCategory");

    final filteredJobs = _jobs.where((j) {
      if (_activeCategory == 'ALL') return true;
      final dept = j['department']?.toString().toUpperCase();
      return dept == _activeCategory;
    }).toList();

    debugPrint("FILTERED JOBS COUNT: ${filteredJobs.length}");

    if (filteredJobs.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 32),
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.02),
          borderRadius: BorderRadius.circular(48),
          border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1), style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.briefcase, color: (isDark ? Colors.white : Colors.black).withOpacity(0.1), size: 40),
            ),
            const SizedBox(height: 24),
            Text(
              'NO ACTIVE VACANCIES CURRENTLY AVAILABLE',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(color: (isDark ? Colors.white : Colors.black).withOpacity(0.3), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2),
            ),
          ],
        ),
      );
    }

    return Column(
      children: filteredJobs.map((job) => _buildJobCard(job)).toList(),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => JobDetailScreen(job: job))),
        borderRadius: BorderRadius.circular(32),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.04),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (job['title'] ?? '').toString().toUpperCase(),
                      style: GoogleFonts.montserrat(color: isDark ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          (job['department'] ?? '').toString().toUpperCase(),
                          style: GoogleFonts.montserrat(color: isDark ? Colors.white54 : Colors.black54, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                        ),
                        const SizedBox(width: 12),
                        Icon(LucideIcons.mapPin, color: (isDark ? Colors.white : Colors.black).withOpacity(0.3), size: 12),
                        const SizedBox(width: 4),
                        Text(
                          (job['location'] ?? 'MUMBAI').toString().toUpperCase(),
                          style: GoogleFonts.montserrat(color: (isDark ? Colors.white : Colors.black).withOpacity(0.3), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white : Colors.black,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.chevronRight, 
                  color: isDark ? Colors.black : Colors.white, 
                  size: 16
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCircleAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderCircleAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Icon(icon, color: isDark ? Colors.white : Colors.black, size: 18),
      ),
    );
  }
}
