import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/providers/support_provider.dart';

/// Flutter parity for the web user route `/(user)/support/tickets/[id]`.
///
/// Shows a support ticket's subject/status header, the full conversation
/// thread (message bubbles styled per role), and a reply box that posts a
/// new message. Reached via `Navigator.push` from the support tickets /
/// logs list (constructor takes the ticket `id`, optionally the ticket map).
class TicketDetailScreen extends ConsumerStatefulWidget {
  /// Mongo `_id` of the ticket (web `GET /api/tickets/:id`).
  final String ticketId;

  /// Optional pre-fetched ticket map (`res.data['data']`) so the header can
  /// render instantly before the detail request resolves.
  final Map<String, dynamic>? initialTicket;

  const TicketDetailScreen({
    super.key,
    required this.ticketId,
    this.initialTicket,
  });

  @override
  ConsumerState<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends ConsumerState<TicketDetailScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  Map<String, dynamic>? _ticket;
  List<dynamic> _messages = [];
  bool _loading = true;
  bool _sending = false;
  String? _error;

  /// The ticket owner id, used to decide user-vs-support bubble styling.
  String? _ownerId;

  @override
  void initState() {
    super.initState();
    _ticket = widget.initialTicket;
    _messages = (widget.initialTicket?['messages'] as List<dynamic>?) ?? [];
    _ownerId = _extractId(widget.initialTicket?['user']);
    Future.microtask(_fetchTicket);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ─── Data ──────────────────────────────────────────────────────────────────

  Future<void> _fetchTicket() async {
    try {
      final data = await ref.read(supportProvider.notifier).fetchTicketDetail(widget.ticketId);
      if (!mounted) return;
      if (data != null) {
        setState(() {
          _ticket = data;
          _messages = (data['messages'] as List<dynamic>?) ?? [];
          _ownerId = _extractId(data['user']) ?? _ownerId;
          _loading = false;
          _error = null;
        });
        _scrollToBottom();
      } else {
        setState(() {
          _loading = false;
          _error = 'Failed to load ticket';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _handleSend() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    final updated = await ref.read(supportProvider.notifier).sendMessage(widget.ticketId, text);
    if (!mounted) return;

    if (updated != null) {
      setState(() {
        _ticket = updated;
        _messages = (updated['messages'] as List<dynamic>?) ?? _messages;
        _ownerId = _extractId(updated['user']) ?? _ownerId;
        _messageController.clear();
        _sending = false;
      });
      _scrollToBottom();
    } else {
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send message')),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  /// Normalises an id that may be a raw string or a populated `{ _id }` map.
  String? _extractId(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map) return value['_id']?.toString() ?? value['id']?.toString();
    return value.toString();
  }

  /// A message is "from the user" when its sender matches the ticket owner.
  /// Anything else (support / admin) is rendered on the opposite side.
  bool _isUserMessage(dynamic msg) {
    if (msg is! Map) return false;
    final sender = _extractId(msg['sender']);
    if (_ownerId == null || sender == null) return true; // default to right side
    return sender == _ownerId;
  }

  String _formatTime(dynamic msg) {
    final raw = (msg is Map) ? (msg['timestamp'] ?? msg['time']) : null;
    if (raw == null) return '';
    if (raw is String) {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) return DateFormat('hh:mm a').format(parsed.toLocal());
      return raw;
    }
    return '';
  }

  String get _statusLabel {
    final s = (_ticket?['status'] as String?) ?? 'Open';
    return s.toUpperCase();
  }

  bool get _isOpen {
    final s = (_ticket?['status'] as String?)?.toLowerCase() ?? 'open';
    return s == 'open' || s == 'in progress';
  }

  String get _displayId {
    final tid = _ticket?['ticketId'] as String?;
    if (tid != null && tid.isNotEmpty) return tid;
    final id = widget.ticketId;
    return id.length > 8 ? id.substring(id.length - 8).toUpperCase() : id.toUpperCase();
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.black : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black;
    final muted = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5);
    final border = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06);

    return Scaffold(
      backgroundColor: bg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(isDark, textPrimary, muted, border),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: M4Theme.premiumBlue))
                  : _error != null
                      ? _buildError(textPrimary, muted)
                      : _buildThread(isDark, textPrimary, muted, border),
            ),
            _buildInputBar(isDark, textPrimary, muted, border),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, Color textPrimary, Color muted, Color border) {
    final subject = (_ticket?['subject'] as String?)?.toUpperCase() ?? 'TICKET $_displayId';
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Row(
        children: [
          _PressableScale(
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/support');
              }
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: border),
              ),
              child: Icon(LucideIcons.chevronLeft, size: 18, color: textPrimary),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: textPrimary,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'SUPPORT AGENT ONLINE',
                      style: GoogleFonts.montserrat(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        color: muted,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: (_isOpen ? Colors.blue : const Color(0xFF22C55E)).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: border),
            ),
            child: Text(
              _statusLabel,
              style: GoogleFonts.montserrat(
                fontSize: 8,
                fontWeight: FontWeight.w900,
                color: _isOpen ? Colors.blue : const Color(0xFF22C55E),
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(Color textPrimary, Color muted) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.alertTriangle, size: 40, color: muted),
            const SizedBox(height: 20),
            Text(
              'UNABLE TO LOAD TICKET',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: textPrimary,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 24),
            _PressableScale(
              onTap: () {
                setState(() {
                  _loading = true;
                  _error = null;
                });
                _fetchTicket();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                decoration: BoxDecoration(
                  color: textPrimary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'RETRY',
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: textPrimary == Colors.white ? Colors.black : Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThread(bool isDark, Color textPrimary, Color muted, Color border) {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.messageSquare, size: 40, color: muted),
            const SizedBox(height: 20),
            Text(
              'NO MESSAGES YET',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: textPrimary,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'START THE CONVERSATION BELOW',
              style: GoogleFonts.montserrat(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: muted,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      physics: const BouncingScrollPhysics(),
      children: [
        // Date chip (web: "Today, Jan 26")
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: border),
            ),
            child: Text(
              DateFormat('EEEE, MMM d').format(DateTime.now()).toUpperCase(),
              style: GoogleFonts.montserrat(
                fontSize: 8,
                fontWeight: FontWeight.w900,
                color: muted,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        ..._messages.map((m) => _buildBubble(m, isDark, textPrimary, muted, border)),
        // Secure consultation footer (web parity)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Opacity(
            opacity: 0.4,
            child: Row(
              children: [
                Expanded(child: Divider(color: border, thickness: 1)),
                const SizedBox(width: 12),
                Icon(LucideIcons.shield, size: 14, color: textPrimary),
                const SizedBox(width: 8),
                Text(
                  'SECURE CONSULTATION',
                  style: GoogleFonts.montserrat(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: muted,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Divider(color: border, thickness: 1)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBubble(dynamic msg, bool isDark, Color textPrimary, Color muted, Color border) {
    final isUser = _isUserMessage(msg);
    final text = (msg is Map) ? (msg['text']?.toString() ?? '') : msg.toString();
    final time = _formatTime(msg);
    final attachment = (msg is Map) ? msg['attachment']?.toString() : null;
    final apiClient = ref.read(apiClientProvider);

    // User bubble: solid (foreground/background inversion). Support: card style.
    final bubbleColor = isUser ? textPrimary : (isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white);
    final bubbleTextColor = isUser ? (isDark ? Colors.black : Colors.white) : textPrimary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: isUser ? null : Border.all(color: border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (text.isNotEmpty)
                    Text(
                      text,
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: bubbleTextColor,
                        height: 1.4,
                      ),
                    ),
                  if (attachment != null && attachment.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildAttachment(attachment, apiClient, isUser, bubbleTextColor),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: GoogleFonts.montserrat(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: muted,
                    letterSpacing: 1.5,
                  ),
                ),
                if (isUser) ...[
                  const SizedBox(width: 4),
                  Icon(LucideIcons.checkCheck, size: 12, color: muted),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachment(String attachment, ApiClient apiClient, bool isUser, Color textColor) {
    final url = apiClient.resolveUrl(attachment);
    final isImage = RegExp(r'\.(jpg|jpeg|png|gif|webp)$', caseSensitive: false).hasMatch(attachment);

    if (isImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.paperclip, size: 12, color: textColor),
              const SizedBox(width: 6),
              Text(
                'VIEW ATTACHMENT',
                style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w900, color: textColor),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: (isUser ? Colors.white : Colors.black).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.paperclip, size: 12, color: textColor),
          const SizedBox(width: 6),
          Text(
            'VIEW ATTACHMENT',
            style: GoogleFonts.montserrat(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: textColor,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(bool isDark, Color textPrimary, Color muted, Color border) {
    final card = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).viewPadding.bottom),
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        border: Border(top: BorderSide(color: border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: border),
              ),
              child: TextField(
                controller: _messageController,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _handleSend(),
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'TYPE MESSAGE...',
                  hintStyle: GoogleFonts.montserrat(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: muted.withValues(alpha: 0.6),
                    letterSpacing: 1,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _PressableScale(
            onTap: _sending ? null : _handleSend,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: textPrimary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _sending
                  ? Padding(
                      padding: const EdgeInsets.all(14),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: isDark ? Colors.black : Colors.white,
                      ),
                    )
                  : Icon(
                      LucideIcons.send,
                      size: 18,
                      color: isDark ? Colors.black : Colors.white,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small press-feedback wrapper (web buttons use `active:scale-95`).
class _PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _PressableScale({required this.child, this.onTap});

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: widget.child,
      ),
    );
  }
}
