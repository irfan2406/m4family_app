import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/providers/project_provider.dart';

/// Web `/cp/booking/inquiry` — quick lead via `POST /api/leads`.
class CpInquiryScreen extends ConsumerStatefulWidget {
  const CpInquiryScreen({super.key});

  @override
  ConsumerState<CpInquiryScreen> createState() => _CpInquiryScreenState();
}

class _CpInquiryScreenState extends ConsumerState<CpInquiryScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _message = TextEditingController();
  String? _projectId;
  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty || _phone.text.trim().isEmpty || _projectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fill required fields')));
      return;
    }
    final user = ref.read(authProvider).user;
    final display = user?['firstName']?.toString() ?? user?['companyName']?.toString() ?? 'Partner';
    setState(() => _submitting = true);
    try {
      final res = await ref.read(apiClientProvider).submitLead({
        'name': _name.text.trim(),
        'phone': _phone.text.trim(),
        'source': 'cp inquiry',
        'projectId': _projectId,
        'userId': display,
        'notes': _message.text.trim().isEmpty ? 'CP booking inquiry' : _message.text.trim(),
      });
      if (!mounted) return;
      if ((res.statusCode == 200 || res.statusCode == 201) && res.data['status'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Inquiry sent')));
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.data['message']?.toString() ?? 'Failed')),
        );
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
        title: Text('Send inquiry', style: GoogleFonts.montserrat(fontWeight: FontWeight.w800)),
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
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Client name')),
          const SizedBox(height: 12),
          TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone')),
          const SizedBox(height: 12),
          TextField(controller: _message, maxLines: 3, decoration: const InputDecoration(labelText: 'Message (optional)')),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('SUBMIT'),
          ),
        ],
      ),
    );
  }
}
