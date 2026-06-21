import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

/// Investor profile details — parity with web `app/investor/profile/details/page.tsx`.
/// Edit mode for name, email, phone, address, bio + avatar upload (camera button).
/// Saves to `/auth/me`. Follows M4 conventions.
class InvestorProfileDetailsScreen extends ConsumerStatefulWidget {
  const InvestorProfileDetailsScreen({super.key});

  @override
  ConsumerState<InvestorProfileDetailsScreen> createState() => _InvestorProfileDetailsScreenState();
}

class _InvestorProfileDetailsScreenState extends ConsumerState<InvestorProfileDetailsScreen> {
  static const _gold = Color(0xFFFFD700);

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _bio = TextEditingController();

  bool _loading = true;
  bool _editing = false;
  bool _saving = false;
  bool _uploadingAvatar = false;
  String? _avatarUrl;

  // Snapshot for cancel.
  String _snapName = '';
  String _snapEmail = '';
  String _snapPhone = '';
  String _snapAddress = '';
  String _snapBio = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    _bio.dispose();
    super.dispose();
  }

  void _applyUser(Map<String, dynamic> u) {
    final fn = u['fullName']?.toString().trim();
    final first = u['firstName']?.toString() ?? '';
    final last = u['lastName']?.toString() ?? '';
    final combined = '$first $last'.trim();
    _name.text = (fn != null && fn.isNotEmpty) ? fn : combined;
    _email.text = u['email']?.toString() ?? '';
    _phone.text = u['phone']?.toString() ?? '';
    _address.text = u['address']?.toString() ?? '';
    _bio.text = u['bio']?.toString() ?? '';
    final av = u['avatarUrl'] ?? u['avatar'];
    _avatarUrl = av?.toString();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ref.read(apiClientProvider).getCurrentUser();
      final body = res.data;
      Map<String, dynamic>? u;
      if (body is Map && body['data'] is Map) {
        u = Map<String, dynamic>.from(body['data'] as Map);
      }
      u ??= ref.read(authProvider).user;
      if (u != null) _applyUser(u);
    } catch (e) {
      debugPrint('Investor profile details load: $e');
      final u = ref.read(authProvider).user;
      if (u != null) _applyUser(u);
    }
    if (mounted) setState(() => _loading = false);
  }

  void _enterEdit() {
    _snapName = _name.text;
    _snapEmail = _email.text;
    _snapPhone = _phone.text;
    _snapAddress = _address.text;
    _snapBio = _bio.text;
    setState(() => _editing = true);
  }

  void _cancelEdit() {
    _name.text = _snapName;
    _email.text = _snapEmail;
    _phone.text = _snapPhone;
    _address.text = _snapAddress;
    _bio.text = _snapBio;
    setState(() => _editing = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final trimmed = _name.text.trim();
      String firstName = trimmed;
      String lastName = '';
      final sp = trimmed.indexOf(' ');
      if (sp > 0) {
        firstName = trimmed.substring(0, sp).trim();
        lastName = trimmed.substring(sp + 1).trim();
      }
      final res = await ref.read(apiClientProvider).updateMe({
        'firstName': firstName,
        if (lastName.isNotEmpty) 'lastName': lastName,
        'phone': _phone.text.trim(),
        'address': _address.text.trim(),
        'bio': _bio.text.trim(),
      });
      if (!mounted) return;
      final ok = res.data is Map && (res.data as Map)['status'] == true;
      if (ok) {
        await ref.read(authProvider.notifier).fetchMe();
        if (mounted) {
          setState(() => _editing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
        }
      } else {
        final msg = res.data is Map ? (res.data as Map)['message']?.toString() : null;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg ?? 'Update failed')));
      }
    } on DioException catch (e) {
      if (mounted) {
        final m = e.response?.data is Map ? (e.response!.data as Map)['message']?.toString() : null;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m ?? e.message ?? 'Network error')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 88,
    );
    if (x == null || !mounted) return;
    final len = await File(x.path).length();
    if (len > 2 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File too large (max 2MB)')),
        );
      }
      return;
    }
    setState(() => _uploadingAvatar = true);
    try {
      final res = await ref.read(apiClientProvider).uploadAvatar(x.path);
      final body = res.data;
      String? newUrl;
      if (body is Map && body['data'] is Map) {
        final d = body['data'] as Map;
        newUrl = d['fileUrl']?.toString() ?? d['url']?.toString();
      }
      if (newUrl == null || newUrl.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Upload failed')),
          );
        }
        return;
      }
      final patch = await ref.read(apiClientProvider).updateMe({'avatarUrl': newUrl});
      final ok = patch.data is Map && (patch.data as Map)['status'] == true;
      if (ok) {
        setState(() => _avatarUrl = newUrl);
        await ref.read(authProvider.notifier).fetchMe();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile photo updated')),
          );
        }
      } else {
        final msg = patch.data is Map ? (patch.data as Map)['message']?.toString() : null;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg ?? 'Update failed')));
        }
      }
    } on DioException catch (e) {
      if (mounted) {
        final m = e.response?.data is Map ? (e.response!.data as Map)['message']?.toString() : null;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m ?? 'Upload failed')));
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.black : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black;
    final muted = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5);
    final card = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;
    final border = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06);

    if (_loading) {
      return Scaffold(
        backgroundColor: bg,
        body: const Center(
          child: CircularProgressIndicator(color: M4Theme.premiumBlue),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(textPrimary, muted, card, border),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _avatarSection(),
                    const SizedBox(height: 28),
                    _field(
                      label: 'FULL NAME',
                      controller: _name,
                      icon: LucideIcons.user,
                      textPrimary: textPrimary,
                      muted: muted,
                      isDark: isDark,
                      border: border,
                    ),
                    const SizedBox(height: 16),
                    _field(
                      label: 'EMAIL ADDRESS',
                      controller: _email,
                      icon: LucideIcons.mail,
                      keyboardType: TextInputType.emailAddress,
                      textPrimary: textPrimary,
                      muted: muted,
                      isDark: isDark,
                      border: border,
                    ),
                    const SizedBox(height: 16),
                    _field(
                      label: 'PHONE NUMBER',
                      controller: _phone,
                      icon: LucideIcons.phone,
                      keyboardType: TextInputType.phone,
                      textPrimary: textPrimary,
                      muted: muted,
                      isDark: isDark,
                      border: border,
                    ),
                    const SizedBox(height: 16),
                    _field(
                      label: 'MAILING ADDRESS',
                      controller: _address,
                      icon: LucideIcons.mapPin,
                      maxLines: 3,
                      textPrimary: textPrimary,
                      muted: muted,
                      isDark: isDark,
                      border: border,
                    ),
                    const SizedBox(height: 16),
                    _field(
                      label: 'BIO',
                      controller: _bio,
                      icon: LucideIcons.fileText,
                      maxLines: 4,
                      textPrimary: textPrimary,
                      muted: muted,
                      isDark: isDark,
                      border: border,
                    ),
                    if (_editing) ...[
                      const SizedBox(height: 24),
                      _actionRow(textPrimary, border),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(Color textPrimary, Color muted, Color card, Color border) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Row(
        children: [
          Material(
            color: card,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: () => context.canPop() ? context.pop() : context.go('/investor/home'),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: border),
                ),
                child: Icon(LucideIcons.arrowLeft, size: 18, color: textPrimary),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MY PROFILE',
                  style: GoogleFonts.montserrat(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'MANAGE YOUR PERSONAL DETAILS',
                  style: GoogleFonts.montserrat(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: muted,
                  ),
                ),
              ],
            ),
          ),
          if (!_editing)
            Material(
              color: card,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: _enterEdit,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: border),
                  ),
                  child: Icon(LucideIcons.edit2, size: 16, color: muted),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _avatarSection() {
    return Center(
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _gold.withValues(alpha: 0.2),
                      _gold.withValues(alpha: 0.1),
                    ],
                  ),
                  border: Border.all(color: _gold.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: _gold.withValues(alpha: 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(23),
                  child: _avatarUrl != null && _avatarUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: ref.read(apiClientProvider).resolveUrl(_avatarUrl!),
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                          memCacheWidth: 192,
                          memCacheHeight: 192,
                          fadeInDuration: Duration.zero,
                          errorWidget: (_, __, ___) =>
                              const Icon(LucideIcons.user, size: 40, color: _gold),
                        )
                      : const Center(child: Icon(LucideIcons.user, size: 40, color: _gold)),
                ),
              ),
              if (_uploadingAvatar)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: Colors.black54,
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              if (_editing)
                Positioned(
                  bottom: -8,
                  right: -8,
                  child: Material(
                    color: _gold,
                    shape: const CircleBorder(),
                    elevation: 4,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _uploadingAvatar ? null : _pickAndUploadAvatar,
                      child: const Padding(
                        padding: EdgeInsets.all(9),
                        child: Icon(LucideIcons.camera, size: 16, color: Colors.black),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _gold.withValues(alpha: 0.2)),
            ),
            child: Text(
              'PLATINUM MEMBER',
              style: GoogleFonts.montserrat(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                color: _gold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required Color textPrimary,
    required Color muted,
    required bool isDark,
    required Color border,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    final enabled = _editing;
    final fillColor = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02);
    final borderColor = enabled ? _gold.withValues(alpha: 0.5) : border;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: muted,
            ),
          ),
        ),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: enabled ? textPrimary : textPrimary.withValues(alpha: 0.8),
          ),
          decoration: InputDecoration(
            isDense: true,
            prefixIcon: Padding(
              padding: EdgeInsets.only(left: 12, right: 8, bottom: maxLines > 1 ? (maxLines - 1) * 18.0 : 0),
              child: Icon(icon, size: 16, color: muted),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 20),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
            filled: true,
            fillColor: fillColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: borderColor),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _gold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionRow(Color textPrimary, Color border) {
    return Row(
      children: [
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _saving ? null : _cancelEdit,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: border),
                ),
                child: Text(
                  'CANCEL',
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Material(
            color: _gold,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: _saving ? null : _save,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                height: 52,
                alignment: Alignment.center,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : Text(
                        'SAVE CHANGES',
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: Colors.black,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
