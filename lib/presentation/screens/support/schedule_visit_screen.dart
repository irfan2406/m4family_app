import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m4_mobile/presentation/providers/project_provider.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

class ScheduleVisitScreen extends ConsumerStatefulWidget {
  const ScheduleVisitScreen({super.key});

  @override
  ConsumerState<ScheduleVisitScreen> createState() => _ScheduleVisitScreenState();
}

class _ScheduleVisitScreenState extends ConsumerState<ScheduleVisitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  
  String? _selectedProjectId;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isProjectDropdownOpen = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.blueAccent,
              onPrimary: Colors.white,
              surface: Color(0xFF1A1D21),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.blueAccent,
              onPrimary: Colors.white,
              surface: Color(0xFF1A1D21),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedProjectId == null || _selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields')),
      );
      return;
    }

    try {
      final apiClient = ref.read(apiClientProvider);
      
      final String visitDetails = "Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}, Time: ${_selectedTime!.format(context)}. Notes: ${_notesController.text}";

      final response = await apiClient.submitLead({
        'name': _nameController.text,
        'phone': _phoneController.text,
        'interest': 'Site Visit',
        'projectId': _selectedProjectId,
        'message': visitDetails,
        'source': 'Mobile App'
      });
      
      if (!mounted) return;
      
      if (response.data['status'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Visit scheduled successfully! We will contact you soon.')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.data['message'] ?? 'Failed to schedule visit')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
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
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                  shape: BoxShape.circle,
                  border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
                ),
                child: Icon(LucideIcons.chevronLeft, color: Theme.of(context).colorScheme.onSurface, size: 16),
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
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
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
                // Top Note
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF111111) : Colors.black,
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
                        child: const Icon(LucideIcons.info, color: Colors.white, size: 18),
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
                  validator: (v) => v!.isEmpty ? 'Phone number is required' : null,
                ),
                const SizedBox(height: 24),

                _buildLabel('SELECT PROJECT *'),
                const SizedBox(height: 12),
                projectsAsync.when(
                  data: (projects) => _buildDropdown(projects),
                  loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  error: (e, s) => Text('Error loading projects', style: TextStyle(color: Colors.red[400])),
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('DATE *'),
                          const SizedBox(height: 12),
                          _buildPickerButton(
                            text: _selectedDate == null 
                                ? 'DD-MM-YYYY' 
                                : DateFormat('dd-MM-yyyy').format(_selectedDate!),
                            icon: LucideIcons.calendar,
                            onTap: () => _selectDate(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('TIME *'),
                          const SizedBox(height: 12),
                          _buildPickerButton(
                            text: _selectedTime == null 
                                ? 'TIME' 
                                : _selectedTime!.format(context),
                            icon: LucideIcons.clock,
                            onTap: () => _selectTime(context),
                          ),
                        ],
                      ),
                    ),
                  ],
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
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.38),
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
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.montserrat(color: isDark ? Colors.white : Colors.black, fontSize: 13, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        filled: true,
        fillColor: (isDark ? Colors.white : Colors.black).withOpacity(0.03),
        hintText: hint.toUpperCase(),
        hintStyle: GoogleFonts.montserrat(color: (isDark ? Colors.white : Colors.black).withOpacity(0.2), fontSize: 13, fontWeight: FontWeight.bold),
        prefixIcon: icon != null ? Icon(icon, color: (isDark ? Colors.white : Colors.black).withOpacity(0.2), size: 18) : null,
        errorStyle: GoogleFonts.montserrat(color: isDark ? Colors.white38 : Colors.black38, fontSize: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: (isDark ? Colors.white : Colors.black).withOpacity(0.2), width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: (isDark ? Colors.white : Colors.black).withOpacity(0.2), width: 1),
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
          onTap: () => setState(() => _isProjectDropdownOpen = !_isProjectDropdownOpen),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isProjectDropdownOpen ? (isDark ? Colors.white : Colors.black).withOpacity(0.2) : (isDark ? Colors.white : Colors.black).withOpacity(0.1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedProject != null ? selectedProject['title'].toString().toUpperCase() : 'CHOOSE PROJECT',
                  style: GoogleFonts.montserrat(
                    color: selectedProject != null ? (isDark ? Colors.white : Colors.black) : (isDark ? Colors.white : Colors.black).withOpacity(0.2),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                Icon(
                  _isProjectDropdownOpen ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.2),
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
              boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
              border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? (isDark ? Colors.white : Colors.black).withOpacity(0.05) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      (project['title'] ?? '').toString().toUpperCase(),
                      style: GoogleFonts.montserrat(
                        color: isSelected ? (isDark ? Colors.white : Colors.black) : (isDark ? Colors.white38 : Colors.black38),
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
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

  Widget _buildPickerButton({required String text, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2), size: 18),
                const SizedBox(width: 12),
                Text(
                  text,
                  style: GoogleFonts.montserrat(
                    color: text.contains('Select') || text.contains('MM') || text.contains('TIME') ? Theme.of(context).colorScheme.onSurface.withOpacity(0.2) : Theme.of(context).colorScheme.onSurface,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 300.ms);
  }


  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
          foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: Row(
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
            Icon(LucideIcons.shieldCheck, color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white, size: 16),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2);
  }

}
