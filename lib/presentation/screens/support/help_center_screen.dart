import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:m4_mobile/presentation/screens/support/contact_screen.dart';

/// Web `/cp/support/help-center` (`app/(cp)/cp/support/help-center/page.tsx`) —
/// "Support Index / FAQ & Governance": circular back button + title, search,
/// FAQ categories where each category's questions live in ONE white card with
/// dividers (not separate cards), and a "Still need help?" card.
class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const _faqs = [
    {
      'category': 'PAYMENTS',
      'items': [
        {
          'q': 'How do I make a maintenance payment?',
          'a':
              "You can make payments via the 'Pay Now' button in your dashboard using UPI, Credit Card, or Net Banking.",
        },
        {
          'q': 'Where can I find payment receipts?',
          'a':
              "All receipts are automatically generated and stored in the 'Documents' section of your profile.",
        },
        {
          'q': 'Can I schedule auto-debit?',
          'a':
              "Yes, you can enable auto-debit from the 'Settings' tab in your profile.",
        },
      ],
    },
    {
      'category': 'BOOKINGS & SITE VISITS',
      'items': [
        {
          'q': 'How do I schedule a site visit?',
          'a':
              "Go to the 'Support' tab and click on 'Schedule Visit'. You can choose a date and time that suits you.",
        },
        {
          'q': 'What is the token amount for booking?',
          'a':
              'The token amount varies by project. Typically it is 1% of the property value or ₹1 Lakh, whichever is lower.',
        },
      ],
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, String>> _filter(List items) {
    return items
        .cast<Map<String, String>>()
        .where((q) => (q['q']! + q['a']!).toLowerCase().contains(_searchQuery))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildSearchBar(),
              const SizedBox(height: 40),
              _buildFAQSection(),
              const SizedBox(height: 40),
              _buildNeedHelpSection(),
            ],
          ),
        ),
      ),
    );
  }

  // Web parity: circular back button + "Support Index" title with a
  // "Faq & Governance" subtitle beside it (a Row, not a stacked header).
  Widget _buildHeader() {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Icon(
              LucideIcons.arrowLeft,
              size: 16,
              color: scheme.onSurface,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SUPPORT INDEX',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'FAQ & GOVERNANCE',
              style: GoogleFonts.montserrat(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn().slideX(begin: -0.1);
  }

  // Web parity: a white pill with soft shadow (glass-card), not a grey fill.
  Widget _buildSearchBar() {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: isDark
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.3)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) =>
            setState(() => _searchQuery = value.toLowerCase()),
        style: GoogleFonts.montserrat(
          color: scheme.onSurface,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          hintText: 'SEARCH FOR HELP...',
          hintStyle: GoogleFonts.montserrat(
            color: scheme.onSurface.withValues(alpha: 0.4),
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
          prefixIcon: Icon(
            LucideIcons.search,
            color: scheme.onSurface.withValues(alpha: 0.4),
            size: 18,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    LucideIcons.x,
                    color: scheme.onSurface.withValues(alpha: 0.4),
                    size: 16,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildFAQSection() {
    final scheme = Theme.of(context).colorScheme;
    final categories = _faqs
        .map(
          (c) => {
            'category': c['category'],
            'items': _filter(c['items'] as List),
          },
        )
        .where((c) => (c['items'] as List).isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FREQUENTLY ASKED QUESTIONS',
          style: GoogleFonts.montserrat(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 24),
        ...categories.map(
          (c) => Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: _FaqCategory(
              title: c['category'] as String,
              questions: (c['items'] as List).cast<Map<String, String>>(),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 300.ms);
  }

  // Web parity: a white card with shadow, help icon in a circle, "Still need
  // help?" + "Our team is available 24/7", black "Contact Support" button.
  Widget _buildNeedHelpSection() {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.3)
            : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 30,
                  offset: const Offset(0, 14),
                ),
              ],
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: scheme.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Icon(
              LucideIcons.helpCircle,
              color: scheme.onSurface,
              size: 30,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'STILL NEED HELP?',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: scheme.onSurface,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'OUR TEAM IS AVAILABLE 24/7',
            style: GoogleFonts.montserrat(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ContactScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.white : Colors.black,
                foregroundColor: isDark ? Colors.black : Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'CONTACT SUPPORT',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }
}

/// A single FAQ category: dot + label, then ONE white card holding all the
/// category's questions as expandable rows separated by dividers (web parity).
class _FaqCategory extends StatelessWidget {
  final String title;
  final List<Map<String, String>> questions;

  const _FaqCategory({required this.title, required this.questions});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.montserrat(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? scheme.surfaceContainerHighest.withValues(alpha: 0.3)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.4),
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (int i = 0; i < questions.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: scheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                _FaqRow(
                  question: questions[i]['q']!,
                  answer: questions[i]['a']!,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _FaqRow extends StatefulWidget {
  final String question;
  final String answer;

  const _FaqRow({required this.question, required this.answer});

  @override
  State<_FaqRow> createState() => _FaqRowState();
}

class _FaqRowState extends State<_FaqRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      widget.question.toUpperCase(),
                      style: GoogleFonts.montserrat(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 0.3,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    _expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                    size: 16,
                  ),
                ],
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox(width: double.infinity),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    widget.answer,
                    style: GoogleFonts.montserrat(
                      color: scheme.onSurfaceVariant,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      height: 1.6,
                    ),
                  ),
                ),
                crossFadeState: _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
