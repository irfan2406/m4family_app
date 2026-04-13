import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:m4_mobile/presentation/screens/support/contact_support_screen.dart';


class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildSearchBar(),
              const SizedBox(height: 40),
              _buildPopularGuides(),
              const SizedBox(height: 48),
              _buildFAQSection(),
              const SizedBox(height: 60),
              _buildNeedHelpSection(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SUPPORT INDEX',
          style: GoogleFonts.montserrat(
            fontSize: 24,
            fontWeight: FontWeight.w300,
            color: Theme.of(context).colorScheme.onSurface,
            letterSpacing: 2,
          ),
        ),
        Text(
          'FAQ & GOVERNANCE',
          style: GoogleFonts.montserrat(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            letterSpacing: 4,
          ),
        ),
      ],
    ).animate().fadeIn().slideX(begin: -0.1);
  }

  Widget _buildSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
            style: GoogleFonts.montserrat(color: Theme.of(context).colorScheme.onSurface, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'SEARCH FOR HELP...',
              hintStyle: GoogleFonts.montserrat(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1),
              prefixIcon: Icon(LucideIcons.search, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2), size: 18),
              suffixIcon: _searchQuery.isNotEmpty ? IconButton(
                icon: Icon(LucideIcons.x, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2), size: 16),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              ) : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildPopularGuides() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'POPULAR GUIDES',
          style: GoogleFonts.montserrat(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              if ('home buyer\'s guide'.contains(_searchQuery))
                _GuideCard(
                  title: 'HOME BUYER\'S GUIDE',
                  readingTime: '5 MIN READ',
                  icon: LucideIcons.home,
                ),
              if ('home buyer\'s guide'.contains(_searchQuery) && 'understanding norms'.contains(_searchQuery))
                const SizedBox(width: 16),
              if ('understanding norms'.contains(_searchQuery))
                _GuideCard(
                  title: 'UNDERSTANDING NORMS',
                  readingTime: '8 MIN READ',
                  icon: LucideIcons.shield,
                ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildFAQSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_searchQuery.isEmpty)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'FREQUENTLY ASKED QUESTIONS',
                style: GoogleFonts.montserrat(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  letterSpacing: 2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'UPDATED',
                  style: GoogleFonts.montserrat(
                    fontSize: 7,
                    fontWeight: FontWeight.w900,
                    color: Colors.orangeAccent,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        const SizedBox(height: 32),
        _buildFilteredFAQCategory(
          title: 'PAYMENTS',
          questions: const [
            {
              'q': 'How do I make a maintenance payment?',
              'a': 'You can pay via the \'Payments\' section in your dashboard. Select your project and follow the on-screen instructions for secure transaction.'
            },
            {
              'q': 'Where can I find payment receipts?',
              'a': 'All receipts are automatically generated and stored under the \'Documents\' section of each project. You can view or download them anytime.'
            },
            {
              'q': 'Can I schedule auto-debit?',
              'a': 'Yes, you can enable auto-debit from the \'Settings\' tab in your profile. Select your preferred bank account and authorization method.'
            },
          ],
        ),
        const SizedBox(height: 24),
        _buildFilteredFAQCategory(
          title: 'BOOKINGS & SITE VISITS',
          questions: const [
            {
              'q': 'How do I schedule a site visit?',
              'a': 'Use the \'Schedule Visit\' option in the Support Hub. Choose your preferred project, date, and time, and our manager will confirm within 2 hours.'
            },
            {
              'q': 'What is the token amount for booking?',
              'a': 'Token amounts vary by project and unit type. Generally, it starts from ₹50,000. Exact details are available in the pricing sheet of each project.'
            },
          ],
        ),
      ],
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildNeedHelpSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(LucideIcons.helpCircle, color: Theme.of(context).colorScheme.onSurface, size: 24),
              ),
              const SizedBox(height: 24),
              Text(
                'STILL NEED HELP?',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'OUR TEAM IS AVAILABLE 24/7',
                style: GoogleFonts.montserrat(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ContactSupportScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                    foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'CONTACT SUPPORT',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms);
  }
  Widget _buildFilteredFAQCategory({required String title, required List<Map<String, String>> questions}) {
    final filtered = questions.where((q) {
      final text = (q['q']! + q['a']!).toLowerCase();
      return text.contains(_searchQuery);
    }).toList();

    if (filtered.isEmpty) return const SizedBox.shrink();

    return _FAQCategory(
      title: title,
      questions: filtered,
    );
  }
}

class _GuideCard extends StatelessWidget {
  final String title;
  final String readingTime;
  final IconData icon;

  const _GuideCard({
    required this.title,
    required this.readingTime,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 160,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.6)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), size: 20),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: GoogleFonts.montserrat(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                readingTime,
                style: GoogleFonts.montserrat(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FAQCategory extends StatelessWidget {
  final String title;
  final List<Map<String, String>> questions;

  const _FAQCategory({
    required this.title,
    required this.questions,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.montserrat(
                fontSize: 8,
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...questions.map((q) => _FAQTile(question: q['q']!, answer: q['a']!)).toList(),
      ],
    );
  }
}

class _FAQTile extends StatefulWidget {
  final String question;
  final String answer;

  const _FAQTile({required this.question, required this.answer});

  @override
  State<_FAQTile> createState() => _FAQTileState();
}

class _FAQTileState extends State<_FAQTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const RoundedRectangleBorder(side: BorderSide.none),
          onExpansionChanged: (expanded) => setState(() => _isExpanded = expanded),
          title: Text(
            widget.question.toUpperCase(),
            style: GoogleFonts.montserrat(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
          trailing: Icon(
            _isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
            size: 16,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                widget.answer,
                style: GoogleFonts.montserrat(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  fontSize: 10,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
