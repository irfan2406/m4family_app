import 'dart:io';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:m4_mobile/core/utils/validators.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/widgets/side_menu_button.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/widgets/conditional_drawer.dart';

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
  void initState() {
    super.initState();
    // Pre-populate if user is logged in
    final authState = ref.read(authProvider);
    if (authState.user != null) {
      final user = authState.user!;
      _fullNameController.text =
          user['fullName'] ??
          '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();
      _emailController.text = user['email'] ?? '';
      _phoneController.text = user['phone'] ?? '';
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitApplication() async {
    final validationError =
        Validators.nameError(_fullNameController.text, field: 'full name') ??
        Validators.emailError(_emailController.text) ??
        Validators.phoneError(_phoneController.text);
    if (validationError != null) {
      _showToast(validationError, isError: true);
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

      final uploadResponse = await apiClient.uploadResume(
        _resumeFile!.path,
        fileName,
      );
      if (uploadResponse.data['status'] == true) {
        resumeUrl = uploadResponse.data['data']['resumeUrl'];
      } else {
        _showToast(
          uploadResponse.data['message'] ?? 'Failed to upload resume',
          isError: true,
        );
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
        _showToast(
          response.data['message'] ?? 'Failed to submit application',
          isError: true,
        );
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
        content: Text(
          message,
          style: GoogleFonts.ebGaramond(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF163A2C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        centerTitle: true,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              (widget.job['title'] ?? '').toString().toUpperCase(),
              style: GoogleFonts.ebGaramond(
                color: isDark ? Colors.white : Color(0xFF163A2C),
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              (widget.job['department'] ?? '').toString().toUpperCase(),
              style: GoogleFonts.ebGaramond(
                color: (isDark ? Colors.white : Color(0xFF163A2C)).withOpacity(0.68),
                fontWeight: FontWeight.w400,
                fontSize: 8,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        backgroundColor: (isDark ? Colors.black : Theme.of(context).scaffoldBackgroundColor).withOpacity(
          0.8,
        ),
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
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Color(0xFF163A2C)).withOpacity(
                    0.05,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (isDark ? Colors.white : Color(0xFF163A2C)).withOpacity(
                      0.08,
                    ),
                  ),
                ),
                child: Icon(
                  LucideIcons.arrowLeft,
                  color: isDark ? Colors.white : Color(0xFF163A2C),
                  size: 16,
                ),
              ),
            ),
          ),
        ),
        actions: [
          Builder(
            builder: (context) => Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: const SideMenuButton(),
              ),
            ),
          ),
        ],
      ),
      drawer: const ConditionalDrawer(),
      body: Container(
        padding: const EdgeInsets.only(top: 120),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          gradient: isDark
              ? const RadialGradient(
                  center: Alignment.topCenter,
                  radius: 2.5,
                  colors: [Color(0xFF141B3A), Colors.black],
                )
              : null,
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'APPLYING FOR',
                        style: GoogleFonts.ebGaramond(
                          color: (isDark ? Colors.white : Color(0xFF163A2C))
                              .withOpacity(0.6),
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      (widget.job['title'] ?? '').toString().toUpperCase(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.gelasio(
                        color: isDark ? Colors.white : Color(0xFF163A2C),
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        letterSpacing: -1,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      (widget.job['location'] ?? 'MUMBAI')
                          .toString()
                          .toUpperCase(),
                      style: GoogleFonts.gelasio(
                        // Web parity: location shown in the M4 slate-blue accent.
                        color: isDark
                            ? Colors.white.withOpacity(0.7)
                            : const Color(0xFF141B3A),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // Form Fields
              _buildLabel('FULL NAME', isDark),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _fullNameController,
                hint: 'JOHN DOE',
              ),
              const SizedBox(height: 32),

              _buildLabel('PHONE NUMBER', isDark),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _phoneController,
                hint: '+1 234 567 890',
                isPhone: true,
              ),
              const SizedBox(height: 32),

              _buildLabel('EMAIL ADDRESS', isDark),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _emailController,
                hint: 'JOHN.DOE@M4FAMILY.COM',
                isEmail: true,
              ),
              const SizedBox(height: 48),

              // PDF Upload Area
              _buildLabel('RESUME / PORTFOLIO (PDF)', isDark),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  FilePickerResult? result = await FilePicker.platform
                      .pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['pdf'],
                      );
                  if (result != null) {
                    setState(
                      () => _resumeFile = File(result.files.single.path!),
                    );
                  }
                },
                child: CustomPaint(
                  // Web parity: dashed rounded border drawn ON TOP of the fill
                  // (foregroundPainter) so the full stroke is visible.
                  foregroundPainter: _DashedRRectPainter(
                    color: _resumeFile != null
                        ? (isDark ? Colors.white : Color(0xFF163A2C))
                        : (isDark ? Colors.white : Color(0xFF163A2C)).withOpacity(
                            0.28,
                          ),
                    radius: 40,
                  ),
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.03)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: isDark
                          ? null
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: _resumeFile != null
                                ? Colors.black
                                : (isDark ? Colors.white : Color(0xFF163A2C)),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Icon(
                            _resumeFile != null
                                ? LucideIcons.fileCheck
                                : LucideIcons.rocket,
                            color: _resumeFile != null
                                ? Colors.white
                                : (isDark ? Colors.black : Colors.white),
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            _resumeFile != null
                                ? _resumeFile!.path
                                      .split('/')
                                      .last
                                      .toUpperCase()
                                : 'SELECT PDF DOCUMENT',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.gelasio(
                              color: isDark ? Colors.white : Color(0xFF163A2C),
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
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
                    backgroundColor: isDark ? Colors.white : Color(0xFF163A2C),
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? CircularProgressIndicator(
                          color: Theme.of(context).scaffoldBackgroundColor,
                        )
                      : Text(
                          'SUBMIT APPLICATION',
                          style: GoogleFonts.gelasio(
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

  Widget _buildLabel(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Text(
        text,
        style: GoogleFonts.ebGaramond(
          color: (isDark ? Colors.white : Color(0xFF163A2C)).withOpacity(0.6),
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool isEmail = false,
    bool isPhone = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Web parity: white "card" field with a soft shadow and light border.
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: isEmail
            ? TextInputType.emailAddress
            : isPhone
            ? TextInputType.phone
            : TextInputType.name,
        inputFormatters: isEmail
            ? Validators.emailFormatters
            : isPhone
            ? Validators.phoneFormatters
            : Validators.nameFormatters,
        style: GoogleFonts.ebGaramond(
          color: isDark ? Colors.white : Color(0xFF163A2C),
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.ebGaramond(
            color: (isDark ? Colors.white : Color(0xFF163A2C)).withOpacity(0.72),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          filled: true,
          fillColor: isDark ? const Color(0xFF141B3A) : Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: (isDark ? Colors.white : Color(0xFF163A2C)).withOpacity(0.06),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFFC5A35B), width: 1.5),
          ),
        ),
      ),
    );
  }
}

// Web parity: dashed rounded-rectangle border for the résumé upload zone.
class _DashedRRectPainter extends CustomPainter {
  final Color color;
  final double radius;

  _DashedRRectPainter({required this.color, this.radius = 40});

  static const double _dashWidth = 7;
  static const double _dashGap = 5;
  static const double _strokeWidth = 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final source = Path()..addRRect(rrect);
    final dashed = Path();
    for (final metric in source.computeMetrics()) {
      double dist = 0;
      while (dist < metric.length) {
        dashed.addPath(
          metric.extractPath(dist, dist + _dashWidth),
          Offset.zero,
        );
        dist += _dashWidth + _dashGap;
      }
    }
    canvas.drawPath(dashed, paint);
  }

  @override
  bool shouldRepaint(_DashedRRectPainter old) =>
      old.color != color || old.radius != radius;
}
