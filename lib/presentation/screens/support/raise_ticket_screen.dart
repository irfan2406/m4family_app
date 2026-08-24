import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/widgets/navigation_pill.dart';
import 'package:m4_mobile/presentation/widgets/main_shell.dart';

/// Mirrors web `app/(user)/support/new-ticket` — opened from the project
/// detail's chat/contact action (subject prefilled with "INQUIRY: <project>").
class RaiseTicketScreen extends ConsumerStatefulWidget {
  final String initialSubject;
  const RaiseTicketScreen({super.key, this.initialSubject = ''});

  @override
  ConsumerState<RaiseTicketScreen> createState() => _RaiseTicketScreenState();
}

class _RaiseTicketScreenState extends ConsumerState<RaiseTicketScreen> {
  late final TextEditingController _subjectController;
  final TextEditingController _messageController = TextEditingController();
  String? _category;
  bool _submitting = false;
  final List<String> _attachments = [];

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
      if (result == null) return;
      setState(() {
        for (final f in result.files) {
          if (f.path != null && !_attachments.contains(f.path)) {
            _attachments.add(f.path!);
          }
        }
      });
    } catch (_) {
      // Picker unavailable/cancelled — ignore.
    }
  }

  // Web parity: value -> display label.
  static const _categories = <String, String>{
    'Billing': 'PAYMENT & BILLING',
    'Project': 'PROJECT / POSSESSION',
    'Technical': 'LEGAL & TECHNICAL',
    'Other': 'GENERAL QUERY',
  };

  @override
  void initState() {
    super.initState();
    _subjectController = TextEditingController(text: widget.initialSubject);
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final subject = _subjectController.text.trim();
    final message = _messageController.text.trim();
    if (subject.isEmpty || message.isEmpty || _category == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFFC65B46),
            content: Text('Please fill in subject, category and message'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(milliseconds: 1800),
          ),
        );
      return;
    }
    setState(() => _submitting = true);
    try {
      final res = await ref.read(apiClientProvider).createTicket({
        'subject': subject,
        'category': _category,
        'message': message,
        if (_attachments.isNotEmpty) 'attachments': _attachments,
      });
      if (!mounted) return;
      final ok = res.data is Map && (res.data['status'] == true);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF163A2C),
            content: Text(
              ok ? 'Ticket raised successfully!' : 'Failed to raise ticket',
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(milliseconds: 1800),
          ),
        );
      if (ok) Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFFC65B46),
            content: Text('Failed to raise ticket'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(milliseconds: 1800),
          ),
        );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = isDark ? Colors.white : Color(0xFF0C312B);
    const amber = Color(0xFFC5A35B);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF141B3A) : const Color(0xFFF4EFE3),
      extendBody: true,
      // Web parity: persistent bottom nav (this screen is pushed over the shell,
      // so a tab tap returns to the shell and selects that tab).
      bottomNavigationBar: NavigationPill(
        currentIndex: -1,
        onTap: (i) {
          ref.read(navigationProvider.notifier).state = i;
          Navigator.of(context).popUntil((r) => r.isFirst);
        },
      ),
      body: SafeArea(
        // Edge-to-edge: content runs under the gesture bar so scrolling fills
        // the screen. Trailing padding keeps the last item reachable.
        bottom: false,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : const Color(0xFFF4EFE3),
                        border: Border.all(color: onSurface.withOpacity(0.1)),
                      ),
                      child: Icon(
                        LucideIcons.chevronLeft,
                        color: onSurface,
                        size: 20,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'RAISE TICKET',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        color: onSurface,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Amber info box
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: amber.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: amber.withOpacity(0.12)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: amber.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              LucideIcons.info,
                              color: amber,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'MOST TICKETS ARE RESOLVED WITHIN 4-6 WORKING HOURS. PLEASE PROVIDE DETAIL.',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                color: amber.withOpacity(0.75),
                                letterSpacing: 1,
                                height: 1.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    _label('SUBJECT', onSurface),
                    const SizedBox(height: 10),
                    _fieldBox(
                      isDark: isDark,
                      onSurface: onSurface,
                      child: TextField(
                        controller: _subjectController,
                        textCapitalization: TextCapitalization.characters,
                        cursorColor: onSurface,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: onSurface,
                        ),
                        decoration: _inputDecoration(
                          'E.g. Payment receipt',
                          onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    _label('CATEGORY', onSurface),
                    const SizedBox(height: 10),
                    _fieldBox(
                      isDark: isDark,
                      onSurface: onSurface,
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _category,
                          isExpanded: true,
                          hint: Text(
                            'SELECT CATEGORY',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: onSurface.withOpacity(0.68),
                              letterSpacing: 1,
                            ),
                          ),
                          icon: Icon(
                            LucideIcons.chevronDown,
                            color: onSurface.withOpacity(0.4),
                            size: 18,
                          ),
                          dropdownColor: isDark
                              ? const Color(0xFF141B3A)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          items: _categories.entries
                              .map(
                                (e) => DropdownMenuItem<String>(
                                  value: e.key,
                                  child: Text(
                                    e.value,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: onSurface,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _category = v),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    _label('MESSAGE', onSurface),
                    const SizedBox(height: 10),
                    _fieldBox(
                      isDark: isDark,
                      onSurface: onSurface,
                      child: TextField(
                        controller: _messageController,
                        maxLines: 6,
                        cursorColor: onSurface,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: onSurface,
                        ),
                        decoration: _inputDecoration(
                          'Describe your issue...',
                          onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    _label('ATTACHMENTS', onSurface),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _pickFiles,
                      child: CustomPaint(
                        painter: _DashedRRectPainter(
                          color: onSurface.withOpacity(0.2),
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 28),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.paperclip,
                                color: onSurface.withOpacity(0.5),
                                size: 22,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _attachments.isEmpty
                                    ? 'ADD FILES (PDF, JPG)'
                                    : '${_attachments.length} FILE(S) ATTACHED',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: onSurface.withOpacity(0.68),
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: FilledButton(
                        onPressed: _submitting ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: onSurface,
                          foregroundColor: isDark ? Colors.black : const Color(0xFFF4EFE3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: _submitting
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: isDark ? Colors.black : const Color(0xFFF4EFE3),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'RAISE TICKET',
                                    style: GoogleFonts.gelasio(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(LucideIcons.send, size: 16),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text, Color onSurface) => Padding(
    padding: const EdgeInsets.only(left: 4),
    child: Text(
      text,
      style: GoogleFonts.gelasio(
        fontSize: 9,
        fontWeight: FontWeight.w700,
        color: onSurface.withOpacity(0.68),
        letterSpacing: 1.5,
      ),
    ),
  );

  Widget _fieldBox({
    required bool isDark,
    required Color onSurface,
    required Widget child,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
    decoration: BoxDecoration(
      color: onSurface.withOpacity(0.03),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: onSurface.withOpacity(0.08)),
    ),
    child: child,
  );

  InputDecoration _inputDecoration(String hint, Color onSurface) =>
      InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: onSurface.withOpacity(0.68),
        ),
        filled: false,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      );
}

/// Dashed rounded-rectangle border (web parity: the attachments drop zone).
class _DashedRRectPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double dash;
  final double gap;
  final double strokeWidth;

  _DashedRRectPainter({
    required this.color,
    this.radius = 20,
    this.dash = 6,
    this.gap = 5,
    this.strokeWidth = 1.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var dist = 0.0;
      while (dist < metric.length) {
        final len = math.min(dash, metric.length - dist);
        canvas.drawPath(metric.extractPath(dist, dist + len), paint);
        dist += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter old) => old.color != color;
}
