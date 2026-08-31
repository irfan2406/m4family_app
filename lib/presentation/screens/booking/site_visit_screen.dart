import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/providers/project_provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:m4_mobile/presentation/widgets/navigation_pill.dart';
import 'package:m4_mobile/presentation/widgets/main_shell.dart';
import 'package:m4_mobile/presentation/widgets/wheel_date_time_picker.dart';

class SiteVisitScreen extends ConsumerStatefulWidget {
  final dynamic project;
  final String projectId;

  const SiteVisitScreen({super.key, required this.projectId, this.project});

  @override
  ConsumerState<SiteVisitScreen> createState() => _SiteVisitScreenState();
}

class _SiteVisitScreenState extends ConsumerState<SiteVisitScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _prefilled = false;
  // CP-only: the visit can be handed to one of the partner's employees. The
  // list endpoint is CP-scoped, so it is only fetched for a CP account.
  List<Map<String, dynamic>> _employees = [];
  String? _employeeId;
  bool _isCp = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _visitType = 'Site Visit';
  String? _selectedProjectId;
  bool _isLoading = false;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _selectedProjectId = widget.projectId;
    // Fields intentionally left empty for manual entry to match web protocol
  }

  /// Seeds the visitor fields from the signed-in account, so the form matches
  /// the web layout without making a logged-in user retype what we already know.
  void _prefillFromAccount() {
    if (_prefilled) return;
    final u = ref.read(authProvider).user;
    if (u == null) return;
    _prefilled = true;
    _isCp = u['role']?.toString().toLowerCase() == 'cp';
    if (_isCp) unawaited(_fetchEmployees());
    _nameController.text = (u['fullName'] ?? u['username'] ?? '').toString();
    _phoneController.text = (u['phone'] ?? '').toString();
  }

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
      // Non-fatal: the field simply stays empty rather than blocking booking.
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    final now = DateTime.now();
    // No past slots. A site visit is never booked for today (the form itself
    // promises a confirmation call within 2 hours), and `temp` already
    // defaults to tomorrow — so floor the wheels at midnight tomorrow. This
    // also drops the part-elapsed current month/day from the month/day lists.
    final minSchedule = DateTime(now.year, now.month, now.day + 1);
    DateTime temp = _selectedDate ?? now.add(const Duration(days: 1));
    if (temp.isBefore(minSchedule)) temp = now.add(const Duration(days: 1));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Web parity: absolute Day/Month/Year + time wheel picker (CANCEL/CONFIRM).
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
      setState(() {
        _selectedDate = result;
        _selectedTime = TimeOfDay.fromDateTime(result);
      });
    }
  }

  Future<void> _submitBooking() async {
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFC65B46),
          content: Text('Please select a date and time'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final authUser = ref.read(authProvider).user;

      final res = await apiClient.post('/api/user/site-visit', {
        'project': _selectedProjectId ?? widget.projectId,
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
        'time': _selectedTime!.format(context),
        // Web parity: user details come from the logged-in account.
        'name': _nameController.text.trim().isNotEmpty
            ? _nameController.text.trim()
            : (authUser?['fullName']?.toString() ??
                  authUser?['username']?.toString() ??
                  'App User'),
        'phone': _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : (authUser?['phone']?.toString() ?? ''),
        'email': authUser?['email']?.toString() ?? '',
        if (_employeeId != null) 'employeeId': _employeeId,
        'notes': _notesController.text.trim(),
        'visitType': _visitType,
      });

      if (res.data['status'] == true) {
        setState(() => _isSuccess = true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFC65B46),
            content: Text(res.data['message'] ?? 'Failed to schedule visit'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFC65B46),
          content: Text('Error scheduling visit. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _prefillFromAccount();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isSuccess) {
      return Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF141B3A)
            : const Color(0xFFD4CFBC),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white : const Color(0xFF0C312B),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    LucideIcons.checkCircle2,
                    color: isDark
                        ? const Color(0xFF0C312B)
                        : const Color(0xFFF4EFE3),
                    size: 50,
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  'SUBMITTED',
                  style: GoogleFonts.gelasio(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Your request has been registered. Our team will contact you shortly.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.gelasio(
                    fontSize: 10,
                    color: isDark ? Colors.white38 : const Color(0xFF155A4F),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    height: 1.8,
                  ),
                ),
                const SizedBox(height: 48),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: double.infinity,
                    height: 64,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white : const Color(0xFF0C312B),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (isDark ? Colors.white : const Color(0xFF0C312B))
                                  .withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'BACK TO PROJECT',
                        style: GoogleFonts.gelasio(
                          color: isDark
                              ? const Color(0xFF0C312B)
                              : const Color(0xFFF4EFE3),
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF141B3A)
          : const Color(0xFFD4CFBC),
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
        leading: IconButton(
          icon: Icon(
            LucideIcons.chevronLeft,
            color: isDark ? Colors.white : const Color(0xFF0C312B),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SITE VISIT',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF155A4F),
              ),
            ),
            Text(
              'PROTOCOL VERIFICATION',
              style: GoogleFonts.inter(
                fontSize: 8,
                color: (isDark ? Colors.white : const Color(0xFF0C312B))
                    .withOpacity(0.68),
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                // Web parity: bg-primary/5 + border-primary/10 + shadow-sm —
                // a light tinted card with a soft shadow (not a solid black box).
                color: (isDark ? Colors.white : const Color(0xFF0C312B))
                    .withOpacity(0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: (isDark ? Colors.white : const Color(0xFF0C312B))
                      .withOpacity(0.08),
                ),
                boxShadow: isDark
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
                      color: isDark ? Colors.white : const Color(0xFF0C312B),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      LucideIcons.info,
                      color: isDark
                          ? const Color(0xFF0C312B)
                          : const Color(0xFFF4EFE3),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'NOTE: OUR RELATIONSHIP MANAGER WILL CONTACT YOU WITHIN 2 HOURS TO CONFIRM YOUR SCHEDULE.',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: (isDark ? Colors.white : const Color(0xFF0C312B))
                            .withOpacity(0.7),
                        letterSpacing: 0.5,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // Web parity: the booking form asks for the visitor's name and
            // number. Both are pre-filled from the signed-in account so a
            // logged-in user does not retype them, and stay editable.
            _buildFieldLabel('FULL NAME'),
            _buildTextField(
              _nameController,
              LucideIcons.user,
              'Enter Full Name',
            ),
            const SizedBox(height: 24),
            _buildFieldLabel('PHONE NUMBER'),
            _buildTextField(
              _phoneController,
              LucideIcons.phone,
              'Enter Mobile Number',
            ),
            const SizedBox(height: 24),
            _buildFieldLabel('SELECT PROJECT'),
            Consumer(
              builder: (context, ref, child) {
                final projectsAsync = ref.watch(projectsProvider);
                return projectsAsync.when(
                  data: (projects) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.03)
                            : Colors.black.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.black.withOpacity(0.05),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedProjectId,
                          isExpanded: true,
                          icon: Icon(
                            LucideIcons.chevronDown,
                            color: isDark
                                ? Colors.white24
                                : const Color(0x420C312B),
                            size: 18,
                          ),
                          dropdownColor: isDark
                              ? const Color(0xFF141B3A)
                              : Colors.white,
                          items: projects.map((p) {
                            return DropdownMenuItem<String>(
                              value: p['_id']?.toString(),
                              child: Text(
                                (p['title'] ?? 'PROJECT')
                                    .toString()
                                    .toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF155A4F),
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) =>
                              setState(() => _selectedProjectId = val),
                        ),
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CupertinoActivityIndicator()),
                  error: (e, s) => Text(
                    'Error loading projects',
                    style: GoogleFonts.inter(fontSize: 10, color: Colors.red),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
            if (_isCp) ...[
              _buildFieldLabel('HANDLED BY (EMPLOYEE)'),
              _buildEmployeeField(),
              const SizedBox(height: 24),
            ],
            _buildFieldLabel('SCHEDULE'),
            GestureDetector(
              onTap: _selectDateTime,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.03)
                      : Colors.black.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.05),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.calendar,
                      color: isDark ? Colors.white38 : const Color(0xFF155A4F),
                      size: 18,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      _selectedDate == null
                          ? 'SELECT DATE & TIME'
                          : '${DateFormat('dd MMM yyyy').format(_selectedDate!)} @ ${_selectedTime!.format(context)}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _selectedDate == null
                            ? (isDark
                                  ? Colors.white24
                                  : const Color(0x420C312B))
                            : (isDark ? Colors.white : const Color(0xFF0C312B)),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      LucideIcons.chevronRight,
                      color: isDark ? Colors.white24 : const Color(0x420C312B),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            _buildFieldLabel('ADDITIONAL NOTES'),
            _buildTextField(
              _notesController,
              LucideIcons.messageSquare,
              'Enter Specific Requirements',
              maxLines: 4,
            ),
            const SizedBox(height: 56),
            GestureDetector(
              onTap: _isLoading ? null : _submitBooking,
              child: Container(
                width: double.infinity,
                height: 64,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white : const Color(0xFF0C312B),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? Colors.white : const Color(0xFF0C312B))
                          .withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: isDark
                                ? Colors.black
                                : const Color(0xFFF4EFE3),
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'SECURE BOOKING',
                              style: GoogleFonts.gelasio(
                                color: isDark
                                    ? const Color(0xFF0C312B)
                                    : const Color(0xFFF4EFE3),
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                                letterSpacing: 2,
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
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                '* PICK-UP AND DROP FACILITY INCLUDED FOR PREMIUM TIER MEMBERS.',
                style: GoogleFonts.inter(
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white24 : const Color(0x420C312B),
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  /// CP-only handler picker. Same cream field treatment as the other inputs.
  Widget _buildEmployeeField() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selected = _employees.firstWhere(
      (e) => e["_id"]?.toString() == _employeeId,
      orElse: () => <String, dynamic>{},
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.03)
            : const Color(0xFFF4EFE3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : const Color(0xFFD4CFBC),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _employeeId,
          isExpanded: true,
          dropdownColor: isDark
              ? const Color(0xFF141B3A)
              : const Color(0xFFF4EFE3),
          borderRadius: BorderRadius.circular(8),
          icon: Icon(
            LucideIcons.chevronDown,
            size: 18,
            color: isDark ? Colors.white70 : const Color(0xFF0C312B),
          ),
          hint: Text(
            "SELECT EMPLOYEE",
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? Colors.white70
                  : const Color(0xFF0C312B).withValues(alpha: 0.6),
            ),
          ),
          items: _employees.map((e) {
            return DropdownMenuItem<String>(
              value: e["_id"]?.toString(),
              child: Text(
                (e["name"] ?? "").toString().toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : const Color(0xFF0C312B),
                ),
              ),
            );
          }).toList(),
          onChanged: (v) => setState(() => _employeeId = v),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        label,
        style: GoogleFonts.gelasio(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: (isDark ? Colors.white : const Color(0xFF0C312B)).withOpacity(
            0.75,
          ),
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    IconData icon,
    String hint, {
    int maxLines = 1,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.03)
            : const Color(0xFFF4EFE3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : const Color(0xFFD4CFBC),
        ),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : const Color(0xFF0C312B),
        ),
        decoration: InputDecoration(
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          hintText: hint,
          hintStyle: GoogleFonts.inter(
            fontSize: 11,
            color: (isDark ? Colors.white : const Color(0xFF0C312B))
                .withOpacity(0.68),
            fontWeight: FontWeight.bold,
          ),
          icon: maxLines == 1
              ? Icon(
                  icon,
                  color: (isDark ? Colors.white : const Color(0xFF0C312B))
                      .withOpacity(0.4),
                  size: 18,
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }
}
