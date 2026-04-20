import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/providers/project_provider.dart';

/// Web `/cp/booking/site-visit` — registers a site-visit lead via `POST /api/leads`.
class CpSiteVisitScreen extends ConsumerStatefulWidget {
  const CpSiteVisitScreen({super.key});

  @override
  ConsumerState<CpSiteVisitScreen> createState() => _CpSiteVisitScreenState();
}

class _CpSiteVisitScreenState extends ConsumerState<CpSiteVisitScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _employee = TextEditingController();
  final _unitNo = TextEditingController();
  final _type = TextEditingController();
  String? _projectId;
  DateTime? _visitDateTime;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final qp = GoRouterState.of(context).uri.queryParameters;
      final pid = qp['projectId'];
      if (pid != null && pid.isNotEmpty) {
        setState(() => _projectId = pid);
      }
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _employee.dispose();
    _unitNo.dispose();
    _type.dispose();
    super.dispose();
  }

  Future<void> _pickDt() async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: DateTime.now(),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (t == null || !mounted) return;
    setState(() {
      _visitDateTime = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    });
  }

  Future<void> _submit() async {
    if (_projectId == null ||
        _name.text.trim().isEmpty ||
        _phone.text.trim().isEmpty ||
        _email.text.trim().isEmpty ||
        _visitDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fill all fields')));
      return;
    }
    if (_employee.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter staff / employee name')));
      return;
    }
    final async = ref.read(projectsProvider);
    final projects = async.value ?? <dynamic>[];
    String projectTitle = 'Project';
    for (final x in projects) {
      if ((x['_id'] ?? x['id'])?.toString() == _projectId) {
        projectTitle = (x['title'] ?? 'Project').toString();
        break;
      }
    }
    final uid = ref.read(authProvider).user?['id']?.toString() ?? ref.read(authProvider).user?['_id']?.toString();

    setState(() => _submitting = true);
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.submitLead({
        'name': _name.text.trim(),
        'phone': _phone.text.trim(),
        'email': _email.text.trim(),
        'projectId': _projectId,
        'project': projectTitle,
        'interest': 'Site Visit',
        'status': 'site-visit',
        'source': 'cp',
        'message': 'CP site visit • Employee: ${_employee.text.trim()} • $projectTitle',
        'notes': 'Site visit booking • Staff: ${_employee.text.trim()}',
        if (_unitNo.text.trim().isNotEmpty) 'unitNo': _unitNo.text.trim(),
        if (_type.text.trim().isNotEmpty) 'configuration': _type.text.trim(),
        'visitDate': _visitDateTime!.toIso8601String(),
        'visitTime': DateFormat.jm().format(_visitDateTime!.toLocal()),
        if (uid != null && uid.length == 24) 'sourceId': uid,
      });
      if (!mounted) return;
      if (res.statusCode == 200 || res.statusCode == 201) {
        final ok = res.data['status'] == true;
        if (ok) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Site visit booked')));
          context.pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res.data['message']?.toString() ?? 'Failed')),
          );
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectsProvider);
    final scheme = Theme.of(context).colorScheme;
    final isLight = scheme.brightness == Brightness.light;
    final btnBg = isLight ? Colors.black : Colors.white;
    final btnFg = isLight ? Colors.white : Colors.black;
    final accent = isLight ? Colors.black : scheme.primary;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft), onPressed: () => context.pop()),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('BOOK VISIT', style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, letterSpacing: -0.3)),
            Text('CLIENT REGISTRATION', style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 2, color: scheme.onSurfaceVariant)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
        children: [
          _label(scheme, 'Enter employee name'),
          const SizedBox(height: 6),
          _field(scheme, controller: _employee, hint: 'EMPLOYEE NAME'),
          const SizedBox(height: 12),
          projectsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text('Projects unavailable'),
            data: (projects) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _label(scheme, 'Project'),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _projectId,
                    decoration: _dec(scheme, hint: '— Select project —'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('— Select —')),
                      for (final p in projects)
                        if ((p['_id']?.toString() ?? p['id']?.toString() ?? '').isNotEmpty)
                          DropdownMenuItem(
                            value: p['_id']?.toString() ?? p['id']!.toString(),
                            child: Text((p['title'] ?? '').toString()),
                          ),
                    ],
                    onChanged: (v) => setState(() => _projectId = v),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          _label(scheme, 'Client Name'),
          const SizedBox(height: 6),
          _field(scheme, controller: _name, hint: 'CLIENT NAME'),
          const SizedBox(height: 12),
          _label(scheme, 'Client Number'),
          const SizedBox(height: 6),
          _field(scheme, controller: _phone, hint: 'PHONE NUMBER', keyboardType: TextInputType.phone),
          const SizedBox(height: 12),
          _label(scheme, 'E-mail'),
          const SizedBox(height: 6),
          _field(scheme, controller: _email, hint: 'EMAIL ADDRESS', keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _label(scheme, 'Unit No (interest)'),
                    const SizedBox(height: 6),
                    _field(scheme, controller: _unitNo, hint: 'E.G. A-101'),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _label(scheme, 'Type (e.g. 2BHK)'),
                    const SizedBox(height: 6),
                    _field(scheme, controller: _type, hint: 'E.G. 3BHK'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _label(scheme, 'Date & Time'),
          const SizedBox(height: 6),
          OutlinedButton.icon(
            onPressed: _pickDt,
            icon: const Icon(LucideIcons.calendar),
            label: Text(
              _visitDateTime == null ? 'dd-mm-yyyy • --:--' : DateFormat('d MMM y, h:mm a').format(_visitDateTime!.toLocal()),
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              foregroundColor: accent,
              side: BorderSide(color: accent.withValues(alpha: 0.55)),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: btnBg,
              foregroundColor: btnFg,
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _submitting
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                : Text('SUBMIT', style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, letterSpacing: 3)),
          ),
        ],
      ),
    );
  }

  Widget _label(ColorScheme scheme, String text) {
    return Text(
      text,
      style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w800, color: scheme.onSurface),
    );
  }

  Widget _field(ColorScheme scheme, {required TextEditingController controller, required String hint, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: _dec(scheme, hint: hint),
      style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
    );
  }

  InputDecoration _dec(ColorScheme scheme, {required String hint}) {
    final isLight = scheme.brightness == Brightness.light;
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.montserrat(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.8,
        color: scheme.onSurface.withValues(alpha: isLight ? 0.55 : 0.45),
      ),
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withValues(alpha: isLight ? 0.16 : 0.2),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5))),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.onSurface.withValues(alpha: isLight ? 0.8 : 0.65)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}
