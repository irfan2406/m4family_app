import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:image_picker/image_picker.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/core/providers/theme_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  ConsumerState<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends ConsumerState<ProfileSettingsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _dobController;
  late TextEditingController _addressController;
  late TextEditingController _panController;
  late TextEditingController _aadharController;

  bool _pushNotifications = true;
  bool _emailUpdates = true;
  bool _smsAlerts = true;
  bool _isSaving = false;
  bool _isEditing = false;
  bool _isUploadingAvatar = false;
  DateTime? _selectedDob;
  List<Map<String, dynamic>> _familyMembers = [];
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = ref.read(authProvider).user;
    final ownerDetails = _normalizeOwnerDetails(user?['ownerDetails']);
    
    _nameController = TextEditingController(text: user?['fullName'] ?? '${user?['firstName'] ?? ''} ${user?['lastName'] ?? ''}'.trim());
    _emailController = TextEditingController(text: user?['email'] ?? '');
    _phoneController = TextEditingController(text: user?['phone'] ?? '');
    _addressController = TextEditingController(text: user?['address'] ?? '');
    _panController = TextEditingController(text: (ownerDetails['PAN'] ?? '').toUpperCase());
    _aadharController = TextEditingController(text: ownerDetails['AADHAR'] ?? '');
    
    if (user?['dob'] != null && user!['dob'].toString().isNotEmpty && !user!['dob'].toString().startsWith('0000')) {
      try {
        _selectedDob = DateTime.parse(user!['dob']);
        _dobController = TextEditingController(text: DateFormat('dd MMM yyyy').format(_selectedDob!).toUpperCase());
      } catch (e) {
        _dobController = TextEditingController();
      }
    } else {
      _dobController = TextEditingController();
    }

    _pushNotifications = user?['pushNotifications'] ?? true;
    _emailUpdates = user?['emailUpdates'] ?? true;
    _smsAlerts = user?['smsAlerts'] ?? true;
    _avatarUrl = user?['avatarUrl'];
    
    _familyMembers = List<Map<String, dynamic>>.from(user?['familyMembers'] ?? user?['familyDetails'] ?? []);
  }

  Map<String, String> _normalizeOwnerDetails(dynamic raw) {
    if (raw == null || raw is! Map) return {'PAN': '', 'AADHAR': ''};
    final map = Map<String, dynamic>.from(raw);
    return {
      'PAN': map['PAN']?.toString() ?? map['pan']?.toString() ?? '',
      'AADHAR': map['AADHAR']?.toString() ?? map['aadhaar']?.toString() ?? map['aadhar']?.toString() ?? '',
    };
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _panController.dispose();
    _aadharController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    if (!_isEditing) return;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Colors.white,
            onPrimary: Colors.black,
            surface: Color(0xFF18181B),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedDob = picked;
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    try {
      final nameParts = _nameController.text.trim().split(" ");
      final firstName = nameParts[0];
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(" ") : "";

      final user = ref.read(authProvider).user;
      final existingOwnerDetails = user?['ownerDetails'] is Map ? Map<String, dynamic>.from(user!['ownerDetails']) : <String, dynamic>{};

      final updateData = {
        'firstName': firstName,
        'lastName': lastName,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
        'dob': _selectedDob?.toIso8601String(),
        'familyDetails': _familyMembers,
        'familyMembers': _familyMembers,
        'ownerDetails': {
          ...existingOwnerDetails,
          'PAN': _panController.text,
          'AADHAR': _aadharController.text,
        },
        'pushNotifications': _pushNotifications,
        'emailUpdates': _emailUpdates,
        'smsAlerts': _smsAlerts,
      };
      
      final res = await ref.read(apiClientProvider).updateMe(updateData);
      if (res.data['status'] == true) {
        await ref.read(authProvider.notifier).fetchMe();
        setState(() => _isEditing = false);
      }
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (image == null) return;

    setState(() => _isUploadingAvatar = true);
    try {
      final res = await ref.read(apiClientProvider).uploadAvatar(image.path);
      if (res.data['status'] == true && res.data['data'] != null) {
        final newUrl = res.data['data']['fileUrl'];
        // Update user profile with new avatar URL
        await ref.read(apiClientProvider).updateMe({'avatarUrl': newUrl});
        await ref.read(authProvider.notifier).fetchMe();
        setState(() => _avatarUrl = newUrl);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload profile picture')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF09090B) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAvatarSection(isDark),
                    const SizedBox(height: 32),
                    _buildField("FULL NAME", _nameController, isDark, enabled: _isEditing),
                    const SizedBox(height: 24),
                    _buildField("EMAIL ADDRESS", _emailController, isDark, enabled: _isEditing),
                    const SizedBox(height: 24),
                    _buildField("PHONE NUMBER", _phoneController, isDark, enabled: _isEditing),
                    const SizedBox(height: 24),
                    _buildDateField("DATE OF BIRTH", _dobController, isDark),
                    const SizedBox(height: 24),
                    _buildField("CURRENT ADDRESS", _addressController, isDark, enabled: _isEditing),
                    const SizedBox(height: 24),
                    _buildField("PAN", _panController, isDark, enabled: _isEditing, capitalization: TextCapitalization.characters),
                    const SizedBox(height: 24),
                    _buildField("AADHAAR", _aadharController, isDark, enabled: _isEditing),
                    const SizedBox(height: 40),
                    _buildNotificationPreferences(isDark),
                    const SizedBox(height: 32),
                    _buildFamilyDetailsSection(isDark),
                    const SizedBox(height: 32),
                    _buildAccountManagement(isDark),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _isSaving ? LinearProgressIndicator(minHeight: 2, backgroundColor: Colors.transparent, color: isDark ? Colors.white24 : Colors.black26) : null,
    );
  }

  Widget _buildAvatarSection(bool isDark) {
    final apiClient = ref.read(apiClientProvider);
    final String name = _nameController.text;
    final String initial = name.isNotEmpty ? name[0].toUpperCase() : "U";

    return Center(
      child: Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1), width: 4),
              boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: ClipOval(
              child: _isUploadingAvatar
                  ? Container(
                      color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : _avatarUrl != null
                      ? CachedNetworkImage(
                          imageUrl: apiClient.resolveUrl(_avatarUrl),
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                          errorWidget: (_, __, ___) => _buildAvatarPlaceholder(isDark, initial),
                        )
                      : _buildAvatarPlaceholder(isDark, initial),
            ),
          ),
          if (!_isUploadingAvatar)
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _pickAndUploadAvatar,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: isDark ? const Color(0xFF09090B) : Colors.white, width: 3),
                  ),
                  child: const Icon(LucideIcons.camera, color: Colors.white, size: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder(bool isDark, String initial) {
    return Container(
      color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.montserrat(textStyle: const TextStyle(inherit: true), 
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          _IconButton(
            icon: LucideIcons.chevronLeft,
            isDark: isDark,
            onTap: () => Navigator.pop(context),
          ),
          Expanded(
            child: Center(
              child: Text(
                'SETTINGS',
                style: GoogleFonts.montserrat(textStyle: const TextStyle(inherit: true), 
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          if (!_isEditing)
            _IconButton(
              icon: LucideIcons.edit2,
              isDark: isDark,
              onTap: () => setState(() => _isEditing = true),
            )
          else
            TextButton(
              onPressed: _handleSave,
              style: TextButton.styleFrom(
                backgroundColor: isDark ? Colors.white : Colors.black,
                foregroundColor: isDark ? Colors.black : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'SAVE',
                style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, bool isDark, {bool enabled = true, TextCapitalization capitalization = TextCapitalization.none}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: GoogleFonts.montserrat(textStyle: const TextStyle(inherit: true), 
              fontSize: 8,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white38 : Colors.black38,
              letterSpacing: 1,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF18181B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
            boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            textCapitalization: capitalization,
            style: GoogleFonts.montserrat(textStyle: const TextStyle(inherit: true), 
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: enabled ? (isDark ? Colors.white : Colors.black) : (isDark ? Colors.white24 : Colors.black26),
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(String label, TextEditingController controller, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: GoogleFonts.montserrat(textStyle: const TextStyle(inherit: true), 
              fontSize: 8,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white38 : Colors.black38,
              letterSpacing: 1,
            ),
          ),
        ),
        GestureDetector(
          onTap: _selectDate,
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF18181B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
              boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Text(
                      controller.text.isEmpty ? "SELECT DATE" : controller.text,
                      style: GoogleFonts.montserrat(textStyle: const TextStyle(inherit: true), 
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _isEditing ? (isDark ? Colors.white : Colors.black) : (isDark ? Colors.white24 : Colors.black26),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Icon(LucideIcons.calendar, color: isDark ? Colors.white38 : Colors.black38, size: 16),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationPreferences(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "NOTIFICATION PREFERENCES",
          style: GoogleFonts.montserrat(textStyle: const TextStyle(inherit: true), 
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white38 : Colors.black38,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        _buildToggleTile("PUSH NOTIFICATIONS", "RECEIVE ALERTS ON YOUR DEVICE", _pushNotifications, isDark, (val) => setState(() => _pushNotifications = val)),
        const SizedBox(height: 12),
        _buildToggleTile("EMAIL UPDATES", "PROPERTY NEWS AND OFFERS", _emailUpdates, isDark, (val) => setState(() => _emailUpdates = val)),
        const SizedBox(height: 12),
        _buildToggleTile("SMS ALERTS", "PAYMENT AND BOOKING UPDATES", _smsAlerts, isDark, (val) => setState(() => _smsAlerts = val)),
      ],
    );
  }

  Widget _buildToggleTile(String title, String subtitle, bool value, bool isDark, Function(bool) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black)),
                Text(subtitle, style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w700, color: isDark ? Colors.white38 : Colors.black38)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: _isEditing ? onChanged : null,
            activeColor: isDark ? Colors.white : Colors.black,
            activeTrackColor: isDark ? Colors.white24 : Colors.black12,
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyDetailsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'FAMILY DETAILS',
              style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w800, color: isDark ? Colors.white38 : Colors.black38, letterSpacing: 1.5),
            ),
            if (_isEditing)
              TextButton(
                onPressed: _addFamilyMember,
                child: Text('ADD MEMBER', style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.blue)),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_familyMembers.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1), style: BorderStyle.solid), // Should be dashed if possible
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(child: Text("NO FAMILY MEMBERS REGISTERED", style: GoogleFonts.montserrat(fontSize: 10, color: isDark ? Colors.white24 : Colors.black26))),
          )
        else
          ..._familyMembers.map((member) => _buildFamilyMemberCard(member, isDark)).toList(),
      ],
    );
  }

  Widget _buildFamilyMemberCard(Map<String, dynamic> member, bool isDark) {
    final index = _familyMembers.indexOf(member);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildFamilyField("NAME", member['name'] ?? '', isDark, (val) => setState(() => _familyMembers[index]['name'] = val))),
              const SizedBox(width: 12),
              Expanded(child: _buildFamilyRelationDropdown(member['relation'] ?? '', isDark, (val) => setState(() => _familyMembers[index]['relation'] = val))),
            ],
          ),
          const SizedBox(height: 12),
          _buildFamilyDateField("DATE OF BIRTH", member['dob'] ?? '', isDark, (val) => setState(() => _familyMembers[index]['dob'] = val)),
          if (_isEditing)
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(LucideIcons.x, color: Colors.redAccent, size: 16),
                onPressed: () => setState(() => _familyMembers.removeAt(index)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFamilyField(String label, String value, bool isDark, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w800, color: isDark ? Colors.white38 : Colors.black38)),
        const SizedBox(height: 4),
        TextField(
          controller: TextEditingController(text: value)..selection = TextSelection.collapsed(offset: value.length),
          enabled: _isEditing,
          onChanged: onChanged,
          style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            filled: true,
            fillColor: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildFamilyRelationDropdown(String value, bool isDark, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("RELATION", style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w800, color: isDark ? Colors.white38 : Colors.black38)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: ['Spouse', 'Son', 'Daughter', 'Parent'].contains(value) ? value : null,
          items: ['Spouse', 'Son', 'Daughter', 'Parent'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 10)))).toList(),
          onChanged: _isEditing ? onChanged : null,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            filled: true,
            fillColor: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          ),
          dropdownColor: isDark ? const Color(0xFF18181B) : Colors.white,
          style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
        ),
      ],
    );
  }

  Widget _buildFamilyDateField(String label, String value, bool isDark, Function(String) onChanged) {
    String displayValue = value;
    if (value.isNotEmpty) {
      try {
        displayValue = DateFormat('dd MMM yyyy').format(DateTime.parse(value)).toUpperCase();
      } catch (_) {}
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.montserrat(textStyle: const TextStyle(inherit: true), fontSize: 8, fontWeight: FontWeight.w800, color: isDark ? Colors.white38 : Colors.black38)),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () async {
            if (!_isEditing) return;
            final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(1900), lastDate: DateTime.now());
            if (date != null) onChanged(DateFormat('yyyy-MM-dd').format(date));
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(value.isEmpty ? "SELECT DATE" : displayValue, style: GoogleFonts.montserrat(textStyle: const TextStyle(inherit: true), fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
          ),
        ),
      ],
    );
  }

  void _addFamilyMember() {
    setState(() {
      _familyMembers.add({'name': '', 'relation': 'Spouse', 'dob': ''});
    });
  }

  Widget _buildAccountManagement(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("SECURITY & ACCESS", style: GoogleFonts.montserrat(textStyle: const TextStyle(inherit: true), fontSize: 9, fontWeight: FontWeight.bold, color: isDark ? Colors.white38 : Colors.black38, letterSpacing: 1.5)),
        const SizedBox(height: 16),
        _buildActionButton("DEACTIVATE ACCOUNT", LucideIcons.userX, isDark, () => GoRouter.of(context).push('/profile/deactivate'), isDestructive: true),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, bool isDark, VoidCallback onTap, {bool isDestructive = false}) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(label, style: GoogleFonts.montserrat(textStyle: const TextStyle(inherit: true), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        style: OutlinedButton.styleFrom(
          foregroundColor: isDestructive ? const Color(0xFFEF4444) : (isDark ? Colors.white70 : Colors.black87),
          side: BorderSide(color: isDestructive ? const Color(0xFFEF4444).withOpacity(0.2) : (isDark ? Colors.white : Colors.black).withOpacity(0.1)),
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: isDark ? const Color(0xFF18181B) : Colors.white,
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;
  const _IconButton({required this.icon, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF18181B) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
        ),
        child: Icon(icon, color: isDark ? Colors.white54 : Colors.black54, size: 20),
      ),
    );
  }
}
