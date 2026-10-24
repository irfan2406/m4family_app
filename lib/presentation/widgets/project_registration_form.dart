import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/core/utils/validators.dart';
import 'package:m4_mobile/presentation/widgets/wheel_date_time_picker.dart';

/// The data a user entered into the inline registration form, handed to the
/// screen's own submit callback so each portal keeps its existing lead payload.
class RegistrationFormData {
  const RegistrationFormData({
    required this.name,
    required this.phone,
    required this.email,
    required this.configuration,
    required this.visitType, // 'Site Visit' | 'Video Call'
    required this.dateTime,
    required this.notes,
  });

  final String name;
  final String phone;
  final String email;
  final String configuration;
  final String visitType;
  final DateTime dateTime;
  final String notes;
}

/// Shared inline "Register / Book a Visit" form shown directly below the
/// Construction Progress section on every project detail page (customer,
/// investor, guest, CP). It collects the client name, contact number, email,
/// preferred configuration, request type (Site Visit / Video Call), date & time
/// and notes; on success it flips to a confirmation panel that echoes exactly
/// what was entered (so the user never has to re-type it).
///
/// Each screen passes [onSubmit], which maps the data to that portal's existing
/// lead API and returns true on success.
class ProjectRegistrationForm extends StatefulWidget {
  const ProjectRegistrationForm({
    super.key,
    required this.onSubmit,
    this.configurations = const ['1 BHK', '2 BHK', '3 BHK', '4 BHK', 'PENTHOUSE'],
    this.accent,
  });

  /// Submits the lead; returns true on success. The screen builds its own
  /// payload (project id, source, etc.) inside this callback.
  final Future<bool> Function(RegistrationFormData data) onSubmit;

  /// Selectable unit configurations (chips).
  final List<String> configurations;

  /// Optional accent override; defaults to the brand green / white by theme.
  final Color? accent;

  @override
  State<ProjectRegistrationForm> createState() =>
      _ProjectRegistrationFormState();
}

