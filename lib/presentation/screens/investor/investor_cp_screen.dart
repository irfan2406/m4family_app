import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/core/utils/support_handlers.dart';

/// Web `/investor/cp` — Channel Partner portal surface from the investor app.
///
/// The web page is a self-contained CP portal mockup (gated login → partner
/// dashboard with active-lead / earnings stats, a registered-leads pipeline and
/// a "register new lead" form). This screen mirrors that structure with M4
/// premium glass styling: searchable lead pipeline, stat cards, per-lead
/// call / update actions and a "Register New Lead" bottom sheet.
class InvestorCpScreen extends ConsumerStatefulWidget {
  const InvestorCpScreen({super.key});

  @override
  ConsumerState<InvestorCpScreen> createState() => _InvestorCpScreenState();
}

class _InvestorCpScreenState extends ConsumerState<InvestorCpScreen> {
  static const _gold = Color(0xFFFFD700);

  final _search = TextEditingController();
  String _q = '';

  static const _stats = [
    _Stat('Active Leads', '12', LucideIcons.userCheck),
    _Stat('Total Earned', '₹ 2.4L', LucideIcons.trophy),
    _Stat('Lead Pipeline', '450+', LucideIcons.barChart3),
  ];

  static const _leads = [
    _Lead('Amit Sharma', 'M4 Prestige', 'Visit Scheduled'),
    _Lead('Priya V', 'M4 Core', 'Booking Done'),
    _Lead('Rahul K', 'M4 Core', 'Follow-up'),
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<_Lead> get _filtered {
    if (_q.isEmpty) return _leads;
    return _leads
        .where((l) =>
            l.name.toLowerCase().contains(_q) ||
            l.project.toLowerCase().contains(_q) ||
            l.status.toLowerCase().contains(_q))
        .toList();
  }

  Future<void> _call() async => SupportHandlers.launchCall();

  void _openLeadForm() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LeadFormSheet(isDark: isDark),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.black : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black;
    final muted = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5);
    final card = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: textPrimary),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/investor/home'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Partner Dashboard',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: textPrimary,
              ),
            ),
            Text(
              'ID: CP-9021 • M4 PARTNER',
              style: GoogleFonts.montserrat(
                fontSize: 8,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                color: _gold,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: _openLeadForm,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: textPrimary,
                  shape: BoxShape.circle,
                ),
                child: Icon(LucideIcons.plus, size: 20, color: bg),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          // Search input
          _buildSearch(textPrimary, muted, card, border),
          const SizedBox(height: 20),

          // Dashboard stats
          ..._stats.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _StatCard(
                  stat: s,
                  textPrimary: textPrimary,
                  muted: muted,
                  card: card,
                  border: border,
                ),
              )),

          const SizedBox(height: 12),

          // Registered Leads header
          Row(
            children: [
              const Icon(LucideIcons.users, size: 14, color: _gold),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'REGISTERED LEADS',
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: textPrimary.withValues(alpha: 0.6),
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${filtered.length} ACTIVE',
                  style: GoogleFonts.montserrat(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: _gold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Lead cards
          ...filtered.map((l) => _LeadCard(
                lead: l,
                textPrimary: textPrimary,
                muted: muted,
                card: card,
                border: border,
                bg: bg,
                onCall: _call,
                onUpdate: _openLeadForm,
              )),

          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Column(
                  children: [
                    Icon(LucideIcons.searchX,
                        size: 36, color: textPrimary.withValues(alpha: 0.25)),
                    const SizedBox(height: 12),
                    Text(
                      'NO LEADS FOUND',
                      style: GoogleFonts.montserrat(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        color: textPrimary.withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 20),

          // Register new lead CTA card
          _RegisterCard(
            isDark: isDark,
            textPrimary: textPrimary,
            bg: bg,
            onTap: _openLeadForm,
          ),
        ],
      ),
    );
  }

  Widget _buildSearch(
      Color textPrimary, Color muted, Color card, Color border) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: TextField(
        controller: _search,
        style: GoogleFonts.montserrat(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Search registered leads…',
          hintStyle: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: muted,
          ),
          prefixIcon: const Icon(LucideIcons.search, size: 20, color: _gold),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
        ),
        onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
      ),
    );
  }
}

class _Stat {
  final String label;
  final String value;
  final IconData icon;
  const _Stat(this.label, this.value, this.icon);
}

