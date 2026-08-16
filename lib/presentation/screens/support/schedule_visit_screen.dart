import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  String? _selectedProjectId;
  DateTime? _scheduledAt;
  bool _isProjectDropdownOpen = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  // Web parity: a single combined "Schedule" trigger opening the same
  // absolute-date wheel picker used by the CP video call / site visit forms
  // (matches web's IOSDateTimePicker), instead of separate DATE/TIME fields.
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
          color: isDark ? const Color(0xFF141B3A) : const Color(0xFFFBF7EF),
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
                style: GoogleFonts.ebGaramond(
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
                      style: GoogleFonts.ebGaramond(
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
                      style: GoogleFonts.ebGaramond(
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
    // Web parity: only Property + Schedule are required; client details come
    // from the logged-in account (web pre-fills these from the stored user).
    if (_selectedProjectId == null || _scheduledAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final authUser = ref.read(authProvider).user;

      final String visitDetails =
          "Date: ${DateFormat('yyyy-MM-dd').format(_scheduledAt!)}, Time: ${DateFormat('hh:mm a').format(_scheduledAt!)}. Notes: ${_notesController.text}";

      final response = await apiClient.submitLead({
        'name':
            authUser?['fullName']?.toString() ??
            authUser?['username']?.toString() ??
            'App User',
        'phone': authUser?['phone']?.toString() ?? '',
        'interest': 'Site Visit',
        'projectId': _selectedProjectId,
        'message': visitDetails,
        'source': 'Mobile App',
      });

      if (!mounted) return;

      if (response.data['status'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Visit scheduled successfully! We will contact you soon.',
            ),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.data['message'] ?? 'Failed to schedule visit',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              'SCHEDULE VISIT',
              style: GoogleFonts.ebGaramond(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.onSurface,
                letterSpacing: 0,
              ),
            ),
            Text(
              'PREMIUM PROTOCOL',
              style: GoogleFonts.ebGaramond(
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
                      'NOTE: OUR RELATIONSHIP MANAGER WILL CONTACT YOU WITHIN 2 HOURS TO CONFIRM YOUR SCHEDULE.',
                      style: GoogleFonts.ebGaramond(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
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

            // Web parity: no Name / Phone / Employee fields — the form starts
            // at Select Property, then Schedule, then Additional Notes.
            _buildLabel('SELECT PROPERTY'),
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
              hint: 'SPECIFIC REQUIREMENTS, PICKUP DETAILS, ETC...',
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
                style: GoogleFonts.ebGaramond(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
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
      style: GoogleFonts.ebGaramond(
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
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Web parity: a bright "enabled-looking" card (bg-card + shadow-xl)
    // instead of a near-invisible tinted fill — InputDecoration alone can't
    // draw a drop shadow, so this wraps the field in a shadowed Container.
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141B3A) : const Color(0xFFFBF7EF),
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
        style: GoogleFonts.ebGaramond(
          color: isDark ? Colors.white : const Color(0xFF15271E),
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          hintText: hint.toUpperCase(),
          hintStyle: GoogleFonts.ebGaramond(
            color: (isDark ? Colors.white : const Color(0xFF15271E))
                .withOpacity(0.55),
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
          prefixIcon: icon != null
              ? Icon(
                  icon,
                  color: isDark
                      ? Colors.white.withOpacity(0.6)
                      : const Color(0xFFC5A35B),
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
              color: isDark ? const Color(0xFF141B3A) : const Color(0xFFFBF7EF),
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
                      ? _projectLabel(selectedProject)
                      : 'CHOOSE PROPERTY',
                  style: GoogleFonts.ebGaramond(
                    color: selectedProject != null
                        ? (isDark ? Colors.white : Colors.black)
                        : (isDark ? Colors.white : Colors.black).withOpacity(
                            0.68,
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
              color: isDark ? const Color(0xFF0B1026) : const Color(0xFFFBF7EF),
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
                      _projectLabel(project),
                      style: GoogleFonts.ebGaramond(
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
          color: isDark ? const Color(0xFF141B3A) : const Color(0xFFFBF7EF),
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
                style: GoogleFonts.ebGaramond(
                  color: isPlaceholder
                      ? (isDark ? Colors.white : Colors.black).withOpacity(0.68)
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? Colors.white : Colors.black,
          foregroundColor: isDark ? Colors.black : Colors.white,
          disabledBackgroundColor: (isDark ? Colors.white : Colors.black)
              .withOpacity(0.7),
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
                  color: isDark ? Colors.black : Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'SECURE BOOKING',
                    style: GoogleFonts.ebGaramond(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    LucideIcons.send,
                    color: isDark ? Colors.black : Colors.white,
                    size: 16,
                  ),
                ],
              ),
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2);
  }
}