class _ProjectRegistrationFormState extends State<ProjectRegistrationForm> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _notes = TextEditingController();

  late String _config = widget.configurations.isNotEmpty
      ? widget.configurations.first
      : '';
  String _visitType = 'Site Visit';
  DateTime? _dateTime;
  bool _submitting = false;

  // Set once the lead is accepted, so the confirmation can echo it back.
  RegistrationFormData? _submitted;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _notes.dispose();
    super.dispose();
  }

  Color _accent(bool isDark) =>
      widget.accent ?? (isDark ? Colors.white : const Color(0xFF0C312B));

  void _toast(String msg, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: success
            ? const Color(0xFF2E7D32)
            : const Color(0xFFC65B46),
        content: Text(msg),
      ),
    );
  }

  // The app's own date & time sheet (Day | Month | Year | Hour | Minute |
  // AM/PM wheels, CANCEL / CONFIRM) — the same chooser every other booking
  // form opens, instead of the stock Android calendar and clock dialogs.
  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    // Tomorrow onwards, like every other booking sheet in the app; the form's
    // one-year window is kept.
    final minSchedule = DateTime(now.year, now.month, now.day + 1);
    final picked = await showM4DateTimeSheet(
      context,
      initial: _dateTime ?? now.add(const Duration(days: 1)),
      minDate: minSchedule,
      maxDate: now.add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) return;
    setState(() => _dateTime = picked);
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final name = _name.text.trim();
    final phone = _phone.text.trim();
    final email = _email.text.trim();

    final err =
        Validators.nameError(name, field: 'name') ??
        Validators.phoneError(phone) ??
        (email.isEmpty ? null : Validators.emailError(email));
    if (err != null) {
      _toast(err);
      return;
    }
    if (_config.isEmpty) {
      _toast('Please choose a configuration');
      return;
    }
    if (_dateTime == null) {
      _toast('Please select a date & time');
      return;
    }

    final data = RegistrationFormData(
      name: name,
      phone: phone,
      email: email,
      configuration: _config,
      visitType: _visitType,
      dateTime: _dateTime!,
      notes: _notes.text.trim(),
    );

    setState(() => _submitting = true);
    bool ok = false;
    try {
      ok = await widget.onSubmit(data);
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;
    setState(() {
      _submitting = false;
      if (ok) _submitted = data;
    });
    if (!ok) _toast('Could not submit. Please try again.');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _accent(isDark);
    if (_submitted != null) {
      return _confirmation(isDark, accent, _submitted!);
    }
    return _form(isDark, accent);
  }

  // ─── Form ──────────────────────────────────────────────────────────────────

  Widget _form(bool isDark, Color accent) {
    final muted = accent.withValues(alpha: 0.7);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : const Color(0xFFF4EFE3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'REGISTER YOUR INTEREST',
            style: GoogleFonts.gelasio(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: accent,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Book a site visit or a video call — we\'ll confirm your slot.',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: muted,
            ),
          ),
          const SizedBox(height: 18),
          _field(_name, 'FULL NAME *', LucideIcons.user, isDark, accent),
          const SizedBox(height: 12),
          _field(
            _phone,
            'MOBILE NUMBER *',
            LucideIcons.phone,
            isDark,
            accent,
            keyboard: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          _field(
            _email,
            'EMAIL (OPTIONAL)',
            LucideIcons.mail,
            isDark,
            accent,
            keyboard: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _label('PREFERRED CONFIGURATION *', muted),
          const SizedBox(height: 10),
          _configDropdown(isDark, accent),
          const SizedBox(height: 16),
          _label('REQUEST TYPE *', muted),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _chip(
                  'Site Visit',
                  _visitType == 'Site Visit',
                  () => setState(() => _visitType = 'Site Visit'),
                  isDark,
                  accent,
                  icon: LucideIcons.mapPin,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _chip(
                  'Video Call',
                  _visitType == 'Video Call',
                  () => setState(() => _visitType = 'Video Call'),
                  isDark,
                  accent,
                  icon: LucideIcons.video,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _label('DATE & TIME *', muted),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _pickDateTime,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accent.withValues(alpha: 0.18)),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.calendar, size: 16, color: muted),
                  const SizedBox(width: 10),
                  Text(
                    _dateTime == null
                        ? 'Select date & time'
                        : DateFormat('EEE, MMM d · h:mm a').format(_dateTime!),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _dateTime == null ? muted : accent,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _field(
            _notes,
            'ADDITIONAL NOTES (OPTIONAL)',
            LucideIcons.messageSquare,
            isDark,
            accent,
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: _submitting ? null : _submit,
              child: Container(
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: _submitting
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDark ? const Color(0xFF0C312B) : Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        'SUBMIT REQUEST',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: isDark ? const Color(0xFF0C312B) : Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Confirmation (echoes what was entered) ──────────────────────────────────

  Widget _confirmation(bool isDark, Color accent, RegistrationFormData d) {
    final muted = accent.withValues(alpha: 0.7);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : const Color(0xFFF4EFE3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Color(0xFF2E7D32),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.check,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.visitType == 'Video Call'
                          ? 'VIDEO CALL REQUESTED'
                          : 'SITE VISIT REQUESTED',
                      style: GoogleFonts.gelasio(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: accent,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      'We\'ll call you to confirm your slot.',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _summaryRow('Name', d.name, accent, muted),
          _summaryRow('Mobile', d.phone, accent, muted),
          if (d.email.isNotEmpty) _summaryRow('Email', d.email, accent, muted),
          _summaryRow('Configuration', d.configuration, accent, muted),
          _summaryRow('Type', d.visitType, accent, muted),
          _summaryRow(
            'When',
            DateFormat('EEE, MMM d · h:mm a').format(d.dateTime),
            accent,
            muted,
          ),
          if (d.notes.isNotEmpty) _summaryRow('Notes', d.notes, accent, muted),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: () => setState(() => _submitted = null),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.plus, size: 14, color: muted),
                const SizedBox(width: 6),
                Text(
                  'SUBMIT ANOTHER REQUEST',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String k, String v, Color accent, Color muted) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: Text(
              k.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: muted,
                letterSpacing: 1,
              ),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Small pieces ────────────────────────────────────────────────────────────

  Widget _label(String text, Color muted) => Text(
    text,
    style: GoogleFonts.inter(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: muted,
      letterSpacing: 1,
    ),
  );

  Widget _field(
    TextEditingController c,
    String hint,
    IconData icon,
    bool isDark,
    Color accent, {
    TextInputType? keyboard,
    int maxLines = 1,
  }) {
    return TextField(
      controller: c,
      keyboardType: keyboard,
      maxLines: maxLines,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: accent,
      ),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, size: 16, color: accent.withValues(alpha: 0.6)),
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: accent.withValues(alpha: 0.5),
          letterSpacing: 0.5,
        ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.white.withValues(alpha: 0.6),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent.withValues(alpha: 0.18)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent.withValues(alpha: 0.18)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent.withValues(alpha: 0.5)),
        ),
      ),
    );
  }

  /// PREFERRED CONFIGURATION as a dropdown: one field (styled like the date
  /// field) showing the chosen configuration, opening a menu of all of them.
  Widget _configDropdown(bool isDark, Color accent) {
    final muted = accent.withValues(alpha: 0.7);
    return Builder(
      builder: (fieldContext) => GestureDetector(
        onTap: () => _openConfigMenu(fieldContext, isDark, accent),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accent.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.home, size: 16, color: muted),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _config.isEmpty ? 'Select configuration' : _config,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _config.isEmpty ? muted : accent,
                  ),
                ),
              ),
              Icon(LucideIcons.chevronDown, size: 18, color: muted),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openConfigMenu(
    BuildContext fieldContext,
    bool isDark,
    Color accent,
  ) async {
    final box = fieldContext.findRenderObject() as RenderBox?;
    final overlay =
        Navigator.of(context).overlay?.context.findRenderObject() as RenderBox?;
    if (box == null || overlay == null) return;
    // Opens just below the field, exactly as wide as it.
    final topLeft = box.localToGlobal(
      Offset(0, box.size.height + 6),
      ancestor: overlay,
    );
    final position = RelativeRect.fromRect(
      Rect.fromLTWH(topLeft.dx, topLeft.dy, box.size.width, 0),
      Offset.zero & overlay.size,
    );
    final picked = await showMenu<String>(
      context: context,
      position: position,
      color: isDark ? const Color(0xFF141B3A) : const Color(0xFFF4EFE3),
      surfaceTintColor: Colors.transparent,
      elevation: 12,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      constraints: BoxConstraints(
        minWidth: box.size.width,
        maxWidth: box.size.width,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: accent.withValues(alpha: 0.12)),
      ),
      menuPadding: const EdgeInsets.symmetric(vertical: 6),
      items: [
        for (final c in widget.configurations)
          PopupMenuItem<String>(
            value: c,
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: c == _config
                    ? accent.withValues(alpha: 0.08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      c.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: c == _config
                            ? FontWeight.w700
                            : FontWeight.w500,
                        letterSpacing: 0.6,
                        color: accent.withValues(alpha: c == _config ? 1 : 0.8),
                      ),
                    ),
                  ),
                  if (c == _config)
                    Icon(LucideIcons.check, size: 16, color: accent),
                ],
              ),
            ),
          ),
      ],
    );
    if (picked != null && mounted) setState(() => _config = picked);
  }

  Widget _chip(
    String label,
    bool active,
    VoidCallback onTap,
    bool isDark,
    Color accent, {
    IconData? icon,
  }) {
    final fg = active ? (isDark ? const Color(0xFF0C312B) : Colors.white) : accent;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? accent : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accent.withValues(alpha: active ? 1 : 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: fg),
              const SizedBox(width: 6),
            ],
            // Shrinks a little on a narrow phone instead of overflowing
            // ("VIDEO CALL" ran 3.5px past its half-width button).
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: fg,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
