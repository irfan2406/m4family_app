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

class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  ConsumerState<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends ConsumerState<ProfileSettingsScreen> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late DateTime? _dob;
  
  List<Map<String, dynamic>> _familyMembers = [];
  bool _isEditing = false;
  bool _isSaving = false;
  File? _pickedImage;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _firstNameController = TextEditingController(text: user?['firstName'] ?? '');
    _lastNameController = TextEditingController(text: user?['lastName'] ?? '');
    _emailController = TextEditingController(text: user?['email'] ?? '');
    _phoneController = TextEditingController(text: user?['phone'] ?? '');
    _addressController = TextEditingController(text: user?['address'] ?? '');
    _dob = user?['dob'] != null ? DateTime.parse(user?['dob']) : null;
    
    if (user?['familyDetails'] != null && user?['familyDetails'] is List) {
      _familyMembers = List<Map<String, dynamic>>.from(user!['familyDetails']);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _pickedImage = File(image.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      
      // 1. Upload Avatar if picked
      String? avatarUrl;
      if (_pickedImage != null) {
        final response = await apiClient.uploadAvatar(_pickedImage!.path);
        if (response.data['status'] == true) {
          avatarUrl = response.data['data']['url'];
        }
      }

      // 2. Update Profile
      final Map<String, dynamic> updateData = {
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'email': _emailController.text,
        'address': _addressController.text,
        'dob': _dob?.toIso8601String(),
        'familyDetails': _familyMembers,
      };
      
      if (avatarUrl != null) updateData['avatarUrl'] = avatarUrl;

      await apiClient.updateMe(updateData);
      
      // 3. Refresh Auth State
      await ref.read(authProvider.notifier).fetchMe();

      if (mounted) {
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final String currentAvatarUrl = user?['avatarUrl'] ?? '';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildAvatarSection(currentAvatarUrl),
                      const SizedBox(height: 40),
                      _buildFormSection(),
                      const SizedBox(height: 30),
                      _buildFamilySection(),
                      const SizedBox(height: 40),
                      _buildSecurityActions(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(LucideIcons.chevronLeft, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
              ),
              const SizedBox(width: 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SETTINGS',
                    style: GoogleFonts.montserrat(
                      fontSize: 24,
                      fontWeight: FontWeight.w300,
                      color: Theme.of(context).colorScheme.onSurface,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    'MANAGE ACCOUNT',
                    style: GoogleFonts.montserrat(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      letterSpacing: 4,
                    ),
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            onPressed: () {
              if (_isEditing) {
                _saveProfile();
              } else {
                setState(() => _isEditing = true);
              }
            },
            icon: _isSaving 
              ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.onSurface))
              : Icon(_isEditing ? LucideIcons.check : LucideIcons.pencil, 
                     color: _isEditing ? Colors.greenAccent : Theme.of(context).colorScheme.onSurface.withOpacity(0.7), size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection(String currentAvatarUrl) {
    final String initial = _firstNameController.text.isNotEmpty ? _firstNameController.text[0] : 'U';

    return Center(
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black).withOpacity(0.08), width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 30,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(65),
              child: _pickedImage != null 
                ? Image.file(_pickedImage!, fit: BoxFit.cover)
                : currentAvatarUrl.isNotEmpty
                  ? Image.network(ref.read(apiClientProvider).resolveUrl(currentAvatarUrl), fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.black.withOpacity(0.05),
                        child: const Center(child: Icon(LucideIcons.user, color: Colors.black12, size: 40)),
                      ),
                    )
                  : Container(
                      color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black).withOpacity(0.03),
                      child: Center(
                        child: Text(
                          initial.toUpperCase(),
                          style: GoogleFonts.montserrat(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
                            fontSize: 48,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          if (_isEditing)
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.camera, color: Colors.black, size: 18),
              ),
            ),
        ],
      ),
    ).animate().scale(delay: 200.ms);
  }

  Widget _buildFormSection() {
    return Column(
      children: [
        _buildGlassField('First Name', _firstNameController, LucideIcons.user),
        const SizedBox(height: 20),
        _buildGlassField('Last Name', _lastNameController, LucideIcons.user),
        const SizedBox(height: 20),
        _buildGlassField('Email Address', _emailController, LucideIcons.mail, enabled: _isEditing),
        const SizedBox(height: 20),
        _buildGlassField('Phone Number', _phoneController, LucideIcons.phone, enabled: false), // Phone usually fixed to account
        const SizedBox(height: 20),
        _buildDatePickerField(),
        const SizedBox(height: 20),
        _buildGlassField('Current Address', _addressController, LucideIcons.mapPin, maxLines: 3),
      ],
    );
  }

  Widget _buildGlassField(String label, TextEditingController controller, IconData icon, {bool enabled = true, int maxLines = 1}) {
    final bool canEdit = _isEditing && enabled;
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(canEdit ? 0.1 : 0.04)),
      ),
      child: TextField(
        controller: controller,
        enabled: canEdit,
        maxLines: maxLines,
        style: GoogleFonts.montserrat(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
        decoration: InputDecoration(
          labelText: label.toUpperCase(),
          labelStyle: GoogleFonts.montserrat(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3), fontSize: 10, fontWeight: FontWeight.w800),
          prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2), size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),
      ),
    );
  }

  Widget _buildDatePickerField() {
    final String dateStr = _dob != null ? DateFormat('MMM dd, yyyy').format(_dob!) : 'NOT PROVIDED';
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: _isEditing ? () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _dob ?? DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: Theme.of(context).colorScheme.onSurface,
                onPrimary: Theme.of(context).colorScheme.surface,
              ),
            ),
            child: child!,
          ),
        );
        if (date != null) setState(() => _dob = date);
      } : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.02),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(_isEditing ? 0.1 : 0.04)),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.calendar, color: Colors.white24, size: 18),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DATE OF BIRTH',
                  style: GoogleFonts.montserrat(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3), fontSize: 10, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  dateStr.toUpperCase(),
                  style: GoogleFonts.montserrat(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'FAMILY DETAILS',
              style: GoogleFonts.montserrat(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            if (_isEditing)
              IconButton(
                onPressed: _addFamilyMember,
                icon: Icon(LucideIcons.plusCircle, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), size: 20),
              ),
          ],
        ),
        const SizedBox(height: 15),
        ..._familyMembers.map((member) => _buildFamilyMemberItem(member)).toList(),
      ],
    );
  }

  Widget _buildFamilyMemberItem(Map<String, dynamic> member) {
    final int index = _familyMembers.indexOf(member);
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.04)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(LucideIcons.users, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), size: 18),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (member['name'] ?? 'MEMBER').toString().toUpperCase(),
                  style: GoogleFonts.montserrat(color: Theme.of(context).colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.w800),
                ),
                Text(
                  (member['relation'] ?? 'Relation').toString().toUpperCase(),
                  style: GoogleFonts.montserrat(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          if (_isEditing)
            IconButton(
              onPressed: () => setState(() => _familyMembers.removeAt(index)),
              icon: const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 16),
            ),
        ],
      ),
    );
  }

  void _addFamilyMember() {
    final nameCtrl = TextEditingController();
    String relation = 'Spouse';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          title: Text('ADD FAMILY MEMBER', 
                style: GoogleFonts.montserrat(color: Theme.of(context).colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w900)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'Name', 
                  labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1))),
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: relation,
                dropdownColor: Theme.of(context).scaffoldBackgroundColor,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'Relation', 
                  labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1))),
                ),
                items: ['Spouse', 'Son', 'Daughter', 'Parent', 'Other']
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (val) => setDialogState(() => relation = val!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
            TextButton(
              onPressed: () {
                if (nameCtrl.text.isNotEmpty) {
                  setState(() {
                    _familyMembers.add({'name': nameCtrl.text, 'relation': relation});
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('ADD'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityActions() {
    return Column(
      children: [
        _buildActionButton(LucideIcons.lock, 'UPDATE SECURITY PASSWORD', Theme.of(context).colorScheme.onSurface, () {}),
        const SizedBox(height: 15),
        _buildActionButton(LucideIcons.userX, 'DEACTIVATE ACCOUNT', Colors.redAccent, _showDeactivateDialog),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color.withOpacity(0.7), size: 18),
            const SizedBox(width: 15),
            Text(
              label,
              style: GoogleFonts.montserrat(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeactivateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text('DEACTIVATE ACCOUNT', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        content: Text('Are you sure you want to deactivate your account? This action cannot be undone.', 
                 style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () async {
              try {
                await ref.read(apiClientProvider).deleteMe();
                // Logout and navigate home
                await ref.read(authProvider.notifier).logout();
                if (mounted) {
                   Navigator.of(context).popUntil((route) => route.isFirst);
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('DEACTIVATE', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
