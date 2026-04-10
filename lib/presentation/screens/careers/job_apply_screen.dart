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
import 'package:m4_mobile/presentation/widgets/sidebar_menu.dart';

class JobApplyScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> job;

  const JobApplyScreen({super.key, required this.job});

  @override
  ConsumerState<JobApplyScreen> createState() => _JobApplyScreenState();
}

class _JobApplyScreenState extends ConsumerState<JobApplyScreen> {
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  File? _resumeFile;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitApplication() async {
    if (_fullNameController.text.trim().isEmpty || 
        _phoneController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty) {
      _showToast('Please fill in all required fields', isError: true);
      return;
    }
    
    if (_resumeFile == null) {
      _showToast('Please upload your resume (PDF)', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      
      // 1. Upload Resume
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

      // 2. Submit Application
      final response = await apiClient.applyJob({
        'jobId': widget.job['_id'],
        'fullName': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'resumeUrl': resumeUrl,
      });

      if (response.data['status'] == true) {
        _showToast('Application Submitted Successfully!');
        if (mounted) {
           Navigator.pop(context); // Close Application form
           Navigator.pop(context); // Close Job Detail
        }
      } else {
        _showToast(response.data['message'] ?? 'Failed to submit application', isError: true);
      }
    } catch (e) {
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
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              (widget.job['title'] ?? '').toString().toUpperCase(),
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              (widget.job['department'] ?? '').toString().toUpperCase(),
              style: GoogleFonts.montserrat(
                color: Colors.white54,
                fontWeight: FontWeight.w900,
                fontSize: 9,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(LucideIcons.moreHorizontal, color: Colors.white70),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ],
      ),
      drawer: const SidebarMenu(),
      body: Container(
        padding: const EdgeInsets.only(top: 120),
        decoration: const BoxDecoration(
          color: Colors.black,
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 2.5,
            colors: [Color(0xFF111319), Colors.black],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // APPLYING FOR Header
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'APPLYING FOR',
                        style: GoogleFonts.montserrat(
                          color: Colors.white38,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      (widget.job['title'] ?? '').toString().toUpperCase(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        letterSpacing: -1,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      (widget.job['location'] ?? 'MUMBAI').toString().toUpperCase(),
                      style: GoogleFonts.montserrat(
                        color: Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // Form Fields
              _buildLabel('FULL NAME'),
              const SizedBox(height: 12),
              _buildTextField(controller: _fullNameController, hint: 'IRFAN KHAN'),
              const SizedBox(height: 32),

              _buildLabel('PHONE NUMBER'),
              const SizedBox(height: 12),
              _buildTextField(controller: _phoneController, hint: '+1 234 567 890', isPhone: true),
              const SizedBox(height: 32),

              _buildLabel('EMAIL ADDRESS'),
              const SizedBox(height: 12),
              _buildTextField(controller: _emailController, hint: 'IRFAN1@GMAIL.COM', isEmail: true),
              const SizedBox(height: 48),

              // PDF Upload Area
              _buildLabel('RESUME / PORTFOLIO (PDF)'),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  FilePickerResult? result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['pdf'],
                  );
                  if (result != null) {
                    setState(() => _resumeFile = File(result.files.single.path!));
                  }
                },
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color: _resumeFile != null ? Colors.white : Colors.white.withOpacity(0.05),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _resumeFile != null ? Colors.white : Colors.white.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _resumeFile != null ? LucideIcons.fileCheck : LucideIcons.rocket,
                          color: _resumeFile != null ? Colors.black : Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _resumeFile != null 
                            ? _resumeFile!.path.split('/').last.toUpperCase()
                            : 'SELECT PDF DOCUMENT',
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
              const SizedBox(height: 64),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitApplication,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.black)
                      : Text(
                          'SUBMIT APPLICATION',
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Text(
        text,
        style: GoogleFonts.montserrat(
          color: Colors.white38,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hint, bool isEmail = false, bool isPhone = false}) {
    return TextField(
      controller: controller,
      keyboardType: isEmail ? TextInputType.emailAddress : isPhone ? TextInputType.phone : TextInputType.text,
      style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.montserrat(color: Colors.white.withOpacity(0.15), fontWeight: FontWeight.bold, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF0F1219),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.white, width: 1.5),
        ),
      ),
    );
  }
}
