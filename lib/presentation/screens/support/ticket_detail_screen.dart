import 'dart:async';

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

  /// Polls the open chat every 15s so an admin's reply shows up live, the
  /// same cadence the website uses.
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _ticket = widget.initialTicket;
    _messages = (widget.initialTicket?['messages'] as List<dynamic>?) ?? [];
    _ownerId = _extractId(widget.initialTicket?['user']);
    Future.microtask(_fetchTicket);
    _pollTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _pollTicket(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ─── Data ──────────────────────────────────────────────────────────────────

  Future<void> _fetchTicket() async {
    try {
      final data = await ref
          .read(supportProvider.notifier)
          .fetchTicketDetail(widget.ticketId);
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

  /// Silent refresh used by the 15s poll and pull-to-refresh: it never flips
  /// the screen back to the loading/error state, it just folds in any new
  /// messages and scrolls down when the count grows.
  Future<void> _pollTicket() async {
    if (_sending) return; // don't fight an in-flight send
    try {
      final data = await ref
          .read(supportProvider.notifier)
          .fetchTicketDetail(widget.ticketId);
      if (!mounted || data == null) return;
      final next = (data['messages'] as List<dynamic>?) ?? _messages;
      final grew = next.length > _messages.length;
      setState(() {
        _ticket = data;
        _messages = next;
        _ownerId = _extractId(data['user']) ?? _ownerId;
        _loading = false;
        _error = null;
      });
      if (grew) _scrollToBottom();
    } catch (_) {
      // Polling is best-effort; keep whatever is already on screen.
    }
  }

  Future<void> _handleSend() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    final updated = await ref
        .read(supportProvider.notifier)
        .sendMessage(widget.ticketId, text);
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
        const SnackBar(
          backgroundColor: Color(0xFFC65B46),
          content: Text('Failed to send message'),
        ),
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
    if (value is Map)
      return value['_id']?.toString() ?? value['id']?.toString();
    return value.toString();
  }

  /// A message is from M4 Support when its sender's role is ADMIN, or — in the
  /// shapes where the sender is only an id — when it isn't the ticket owner.
  /// Those render on the LEFT, labelled "M4 Support".
  bool _isSupportMessage(dynamic msg) {
    if (msg is! Map) return false;
    final sender = msg['sender'];
    // GET /tickets/:id populates sender as an object with a role — trust it.
    if (sender is Map) {
      final role = sender['role']?.toString().toUpperCase();
      if (role == 'ADMIN') return true;
      if (role != null && role.isNotEmpty) return false; // the user's own role
    }
    // Fallback (sender is a bare id, or role missing): support when it is not
    // the ticket owner.
    final sid = _extractId(sender);
    if (sid == null || _ownerId == null) return false; // can't tell → user side
    return sid != _ownerId;
  }

  /// The user's own messages sit on the right; everything else (support) left.
  bool _isUserMessage(dynamic msg) => !_isSupportMessage(msg);

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

  String get _displayId {
    final tid = _ticket?['ticketId'] as String?;
    if (tid != null && tid.isNotEmpty) return tid;
    final id = widget.ticketId;
    return id.length > 8
        ? id.substring(id.length - 8).toUpperCase()
        : id.toUpperCase();
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.black : const Color(0xFFF4EFE3);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0C312B);
    final muted = (isDark ? Colors.white : const Color(0xFF0C312B)).withValues(
      alpha: 0.68,
    );
    final border = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

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
                  ? const Center(
                      child: CircularProgressIndicator.adaptive(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          M4Theme.premiumBlue,
                        ),
                      ),
                    )
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

  Widget _buildHeader(
    bool isDark,
    Color textPrimary,
    Color muted,
    Color border,
  ) {
    final subject =
        (_ticket?['subject'] as String?)?.toUpperCase() ?? 'TICKET $_displayId';
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: isDark ? Colors.black : const Color(0xFFF4EFE3),
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
                color: isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : const Color(0xFFF4EFE3),
                shape: BoxShape.circle,
                border: Border.all(color: border),
              ),
              child: Icon(
                LucideIcons.chevronLeft,
                size: 18,
                color: textPrimary,
              ),
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
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                // Web parity: a green "active" dot and AGENT ONLINE in the
                // header's bold sans. The dot was #163A2C, which reads as
                // black rather than as "online".
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
                      'AGENT ONLINE',
                      style: GoogleFonts.inter(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: muted,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ],
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
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: textPrimary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'RETRY',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: textPrimary == Colors.white
                        ? const Color(0xFF0C312B)
                        : Colors.white,
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

  Widget _buildThread(
    bool isDark,
    Color textPrimary,
    Color muted,
    Color border,
  ) {
    if (_messages.isEmpty) {
      return RefreshIndicator.adaptive(
        onRefresh: _pollTicket,
        color: textPrimary,
        child: ListView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.3),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.messageSquare, size: 40, color: muted),
                const SizedBox(height: 20),
                Text(
                  'NO MESSAGES YET',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'START THE CONVERSATION BELOW',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: muted,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return RefreshIndicator.adaptive(
      onRefresh: _pollTicket,
      color: textPrimary,
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        children: [
        // Date chip (web: "Today, Jan 26")
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : const Color(0xFFF4EFE3),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: border),
            ),
            child: Text(
              DateFormat('EEEE, MMM d').format(DateTime.now()).toUpperCase(),
              style: GoogleFonts.gelasio(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: muted,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        ..._messages.map(
          (m) => _buildBubble(m, isDark, textPrimary, muted, border),
        ),
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
                  style: GoogleFonts.gelasio(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
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
      ),
    );
  }

  Widget _buildBubble(
    dynamic msg,
    bool isDark,
    Color textPrimary,
    Color muted,
    Color border,
  ) {
    final isUser = _isUserMessage(msg);
    final text = (msg is Map)
        ? (msg['text']?.toString() ?? '')
        : msg.toString();
    final time = _formatTime(msg);
    final attachment = (msg is Map) ? msg['attachment']?.toString() : null;
    final apiClient = ref.read(apiClientProvider);

    // User bubble: solid (foreground/background inversion). Support: card style.
    final bubbleColor = isUser
        ? textPrimary
        : (isDark
              ? Colors.white.withValues(alpha: 0.03)
              : const Color(0xFFF4EFE3));
    final bubbleTextColor = isUser
        ? (isDark ? Colors.black : Colors.white)
        : textPrimary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          // Name the sender on support replies so the user can see it is M4,
          // not their own message.
          if (!isUser) ...[
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.shieldCheck, size: 11, color: muted),
                  const SizedBox(width: 5),
                  Text(
                    'M4 SUPPORT',
                    style: GoogleFonts.inter(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: muted,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
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
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: bubbleTextColor,
                        height: 1.4,
                      ),
                    ),
                  if (attachment != null && attachment.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildAttachment(
                      attachment,
                      apiClient,
                      isUser,
                      bubbleTextColor,
                    ),
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
                  style: GoogleFonts.gelasio(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
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

  Widget _buildAttachment(
    String attachment,
    ApiClient apiClient,
    bool isUser,
    Color textColor,
  ) {
    final url = apiClient.resolveUrl(attachment);
    final isImage = RegExp(
      r'\.(jpg|jpeg|png|gif|webp)$',
      caseSensitive: false,
    ).hasMatch(attachment);

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
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
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
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: textColor,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(
    bool isDark,
    Color textPrimary,
    Color muted,
    Color border,
  ) {
    final card = isDark
        ? Colors.white.withValues(alpha: 0.03)
        : const Color(0xFFF4EFE3);
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).viewPadding.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? Colors.black : const Color(0xFFF4EFE3),
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
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter Message',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: muted.withValues(alpha: 0.6),
                    letterSpacing: 1,
                  ),
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
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
                      child: CircularProgressIndicator.adaptive(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark ? Colors.black : const Color(0xFFF4EFE3),
                        ),
                      ),
                    )
                  : Icon(
                      LucideIcons.send,
                      size: 18,
                      color: isDark
                          ? const Color(0xFF0C312B)
                          : const Color(0xFFF4EFE3),
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
