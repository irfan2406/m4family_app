import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/core/providers/theme_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:m4_mobile/presentation/widgets/navigation_pill.dart';
import 'package:m4_mobile/presentation/widgets/main_shell.dart';

class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  ConsumerState<ProfileSettingsScreen> createState() =>
      _ProfileSettingsScreenState();
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

    _nameController = TextEditingController(
      text:
          user?['fullName'] ??
          '${user?['firstName'] ?? ''} ${user?['lastName'] ?? ''}'.trim(),
    );
    _emailController = TextEditingController(text: user?['email'] ?? '');
    _phoneController = TextEditingController(text: user?['phone'] ?? '');
    _addressController = TextEditingController(text: user?['address'] ?? '');
    _panController = TextEditingController(
      text: (ownerDetails['PAN'] ?? '').toUpperCase(),
    );
    _aadharController = TextEditingController(
      text: ownerDetails['AADHAR'] ?? '',
    );

    if (user?['dob'] != null &&
        user!['dob'].toString().isNotEmpty &&
        !user['dob'].toString().startsWith('0000')) {
      try {
        _selectedDob = DateTime.parse(user['dob']);
        _dobController = TextEditingController(
          text: DateFormat('dd MMM yyyy').format(_selectedDob!).toUpperCase(),
        );
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

    _familyMembers = List<Map<String, dynamic>>.from(
      user?['familyMembers'] ?? user?['familyDetails'] ?? [],
    );
  }

  Map<String, String> _normalizeOwnerDetails(dynamic raw) {
    if (raw == null || raw is! Map) return {'PAN': '', 'AADHAR': ''};
    final map = Map<String, dynamic>.from(raw);
    return {
      'PAN': map['PAN']?.toString() ?? map['pan']?.toString() ?? '',
      'AADHAR':
          map['AADHAR']?.toString() ??
          map['aadhaar']?.toString() ??
          map['aadhar']?.toString() ??
          '',
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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    DateTime tempDate = _selectedDob ?? DateTime(2000);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: 350,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF09090B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(25, 20, 25, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "SELECT BIRTHDAY",
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.black.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "DONE",
                          style: GoogleFonts.dmSerifDisplay(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.blue,
                          ),
                        ),
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
                      dateTimePickerTextStyle: GoogleFonts.dmSerifDisplay(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: tempDate,
                    maximumDate: DateTime.now(),
                    onDateTimeChanged: (DateTime picked) {
                      setState(() {
                        _selectedDob = picked;
                        _dobController.text = DateFormat(
                          'dd MMM yyyy',
                        ).format(picked).toUpperCase();
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    try {
      final nameParts = _nameController.text.trim().split(" ");
      final firstName = nameParts[0];
      final lastName = nameParts.length > 1
          ? nameParts.sublist(1).join(" ")
          : "";

      final user = ref.read(authProvider).user;
      final existingOwnerDetails = user?['ownerDetails'] is Map
          ? Map<String, dynamic>.from(user!['ownerDetails'])
          : <String, dynamic>{};

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
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

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
          const SnackBar(
            backgroundColor: Color(0xFFE24B4A),
            content: Text('Failed to upload profile picture'),
          ),
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
      backgroundColor: isDark
          ? const Color(0xFF09090B)
          : const Color(0xFFF8FAFC),
      extendBody: true,
      bottomNavigationBar: NavigationPill(
        currentIndex: -1,
        onTap: (i) {
          ref.read(navigationProvider.notifier).state = i;
          Navigator.of(context).popUntil((r) => r.isFirst);
        },
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(isDark),
            if (_isSaving)
              LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: Colors.transparent,
                color: isDark ? Colors.white24 : Colors.black26,
              ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAvatarSection(isDark),
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 16),
                      child: Text(
                        'ACCOUNT DETAILS',
                        style: GoogleFonts.dmSerifDisplay(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white38 : Colors.black38,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    // Web parity: ALL fields inside ONE card with a single shadow.
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF18181B) : Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: (isDark ? Colors.white : Colors.black)
                              .withOpacity(0.05),
                        ),
                        boxShadow: isDark
                            ? []
                            : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 30,
                                  offset: const Offset(0, 15),
                                ),
                              ],
                      ),
                      child: Column(
                        children: [
                          _buildField(
                            "FULL NAME",
                            _nameController,
                            isDark,
                            enabled: _isEditing,
                          ),
                          const SizedBox(height: 20),
                          _buildField(
                            "EMAIL ADDRESS",
                            _emailController,
                            isDark,
                            enabled: _isEditing,
                          ),
                          const SizedBox(height: 20),
                          _buildField(
                            "PHONE NUMBER",
                            _phoneController,
                            isDark,
                            enabled: _isEditing,
                          ),
                          const SizedBox(height: 20),
                          _buildDateField(
                            "DATE OF BIRTH",
                            _dobController,
                            isDark,
                          ),
                          const SizedBox(height: 20),
                          _buildField(
                            "CURRENT ADDRESS",
                            _addressController,
                            isDark,
                            enabled: _isEditing,
                          ),
                          const SizedBox(height: 20),
                          _buildField(
                            "PAN",
                            _panController,
                            isDark,
                            enabled: _isEditing,
                            capitalization: TextCapitalization.characters,
                          ),
                          const SizedBox(height: 20),
                          _buildField(
                            "AADHAAR",
                            _aadharController,
                            isDark,
                            enabled: _isEditing,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildNotificationPreferences(isDark),
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
    );
  }

  // Web parity: a profile header CARD — avatar (with dark camera badge),
  // the name, and the email, all centered in a white rounded card.
  Widget _buildAvatarSection(bool isDark) {
    final apiClient = ref.read(apiClientProvider);
    final String name = _nameController.text;
    final String email = _emailController.text;
    final String initial = name.isNotEmpty ? name[0].toUpperCase() : "U";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : Colors.white,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: (isDark ? Colors.white : Colors.black).withOpacity(
                      0.1,
                    ),
                    width: 2,
                  ),
                  boxShadow: isDark
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                ),
                child: ClipOval(
                  child: _isUploadingAvatar
                      ? Container(
                          color: isDark
                              ? Colors.white10
                              : Colors.black.withOpacity(0.05),
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _avatarUrl != null
                      ? CachedNetworkImage(
                          imageUrl: apiClient.resolveUrl(_avatarUrl),
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: isDark
                                ? Colors.white10
                                : Colors.black.withOpacity(0.05),
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (_, __, ___) =>
                              _buildAvatarPlaceholder(isDark, initial),
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
                        // Web parity: bg-primary (dark) badge, not blue.
                        color: isDark ? Colors.white : Colors.black,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF18181B)
                              : Colors.white,
                          width: 3,
                        ),
                      ),
                      child: Icon(
                        LucideIcons.camera,
                        color: isDark ? Colors.black : Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            name.toUpperCase(),
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : Colors.black,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email.toUpperCase(),
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white38 : Colors.black45,
              letterSpacing: 2,
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
          style: GoogleFonts.dmSerifDisplay(
            textStyle: const TextStyle(inherit: true),
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
                style: GoogleFonts.dmSerifDisplay(
                  textStyle: const TextStyle(inherit: true),
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
            // Web parity: black pill with a save (disk) icon + "SAVE".
            TextButton.icon(
              onPressed: _handleSave,
              icon: Icon(
                LucideIcons.save,
                size: 14,
                color: isDark ? Colors.black : Colors.white,
              ),
              style: TextButton.styleFrom(
                backgroundColor: isDark ? Colors.white : Colors.black,
                foregroundColor: isDark ? Colors.black : Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              label: Text(
                'SAVE',
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    bool isDark, {
    bool enabled = true,
    TextCapitalization capitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: GoogleFonts.dmSerifDisplay(
              textStyle: const TextStyle(inherit: true),
              fontSize: 8,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white38 : Colors.black38,
              letterSpacing: 1,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            // Flat inset input — the single shadow lives on the outer card.
            color: isDark
                ? Colors.white.withOpacity(0.03)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
            ),
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            textCapitalization: capitalization,
            style: GoogleFonts.dmSerifDisplay(
              textStyle: const TextStyle(inherit: true),
              fontSize: 13,
              fontWeight: FontWeight.w800,
              // Keep values dark/readable even when not editing.
              color: enabled
                  ? (isDark ? Colors.white : Colors.black)
                  : (isDark ? Colors.white70 : Colors.black87),
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(
    String label,
    TextEditingController controller,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: GoogleFonts.dmSerifDisplay(
              textStyle: const TextStyle(inherit: true),
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
              // Flat inset input — the single shadow lives on the outer card.
              color: isDark
                  ? Colors.white.withOpacity(0.03)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Text(
                      controller.text.isEmpty ? "SELECT DATE" : controller.text,
                      style: GoogleFonts.dmSerifDisplay(
                        textStyle: const TextStyle(inherit: true),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _isEditing
                            ? (isDark ? Colors.white : Colors.black)
                            : (isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Icon(
                    LucideIcons.calendar,
                    color: isDark ? Colors.white38 : Colors.black38,
                    size: 16,
                  ),
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
          style: GoogleFonts.dmSerifDisplay(
            textStyle: const TextStyle(inherit: true),
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white38 : Colors.black38,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        // Web parity: all three toggles inside ONE card.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF18181B) : Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
            ),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
          ),
          child: Column(
            children: [
              _buildToggleTile(
                "PUSH NOTIFICATIONS",
                "RECEIVE ALERTS ON YOUR DEVICE",
                _pushNotifications,
                isDark,
                (val) => setState(() => _pushNotifications = val),
              ),
              _buildToggleTile(
                "EMAIL UPDATES",
                "PROPERTY NEWS AND OFFERS",
                _emailUpdates,
                isDark,
                (val) => setState(() => _emailUpdates = val),
              ),
              _buildToggleTile(
                "SMS ALERTS",
                "PAYMENT AND BOOKING UPDATES",
                _smsAlerts,
                isDark,
                (val) => setState(() => _smsAlerts = val),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToggleTile(
    String title,
    String subtitle,
    bool value,
    bool isDark,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
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

  // Web parity: a plain red ghost "Deactivate Account" text button — no
  // "Security & Access" label, no border, no icon.
  Widget _buildAccountManagement(bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: () => GoRouter.of(context).push('/profile/deactivate'),
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFFEF4444).withOpacity(0.75),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          'DEACTIVATE ACCOUNT',
          style: GoogleFonts.dmSerifDisplay(
            textStyle: const TextStyle(inherit: true),
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;
  const _IconButton({
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF18181B) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
          ),
        ),
        child: Icon(
          icon,
          color: isDark ? Colors.white54 : Colors.black54,
          size: 20,
        ),
      ),
    );
  }
}
