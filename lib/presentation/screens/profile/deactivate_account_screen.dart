import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

class DeactivateAccountScreen extends ConsumerStatefulWidget {
  const DeactivateAccountScreen({super.key});

  @override
  ConsumerState<DeactivateAccountScreen> createState() =>
      _DeactivateAccountScreenState();
}

class _DeactivateAccountScreenState
    extends ConsumerState<DeactivateAccountScreen> {
  final TextEditingController _confirmController = TextEditingController();
  bool _agreedToTerms = false;
  bool _isDeleting = false;
  String _error = "";

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleDelete() async {
    if (_confirmController.text.trim() != "DELETE") {
      setState(() => _error = "TYPE DELETE TO CONFIRM");
      return;
    }

    if (!_agreedToTerms) {
      setState(() => _error = "ACKNOWLEDGE CONSEQUENCES FIRST");
      return;
    }

    setState(() {
      _isDeleting = true;
      _error = "";
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.dio.delete('/auth/me');

      if (response.data['status'] == true) {
        // Clear auth state and logout
        await ref.read(authProvider.notifier).logout();
        // After session ends, go to guest mode, not the login page.
        if (mounted) context.go('/home');
      } else {
        setState(
          () => _error =
              response.data['message'] ?? "COULD NOT DEACTIVATE ACCOUNT",
        );
      }
    } catch (e) {
      setState(() => _error = "CONNECTION ERROR: COULD NOT DEACTIVATE");
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF4EFE3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: IconButton(
            icon: Icon(
              LucideIcons.arrowLeft,
              color: isDark ? Colors.white54 : Color(0xFF155A4F),
            ),
            onPressed: () => context.pop(),
            style: IconButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFF141B3A) : const Color(0xFFF4EFE3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(
                color: (isDark ? Colors.white : Color(0xFF0C312B)).withOpacity(0.05),
              ),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DEACTIVATE',
              style: GoogleFonts.inter(
                textStyle: const TextStyle(inherit: true),
                color: const Color(0xFFC65B46),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
            Text(
              'PURGE PROTOCOL',
              style: GoogleFonts.gelasio(
                textStyle: const TextStyle(inherit: true),
                color: isDark ? Colors.white24 : Colors.black26,
                fontSize: 8,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            // Warning Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFC65B46).withOpacity(0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFC65B46).withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFC65B46),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      LucideIcons.alertTriangle,
                      color: const Color(0xFFF4EFE3),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CRITICAL WARNING',
                          style: GoogleFonts.inter(
                            textStyle: const TextStyle(inherit: true),
                            color: const Color(0xFFC65B46),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Final action. All institutional ties, documents, and historical data will be permanently purged.',
                          style: GoogleFonts.inter(
                            textStyle: const TextStyle(inherit: true),
                            color: const Color(0xFFC65B46).withOpacity(0.6),
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Scope Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF141B3A) : const Color(0xFFF4EFE3),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: (isDark ? Colors.white : Color(0xFF0C312B)).withOpacity(
                    0.05,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PURGE SCOPE',
                    style: GoogleFonts.gelasio(
                      textStyle: const TextStyle(inherit: true),
                      color: isDark ? Colors.white38 : Color(0xFF155A4F),
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...[
                    "Institutional property bookings",
                    "Historical site visit logs",
                    "Legal documents & receipts",
                    "Platform customizations",
                    "Personal identity data",
                  ].map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: Color(0xFFC65B46),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            item.toUpperCase(),
                            style: GoogleFonts.inter(
                              textStyle: const TextStyle(inherit: true),
                              color: isDark ? Colors.white60 : Color(0xFF155A4F),
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Confirmation Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF141B3A) : const Color(0xFFF4EFE3),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: (isDark ? Colors.white : Color(0xFF0C312B)).withOpacity(
                    0.05,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CONFIRMATION',
                    style: GoogleFonts.gelasio(
                      textStyle: const TextStyle(inherit: true),
                      color: isDark ? Colors.white38 : Color(0xFF155A4F),
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'TYPE DELETE',
                    style: GoogleFonts.gelasio(
                      textStyle: const TextStyle(inherit: true),
                      color: const Color(0xFFC65B46),
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _confirmController,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.gelasio(
                      textStyle: const TextStyle(inherit: true),
                      color: const Color(0xFFC65B46),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 4,
                    ),
                    decoration: InputDecoration(
                      hintText: "DELETE",
                      hintStyle: GoogleFonts.gelasio(
                        textStyle: const TextStyle(inherit: true),
                        color: const Color(0xFFC65B46).withOpacity(0.72),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 4,
                      ),
                      filled: true,
                      fillColor: (isDark ? Colors.white : Color(0xFF0C312B))
                          .withOpacity(0.02),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  GestureDetector(
                    onTap: () =>
                        setState(() => _agreedToTerms = !_agreedToTerms),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Color(0xFF0C312B))
                            .withOpacity(0.02),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _agreedToTerms
                              ? const Color(0xFFC65B46).withOpacity(0.4)
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _agreedToTerms,
                            onChanged: (val) =>
                                setState(() => _agreedToTerms = val ?? false),
                            activeColor: const Color(0xFFC65B46),
                            checkColor: Colors.white,
                            side: BorderSide(
                              color: (isDark ? Colors.white : Color(0xFF0C312B))
                                  .withOpacity(0.1),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'I acknowledge that this protocol will erase my entire digital legacy within M4. Final & irreversible.',
                              style: GoogleFonts.inter(
                                textStyle: const TextStyle(inherit: true),
                                color: isDark ? Colors.white38 : Color(0xFF155A4F),
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_error.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        _error,
                        style: GoogleFonts.inter(
                          textStyle: const TextStyle(inherit: true),
                          color: const Color(0xFFC65B46),
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed:
                          (_confirmController.text.trim() == "DELETE" &&
                              _agreedToTerms &&
                              !_isDeleting)
                          ? _handleDelete
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC65B46),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(
                          0xFFC65B46,
                        ).withOpacity(0.1),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isDeleting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: const Color(0xFFF4EFE3),
                              ),
                            )
                          : Text(
                              'EXECUTE PURGE',
                              style: GoogleFonts.gelasio(
                                textStyle: const TextStyle(inherit: true),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            TextButton(
              onPressed: () => context.pop(),
              child: Text(
                'ABORT PROTOCOL',
                style: GoogleFonts.gelasio(
                  textStyle: const TextStyle(inherit: true),
                  color: isDark ? Colors.white30 : Colors.black26,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