class _Lead {
  final String name;
  final String project;
  final String status;
  const _Lead(this.name, this.project, this.status);
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// STAT CARD — premium glass row with icon circle + value
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _StatCard extends StatelessWidget {
  static const _gold = Color(0xFFFFD700);
  final _Stat stat;
  final Color textPrimary;
  final Color muted;
  final Color card;
  final Color border;
  const _StatCard({
    required this.stat,
    required this.textPrimary,
    required this.muted,
    required this.card,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: _gold.withValues(alpha: 0.25)),
            ),
            child: Icon(stat.icon, size: 22, color: _gold),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat.label.toUpperCase(),
                  style: GoogleFonts.montserrat(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: muted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stat.value,
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: textPrimary.withValues(alpha: 0.04),
              shape: BoxShape.circle,
              border: Border.all(color: border),
            ),
            child: Icon(LucideIcons.chevronRight, size: 18, color: muted),
          ),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// LEAD CARD — premium glass card with status badge + actions
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _LeadCard extends StatelessWidget {
  static const _gold = Color(0xFFFFD700);
  final _Lead lead;
  final Color textPrimary;
  final Color muted;
  final Color card;
  final Color border;
  final Color bg;
  final VoidCallback onCall;
  final VoidCallback onUpdate;

  const _LeadCard({
    required this.lead,
    required this.textPrimary,
    required this.muted,
    required this.card,
    required this.border,
    required this.bg,
    required this.onCall,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lead.name.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lead.project.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: _gold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  lead.status.toUpperCase(),
                  style: GoogleFonts.montserrat(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: _gold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: onCall,
                    icon: const Icon(LucideIcons.phone, size: 16, color: _gold),
                    label: Text(
                      'CALL CLIENT',
                      style: GoogleFonts.montserrat(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: textPrimary,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: onUpdate,
                    icon: Icon(LucideIcons.refreshCw, size: 16, color: bg),
                    label: Text(
                      'UPDATE STATUS',
                      style: GoogleFonts.montserrat(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: bg,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: textPrimary,
                      foregroundColor: bg,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// REGISTER CARD — dark CTA to register a new lead
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _RegisterCard extends StatelessWidget {
  static const _gold = Color(0xFFFFD700);
  final bool isDark;
  final Color textPrimary;
  final Color bg;
  final VoidCallback onTap;
  const _RegisterCard({
    required this.isDark,
    required this.textPrimary,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: textPrimary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: bg.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.userPlus, size: 24, color: _gold),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'REGISTER NEW LEAD',
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: bg,
                      height: 1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Register a high-priority lead against your channel partner ID and '
              'track it through visit, booking and payout.',
              style: GoogleFonts.montserrat(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                height: 1.6,
                color: bg.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: onTap,
                style: FilledButton.styleFrom(
                  backgroundColor: bg,
                  foregroundColor: textPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                child: Text(
                  'REGISTER LEAD',
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// LEAD FORM SHEET — register new lead bottom sheet
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _LeadFormSheet extends StatefulWidget {
  final bool isDark;
  const _LeadFormSheet({required this.isDark});

  @override
  State<_LeadFormSheet> createState() => _LeadFormSheetState();
}

class _LeadFormSheetState extends State<_LeadFormSheet> {
  static const _gold = Color(0xFFFFD700);
  final _name = TextEditingController();
  final _mobile = TextEditingController();
  String _project = 'M4 Prestige';

  static const _projects = ['M4 Prestige', 'M4 Core'];

  @override
  void dispose() {
    _name.dispose();
    _mobile.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lead registered successfully.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bg = isDark ? Colors.black : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black;
    final muted = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5);
    final card = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.03);
    final border = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: border),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: muted,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Register New Lead',
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'HIGH PRIORITY REGISTRATION',
                        style: GoogleFonts.montserrat(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                          color: _gold,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(LucideIcons.x, size: 20, color: muted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _label('SELECT PROJECT', muted),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _project,
                  isExpanded: true,
                  dropdownColor: isDark ? const Color(0xFF111111) : Colors.white,
                  icon: Icon(LucideIcons.chevronDown, size: 18, color: muted),
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                  items: _projects
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _project = v ?? _project),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _label('CLIENT FULL NAME', muted),
            const SizedBox(height: 8),
            _field(_name, 'Enter client name', textPrimary, muted, card, border),
            const SizedBox(height: 16),
            _label('CLIENT MOBILE', muted),
            const SizedBox(height: 8),
            _field(_mobile, 'Enter client mobile', textPrimary, muted, card,
                border,
                keyboard: TextInputType.phone),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: textPrimary,
                  foregroundColor: bg,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                child: Text(
                  'SUBMIT LEAD',
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: bg,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text, Color muted) => Text(
        text,
        style: GoogleFonts.montserrat(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
          color: muted,
        ),
      );

  Widget _field(
    TextEditingController c,
    String hint,
    Color textPrimary,
    Color muted,
    Color card,
    Color border, {
    TextInputType? keyboard,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: TextField(
        controller: c,
        keyboardType: keyboard,
        style: GoogleFonts.montserrat(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: muted,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
