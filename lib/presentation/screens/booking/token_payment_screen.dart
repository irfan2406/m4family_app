import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dio/dio.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/screens/projects/project_detail_screen.dart';
import 'package:m4_mobile/presentation/screens/booking/booking_confirmation_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:m4_mobile/presentation/widgets/navigation_pill.dart';
import 'package:m4_mobile/presentation/widgets/main_shell.dart';

class TokenPaymentScreen extends ConsumerStatefulWidget {
  final dynamic project;
  final String projectId;
  final dynamic plan;

  const TokenPaymentScreen({
    super.key,
    required this.projectId,
    this.project,
    this.plan,
  });

  @override
  ConsumerState<TokenPaymentScreen> createState() => _TokenPaymentScreenState();
}

class _TokenPaymentScreenState extends ConsumerState<TokenPaymentScreen> {
  String _selectedMethod = 'upi';
  bool _agreed = false;
  bool _isLoading = false;
  bool _isSuccess = false;

  // Unit selection state
  List<dynamic> _availableUnits = [];
  String _selectedUnitId = '';
  bool _isLoadingUnits = false;
  String? _unitsError;

  // Document management state
  final List<Map<String, String>> _documents = [];
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _fetchAvailableUnits();
  }

  Future<void> _fetchAvailableUnits() async {
    setState(() {
      _isLoadingUnits = true;
      _unitsError = null;
    });
    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.get(
        '/api/inventory',
        queryParameters: {'projectId': widget.projectId, 'status': 'AVAILABLE'},
      );

      if (res.data['status'] == true) {
        setState(() {
          _availableUnits = res.data['data'] ?? [];
          _isLoadingUnits = false;
        });
      } else {
        setState(() {
          _availableUnits = [];
          _isLoadingUnits = false;
        });
      }
    } catch (e) {
      setState(() {
        _unitsError = 'Failed to load available units.';
        _isLoadingUnits = false;
      });
    }
  }

  void _showToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFFE24B4A),
        content: Text(message),
      ),
    );
  }

  Future<void> _pickDocument() async {
    if (_isUploading) return;
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        // Load bytes too: some providers return a content:// URI with no path.
        withData: true,
      );
    } catch (e) {
      _showToast('Could not open the file picker.');
      return;
    }

    if (result == null || result.files.isEmpty) return;
    final picked = result.files.single;
    final fileName = picked.name;

    setState(() => _isUploading = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      // Prefer the file path; fall back to in-memory bytes (content:// URIs).
      MultipartFile multipart;
      if (picked.path != null) {
        multipart = await MultipartFile.fromFile(
          picked.path!,
          filename: fileName,
        );
      } else if (picked.bytes != null) {
        multipart = MultipartFile.fromBytes(picked.bytes!, filename: fileName);
      } else {
        _showToast('Could not read the selected file.');
        setState(() => _isUploading = false);
        return;
      }
      final formData = FormData.fromMap({'file': multipart});
      final res = await apiClient.post('/api/upload', formData);

      final fileUrl = res.data['data']?['fileUrl'] ?? res.data['fileUrl'];
      if (res.data['status'] == true && fileUrl != null) {
        setState(() {
          _documents.add({'name': fileName, 'url': fileUrl.toString()});
        });
        _showToast('$fileName uploaded successfully');
      } else {
        _showToast(
          res.data['message']?.toString() ?? 'Failed to upload document',
        );
      }
    } catch (e) {
      _showToast('An error occurred during document upload');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _removeDocument(int index) {
    setState(() => _documents.removeAt(index));
  }

  Future<void> _submitBooking() async {
    if (!_agreed) {
      _showToast('Please agree to the booking terms to continue.');
      return;
    }
    if (_selectedUnitId.isEmpty) {
      _showToast('Please select a unit to reserve.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.post('/api/bookings', {
        'project': widget.projectId,
        'unit': _selectedUnitId,
        'type': 'Token Reservation',
        'amount': widget.project?['tokenAmount'] ?? '1,00,000',
        'paymentMethod': _selectedMethod,
        'status': 'Pending',
        'scheduledDate': DateTime.now().toIso8601String(),
        'plan': widget.plan?['name'],
        'documents': _documents
            .map((d) => {...d, 'uploadedAt': DateTime.now().toIso8601String()})
            .toList(),
      });

      if (res.data['status'] == true) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => BookingConfirmationScreen(
              projectId: widget.projectId,
              project: widget.project,
              bookingId: (res.data['data']?['_id'] ?? res.data['data']?['id'])
                  ?.toString(),
              amount: (widget.project?['tokenAmount'] ?? '1,00,000').toString(),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFE24B4A),
            content: Text('Payment failed: ${e.toString()}'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _unitLabel(dynamic unit) {
    final unitNumber = unit['unitNumber'] ?? 'Unit';
    final tower = unit['tower'] ?? 'N/A';
    final floor = unit['floor'] != null ? unit['floor'].toString() : 'N/A';
    final config = unit['configuration'] ?? unit['config'] ?? '';
    final rawPrice = (unit['basePrice'] ?? unit['price'] ?? '0')
        .toString()
        .replaceAll(',', '');
    final price = double.tryParse(rawPrice)?.toStringAsFixed(0) ?? rawPrice;
    return '$unitNumber - Tower $tower - Floor $floor ($config) - $price AED';
  }

  Widget _buildPaymentMethod(String name, IconData icon, bool isDark) {
    final id = name.split(' ')[0].toLowerCase();
    final isActive = _selectedMethod == id;
    final onSurface = isDark ? Colors.white : Color(0xFF163A2C);
    final surface = isDark ? Colors.black : Colors.white;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () => setState(() => _selectedMethod = id),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.02) : Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              // Web parity: selected = dark border (not gold).
              color: isActive ? onSurface : onSurface.withOpacity(0.08),
              width: isActive ? 1.5 : 1,
            ),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            children: [
              // Icon in a box: selected = dark box/white icon, else light.
              Container(
                width: 54,
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isActive ? onSurface : onSurface.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: isActive ? surface : onSurface.withOpacity(0.5),
                  size: 22,
                ),
              ),
              const SizedBox(width: 18),
              Text(
                name,
                style: GoogleFonts.ebGaramond(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: onSurface,
                ),
              ),
              const Spacer(),
              // Radio: selected = filled dark check, else empty ring.
              isActive
                  ? Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: onSurface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(LucideIcons.check, color: surface, size: 13),
                    )
                  : Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: onSurface.withOpacity(0.15),
                          width: 1.5,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Web parity: format the token amount with Indian grouping (₹1,00,000).
    final _amountDigits = (widget.project?['tokenAmount'] ?? '100000')
        .toString()
        .replaceAll(RegExp(r'[^0-9]'), '');
    final formattedAmount = NumberFormat.decimalPattern(
      'en_IN',
    ).format(int.tryParse(_amountDigits) ?? 100000);

    if (_isSuccess) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF141B3A) : Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  LucideIcons.checkCircle2,
                  size: 80,
                  color: M4Theme.premiumBlue,
                ),
                const SizedBox(height: 24),
                Text(
                  'BOOKING SUCCESSFUL',
                  style: GoogleFonts.gelasio(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : Color(0xFF163A2C),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Your token payment has been received. Our team will verify the documents and contact you for the next steps.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.gelasio(
                    fontSize: 10,
                    color: (isDark ? Colors.white : Color(0xFF163A2C)).withOpacity(
                      0.6,
                    ),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    height: 1.8,
                  ),
                ),
                const SizedBox(height: 48),
                GestureDetector(
                  onTap: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                  child: Container(
                    width: double.infinity,
                    height: 64,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white : Color(0xFF163A2C),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Center(
                      child: Text(
                        'BACK TO HOME',
                        style: GoogleFonts.gelasio(
                          color: isDark ? Colors.black : Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF141B3A)
          : const Color(0xFFF9FAFB),
      extendBody: true,
      bottomNavigationBar: NavigationPill(
        currentIndex: -1,
        onTap: (i) {
          ref.read(navigationProvider.notifier).state = i;
          Navigator.of(context).popUntil((r) => r.isFirst);
        },
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            LucideIcons.chevronLeft,
            color: isDark ? Colors.white : Color(0xFF163A2C),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'SECURE PAYMENT',
          style: GoogleFonts.ebGaramond(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : Color(0xFF163A2C),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Token Amount Card
            Container(
              width: double.infinity,
              height: 220,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  // Web parity: subtle bottom-left → top-right gradient.
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomLeft,
                          end: Alignment.topRight,
                          colors: [
                            const Color(0xFF1B2233).withOpacity(0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Large shield watermark, vertically centered on the right
                  // (web: big ShieldCheck offset to the right edge).
                  Positioned(
                    top: 0,
                    bottom: 0,
                    right: -30,
                    child: Center(
                      child: Icon(
                        LucideIcons.shieldCheck,
                        color: Colors.white.withOpacity(0.1),
                        size: 190,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'TOKEN AMOUNT',
                          style: GoogleFonts.gelasio(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.white70,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '₹$formattedAmount',
                          style: GoogleFonts.gelasio(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 18),
                        // Web parity: 100% REFUNDABLE pill · divider · INSTANT RECEIPT.
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    LucideIcons.shieldCheck,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '100% REFUNDABLE',
                                    style: GoogleFonts.ebGaramond(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 1,
                              height: 14,
                              color: Colors.white.withOpacity(0.2),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'INSTANT RECEIPT',
                              style: GoogleFonts.ebGaramond(
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                color: Colors.white.withOpacity(0.68),
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),

            // Unit Selection Section
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SELECT UNIT',
                  style: GoogleFonts.gelasio(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: (isDark ? Colors.white : Color(0xFF163A2C)).withOpacity(
                      0.6,
                    ),
                    letterSpacing: 1.5,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white : Color(0xFF163A2C),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'REQUIRED',
                    style: GoogleFonts.ebGaramond(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.black : Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.02)
                    : Colors.white,
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05),
                ),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AVAILABLE UNITS',
                    style: GoogleFonts.gelasio(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: (isDark ? Colors.white : Color(0xFF163A2C)).withOpacity(
                        0.6,
                      ),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isLoadingUnits)
                    const SizedBox(
                      height: 56,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: M4Theme.premiumBlue,
                        ),
                      ),
                    )
                  else if (_unitsError != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _unitsError!.toUpperCase(),
                          style: GoogleFonts.ebGaramond(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Colors.red,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    )
                  else if (_availableUnits.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'NO AVAILABLE UNITS FOUND FOR THIS PROJECT.',
                          style: GoogleFonts.ebGaramond(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Colors.red,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : Colors.black.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.05),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedUnitId.isEmpty
                              ? null
                              : _selectedUnitId,
                          hint: Text(
                            '-- Select a Unit / Apartment --',
                            style: GoogleFonts.ebGaramond(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: (isDark ? Colors.white : Color(0xFF163A2C))
                                  .withOpacity(0.6),
                            ),
                          ),
                          icon: Icon(
                            LucideIcons.chevronDown,
                            color: (isDark ? Colors.white : Color(0xFF163A2C))
                                .withOpacity(0.6),
                            size: 18,
                          ),
                          dropdownColor: isDark
                              ? const Color(0xFF1A1C20)
                              : Colors.white,
                          style: GoogleFonts.ebGaramond(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Color(0xFF163A2C),
                          ),
                          items: _availableUnits.map<DropdownMenuItem<String>>((
                            unit,
                          ) {
                            return DropdownMenuItem<String>(
                              value: unit['_id']?.toString() ?? '',
                              child: Text(
                                _unitLabel(unit),
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.ebGaramond(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : Color(0xFF163A2C),
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) =>
                              setState(() => _selectedUnitId = value ?? ''),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    'A UNIT IS LOCKED EXCLUSIVELY TO YOUR PROFILE ONCE THE TOKEN RESERVATION PAYMENT IS PROCESSED.',
                    style: GoogleFonts.ebGaramond(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: (isDark ? Colors.white : Color(0xFF163A2C)).withOpacity(
                        0.6,
                      ),
                      letterSpacing: 1,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms).moveX(begin: -20, end: 0),

            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'COMPLIANCE DOCUMENTS',
                  style: GoogleFonts.gelasio(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: (isDark ? Colors.white : Color(0xFF163A2C)).withOpacity(
                      0.6,
                    ),
                    letterSpacing: 1.5,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'OPTIONAL',
                    style: GoogleFonts.ebGaramond(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: (isDark ? Colors.white : Color(0xFF163A2C)).withOpacity(
                        0.6,
                      ),
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Uploaded documents list
            ..._documents.asMap().entries.map((entry) {
              final i = entry.key;
              final doc = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.03)
                        : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: M4Theme.premiumBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          LucideIcons.fileText,
                          color: M4Theme.premiumBlue,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          doc['name']!.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.ebGaramond(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : Color(0xFF163A2C),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => _removeDocument(i),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            LucideIcons.x,
                            color: Colors.red,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn().moveX(begin: -10, end: 0),
              );
            }),

            // Web parity: upload zone + note wrapped in one white card.
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.02) : Colors.white,
                borderRadius: BorderRadius.circular(34),
                border: Border.all(
                  color: (isDark ? Colors.white : Color(0xFF163A2C)).withOpacity(
                    0.06,
                  ),
                ),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
              ),
              child: Column(
                children: [
                  // Upload Area
                  GestureDetector(
                    onTap: _pickDocument,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(2),
                      child: DottedBorder(
                        borderType: BorderType.RRect,
                        radius: const Radius.circular(32),
                        dashPattern: const [6, 6],
                        color: _isUploading
                            ? M4Theme.premiumBlue.withValues(alpha: 0.5)
                            : (isDark ? Colors.white : Color(0xFF163A2C))
                                  .withOpacity(0.35),
                        strokeWidth: 1.5,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 48),
                          decoration: BoxDecoration(
                            color: _isUploading
                                ? M4Theme.premiumBlue.withValues(alpha: 0.04)
                                : (isDark
                                      ? Colors.white.withValues(alpha: 0.02)
                                      : Colors.white),
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_isUploading)
                                  const SizedBox(
                                    width: 32,
                                    height: 32,
                                    child: CircularProgressIndicator(
                                      color: M4Theme.premiumBlue,
                                      strokeWidth: 3,
                                    ),
                                  )
                                else
                                  Container(
                                    width: 56,
                                    height: 56,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color:
                                          (isDark ? Colors.white : Color(0xFF163A2C))
                                              .withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(
                                      LucideIcons.upload,
                                      color:
                                          (isDark ? Colors.white : Color(0xFF163A2C))
                                              .withOpacity(0.5),
                                      size: 24,
                                    ),
                                  ),
                                const SizedBox(height: 20),
                                Text(
                                  _isUploading
                                      ? 'UPLOADING SECURITY VAULT...'
                                      : 'QUICK UPLOAD DOCUMENTS',
                                  style: GoogleFonts.ebGaramond(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: isDark ? Colors.white : Color(0xFF163A2C),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _isUploading
                                      ? 'ESTABLISHING ENCRYPTED CONNECTION'
                                      : 'TAP TO UPLOAD AADHAAR, PAN OR IDENTITY PROOF',
                                  style: GoogleFonts.ebGaramond(
                                    fontSize: 8,
                                    color: isDark
                                        ? Colors.white38
                                        : Color(0xFF5E6B60),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.orange.withOpacity(0.05)
                          : const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? Colors.orange.withOpacity(0.2)
                            : const Color(0xFFFED7AA),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.alertCircle,
                          color: Color(0xFFF97316),
                          size: 18,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'DOCUMENTS ENSURE FASTER BOOKING VERIFICATION BY OUR TEAM.',
                            style: GoogleFonts.ebGaramond(
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              color: isDark
                                  ? Colors.orange.withOpacity(0.8)
                                  : const Color(0xFF9A3412),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 300.ms),
                ],
              ),
            ),

            const SizedBox(height: 48),
            Text(
              'PAYMENT METHOD',
              style: GoogleFonts.gelasio(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: (isDark ? Colors.white : Color(0xFF163A2C)).withOpacity(0.6),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            _buildPaymentMethod(
              'UPI (PHONEPE/GPAY)',
              LucideIcons.smartphone,
              isDark,
            ),
            _buildPaymentMethod(
              'CREDIT / DEBIT CARD',
              LucideIcons.creditCard,
              isDark,
            ),
            _buildPaymentMethod('NET BANKING', LucideIcons.wallet, isDark),

            const SizedBox(height: 40),
            GestureDetector(
              onTap: () => setState(() => _agreed = !_agreed),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.02)
                      : Colors.black.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: (isDark ? Colors.white : Color(0xFF163A2C)).withOpacity(
                      0.06,
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _agreed
                            ? (isDark ? Colors.white : Color(0xFF163A2C))
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isDark ? Colors.white : Color(0xFF163A2C),
                          width: 2,
                        ),
                      ),
                      child: _agreed
                          ? Icon(
                              LucideIcons.check,
                              color: isDark ? Colors.black : Colors.white,
                              size: 14,
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'I AGREE TO THE BOOKING TERMS AND UNDERSTAND THAT THIS TOKEN AMOUNT IS FULLY REFUNDABLE WITHIN 7 DAYS OF PAYMENT.',
                        style: GoogleFonts.ebGaramond(
                          fontSize: 9,
                          color: (isDark ? Colors.white : Color(0xFF163A2C))
                              .withOpacity(0.6),
                          fontWeight: FontWeight.w900,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                // Web parity: the PAY button is always solid black; unit/terms
                // are validated on tap (toast) instead of being greyed out.
                onPressed: _isLoading ? null : _submitBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : Color(0xFF163A2C),
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  disabledBackgroundColor:
                      (isDark ? Colors.white : Color(0xFF163A2C)).withOpacity(0.7),
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? CupertinoActivityIndicator(
                        color: isDark ? Colors.black : Colors.white,
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'PAY ₹$formattedAmount',
                            style: GoogleFonts.ebGaramond(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(LucideIcons.wallet, size: 18),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 32),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.shieldCheck,
                    color: isDark ? Colors.white24 : Colors.black26,
                    size: 14,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'PCI-DSS COMPLIANT • 256-BIT SSL ENCRYPTION',
                    style: GoogleFonts.ebGaramond(
                      fontSize: 7,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white24 : Colors.black26,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 64),
          ],
        ),
      ),
    );
  }
}
