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
  String? _projectId;
  DateTime? _visitDateTime;
  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _employee.dispose();
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

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft), onPressed: () => context.pop()),
        title: Text('Book site visit', style: GoogleFonts.montserrat(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          projectsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text('Projects unavailable'),
            data: (projects) {
              return InputDecorator(
                decoration: const InputDecoration(labelText: 'Project', border: OutlineInputBorder()),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _projectId,
                    hint: const Text('Select project'),
                    items: [
                      for (final p in projects)
                        if ((p['_id']?.toString() ?? p['id']?.toString() ?? '').isNotEmpty)
                          DropdownMenuItem(
                            value: p['_id']?.toString() ?? p['id']!.toString(),
                            child: Text((p['title'] ?? '').toString()),
                          ),
                    ],
                    onChanged: (v) => setState(() => _projectId = v),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          TextField(controller: _employee, decoration: const InputDecoration(labelText: 'M4 staff / employee name')),
          const SizedBox(height: 12),
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Client name')),
          const SizedBox(height: 12),
          TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Client phone')),
          const SizedBox(height: 12),
          TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Client email')),
          const SizedBox(height: 12),
          ListTile(
            title: const Text('Visit date & time'),
            subtitle: Text(_visitDateTime?.toLocal().toString() ?? 'Tap to pick'),
            trailing: const Icon(LucideIcons.calendar),
            onTap: _pickDt,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('CONFIRM'),
          ),
        ],
      ),
    );
  }
}
