import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show TextInputFormatter;

import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m4_mobile/core/utils/validators.dart';
import 'package:m4_mobile/presentation/providers/project_provider.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/widgets/wheel_date_time_picker.dart';
import 'package:m4_mobile/presentation/widgets/navigation_pill.dart';
import 'package:m4_mobile/presentation/widgets/main_shell.dart';

class ScheduleVisitScreen extends ConsumerStatefulWidget {
  const ScheduleVisitScreen({super.key});

  @override
  ConsumerState<ScheduleVisitScreen> createState() =>
      _ScheduleVisitScreenState();
}

class _ScheduleVisitScreenState extends ConsumerState<ScheduleVisitScreen> {
  final _notesController = TextEditingController();
  // CP parity: the partner's version of this form also captures who is
  // visiting and which of the partner's employees is handling it. Both stay
  // hidden for a customer / investor account, whose web page does not ask.
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _prefilled = false;
  bool _isCp = false;
  List<Map<String, dynamic>> _employees = [];
  String? _employeeId;
  bool _isEmployeeDropdownOpen = false;
  String? _nameError;
  String? _phoneError;

  String? _selectedProjectId;
  DateTime? _scheduledAt;
  bool _isProjectDropdownOpen = false;
  bool _isSubmitting = false;

  /// Reads the signed-in account once. The role decides which version of the
  /// form is drawn, and a logged-in partner does not retype what we know.
  void _prefillFromAccount() {
    if (_prefilled) return;
    final u = ref.read(authProvider).user;
    if (u == null) return;
    _prefilled = true;
    _isCp = u['role']?.toString().toLowerCase() == 'cp';
    if (_isCp) {
      _nameController.text = (u['fullName'] ?? u['username'] ?? '').toString();
      _phoneController.text = (u['phone'] ?? '').toString();
      _fetchEmployees();
    }
  }

