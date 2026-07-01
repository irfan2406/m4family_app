import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m4_mobile/presentation/providers/project_provider.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/widgets/wheel_date_time_picker.dart';

/// Web `/cp/booking/site-visit` & `/cp/booking/schedule-visit`
/// (`app/(cp)/cp/booking/schedule-visit/page.tsx`) — "Site Visit / Protocol
/// Verification": Full Name, Phone Number, Select Project, Handled By
/// (Employee), a single combined Schedule date+time trigger, Additional
/// Notes, Secure Booking.
class CpSiteVisitScreen extends ConsumerStatefulWidget {
  const CpSiteVisitScreen({super.key});

  @override
  ConsumerState<CpSiteVisitScreen> createState() => _CpSiteVisitScreenState();
}

class _CpSiteVisitScreenState extends ConsumerState<CpSiteVisitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedProjectId;
  String? _employeeId;
  List<Map<String, dynamic>> _employees = [];
  DateTime? _scheduledAt;
  bool _isProjectDropdownOpen = false;
  bool _isEmployeeDropdownOpen = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
  }

  Future<void> _fetchEmployees() async {
    try {
      final res = await ref.read(apiClientProvider).getCpEmployees();
      final body = res.data;
      if (body is Map && body['status'] == true && body['data'] is List) {
        if (!mounted) return;
        setState(() {
          _employees = (body['data'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Web parity: a single combined "Schedule" trigger opening the same
  // absolute-date wheel picker used by the CP video call form (matches web's
  // IOSDateTimePicker), instead of separate DATE/TIME fields.
  Future<void> _pickScheduleDateTime() async {
    final now = DateTime.now();
    DateTime temp = _scheduledAt ?? now.add(const Duration(days: 1));
    if (temp.isBefore(now)) temp = now.add(const Duration(days: 1));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final result = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0B111E) : Colors.white,
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
                  color: (isDark ? Colors.white : Colors.black).withOpacity(
                    0.15,
                  ),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'SELECT DATE & TIME',
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 8),
            WheelDateTimePicker(
              initial: temp,
              minDate: now,
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
                        color: (isDark ? Colors.white : Colors.black)
                            .withOpacity(0.2),
                      ),
                      foregroundColor: isDark ? Colors.white : Colors.black,
                    ),
                    child: Text(
                      'CANCEL',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w900,
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
                      backgroundColor: isDark ? Colors.white : Colors.black,
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'CONFIRM',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w900,
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
    if (!_formKey.currentState!.validate() ||
        _selectedProjectId == null ||
        _employeeId == null ||
        _scheduledAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final apiClient = ref.read(apiClientProvider);

      // Web parity: `POST /api/cp/visits` with the web's exact payload shape.
      final res = await apiClient.createCpVisit({
        'projectId': _selectedProjectId,
        'employeeId': _employeeId,
        'visitDate': _scheduledAt!.toIso8601String(),
        'clientName': _nameController.text.trim(),
        'clientPhone': _phoneController.text.trim(),
        'notes': _notesController.text.trim(),
      });

      if (!mounted) return;
      final ok = res.data is Map && (res.data as Map)['status'] == true;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Visit scheduled successfully!')),
        );
        Navigator.pop(context);
      } else {
        final msg = res.data is Map
            ? (res.data as Map)['message']?.toString()
            : null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg ?? 'Failed to schedule visit')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
              'SITE VISIT',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.onSurface,
                letterSpacing: 0,
              ),
            ),
            Text(
              'PROTOCOL VERIFICATION',
              style: GoogleFonts.montserrat(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
      body: Container(
        color: Colors.transparent,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF111111)
                        : Colors.black,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.info,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'NOTE: OUR MANAGER WILL CONTACT YOU WITHIN 2 HOURS TO CONFIRM YOUR SCHEDULE.',
                          style: GoogleFonts.montserrat(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.2,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: -0.1),
                const SizedBox(height: 32),

                _buildLabel('FULL NAME *'),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _nameController,
                  hint: 'ENTER NAME',
                  icon: LucideIcons.user,
                  validator: (v) => v!.isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 24),

                _buildLabel('PHONE NUMBER *'),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _phoneController,
                  hint: '+91 XXXXX XXXXX',
                  icon: LucideIcons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (v) =>
                      v!.isEmpty ? 'Phone number is required' : null,
                ),
                const SizedBox(height: 24),

                _buildLabel('SELECT PROJECT *'),
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

                _buildLabel('HANDLED BY (EMPLOYEE) *'),
                const SizedBox(height: 12),
                _buildEmployeeDropdown(),
                const SizedBox(height: 24),

                _buildLabel('SCHEDULE *'),
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
                  hint: 'Specific requirements...',
                  maxLines: 4,
                ),
                const SizedBox(height: 48),

                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.montserrat(
        fontSize: 10,
        fontWeight: FontWeight.w900,
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
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Web parity: a bright "enabled-looking" card (bg-card + shadow-xl)
    // instead of a near-invisible tinted fill — InputDecoration alone can't
    // draw a drop shadow, so this wraps the field in a shadowed Container.
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF15171C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
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
        validator: validator,
        style: GoogleFonts.montserrat(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          hintText: hint.toUpperCase(),
          hintStyle: GoogleFonts.montserrat(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.5),
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
          prefixIcon: icon != null
              ? Icon(
                  icon,
                  color: (isDark ? Colors.white : Colors.black).withOpacity(
                    0.6,
                  ),
                  size: 18,
                )
              : null,
          errorStyle: GoogleFonts.montserrat(
            color: Colors.redAccent,
            fontSize: 10,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 20,
          ),
        ),
      ),
    ).animate().fadeIn(delay: 100.ms);
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
              color: isDark ? const Color(0xFF15171C) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isProjectDropdownOpen
                    ? (isDark ? Colors.white : Colors.black).withOpacity(0.2)
                    : (isDark ? Colors.white : Colors.black).withOpacity(0.06),
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
                Text(
                  selectedProject != null
                      ? selectedProject['title'].toString().toUpperCase()
                      : 'CHOOSE PROJECT',
                  style: GoogleFonts.montserrat(
                    color: selectedProject != null
                        ? (isDark ? Colors.white : Colors.black)
                        : (isDark ? Colors.white : Colors.black).withOpacity(
                            0.5,
                          ),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                Icon(
                  _isProjectDropdownOpen
                      ? LucideIcons.chevronUp
                      : LucideIcons.chevronDown,
                  color: (isDark ? Colors.white : Colors.black).withOpacity(
                    0.6,
                  ),
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
              color: isDark ? const Color(0xFF111111) : Colors.white,
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
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
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
                          ? (isDark ? Colors.white : Colors.black).withOpacity(
                              0.05,
                            )
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      (project['title'] ?? '').toString().toUpperCase(),
                      style: GoogleFonts.montserrat(
                        color: isSelected
                            ? (isDark ? Colors.white : Colors.black)
                            : (isDark ? Colors.white70 : Colors.black87),
                        fontSize: 11,
                        fontWeight: isSelected
                            ? FontWeight.w900
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

  Widget _buildEmployeeDropdown() {
    final selectedEmployee = _employees.firstWhere(
      (e) => e['_id'] == _employeeId,
      orElse: () => {},
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(
            () => _isEmployeeDropdownOpen = !_isEmployeeDropdownOpen,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF15171C) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isEmployeeDropdownOpen
                    ? (isDark ? Colors.white : Colors.black).withOpacity(0.2)
                    : (isDark ? Colors.white : Colors.black).withOpacity(0.06),
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
                Text(
                  selectedEmployee.isNotEmpty
                      ? (selectedEmployee['name'] ?? '')
                            .toString()
                            .toUpperCase()
                      : 'SELECT EMPLOYEE',
                  style: GoogleFonts.montserrat(
                    color: selectedEmployee.isNotEmpty
                        ? (isDark ? Colors.white : Colors.black)
                        : (isDark ? Colors.white : Colors.black).withOpacity(
                            0.5,
                          ),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                Icon(
                  _isEmployeeDropdownOpen
                      ? LucideIcons.chevronUp
                      : LucideIcons.chevronDown,
                  color: (isDark ? Colors.white : Colors.black).withOpacity(
                    0.6,
                  ),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        if (_isEmployeeDropdownOpen)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF111111) : Colors.white,
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
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
              ),
            ),
            child: Column(
              children: _employees.map((emp) {
                final isSelected = _employeeId == emp['_id'];
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
                          ? (isDark ? Colors.white : Colors.black).withOpacity(
                              0.05,
                            )
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${(emp['name'] ?? '').toString().toUpperCase()}${emp['phone'] != null ? ' (${emp['phone']})' : ''}',
                      style: GoogleFonts.montserrat(
                        color: isSelected
                            ? (isDark ? Colors.white : Colors.black)
                            : (isDark ? Colors.white70 : Colors.black87),
                        fontSize: 11,
                        fontWeight: isSelected
                            ? FontWeight.w900
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
          color: isDark ? const Color(0xFF15171C) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
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
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.6),
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.montserrat(
                  color: isPlaceholder
                      ? (isDark ? Colors.white : Colors.black).withOpacity(0.5)
                      : (isDark ? Colors.white : Colors.black),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.45),
              size: 16,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _submitting ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black,
          foregroundColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.black
              : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _submitting
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.black
                      : Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'SECURE BOOKING',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    LucideIcons.send,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.black
                        : Colors.white,
                    size: 16,
                  ),
                ],
              ),
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2);
  }
}
