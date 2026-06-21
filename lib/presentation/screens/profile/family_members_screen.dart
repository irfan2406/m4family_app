import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:m4_mobile/core/providers/theme_provider.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

class FamilyMembersScreen extends ConsumerStatefulWidget {
  const FamilyMembersScreen({super.key});

  @override
  ConsumerState<FamilyMembersScreen> createState() => _FamilyMembersScreenState();
}

class _FamilyMembersScreenState extends ConsumerState<FamilyMembersScreen> {
  List<Map<String, dynamic>> _familyMembers = [];
  String _searchQuery = '';
  bool _isLoading = false;

  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _loadFromAuth();
  }

  void _loadFromAuth() {
    final user = ref.read(authProvider).user;
    final raw = (user?['familyMembers'] is List && (user!['familyMembers'] as List).isNotEmpty)
        ? user['familyMembers']
        : (user?['familyDetails'] ?? user?['familyMembers'] ?? []);
    _familyMembers = (raw as List)
        .whereType<dynamic>()
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─── API: PATCH /api/auth/me (sync both familyMembers + familyDetails) ──────
  Future<bool> _updateFamily(List<Map<String, dynamic>> updated) async {
    setState(() => _isLoading = true);
    try {
      final res = await ref.read(apiClientProvider).updateMe({
        'familyMembers': updated,
        'familyDetails': updated,
      });
      if (res.data['status'] == true) {
        await ref.read(authProvider.notifier).fetchMe();
        if (mounted) {
          setState(() => _familyMembers = updated);
          _showToast('Family details updated successfully');
        }
        return true;
      } else {
        _showToast(res.data['message']?.toString() ?? 'Failed to update family details', isError: true);
        return false;
      }
    } catch (e) {
      _showToast('An error occurred while saving', isError: true);
      return false;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showToast(String message, {bool isError = false}) {
    if (!mounted) return;
    final isDark = ref.read(themeProvider) == ThemeMode.dark;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError
            ? const Color(0xFFEF4444)
            : (isDark ? Colors.white : Colors.black),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        content: Text(
          message,
          style: GoogleFonts.montserrat(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: isError ? Colors.white : (isDark ? Colors.black : Colors.white),
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Future<void> _handleDelete(int index) async {
    final isDark = ref.read(themeProvider) == ThemeMode.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF09090B) : Colors.white,
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1), blurRadius: 30, offset: const Offset(0, 15)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'REMOVE MEMBER',
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : Colors.black,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to remove this family member?',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.55),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _DialogButton(
                      label: 'CANCEL',
                      isDark: isDark,
                      filled: false,
                      onTap: () => Navigator.pop(ctx, false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DialogButton(
                      label: 'REMOVE',
                      isDark: isDark,
                      filled: true,
                      destructive: true,
                      onTap: () => Navigator.pop(ctx, true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      final updated = List<Map<String, dynamic>>.from(_familyMembers)..removeAt(index);
      await _updateFamily(updated);
    }
  }

  void _openAddDialog() {
    _showMemberDialog(isEdit: false);
  }

  void _openEditDialog(int index) {
    _showMemberDialog(isEdit: true, index: index, existing: _familyMembers[index]);
  }

  Future<void> _showMemberDialog({
    required bool isEdit,
    int? index,
    Map<String, dynamic>? existing,
  }) async {
    final isDark = ref.read(themeProvider) == ThemeMode.dark;
    final nameController = TextEditingController(text: existing?['name']?.toString() ?? '');
    String relation = existing?['relation']?.toString() ?? '';
    String dob = existing?['dob']?.toString() ?? '';

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            const predefined = ['Spouse', 'Son', 'Daughter', 'Parent'];
            final isCustom = relation.isNotEmpty && !predefined.contains(relation);

            String dobDisplay = '';
            if (dob.isNotEmpty) {
              try {
                dobDisplay = DateFormat('d MMM yyyy').format(DateTime.parse(dob)).toUpperCase();
              } catch (_) {
                dobDisplay = dob;
              }
            }

            Future<void> pickDob() async {
              DateTime initial;
              try {
                initial = dob.isNotEmpty ? DateTime.parse(dob) : DateTime(2000);
              } catch (_) {
                initial = DateTime(2000);
              }
              await showModalBottomSheet(
                context: ctx,
                backgroundColor: Colors.transparent,
                builder: (sheetCtx) => Container(
                  height: 350,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF09090B) : Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                    border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(25, 20, 25, 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('SELECT DATE OF BIRTH',
                                style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1, color: isDark ? Colors.white : Colors.black)),
                            GestureDetector(
                              onTap: () => Navigator.pop(sheetCtx),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text('DONE', style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blue)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(thickness: 0.5),
                      Expanded(
                        child: CupertinoTheme(
                          data: CupertinoThemeData(
                            brightness: isDark ? Brightness.dark : Brightness.light,
                            textTheme: CupertinoTextThemeData(
                              dateTimePickerTextStyle: GoogleFonts.montserrat(
                                color: isDark ? Colors.white : Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          child: CupertinoDatePicker(
                            mode: CupertinoDatePickerMode.date,
                            initialDateTime: initial,
                            maximumDate: DateTime.now(),
                            onDateTimeChanged: (picked) {
                              setDialogState(() => dob = DateFormat('yyyy-MM-dd').format(picked));
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF09090B) : Colors.white,
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1), blurRadius: 30, offset: const Offset(0, 15)),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEdit ? 'EDIT FAMILY MEMBER' : 'ADD FAMILY MEMBER',
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : Colors.black,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Full Name
                      _DialogLabel(label: 'FULL NAME', isDark: isDark),
                      const SizedBox(height: 8),
                      _DialogInput(
                        controller: nameController,
                        hint: 'Enter Name',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 20),
                      // Relation
                      _DialogLabel(label: 'RELATION', isDark: isDark),
                      const SizedBox(height: 8),
                      _RelationDropdown(
                        isDark: isDark,
                        value: relation,
                        onChanged: (val) => setDialogState(() => relation = val),
                      ),
                      if (isCustom) ...[
                        const SizedBox(height: 12),
                        _DialogLabel(label: 'SPECIFY RELATION', isDark: isDark),
                        const SizedBox(height: 8),
                        _DialogInput(
                          controller: TextEditingController(text: relation)
                            ..selection = TextSelection.collapsed(offset: relation.length),
                          hint: 'Type relation...',
                          isDark: isDark,
                          onChanged: (val) => relation = val,
                        ),
                      ],
                      const SizedBox(height: 20),
                      // Date of Birth (optional)
                      _DialogLabel(label: 'DATE OF BIRTH', isDark: isDark),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: pickDob,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  dobDisplay.isEmpty ? 'SELECT DATE' : dobDisplay,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: dobDisplay.isEmpty
                                        ? (isDark ? Colors.white : Colors.black).withValues(alpha: 0.35)
                                        : (isDark ? Colors.white : Colors.black),
                                  ),
                                ),
                              ),
                              Icon(LucideIcons.calendar, size: 16, color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.4)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: _DialogButton(
                              label: 'CANCEL',
                              isDark: isDark,
                              filled: false,
                              onTap: _isLoading ? null : () => Navigator.pop(ctx),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _DialogButton(
                              label: _isLoading
                                  ? (isEdit ? 'SAVING...' : 'ADDING...')
                                  : (isEdit ? 'SAVE CHANGES' : 'ADD MEMBER'),
                              isDark: isDark,
                              filled: true,
                              onTap: _isLoading
                                  ? null
                                  : () async {
                                      final name = nameController.text.trim();
                                      if (name.isEmpty || relation.trim().isEmpty) {
                                        _showToast('Name and Relation are required', isError: true);
                                        return;
                                      }
                                      FocusScope.of(ctx).unfocus();
                                      final member = {
                                        'name': name,
                                        'relation': relation.trim(),
                                        'dob': dob,
                                      };
                                      List<Map<String, dynamic>> updated;
                                      if (isEdit && index != null) {
                                        updated = List<Map<String, dynamic>>.from(_familyMembers);
                                        updated[index] = member;
                                      } else {
                                        updated = List<Map<String, dynamic>>.from(_familyMembers)..add(member);
                                      }
                                      final ok = await _updateFamily(updated);
                                      if (ok && ctx.mounted) Navigator.pop(ctx);
                                    },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final bg = isDark ? Colors.black : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    final filtered = _familyMembers.where((m) {
      final q = _searchQuery.toLowerCase();
      final name = (m['name'] ?? '').toString().toLowerCase();
      final relation = (m['relation'] ?? '').toString().toLowerCase();
      return name.contains(q) || relation.contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark, textColor),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchBar(isDark, textColor),
                    const SizedBox(height: 20),
                    if (filtered.isEmpty)
                      _buildEmptyState(isDark)
                    else
                      ...List.generate(filtered.length, (i) {
                        final member = filtered[i];
                        final realIndex = _familyMembers.indexOf(member);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildMemberCard(member, realIndex, isDark)
                              .animate()
                              .fadeIn(duration: 300.ms, delay: (i * 60).ms)
                              .slideY(begin: -0.15, end: 0, duration: 300.ms, delay: (i * 60).ms, curve: Curves.easeOut),
                        );
                      }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          _HeaderIconButton(
            icon: LucideIcons.chevronLeft,
            isDark: isDark,
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/profile');
              }
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'FAMILY MEMBERS',
              style: GoogleFonts.montserrat(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: textColor,
                letterSpacing: -0.5,
              ),
            ),
          ),
          _HeaderIconButton(
            icon: LucideIcons.plus,
            isDark: isDark,
            accent: true,
            onTap: _openAddDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark, Color textColor) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)),
        boxShadow: isDark
            ? []
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 10),
            child: Icon(LucideIcons.search, size: 16, color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.4)),
          ),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: GoogleFonts.montserrat(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: textColor,
                letterSpacing: 1.5,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                border: InputBorder.none,
                hintText: 'SEARCH MEMBERS...',
                hintStyle: GoogleFonts.montserrat(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.3),
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    final muted = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.01),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(LucideIcons.users, size: 40, color: muted.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(
            'NO FAMILY MEMBERS FOUND',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: muted,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> member, int index, bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black;
    const accent = Color(0xFFFFD700);
    final String name = (member['name'] ?? '').toString();
    final String relation = (member['relation'] ?? '').toString();
    final String dob = (member['dob'] ?? '').toString();

    String dobDisplay = '';
    if (dob.isNotEmpty) {
      try {
        dobDisplay = DateFormat('d MMM yyyy').format(DateTime.parse(dob));
      } catch (_) {
        dobDisplay = dob;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)),
        boxShadow: isDark
            ? []
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          // Icon box
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.blueAccent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(LucideIcons.users, size: 20, color: Colors.blueAccent.withValues(alpha: 0.7)),
          ),
          const SizedBox(width: 16),
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
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    if (relation.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: accent.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          relation.toUpperCase(),
                          style: GoogleFonts.montserrat(
                            fontSize: 7,
                            fontWeight: FontWeight.w900,
                            color: isDark ? accent : const Color(0xFF8A6D00),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (dobDisplay.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(LucideIcons.calendar, size: 11, color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.45)),
                      const SizedBox(width: 6),
                      Text(
                        dobDisplay.toUpperCase(),
                        style: GoogleFonts.montserrat(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5),
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          _CardActionButton(
            icon: LucideIcons.edit,
            isDark: isDark,
            onTap: () => _openEditDialog(index),
          ),
          const SizedBox(width: 8),
          _CardActionButton(
            icon: LucideIcons.trash2,
            isDark: isDark,
            destructive: true,
            onTap: () => _handleDelete(index),
          ),
        ],
      ),
    );
  }
}

// ─── Press-feedback wrapper ──────────────────────────────────────────────────
class _ScaleTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  const _ScaleTap({required this.child, required this.onTap, this.borderRadius});

  @override
  State<_ScaleTap> createState() => _ScaleTapState();
}

class _ScaleTapState extends State<_ScaleTap> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _pressed = true),
      onTapUp: widget.onTap == null ? null : (_) => setState(() => _pressed = false),
      onTapCancel: widget.onTap == null ? null : () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: widget.child,
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final bool accent;
  final VoidCallback onTap;
  const _HeaderIconButton({required this.icon, required this.isDark, required this.onTap, this.accent = false});

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFFFFD700);
    return _ScaleTap(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: accent
              ? accentColor.withValues(alpha: 0.12)
              : (isDark ? const Color(0xFF18181B) : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: accent
                ? accentColor.withValues(alpha: 0.3)
                : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
          ),
          boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
        ),
        child: Icon(
          icon,
          size: 20,
          color: accent ? (isDark ? accentColor : const Color(0xFF8A6D00)) : (isDark ? Colors.white : Colors.black),
        ),
      ),
    );
  }
}

