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
    DateTime temp = _selectedDate ?? now.add(const Duration(days: 1));
    if (temp.isBefore(now)) temp = now.add(const Duration(days: 1));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Web parity: absolute Day/Month/Year + time wheel picker (CANCEL/CONFIRM).
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
                style: GoogleFonts.dmSerifDisplay(
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
                      style: GoogleFonts.dmSerifDisplay(
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
                      style: GoogleFonts.dmSerifDisplay(
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
      setState(() {
        _selectedDate = result;
        _selectedTime = TimeOfDay.fromDateTime(result);
      });
    }
  }

  Future<void> _submitBooking() async {
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date and time')),
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
        'name':
            authUser?['fullName']?.toString() ??
            authUser?['username']?.toString() ??
            'App User',
        'phone': authUser?['phone']?.toString() ?? '',
        'email': authUser?['email']?.toString() ?? '',
        'notes': _notesController.text.trim(),
        'visitType': _visitType,
      });

      if (res.data['status'] == true) {
        setState(() => _isSuccess = true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.data['message'] ?? 'Failed to schedule visit'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error scheduling visit. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isSuccess) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F1115) : Colors.white,
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
                    color: isDark ? Colors.white : Colors.black,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Icon(
                    LucideIcons.checkCircle2,
                    color: isDark ? Colors.black : Colors.white,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  'SUBMITTED',
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Your request has been registered. Our team will contact you shortly.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 10,
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontWeight: FontWeight.w900,
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
                      color: isDark ? Colors.white : Colors.black,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: (isDark ? Colors.white : Colors.black)
                              .withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'BACK TO PROJECT',
                        style: GoogleFonts.dmSerifDisplay(
                          color: isDark ? Colors.black : Colors.white,
                          fontWeight: FontWeight.w900,
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
      backgroundColor: isDark ? const Color(0xFF0F1115) : Colors.white,
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
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SCHEDULE VISIT',
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            Text(
              'PREMIUM PROTOCOL',
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 8,
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.68),
                fontWeight: FontWeight.w900,
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
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(
                    0.08,
                  ),
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
                      color: isDark ? Colors.white : Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      LucideIcons.info,
                      color: isDark ? Colors.black : Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'NOTE: OUR RELATIONSHIP MANAGER WILL CONTACT YOU WITHIN 2 HOURS TO CONFIRM YOUR SCHEDULE.',
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: (isDark ? Colors.white : Colors.black)
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
            // Web parity: no Name/Phone/Email fields — details come from the
            // logged-in user; the form starts at Select Property.
            _buildFieldLabel('SELECT PROPERTY'),
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
                            color: isDark ? Colors.white24 : Colors.black26,
                            size: 18,
                          ),
                          dropdownColor: isDark
                              ? const Color(0xFF1C1C1E)
                              : Colors.white,
                          items: projects.map((p) {
                            return DropdownMenuItem<String>(
                              value: p['_id']?.toString(),
                              child: Text(
                                (p['title'] ?? 'PROJECT')
                                    .toString()
                                    .toUpperCase(),
                                style: GoogleFonts.dmSerifDisplay(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? Colors.white : Colors.black,
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
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 10,
                      color: Colors.red,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
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
                      color: isDark ? Colors.white38 : Colors.black38,
                      size: 18,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      _selectedDate == null
                          ? 'SELECT DATE & TIME'
                          : '${DateFormat('dd MMM yyyy').format(_selectedDate!)} @ ${_selectedTime!.format(context)}',
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: _selectedDate == null
                            ? (isDark ? Colors.white24 : Colors.black26)
                            : (isDark ? Colors.white : Colors.black),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      LucideIcons.chevronRight,
                      color: isDark ? Colors.white24 : Colors.black26,
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
              'SPECIFIC REQUIREMENTS...',
              maxLines: 4,
            ),
            const SizedBox(height: 56),
            GestureDetector(
              onTap: _isLoading ? null : _submitBooking,
              child: Container(
                width: double.infinity,
                height: 64,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white : Colors.black,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? Colors.white : Colors.black).withOpacity(
                        0.1,
                      ),
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
                            color: isDark ? Colors.black : Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'SECURE BOOKING',
                              style: GoogleFonts.dmSerifDisplay(
                                color: isDark ? Colors.black : Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
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
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                '* PICK-UP AND DROP FACILITY INCLUDED FOR PREMIUM TIER MEMBERS.',
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white24 : Colors.black26,
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

  Widget _buildFieldLabel(String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        label,
        style: GoogleFonts.dmSerifDisplay(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.75),
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
            : Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: GoogleFonts.dmSerifDisplay(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: isDark ? Colors.white : Colors.black,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: GoogleFonts.dmSerifDisplay(
            fontSize: 12,
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.68),
            fontWeight: FontWeight.bold,
          ),
          icon: maxLines == 1
              ? Icon(
                  icon,
                  color: (isDark ? Colors.white : Colors.black).withOpacity(
                    0.4,
                  ),
                  size: 18,
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }
}