  /// GET /api/cp/employees is CP-scoped, so it is only called for a CP
  /// account. A failure leaves the field empty rather than blocking booking.
  Future<void> _fetchEmployees() async {
    try {
      final res = await ref.read(apiClientProvider).getCpEmployees();
      final body = res.data;
      if (body is Map && body['data'] is List && mounted) {
        setState(() {
          _employees = (body['data'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        });
      }
    } catch (_) {
      // Non-fatal: the field stays empty rather than blocking the booking.
    }
  }

  String get _employeeName {
    for (final e in _employees) {
      if (e['_id']?.toString() == _employeeId) {
        return (e['name'] ?? '').toString();
      }
    }
    return '';
  }

  @override
  void dispose() {
    _notesController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Web parity: a single combined "Schedule" trigger opening the same
  // absolute-date wheel picker used by the CP video call / site visit forms
  // (matches web's IOSDateTimePicker), instead of separate DATE/TIME fields.
  Future<void> _pickScheduleDateTime() async {
    final now = DateTime.now();
    // No past slots. A site visit is never booked for today (the form itself
    // promises a confirmation call within 2 hours), and `temp` already
    // defaults to tomorrow — so floor the wheels at midnight tomorrow. This
    // also drops the part-elapsed current month/day from the month/day lists.
    final minSchedule = DateTime(now.year, now.month, now.day + 1);
    DateTime temp = _scheduledAt ?? now.add(const Duration(days: 1));
    if (temp.isBefore(minSchedule)) temp = now.add(const Duration(days: 1));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final result = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141B3A) : const Color(0xFFF4EFE3),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : const Color(0xFF0C312B))
                      .withOpacity(0.15),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'SELECT DATE & TIME',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: isDark ? Colors.white : const Color(0xFF155A4F),
                ),
              ),
            ),
            const SizedBox(height: 8),
            WheelDateTimePicker(
              initial: temp,
              minDate: minSchedule,
              isDark: isDark,
              onChanged: (dt) => temp = dt,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(sheetCtx),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      side: BorderSide(
                        color: (isDark ? Colors.white : const Color(0xFF0C312B))
                            .withOpacity(0.2),
                      ),
                      foregroundColor: isDark
                          ? Colors.white
                          : const Color(0xFF0C312B),
                    ),
                    child: Text(
                      'CANCEL',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(sheetCtx, temp),
                    style: FilledButton.styleFrom(
                      backgroundColor: isDark
                          ? Colors.white
                          : const Color(0xFF0C312B),
                      foregroundColor: isDark
                          ? Colors.black
                          : const Color(0xFFF4EFE3),
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'CONFIRM',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() => _scheduledAt = result);
    }
  }

  Future<void> _submit() async {
    // The CP form asks for the visitor's name and number, so those are checked
    // with the same rules the app's other forms use, on the field itself.
    if (_isCp) {
      final nameErr = Validators.nameError(
        _nameController.text,
        field: 'full name',
      );
      final phoneErr = Validators.phoneError(_phoneController.text);
      setState(() {
        _nameError = nameErr;
        _phoneError = phoneErr;
      });
      if (nameErr != null || phoneErr != null) return;
    }
    // Customer / investor: only Property + Schedule are required; their client
    // details come from the logged-in account, as on their web page.
    if (_selectedProjectId == null || _scheduledAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFC65B46),
          content: Text('Please fill in all required fields'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final authUser = ref.read(authProvider).user;

      // /api/leads has no employee column, so the handler is also written
      // into the message — that way the assignment reaches the CRM as text
      // even if the id below is dropped by the schema.
      final handler = _employeeName.isNotEmpty
          ? ' Handled by: $_employeeName.'
          : '';
      final String visitDetails =
          "Date: ${DateFormat('yyyy-MM-dd').format(_scheduledAt!)}, Time: ${DateFormat('hh:mm a').format(_scheduledAt!)}.$handler Notes: ${_notesController.text}";

      final response = await apiClient.submitLead({
        // Whatever the partner typed wins; the account is the fallback for the
        // shorter customer / investor form, which has no such fields.
        'name': _nameController.text.trim().isNotEmpty
            ? _nameController.text.trim()
            : (authUser?['fullName']?.toString() ??
                  authUser?['username']?.toString() ??
                  'App User'),
        'phone': _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : (authUser?['phone']?.toString() ?? ''),
        if (_employeeId != null) 'employeeId': _employeeId,
        'interest': 'Site Visit',
        // Only ever send a real ObjectId (CastToObjectId/BSONError otherwise).
        if ((_selectedProjectId?.length ?? 0) == 24)
          'projectId': _selectedProjectId,
        'message': visitDetails,
        // Server-side enum: source = online | cp | walk-in | referral | other.
        'source': 'online',
      });

      if (!mounted) return;

      if (response.data['status'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF163A2C),
            content: Text(
              'Visit scheduled successfully! We will contact you soon.',
            ),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFC65B46),
            content: Text(
              response.data['message'] ?? 'Failed to schedule visit',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFC65B46),
          content: Text('Error: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _prefillFromAccount();
    final projectsAsync = ref.watch(projectsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      bottomNavigationBar: NavigationPill(
        currentIndex: -1,
        onTap: (i) {
          ref.read(navigationProvider.notifier).state = i;
          Navigator.of(context).popUntil((r) => r.isFirst);
        },
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.05),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.1),
                  ),
                ),
                child: Icon(
                  LucideIcons.chevronLeft,
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 16,
                ),
              ),
            ),
          ),
        ),
        title: Column(
          children: [
            Text(
              // The CP web page titles this SITE VISIT / PROTOCOL VERIFICATION.
              _isCp ? 'SITE VISIT' : 'SCHEDULE VISIT',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
                letterSpacing: 0,
              ),
            ),
            Text(
              _isCp ? 'PROTOCOL VERIFICATION' : 'PREMIUM PROTOCOL',
              style: GoogleFonts.inter(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Note — web parity: light tinted card (bg-primary/5) with a
            // soft shadow, a dark rounded icon box, and dark body text.
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.08),
                ),
                boxShadow: Theme.of(context).brightness == Brightness.dark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      LucideIcons.info,
                      color: Theme.of(context).colorScheme.surface,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _isCp
                          ? 'NOTE: OUR MANAGER WILL CONTACT YOU WITHIN 2 HOURS TO CONFIRM YOUR SCHEDULE.'
                          : 'NOTE: OUR RELATIONSHIP MANAGER WILL CONTACT YOU WITHIN 2 HOURS TO CONFIRM YOUR SCHEDULE.',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                        letterSpacing: 0.2,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: -0.1),
            const SizedBox(height: 32),

            // Customer / investor start at Select Property, matching their
            // own web page. CP gets the longer web form.
            if (_isCp) ...[
              _buildLabel('FULL NAME'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _nameController,
                hint: 'Enter Name',
                icon: LucideIcons.user,
                inputFormatters: Validators.nameFormatters,
                errorText: _nameError,
              ),
              const SizedBox(height: 24),
              _buildLabel('PHONE NUMBER'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _phoneController,
                hint: '+91 XXXXX XXXXX',
                icon: LucideIcons.phone,
                keyboardType: TextInputType.phone,
                inputFormatters: Validators.phoneFormatters,
                errorText: _phoneError,
              ),
              const SizedBox(height: 24),
            ],
            _buildLabel(_isCp ? 'SELECT PROJECT' : 'SELECT PROPERTY'),
            const SizedBox(height: 12),
            projectsAsync.when(
              data: (projects) => _buildDropdown(projects),
              loading: () => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (e, s) => Text(
                'Error loading projects',
                style: TextStyle(color: Colors.red[400]),
              ),
            ),
            const SizedBox(height: 24),

            if (_isCp) ...[
              _buildLabel('HANDLED BY (EMPLOYEE)'),
              const SizedBox(height: 12),
              _buildEmployeeDropdown(),
              const SizedBox(height: 24),
            ],

            _buildLabel('SCHEDULE'),
            const SizedBox(height: 12),
            _buildPickerButton(
              text: _scheduledAt == null
                  ? 'SELECT DATE & TIME'
                  : '${DateFormat('dd MMM yyyy').format(_scheduledAt!)}, ${DateFormat('hh:mm a').format(_scheduledAt!)}',
              icon: LucideIcons.calendar,
              onTap: _pickScheduleDateTime,
            ),
            const SizedBox(height: 24),

            _buildLabel('ADDITIONAL NOTES'),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _notesController,
              hint: 'Enter Specific Requirements',
              maxLines: 4,
            ),
            const SizedBox(height: 48),

            _buildSubmitButton(),
            const SizedBox(height: 24),
            // Web parity: fine-print line below the SECURE BOOKING button.
            Center(
              child: Text(
                '* PICK-UP AND DROP FACILITY INCLUDED FOR PREMIUM TIER MEMBERS.',
                textAlign: TextAlign.center,
                style: GoogleFonts.gelasio(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.68),
                  letterSpacing: 2,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.gelasio(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
        letterSpacing: 2,
      ),
    ).animate().fadeIn().slideX(begin: -0.1);
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? errorText,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Web parity: a bright "enabled-looking" card (bg-card + shadow-xl)
    // instead of a near-invisible tinted fill — InputDecoration alone can't
    // draw a drop shadow, so this wraps the field in a shadowed Container.
    final field = Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141B3A) : const Color(0xFFF4EFE3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: errorText != null
              ? const Color(0xFFC65B46)
              : (isDark ? Colors.white : const Color(0xFF0C312B)).withOpacity(
                  0.06,
                ),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        // Type-blocking, as on the app's other forms: letters only in a name,
        // digits only in a number.
        inputFormatters: inputFormatters,
        style: GoogleFonts.inter(
          color: isDark ? Colors.white : const Color(0xFF155A4F),
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          // The global inputDecorationTheme sets filled:true. With every border
          // removed below, InputDecorator paints that fill as a plain square
          // rect on top of the rounded Container, squaring off its corners
          // (which is why only the dropdowns looked rounded). Opt out and let
          // the Container draw the rounded surface.
          filled: false,
          hintText: hint,
          hintStyle: GoogleFonts.inter(
            color: (isDark ? Colors.white : const Color(0xFF0C312B))
                .withOpacity(0.68),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          prefixIcon: icon != null
              ? Icon(
                  icon,
                  color: (isDark ? Colors.white : const Color(0xFF0C312B))
                      .withOpacity(0.6),
                  size: 18,
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 20,
          ),
        ),
      ),
    ).animate().fadeIn(delay: 100.ms);

    if (errorText == null) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        field,
        Padding(
          padding: const EdgeInsets.only(top: 8, left: 4),
          child: Text(
            errorText,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFC65B46),
            ),
          ),
        ),
      ],
    );
  }

  /// HANDLED BY (EMPLOYEE). Same expanding panel as the project select, so the
  /// two read as one form rather than two different controls.
  Widget _buildEmployeeDropdown() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color ink = isDark ? Colors.white : const Color(0xFF0C312B);
    final selectedName = _employeeName;

    return Column(
      children: [
        GestureDetector(
          onTap: _employees.isEmpty
              ? null
              : () => setState(
                  () => _isEmployeeDropdownOpen = !_isEmployeeDropdownOpen,
                ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141B3A) : const Color(0xFFF4EFE3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isEmployeeDropdownOpen
                    ? ink.withOpacity(0.2)
                    : ink.withOpacity(0.06),
              ),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    selectedName.isNotEmpty
                        ? selectedName.toUpperCase()
                        : (_employees.isEmpty
                              ? 'NO EMPLOYEES ADDED'
                              : 'SELECT EMPLOYEE'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: selectedName.isNotEmpty
                          ? ink
                          : ink.withOpacity(0.68),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                Icon(
                  _isEmployeeDropdownOpen
                      ? LucideIcons.chevronUp
                      : LucideIcons.chevronDown,
                  color: ink.withOpacity(0.6),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        if (_isEmployeeDropdownOpen && _employees.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141B3A) : const Color(0xFFF4EFE3),
              borderRadius: BorderRadius.circular(16),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
              border: Border.all(color: ink.withOpacity(0.05)),
            ),
            child: Column(
              children: _employees.map((emp) {
                final isSelected = _employeeId == emp['_id']?.toString();
                return InkWell(
                  onTap: () {
                    setState(() {
                      _employeeId = emp['_id']?.toString();
                      _isEmployeeDropdownOpen = false;
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? ink.withOpacity(0.05)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      (emp['name'] ?? '').toString().toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: isDark && !isSelected ? Colors.white70 : ink,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.05, end: 0),
      ],
    );
  }

  // Web parity: SelectItem renders `{proj.title} - {proj.location.name}`.
  String _projectLabel(dynamic p) {
    final title = (p['title'] ?? '').toString();
    final loc = p['location'];
    final locName = loc is Map ? (loc['name']?.toString() ?? '') : '';
    return (locName.isNotEmpty ? '$title - $locName' : title).toUpperCase();
  }

  Widget _buildDropdown(List<dynamic> projects) {
    final selectedProject = projects.firstWhere(
      (p) => p['_id'] == _selectedProjectId,
      orElse: () => null,
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        GestureDetector(
          onTap: () =>
              setState(() => _isProjectDropdownOpen = !_isProjectDropdownOpen),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141B3A) : const Color(0xFFF4EFE3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isProjectDropdownOpen
                    ? (isDark ? Colors.white : const Color(0xFF0C312B))
                          .withOpacity(0.2)
                    : (isDark ? Colors.white : const Color(0xFF0C312B))
                          .withOpacity(0.06),
              ),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Flexed: a long project name, or a larger system font, used
                // to push the chevron off the right edge.
                Expanded(
                  child: Text(
                    selectedProject != null
                        ? _projectLabel(selectedProject)
                        : (_isCp ? 'CHOOSE PROJECT' : 'CHOOSE PROPERTY'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: selectedProject != null
                          ? (isDark ? Colors.white : const Color(0xFF0C312B))
                          : (isDark ? Colors.white : const Color(0xFF0C312B))
                                .withOpacity(0.68),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                Icon(
                  _isProjectDropdownOpen
                      ? LucideIcons.chevronUp
                      : LucideIcons.chevronDown,
                  color: (isDark ? Colors.white : const Color(0xFF0C312B))
                      .withOpacity(0.6),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        if (_isProjectDropdownOpen)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141B3A) : const Color(0xFFF4EFE3),
              borderRadius: BorderRadius.circular(16),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
              border: Border.all(
                color: (isDark ? Colors.white : const Color(0xFF0C312B))
                    .withOpacity(0.05),
              ),
            ),
            child: Column(
              children: projects.map((project) {
                final isSelected = _selectedProjectId == project['_id'];
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedProjectId = project['_id'];
                      _isProjectDropdownOpen = false;
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark ? Colors.white : const Color(0xFF0C312B))
                                .withOpacity(0.05)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _projectLabel(project),
                      style: GoogleFonts.inter(
                        color: isSelected
                            ? (isDark ? Colors.white : const Color(0xFF0C312B))
                            : (isDark
                                  ? Colors.white70
                                  : const Color(0xFF0C312B)),
                        fontSize: 11,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.05, end: 0),
      ],
    );
  }

  Widget _buildPickerButton({
    required String text,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPlaceholder = text.contains('SELECT');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141B3A) : const Color(0xFFF4EFE3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: (isDark ? Colors.white : const Color(0xFF0C312B))
                .withOpacity(0.06),
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: (isDark ? Colors.white : const Color(0xFF0C312B))
                  .withOpacity(0.6),
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.inter(
                  color: isPlaceholder
                      ? (isDark ? Colors.white : const Color(0xFF0C312B))
                            .withOpacity(0.68)
                      : (isDark ? Colors.white : const Color(0xFF0C312B)),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              color: (isDark ? Colors.white : const Color(0xFF0C312B))
                  .withOpacity(0.45),
              size: 16,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildSubmitButton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? Colors.white : const Color(0xFF0C312B),
          foregroundColor: isDark ? Colors.black : const Color(0xFFF4EFE3),
          disabledBackgroundColor:
              (isDark ? Colors.white : const Color(0xFF0C312B)).withOpacity(
                0.7,
              ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isSubmitting
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      'SECURE BOOKING',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.gelasio(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    LucideIcons.send,
                    color: isDark
                        ? const Color(0xFF0C312B)
                        : const Color(0xFFF4EFE3),
                    size: 16,
                  ),
                ],
              ),
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2);
  }
}
