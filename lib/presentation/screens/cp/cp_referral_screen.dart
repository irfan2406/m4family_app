import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/providers/project_provider.dart';

/// Web `/cp/referral`: wallet + submit referral + history (`/api/cp/wallet`, `/api/cp/referrals`).
class CpReferralScreen extends ConsumerStatefulWidget {
  const CpReferralScreen({super.key});

  @override
  ConsumerState<CpReferralScreen> createState() => _CpReferralScreenState();
}

class _CpReferralScreenState extends ConsumerState<CpReferralScreen> {
  Map<String, dynamic>? _wallet;
  List<dynamic> _referrals = [];
  bool _loading = true;
  bool _submitting = false;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _projectId;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      final w = await api.getCpWallet();
      final r = await api.getCpReferrals();
      if (!mounted) return;
      if (w.statusCode == 200 && w.data['status'] == true) {
        final d = w.data['data'];
        if (d is Map) _wallet = Map<String, dynamic>.from(d);
      }
      if (r.statusCode == 200 && r.data['status'] == true) {
        final d = r.data['data'];
        if (d is List) _referrals = List<dynamic>.from(d);
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  num _balance() {
    final w = _wallet;
    if (w == null) return 0;
    return (w['balance'] ?? w['availableBalance'] ?? 0) as num? ?? 0;
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isEmpty || phone.isEmpty || _projectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.createCpReferral({
        'referralName': name,
        'referralPhone': phone,
        'projectId': _projectId,
        'notes': 'Submitted via Flutter CP Portal',
      });
      if (!mounted) return;
      if (res.statusCode == 201 && res.data['status'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Referral registered')));
        _nameController.clear();
        _phoneController.clear();
        setState(() => _projectId = null);
        await _load();
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

  String _name(dynamic r) => (r['referralName'] ?? r['clientName'] ?? '').toString();
  String _status(dynamic r) => (r['status'] ?? 'Pending').toString();

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectsProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Referral & Rewards',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'WALLET BALANCE',
                                style: GoogleFonts.montserrat(fontSize: 9, letterSpacing: 2, color: scheme.outline),
                              ),
                              Text(
                                'AED ${_balance()}',
                                style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                          const Icon(LucideIcons.gift, size: 32, color: Colors.purpleAccent),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'NEW REFERRAL',
                    style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, letterSpacing: 2, fontSize: 10),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Client name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Client phone',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  projectsAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const Text('Could not load projects'),
                    data: (projects) {
                      return InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Project',
                          border: OutlineInputBorder(),
                        ),
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
                                    child: Text((p['title'] ?? 'Project').toString()),
                                  ),
                            ],
                            onChanged: (v) => setState(() => _projectId = v),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('SUBMIT REFERRAL'),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'HISTORY',
                    style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, letterSpacing: 2, fontSize: 10),
                  ),
                  const SizedBox(height: 8),
                  if (_referrals.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('No referrals yet', style: TextStyle(color: scheme.outline)),
                    )
                  else
                    ..._referrals.map((r) {
                      final pid = r['projectId'];
                      String proj = '';
                      if (pid is Map) proj = pid['title']?.toString() ?? '';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          title: Text(_name(r), style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(proj.isNotEmpty ? proj : (r['projectName'] ?? '').toString()),
                          trailing: Chip(
                            label: Text(_status(r), style: const TextStyle(fontSize: 10)),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
