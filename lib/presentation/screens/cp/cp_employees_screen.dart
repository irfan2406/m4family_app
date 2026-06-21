import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

/// Web `/cp/profile/employees` — CP team management.
/// Lists employees (`GET /api/cp/employees`) with add / edit / delete dialogs
/// and search by name / phone / email.
class CpEmployeesScreen extends ConsumerStatefulWidget {
  const CpEmployeesScreen({super.key});

  @override
  ConsumerState<CpEmployeesScreen> createState() => _CpEmployeesScreenState();
}

class _CpEmployeesScreenState extends ConsumerState<CpEmployeesScreen> {
  static const Color _gold = Color(0xFFFFD700);

  bool _loading = true;
  String? _error;
  List<dynamic> _employees = [];
  String _search = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.getCpEmployees();
      final body = res.data;
      if (body is Map && body['status'] == true && body['data'] is List) {
        _employees = List<dynamic>.from(body['data']);
      } else {
        _employees = [];
        _error = body is Map ? body['message']?.toString() : 'Failed to load employees';
        _error ??= 'Failed to load employees';
      }
    } on DioException catch (e) {
      _employees = [];
      _error = e.response?.data is Map
          ? (e.response!.data as Map)['message']?.toString()
          : e.message;
      _error ??= 'Failed to load employees';
    } catch (e) {
      _employees = [];
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  List<dynamic> get _filtered {
    final q = _search.toLowerCase().trim();
    if (q.isEmpty) return _employees;
    return _employees.where((e) {
      final name = (e['name'] ?? '').toString().toLowerCase();
      final phone = (e['phone'] ?? '').toString();
      final email = (e['email'] ?? '').toString().toLowerCase();
      return name.contains(q) || phone.contains(q) || email.contains(q);
    }).toList();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: GoogleFonts.montserrat(fontSize: 12))),
    );
  }

  Future<void> _addEmployee(Map<String, dynamic> body) async {
    final apiClient = ref.read(apiClientProvider);
    try {
      final res = await apiClient.createCpEmployee(body);
      final data = res.data;
      if (data is Map && data['status'] == true) {
        if (data['data'] is Map) {
          setState(() => _employees = [data['data'], ..._employees]);
        } else {
          await _load();
        }
        _toast('Employee added successfully');
      } else {
        _toast(data is Map ? (data['message']?.toString() ?? 'Failed to add employee') : 'Failed to add employee');
      }
    } on DioException catch (e) {
      final m = e.response?.data is Map ? (e.response!.data as Map)['message']?.toString() : e.message;
      _toast(m ?? 'Failed to add employee');
    } catch (_) {
      _toast('Failed to add employee');
    }
  }

  Future<void> _editEmployee(String id, Map<String, dynamic> body) async {
    final apiClient = ref.read(apiClientProvider);
    try {
      final res = await apiClient.updateCpEmployee(id, body);
      final data = res.data;
      if (data is Map && data['status'] == true) {
        if (data['data'] is Map) {
          setState(() {
            _employees = _employees
                .map((e) => (e['_id']?.toString() == id) ? data['data'] : e)
                .toList();
          });
        } else {
          await _load();
        }
        _toast('Employee updated successfully');
      } else {
        _toast(data is Map ? (data['message']?.toString() ?? 'Failed to update employee') : 'Failed to update employee');
      }
    } on DioException catch (e) {
      final m = e.response?.data is Map ? (e.response!.data as Map)['message']?.toString() : e.message;
      _toast(m ?? 'Failed to update employee');
    } catch (_) {
      _toast('Failed to update employee');
    }
  }

  Future<void> _deleteEmployee(String id) async {
    final apiClient = ref.read(apiClientProvider);
    try {
      final res = await apiClient.deleteCpEmployee(id);
      final data = res.data;
      if (data is Map && data['status'] == true) {
        setState(() => _employees = _employees.where((e) => e['_id']?.toString() != id).toList());
        _toast('Employee deleted successfully');
      } else {
        _toast(data is Map ? (data['message']?.toString() ?? 'Failed to delete employee') : 'Failed to delete employee');
      }
    } on DioException catch (e) {
      final m = e.response?.data is Map ? (e.response!.data as Map)['message']?.toString() : e.message;
      _toast(m ?? 'Failed to delete employee');
    } catch (_) {
      _toast('Failed to delete employee');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.black : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black;
    final muted = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5);
    final border = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark, textPrimary, muted, border),
            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator(color: textPrimary, strokeWidth: 2))
                  : _error != null
                      ? _buildError(textPrimary, muted)
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: textPrimary,
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                            children: [
                              _buildSearchBar(isDark, textPrimary, muted, border),
                              const SizedBox(height: 20),
                              if (_filtered.isEmpty)
                                _buildEmptyState(muted, border)
                              else
                                ..._filtered.map((e) => _buildEmployeeCard(e, isDark, textPrimary, muted, border)),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, Color textPrimary, Color muted, Color border) {
    final card = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => context.canPop() ? context.pop() : context.go('/cp/dashboard'),
            icon: Icon(LucideIcons.chevronLeft, size: 18, color: textPrimary),
            style: IconButton.styleFrom(
              backgroundColor: card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: border),
              ),
            ),
          ),
          Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 4, height: 4, decoration: const BoxDecoration(color: _gold, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text(
                    'TEAM MANAGEMENT',
                    style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w900, color: textPrimary, letterSpacing: 1.2),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'MANAGE YOUR PORTAL EMPLOYEES',
                style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w900, color: muted, letterSpacing: 1.5),
              ),
            ],
          ),
          IconButton(
            onPressed: () => _openEmployeeDialog(),
            icon: const Icon(LucideIcons.plusCircle, size: 18, color: _gold),
            style: IconButton.styleFrom(
              backgroundColor: _gold.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: _gold.withValues(alpha: 0.2)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark, Color textPrimary, Color muted, Color border) {
    final card = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(LucideIcons.search, size: 18, color: muted),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w700, color: textPrimary),
              decoration: InputDecoration(
                isCollapsed: true,
                hintText: 'SEARCH BY NAME OR PHONE...',
                hintStyle: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, color: muted.withValues(alpha: 0.6), letterSpacing: 1.2),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard(dynamic emp, bool isDark, Color textPrimary, Color muted, Color border) {
    final card = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;
    final id = emp['_id']?.toString() ?? '';
    final name = (emp['name'] ?? '').toString();
    final phone = (emp['phone'] ?? '').toString();
    final email = (emp['email'] ?? '').toString();
    final isActive = emp['isActive'] != false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _gold.withValues(alpha: 0.2)),
            ),
            child: const Icon(LucideIcons.userCheck, size: 20, color: _gold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name.toUpperCase(),
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w900, color: textPrimary, letterSpacing: 0.3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _statusBadge(isActive),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(LucideIcons.phone, size: 11, color: muted),
                    const SizedBox(width: 6),
                    Text(
                      phone,
                      style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w800, color: muted, letterSpacing: 0.3),
                    ),
                  ],
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(LucideIcons.mail, size: 11, color: muted),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          email,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w600, color: muted),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          _actionButton(LucideIcons.edit, _gold, border, card, () => _openEmployeeDialog(existing: emp)),
          const SizedBox(width: 8),
          _actionButton(LucideIcons.trash2, Colors.red, border, card, () => _confirmDelete(id, name, textPrimary, muted)),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, Color color, Color border, Color card, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border),
        ),
        child: Icon(icon, size: 15, color: color),
      ),
    );
  }

  Widget _statusBadge(bool isActive) {
    final color = isActive ? Colors.green : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        isActive ? 'ACTIVE' : 'INACTIVE',
        style: GoogleFonts.montserrat(fontSize: 7, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildEmptyState(Color muted, Color border) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Icon(LucideIcons.userPlus, size: 30, color: muted.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(
            'NO MATCHING TEAM MEMBERS',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, color: muted, letterSpacing: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildError(Color textPrimary, Color muted) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.alertCircle, size: 30, color: muted),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _load,
              child: Text('RETRY', style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(String id, String name, Color textPrimary, Color muted) {
    if (id.isEmpty) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF111111) : Colors.white;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'DELETE EMPLOYEE',
          style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w900, color: textPrimary, letterSpacing: 0.5),
        ),
        content: Text(
          'Are you sure you want to delete ${name.isEmpty ? 'this employee' : name}?',
          style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w500, color: muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('CANCEL', style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w900, color: muted)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.of(ctx).pop();
              _deleteEmployee(id);
            },
            child: Text('DELETE', style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  /// Add (existing == null) or edit employee dialog.
  void _openEmployeeDialog({dynamic existing}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF111111) : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black;
    final muted = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5);
    final border = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06);
    final card = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;

    final isEdit = existing != null;
    final nameCtrl = TextEditingController(text: isEdit ? (existing['name'] ?? '').toString() : '');
    final phoneCtrl = TextEditingController(text: isEdit ? (existing['phone'] ?? '').toString() : '');
    final emailCtrl = TextEditingController(text: isEdit ? (existing['email'] ?? '').toString() : '');
    final id = isEdit ? (existing['_id']?.toString() ?? '') : '';

    showDialog<void>(
      context: context,
      builder: (ctx) {
        bool saving = false;
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            Widget field(String label, TextEditingController c, String hint, {bool phone = false}) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 6),
                    child: Text(
                      label,
                      style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w900, color: muted, letterSpacing: 0.5),
                    ),
                  ),
                  TextField(
                    controller: c,
                    keyboardType: phone ? TextInputType.phone : TextInputType.text,
                    inputFormatters: phone
                        ? [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)]
                        : null,
                    style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w700, color: textPrimary),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w500, color: muted.withValues(alpha: 0.7)),
                      filled: true,
                      fillColor: card,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _gold),
                      ),
                    ),
                  ),
                ],
              );
            }

            return AlertDialog(
              backgroundColor: dialogBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              title: Text(
                isEdit ? 'EDIT TEAM MEMBER' : 'ADD NEW EMPLOYEE',
                style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w900, color: textPrimary, letterSpacing: 1.0),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    field('FULL NAME', nameCtrl, 'John Doe'),
                    const SizedBox(height: 14),
                    field('PHONE NUMBER (10 DIGITS)', phoneCtrl, '9876543210', phone: true),
                    const SizedBox(height: 14),
                    field('EMAIL ADDRESS', emailCtrl, 'john@example.com'),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.of(ctx).pop(),
                  child: Text('CANCEL', style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w900, color: muted)),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: _gold, foregroundColor: Colors.black),
                  onPressed: saving
                      ? null
                      : () async {
                          final name = nameCtrl.text.trim();
                          final phone = phoneCtrl.text.trim();
                          final email = emailCtrl.text.trim();
                          if (name.isEmpty || phone.isEmpty) {
                            _toast('Name and Phone are required');
                            return;
                          }
                          setLocal(() => saving = true);
                          final body = <String, dynamic>{
                            'name': name,
                            'phone': phone,
                            'email': email,
                          };
                          if (isEdit) {
                            await _editEmployee(id, body);
                          } else {
                            await _addEmployee(body);
                          }
                          if (ctx.mounted) Navigator.of(ctx).pop();
                        },
                  child: Text(
                    saving ? 'SAVING...' : (isEdit ? 'SAVE CHANGES' : 'ADD EMPLOYEE'),
                    style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
