import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

class CareersScreen extends ConsumerStatefulWidget {
  const CareersScreen({super.key});

  @override
  ConsumerState<CareersScreen> createState() => _CareersScreenState();
}

class _CareersScreenState extends ConsumerState<CareersScreen> {
  List<dynamic> _jobs = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  Map<String, dynamic>? _selectedJob;
  
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  File? _resumeFile;

  @override
  void initState() {
    super.initState();
    _fetchJobs();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    super.dispose();
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

  Future<void> _submitApplication() async {
    if (_fullNameController.text.trim().isEmpty || _emailController.text.trim().isEmpty) {
      _showToast('Please fill in all required fields', isError: true);
      return;
    }
    
    if (_resumeFile == null) {
      _showToast('Please upload a resume (PDF)', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      
      // Step 1: Upload Resume
      String resumeUrl = '';
      final fileName = _resumeFile!.path.split('/').last;
      
      final uploadResponse = await apiClient.uploadResume(_resumeFile!.path, fileName);
      if (uploadResponse.data['status'] == true) {
        resumeUrl = uploadResponse.data['data']['resumeUrl'];
      } else {
        _showToast(uploadResponse.data['message'] ?? 'Failed to upload resume', isError: true);
        setState(() => _isSubmitting = false);
        return;
      }

      // Step 2: Submit Application with Resume URL
      final response = await apiClient.applyJob({
        'job': _selectedJob!['_id'],
        'fullName': _fullNameController.text.trim(),
        'email': _emailController.text.trim(),
        'resumeUrl': resumeUrl,
      });

      if (response.data['status'] == true) {
        _showToast('Application Submitted Successfully!');
        setState(() {
          _selectedJob = null;
          _fullNameController.clear();
          _emailController.clear();
          _resumeFile = null;
        });
      } else {
        _showToast(response.data['message'] ?? 'Failed to submit application', isError: true);
      }
    } catch (_) {
      _showToast('An error occurred during submission', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CAREERS', 
                style: GoogleFonts.montserrat(
                  color: Colors.white, 
                  fontWeight: FontWeight.bold, 
                  fontSize: 20, 
                  letterSpacing: 1
                )),
            Text('JOIN OUR FAMILY', 
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
          onPressed: () {
            if (_selectedJob != null) {
              setState(() => _selectedJob = null);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.black,
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 2.5,
            colors: [Color(0xFF0F1115), Colors.black],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white24))
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: _selectedJob == null ? _buildJobList() : _buildApplicationForm(),
                ),
        ),
      ),
    );
  }

  Widget _buildJobList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Hero Section
        ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'BUILD YOUR FUTURE',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(LucideIcons.sparkles, color: Colors.black, size: 24).animate(onPlay: (controller) => controller.repeat(reverse: true)).scaleXY(end: 1.2, duration: 1.seconds),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'EXPLORE OPPORTUNITIES WITH M4 FAMILY',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    color: Colors.black54,
                    fontWeight: FontWeight.w900,
                    fontSize: 9,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn().slideY(begin: 0.1),
        const SizedBox(height: 48),

        // Open Positions Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'OPEN POSITIONS',
            style: GoogleFonts.montserrat(
              color: Colors.white54,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Jobs List
        if (_jobs.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text('No open positions at the moment.', style: TextStyle(color: Colors.white54)),
            ),
          )
        else
          ..._jobs.map((job) => _buildJobCard(job)).toList(),
      ],
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedJob = job),
          borderRadius: BorderRadius.circular(32),
          child: ClipRRect(
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
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: const Icon(LucideIcons.briefcase, color: Colors.white70, size: 24),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (job['title'] ?? '').toString().toUpperCase(),
                            style: GoogleFonts.montserrat(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  (job['department'] ?? '').toString().toUpperCase(),
                                  style: GoogleFonts.montserrat(
                                    color: Colors.white70,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(LucideIcons.mapPin, color: Colors.white.withOpacity(0.5), size: 10),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  (job['location'] ?? '').toString().toUpperCase(),
                                  style: GoogleFonts.montserrat(
                                    color: Colors.white54,
                                    fontSize: 8,
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
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.chevronRight, color: Colors.white54, size: 20),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildApplicationForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Job Meta Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  (_selectedJob!['department'] ?? '').toString().toUpperCase(),
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                (_selectedJob!['title'] ?? '').toString().toUpperCase(),
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _buildMetaBadge(LucideIcons.mapPin, _selectedJob!['location'] ?? ''),
                  const SizedBox(width: 12),
                  _buildMetaBadge(LucideIcons.briefcase, _selectedJob!['type'] ?? ''),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Application Card
        ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'QUICK APPLICATION',
                    style: GoogleFonts.montserrat(
                      color: Colors.white54,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 32),

                  Text(
                    'FULL NAME',
                    style: GoogleFonts.montserrat(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2),
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(controller: _fullNameController, hint: 'John Doe'),
                  const SizedBox(height: 24),

                  Text(
                    'EMAIL',
                    style: GoogleFonts.montserrat(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2),
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(controller: _emailController, hint: 'john@example.com', isEmail: true),
                  const SizedBox(height: 24),

                  Text(
                    'RESUME / CV',
                    style: GoogleFonts.montserrat(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      try {
                        FilePickerResult? result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['pdf'],
                        );

                        if (result != null && result.files.single.path != null) {
                          setState(() {
                            _resumeFile = File(result.files.single.path!);
                          });
                          _showToast('Resume selected successfully');
                        }
                      } catch (e) {
                        _showToast('Error selecting file', isError: true);
                      }
                    },
                    borderRadius: BorderRadius.circular(32),
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: _resumeFile != null ? Colors.white : Colors.white.withOpacity(0.1), 
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _resumeFile != null ? Colors.white : Colors.white.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _resumeFile != null ? LucideIcons.fileCheck : LucideIcons.upload, 
                                color: _resumeFile != null ? Colors.black : Colors.white, 
                                size: 24
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _resumeFile != null ? _resumeFile!.path.split('/').last.toUpperCase() : 'TAP TO UPLOAD PDF',
                              style: GoogleFonts.montserrat(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitApplication,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                        elevation: 10,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : Text(
                              'SUBMIT APPLICATION',
                              style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 3),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn().slideX(begin: 0.1);
  }

  Widget _buildMetaBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 14),
          const SizedBox(width: 8),
          Text(
            text.toUpperCase(),
            style: GoogleFonts.montserrat(
              color: Colors.white70,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hint, bool isEmail = false}) {
    return TextField(
      controller: controller,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.montserrat(color: Colors.white24, fontWeight: FontWeight.bold, fontSize: 13),
        filled: true,
        fillColor: Colors.black.withOpacity(0.3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
      ),
    );
  }
}
