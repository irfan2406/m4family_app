import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/providers/project_provider.dart';

/// Web `/cp/booking/site-visit` (Client Registration): Full parity including Date & Time.
class CpSiteVisitScreen extends ConsumerStatefulWidget {
  const CpSiteVisitScreen({super.key});

  @override
  ConsumerState<CpSiteVisitScreen> createState() => _CpSiteVisitScreenState();
}

class _CpSiteVisitScreenState extends ConsumerState<CpSiteVisitScreen> {
  final _clientName = TextEditingController();
  final _clientPhone = TextEditingController();
  final _clientEmail = TextEditingController();
  final _employeeName = TextEditingController();
  final _unitNo = TextEditingController();
  final _unitType = TextEditingController();
  String? _projectId;
  String? _employeeId;
  DateTime? _visitDate;
  TimeOfDay? _visitTime;
  bool _submitting = false;

  @override
  void dispose() {
    _clientName.dispose();
    _clientPhone.dispose();
    _clientEmail.dispose();
    _employeeName.dispose();
    _unitNo.dispose();
    _unitType.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Colors.black)),
        child: child!,
      ),
    );
    if (d != null) {
      if (!mounted) return;
      final t = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Colors.black)),
          child: child!,
        ),
      );
      if (t != null) {
        setState(() {
          _visitDate = d;
          _visitTime = t;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (_projectId == null || _clientName.text.isEmpty || _clientPhone.text.isEmpty || _visitDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields including Date & Time')));
      return;
    }

    setState(() => _submitting = true);
    try {
      final api = ref.read(apiClientProvider);
      final projects = ref.read(projectsProvider).value ?? [];
      final projectName = projects.firstWhere((p) => (p['_id'] ?? p['id']) == _projectId, orElse: () => {'title': 'Project'})['title'];

      final res = await api.submitLead({
        'name': _clientName.text.trim(),
        'phone': _clientPhone.text.trim(),
        'email': _clientEmail.text.trim(),
        'projectId': _projectId,
        'project': projectName,
        'interest': 'Site Visit',
        'status': 'site-visit',
        'source': 'cp',
        'unitNo': _unitNo.text.trim(),
        'unitType': _unitType.text.trim(),
        'visitDate': _visitDate!.toIso8601String(),
        'visitTime': _visitTime?.format(context) ?? '',
        'message': 'CP Booked Visit • Employee: ${_employeeName.text.trim()}',
      });

      if (mounted && (res.statusCode == 200 || res.statusCode == 201)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CLIENT REGISTERED SUCCESSFULLY')));
        context.pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final projectsAsync = ref.watch(projectsProvider);

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(LucideIcons.chevronLeft, size: 20),
          style: IconButton.styleFrom(backgroundColor: scheme.surfaceContainer),
        ),
        title: Column(
          children: [
            Text('BOOK VISIT', style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1)),
            Text('CLIENT REGISTRATION', style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.black54, letterSpacing: 1)),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(34),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 40, offset: const Offset(0, 20))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _label('Project'),
              projectsAsync.when(
                data: (projects) => _dropdown(
                  hint: '— Select —',
                  value: _projectId,
                  items: projects.map((p) => DropdownMenuItem(value: (p['_id'] ?? p['id']).toString(), child: Text(p['title'].toString().toUpperCase(), style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w800)))).toList(),
                  onChanged: (v) => setState(() => _projectId = v),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Error loading projects'),
              ),
              const SizedBox(height: 16),

              _label('Enter employee name'),
              _field(controller: _employeeName, hint: 'EMPLOYEE NAME'),
              const SizedBox(height: 16),

              _label('Name of the employee'),
              _dropdown(
                hint: '— Select —',
                value: _employeeId,
                items: [
                  const DropdownMenuItem(value: 'admin', child: Text('ADMINISTRATOR')),
                  const DropdownMenuItem(value: 'sales', child: Text('SALES LEAD')),
                ],
                onChanged: (v) => setState(() => _employeeId = v),
              ),
              const SizedBox(height: 16),

              _label('Client Name'),
              _field(controller: _clientName, hint: 'CLIENT NAME'),
              const SizedBox(height: 16),

              _label('Client Number'),
              _field(controller: _clientPhone, hint: 'PHONE NUMBER', keyboardType: TextInputType.phone),
              const SizedBox(height: 16),

              _label('E-mail'),
              _field(controller: _clientEmail, hint: 'EMAIL ADDRESS', keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Unit No (Interest)'),
                        _field(controller: _unitNo, hint: 'E.G. A-101'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Type (e.g. 2BHK)'),
                        _field(controller: _unitType, hint: 'E.G. 3BHK'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _label('Date & Time'),
              InkWell(
                onTap: _pickDateTime,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.01),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black.withOpacity(0.05)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _visitDate == null 
                          ? 'dd-mm-yyyy --:--' 
                          : '${DateFormat('dd-MM-yyyy').format(_visitDate!)} ${_visitTime!.format(context)}',
                        style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w800, color: _visitDate == null ? Colors.black38 : Colors.black),
                      ),
                      const Spacer(),
                      const Icon(LucideIcons.calendar, size: 16, color: Colors.black26),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _submitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('SUBMIT', style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.black),
      ),
    );
  }

  Widget _field({required TextEditingController controller, required String hint, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w800),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black26, letterSpacing: 1),
        filled: true,
        fillColor: Colors.black.withOpacity(0.01),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.black.withOpacity(0.05))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.black.withOpacity(0.05))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black)),
      ),
    );
  }

  Widget _dropdown({required String hint, String? value, required List<DropdownMenuItem<String>> items, required ValueChanged<String?> onChanged}) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items,
      onChanged: onChanged,
      icon: const Icon(LucideIcons.chevronDown, size: 16, color: Colors.black26),
      style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.black),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.black26),
        filled: true,
        fillColor: Colors.black.withOpacity(0.01),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.black.withOpacity(0.05))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.black.withOpacity(0.05))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black)),
      ),
    );
  }
}
