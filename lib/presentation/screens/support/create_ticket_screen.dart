import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/providers/support_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';

class CreateTicketScreen extends ConsumerStatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  ConsumerState<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends ConsumerState<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedCategory = 'Project / Possession';
  String _selectedPriority = 'Medium';
  List<String> _selectedFilePaths = [];
  bool _isCategoryOpen = false;
  bool _isPriorityOpen = false;

  final List<String> _categories = [
    'Payment & Billing',
    'Project / Possession',
    'Legal & Technical',
    'General Query',
  ];

  final List<String> _priorities = ['Low', 'Medium', 'High'];

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(supportProvider.notifier).createTicket(
          subject: _subjectController.text,
          category: _selectedCategory,
          message: _messageController.text,
          attachments: _selectedFilePaths,
        );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ticket raised successfully!')),
        );
        Navigator.pop(context);
      } else {
        final error = ref.read(supportProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error ?? 'Failed to raise ticket')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLoading = ref.watch(supportProvider).isLoading;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF09090B) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                  shape: BoxShape.circle,
                  border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.1)),
                ),
                child: Icon(LucideIcons.chevronLeft, color: isDark ? Colors.white : Colors.black, size: 16),
              ),
            ),
          ),
        ),
        title: Column(
          children: [
            Text(
              'NEW TICKET',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black,
                letterSpacing: 0,
              ),
            ),
            Text(
              'INITIATE SERVICE REQUEST',
              style: GoogleFonts.montserrat(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white38 : Colors.black38,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('SUBJECT', isDark),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _subjectController,
                hint: 'BRIEF DESCRIPTION OF YOUR ISSUE...',
                isDark: isDark,
                validator: (v) => v!.isEmpty ? 'Please enter a subject' : null,
              ),

              const SizedBox(height: 32),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('CATEGORY', isDark),
                        const SizedBox(height: 12),
                        _buildCategoryDropdown(isDark),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('PRIORITY', isDark),
                        const SizedBox(height: 12),
                        _buildPriorityDropdown(isDark),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              _buildLabel('MESSAGE', isDark),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _messageController,
                hint: 'DESCRIBE YOUR REQUEST IN DETAIL...',
                isDark: isDark,
                maxLines: 5,
                validator: (v) => v!.isEmpty ? 'Please enter a message' : null,
              ),

              const SizedBox(height: 32),

              _buildLabel('ATTACHMENTS', isDark),
              const SizedBox(height: 12),
              _buildAttachmentSection(isDark),

              const SizedBox(height: 32),

              // Info Banner (at bottom like web)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.03),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(LucideIcons.info, color: isDark ? Colors.white38 : Colors.black38, size: 20),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'OUR CONCIERGE TEAM TYPICALLY RESPONDS WITHIN 24-48 BUSINESS HOURS. FOR URGENT MATTERS, PLEASE CALL THE DIRECT SERVICE LINE.',
                        style: GoogleFonts.montserrat(
                          color: isDark ? Colors.white38 : Colors.black38,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),
              _buildSubmitButton(isLoading, isDark),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label, bool isDark) {
    return Text(
      label,
      style: GoogleFonts.montserrat(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        color: isDark ? Colors.white24 : Colors.black26,
        letterSpacing: 1,
      ),
    ).animate().fadeIn().slideX(begin: -0.1);
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required bool isDark,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: GoogleFonts.montserrat(color: isDark ? Colors.white : Colors.black, fontSize: 13, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        filled: true,
        fillColor: (isDark ? Colors.white : Colors.black).withOpacity(0.03),
        hintText: hint,
        hintStyle: GoogleFonts.montserrat(color: isDark ? Colors.white24 : Colors.black26, fontSize: 12, fontWeight: FontWeight.w700),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
        ),
        errorStyle: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w700),
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildCategoryDropdown(bool isDark) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() {
            _isCategoryOpen = !_isCategoryOpen;
            _isPriorityOpen = false;
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isCategoryOpen ? const Color(0xFF3B82F6) : (isDark ? Colors.white : Colors.black).withOpacity(0.05),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _selectedCategory.toUpperCase(),
                    style: GoogleFonts.montserrat(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  _isCategoryOpen ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                  color: isDark ? Colors.white24 : Colors.black26,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
        if (_isCategoryOpen)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF111111) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.5 : 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: _categories.map((category) {
                final isSelected = _selectedCategory == category;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedCategory = category;
                      _isCategoryOpen = false;
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF3B82F6).withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      category.toUpperCase(),
                      style: GoogleFonts.montserrat(
                        color: isSelected ? const Color(0xFF3B82F6) : (isDark ? Colors.white38 : Colors.black38),
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.05, end: 0),
      ],
    );
  }

  Widget _buildPriorityDropdown(bool isDark) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() {
            _isPriorityOpen = !_isPriorityOpen;
            _isCategoryOpen = false;
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isPriorityOpen ? const Color(0xFF3B82F6) : (isDark ? Colors.white : Colors.black).withOpacity(0.05),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _selectedPriority.toUpperCase(),
                    style: GoogleFonts.montserrat(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  _isPriorityOpen ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                  color: isDark ? Colors.white24 : Colors.black26,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
        if (_isPriorityOpen)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF111111) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.5 : 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: _priorities.map((priority) {
                final isSelected = _selectedPriority == priority;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedPriority = priority;
                      _isPriorityOpen = false;
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF3B82F6).withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      priority.toUpperCase(),
                      style: GoogleFonts.montserrat(
                        color: isSelected ? const Color(0xFF3B82F6) : (isDark ? Colors.white38 : Colors.black38),
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.05, end: 0),
      ],
    );
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        _selectedFilePaths = [..._selectedFilePaths, ...result.paths.whereType<String>()];
      });
    }
  }

  Widget _buildAttachmentSection(bool isDark) {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickFiles,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.02),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.03),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(LucideIcons.paperclip, color: isDark ? Colors.white24 : Colors.black26, size: 20),
                ),
                const SizedBox(height: 16),
                Text(
                  'ADD FILES (PDF, JPG)',
                  style: GoogleFonts.montserrat(
                    color: isDark ? Colors.white24 : Colors.black26,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_selectedFilePaths.isNotEmpty) ...[
          const SizedBox(height: 16),
          ..._selectedFilePaths.map((path) {
            final fileName = path.split('/').last;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    fileName.toLowerCase().endsWith('.pdf') ? LucideIcons.fileText : LucideIcons.image,
                    color: isDark ? Colors.white38 : Colors.black38,
                    size: 16,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      fileName,
                      style: GoogleFonts.inter(color: isDark ? Colors.white70 : Colors.black87, fontSize: 12, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(LucideIcons.x, color: isDark ? Colors.white38 : Colors.black38, size: 14),
                    onPressed: () {
                      setState(() {
                        _selectedFilePaths.remove(path);
                      });
                    },
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ],
    );
  }

  Widget _buildSubmitButton(bool isLoading, bool isDark) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? Colors.white : Colors.black,
          foregroundColor: isDark ? Colors.black : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(color: isDark ? Colors.black : Colors.white, strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'SUBMIT TICKET REQUEST',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(LucideIcons.send, color: isDark ? Colors.black : Colors.white, size: 16),
                ],
              ),
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2);
  }
}
