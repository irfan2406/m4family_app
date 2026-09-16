import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:m4_mobile/core/utils/api_error.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/widgets/portal_bottom_nav.dart';

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
  bool _isCategoryOpen = false;
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
      final api = ref.read(apiClientProvider);

      // Files go to /api/upload FIRST and the ticket carries their URLs.
      //
      // Posting them inline made the request multipart, and POST /api/tickets
      // has no multipart parser — the server read an empty body and answered
      // "Cannot destructure property 'subject' of 'req.body' as it is
      // undefined", so attaching anything made the ticket impossible to
      // raise. This is the same two-step the résumé and avatar uploads use.
      final uploaded = <String>[];
      for (final path in _attachments) {
        final res = await api.uploadFile(path);
        final body = res.data;
        final inner = body is Map ? body['data'] : null;
        final url = inner is Map ? inner['fileUrl']?.toString() : null;
        if (url == null || url.isEmpty) {
          final name = path.split(Platform.pathSeparator).last.split('/').last;
          throw Exception('Could not upload $name.');
        }
        uploaded.add(url);
      }

      final res = await api.createTicket({
        'subject': subject,
        'category': _category,
        'message': message,
        // The other ticket form (support_provider.createTicket) posts a
        // priority with the note "Default priority as seen in web", and the
        // ticket model carries the field too — this form was the only path
        // leaving it out of the body.
        'priority': 'Medium',
        if (uploaded.isNotEmpty) 'attachments': uploaded,
      });
      if (!mounted) return;
      final ok = res.data is Map && (res.data['status'] == true);
      // On a refusal say WHY. A 200 that is not `status: true` carries the
      // server's own reason; showing a bare "Failed to raise ticket" left the
      // user with nothing to act on.
      final serverMessage = res.data is Map
          ? res.data['message']?.toString()
          : null;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            backgroundColor: ok
                ? const Color(0xFF163A2C)
                : const Color(0xFFC65B46),
            content: Text(
              ok
                  ? 'Ticket raised successfully!'
                  : (serverMessage?.isNotEmpty ?? false)
                  ? serverMessage!
                  : 'Failed to raise ticket',
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(milliseconds: 2600),
          ),
        );
      if (ok) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      // Was `catch (_)` with a fixed string, so every cause — an expired
      // session (the API answers 401 "Authentication required"), a validation
      // refusal, no connection — looked identical and none of them could be
      // acted on. friendlyApiError turns each into a sentence, preferring
      // whatever the server said.
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFC65B46),
            content: Text(
              friendlyApiError(e, fallback: 'Failed to raise ticket'),
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(milliseconds: 2600),
          ),
        );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = isDark ? Colors.white : const Color(0xFF0C312B);
    // The info box follows the app green. It was a one-off gold that matched
    // nothing else on the form.
    const accent = M4Theme.forestGreen;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF141B3A)
          : const Color(0xFFF4EFE3),
      extendBody: true,
      // Web parity: persistent bottom nav (this screen is pushed over the shell,
      // so a tab tap returns to the shell and selects that tab).
      // The portal's own nav: this used to be the customer pill whatever
      // portal opened the screen.
      bottomNavigationBar: const PortalBottomNav(),
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
                // 120 of trailing room so RAISE TICKET comes to rest ABOVE the
                // floating nav pill. The body is drawn behind that pill
                // (extendBody: true) and the pill takes ~90 (M4Nav.height 65 +
                // bottomInset 14 + the system inset), so the old 40 left the
                // button half-hidden under it. Matches the other pushed
                // support screens.
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info box
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: accent.withOpacity(0.12)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              LucideIcons.info,
                              color: accent,
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
                                color: accent.withOpacity(0.75),
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
                          'Enter Subject',
                          onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    _label('CATEGORY', onSurface),
                    const SizedBox(height: 10),
                    // The list opens BELOW the field.
                    //
                    // This was a Material DropdownButton, whose menu is an
                    // overlay positioned so the SELECTED item lands on the
                    // button — so once a category further down the list was
                    // chosen, reopening pushed the menu upwards and it covered
                    // the subject field and the header. Anchoring the panel
                    // under the field keeps it where the user is looking,
                    // whatever is selected. Same construction as the CATEGORY
                    // control on the other ticket form.
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => setState(
                            () => _isCategoryOpen = !_isCategoryOpen,
                          ),
                          child: _fieldBox(
                            isDark: isDark,
                            onSurface: onSurface,
                            child: SizedBox(
                              height: 48,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _category == null
                                          ? 'SELECT CATEGORY'
                                          : _categories[_category]!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: _category == null
                                            ? onSurface.withOpacity(0.68)
                                            : onSurface,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    _isCategoryOpen
                                        ? LucideIcons.chevronUp
                                        : LucideIcons.chevronDown,
                                    color: onSurface.withOpacity(0.4),
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (_isCategoryOpen) ...[
                          const SizedBox(height: 8),
                          Material(
                            color: Colors.transparent,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                // The panel sits on the page's own cream, not
                                // a plain white that stood out against it.
                                color: isDark
                                    ? const Color(0xFF141B3A)
                                    : const Color(0xFFF4EFE3),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: onSurface.withOpacity(0.08),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(
                                      isDark ? 0.5 : 0.1,
                                    ),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: _categories.entries.map((e) {
                                  return InkWell(
                                    borderRadius: BorderRadius.circular(10),
                                    onTap: () => setState(() {
                                      _category = e.key;
                                      _isCategoryOpen = false;
                                    }),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 14,
                                      ),
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
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ],
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
                          'Enter Issue Description',
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
                          foregroundColor: isDark
                              ? Colors.black
                              : const Color(0xFFF4EFE3),
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
                                  color: isDark
                                      ? Colors.black
                                      : const Color(0xFFF4EFE3),
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
          fontSize: 11,
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