class _CardActionButton extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final bool destructive;
  final VoidCallback onTap;
  const _CardActionButton({required this.icon, required this.isDark, required this.onTap, this.destructive = false});

  @override
  Widget build(BuildContext context) {
    return _ScaleTap(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06)),
        ),
        child: Icon(
          icon,
          size: 16,
          color: destructive
              ? const Color(0xFFEF4444)
              : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

class _DialogLabel extends StatelessWidget {
  final String label;
  final bool isDark;
  const _DialogLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: GoogleFonts.montserrat(
          fontSize: 8,
          fontWeight: FontWeight.w900,
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.45),
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _DialogInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool isDark;
  final ValueChanged<String>? onChanged;
  const _DialogInput({required this.controller, required this.hint, required this.isDark, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: GoogleFonts.montserrat(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: isDark ? Colors.white : Colors.black,
        ),
        decoration: InputDecoration(
          isCollapsed: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: InputBorder.none,
          hintText: hint,
          hintStyle: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }
}

class _RelationDropdown extends StatelessWidget {
  final bool isDark;
  final String value;
  final ValueChanged<String> onChanged;
  const _RelationDropdown({required this.isDark, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const predefined = ['Spouse', 'Son', 'Daughter', 'Parent'];
    final isCustom = value.isNotEmpty && !predefined.contains(value);
    final selected = predefined.contains(value) ? value : (isCustom ? 'Other' : null);

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: selected,
          hint: Text(
            'Select Relation',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.3),
            ),
          ),
          icon: Icon(LucideIcons.chevronDown, size: 16, color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.4)),
          dropdownColor: isDark ? const Color(0xFF18181B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : Colors.black,
          ),
          items: [
            ...predefined.map((p) => DropdownMenuItem(value: p, child: Text(p))),
            const DropdownMenuItem(value: 'Other', child: Text('Other / Custom')),
          ],
          onChanged: (val) {
            if (val == null) return;
            if (val == 'Other') {
              // Clear so custom input becomes visible; keep empty until typed.
              onChanged(isCustom ? value : '');
            } else {
              onChanged(val);
            }
          },
        ),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  final String label;
  final bool isDark;
  final bool filled;
  final bool destructive;
  final VoidCallback? onTap;
  const _DialogButton({
    required this.label,
    required this.isDark,
    required this.filled,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    if (filled) {
      bg = destructive ? const Color(0xFFEF4444) : (isDark ? Colors.white : Colors.black);
      fg = destructive ? Colors.white : (isDark ? Colors.black : Colors.white);
    } else {
      bg = Colors.transparent;
      fg = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6);
    }

    return _ScaleTap(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Opacity(
        opacity: onTap == null ? 0.6 : 1.0,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: filled
                ? null
                : Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.12)),
          ),
          child: Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: fg,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}
