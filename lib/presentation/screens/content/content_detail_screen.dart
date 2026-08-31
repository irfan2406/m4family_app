import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:flutter/services.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class ContentDetailScreen extends ConsumerStatefulWidget {
  final dynamic content;

  const ContentDetailScreen({super.key, required this.content});

  @override
  ConsumerState<ContentDetailScreen> createState() =>
      _ContentDetailScreenState();
}

class _ContentDetailScreenState extends ConsumerState<ContentDetailScreen> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    final videoUrl = widget.content['videoUrl'];
    if (videoUrl != null && videoUrl.toString().isNotEmpty) {
      final apiClient = ref.read(apiClientProvider);
      final resolvedUrl = apiClient.resolveUrl(videoUrl);
      final imageUrl = apiClient.resolveUrl(
        (widget.content['image'] != null &&
                widget.content['image'].toString().isNotEmpty)
            ? widget.content['image']
            : widget.content['thumbnail'],
      );

      try {
        _videoPlayerController = VideoPlayerController.networkUrl(
          Uri.parse(resolvedUrl),
        );

        // Add a timeout to initialization
        await _videoPlayerController!.initialize().timeout(
          const Duration(seconds: 15),
        );

        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController!,
          autoPlay: false,
          looping: false,
          aspectRatio: _videoPlayerController!.value.aspectRatio,
          materialProgressColors: ChewieProgressColors(
            playedColor: Colors.white,
            handleColor: Colors.white,
            backgroundColor: Colors.white.withOpacity(0.2),
            bufferedColor: Colors.white.withOpacity(0.5),
          ),
          placeholder: Container(
            color: Colors.black,
            child: Stack(
              children: [
                if (imageUrl.isNotEmpty)
                  Opacity(
                    opacity: 0.3,
                    child: Image.network(
                      imageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ],
            ),
          ),
          autoInitialize: true,
          allowFullScreen: true,
          // Web parity: custom controls so play/time + volume, fullscreen and
          // the 3-dot all sit together in the bottom bar (right side).
          showOptions: false,
          customControls: const _M4VideoControls(),
          deviceOrientationsOnEnterFullScreen:
              _videoPlayerController!.value.aspectRatio < 1
              ? [DeviceOrientation.portraitUp]
              : [
                  DeviceOrientation.landscapeLeft,
                  DeviceOrientation.landscapeRight,
                ],
          deviceOrientationsAfterFullScreen: [DeviceOrientation.portraitUp],
          systemOverlaysOnEnterFullScreen:
              [], // Immersive mode (hide status bar)
          systemOverlaysAfterFullScreen: SystemUiOverlay.values,
          errorBuilder: (context, errorMessage) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    LucideIcons.alertCircle,
                    color: Colors.white,
                    size: 40,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Video format not supported or unreachable',
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          },
        );

        if (mounted) {
          setState(() {
            _isVideoInitialized = true;
          });
        }
      } catch (e) {
        print('DEBUG: Video Init Error: $e');
        // Still allow fallback UI to show
        if (mounted) setState(() => _isVideoInitialized = false);
      }
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  void _shareContent(ApiClient apiClient) {
    final String title = widget.content['title'] ?? 'M4 Family Article';
    final String slug = widget.content['slug'] ?? '';
    final String type = widget.content['type'] ?? 'media';

    // Construct web URL based on API base URL
    String webUrl = apiClient.baseUrl;
    if (webUrl.endsWith('/api'))
      webUrl = webUrl.substring(0, webUrl.length - 4);
    if (webUrl.endsWith('/')) webUrl = webUrl.substring(0, webUrl.length - 1);

    final String fullUrl = '$webUrl/$type/$slug';

    Share.share(
      'Check out this article from M4 Family: $title\n\nRead more at: $fullUrl',
      subject: title,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final apiClient = ref.read(apiClientProvider);

    final String? rawImage =
        (widget.content['image'] != null &&
            widget.content['image'].toString().isNotEmpty)
        ? widget.content['image']
        : (widget.content['thumbnail'] != null &&
              widget.content['thumbnail'].toString().isNotEmpty)
        ? widget.content['thumbnail']
        : widget.content['coverImage'];
    final imageUrl = apiClient.resolveUrl(rawImage);
    final date =
        DateTime.tryParse(widget.content['createdAt'] ?? '') ?? DateTime.now();
    final formattedDate = DateFormat('MM/dd/yyyy').format(date);
    final hasVideo =
        widget.content['videoUrl'] != null &&
        widget.content['videoUrl'].toString().isNotEmpty;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🏷️ STANDARDIZED HEADER (Web Parity)
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildCircleButton(
                            icon: LucideIcons.arrowLeft,
                            onTap: () => Navigator.pop(context),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.content['type'].toString().toUpperCase(),
                                style: GoogleFonts.gelasio(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2,
                                  color: scheme.onSurface,
                                ),
                              ),
                              // Web parity: "DEEP DIVE" kicker under the type.
                              Text(
                                'DEEP DIVE',
                                style: GoogleFonts.gelasio(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 3,
                                  color: scheme.onSurface.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          _buildCircleButton(
                            icon: LucideIcons.share2,
                            onTap: () => _shareContent(apiClient),
                            isBlack: true,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 🖼️ MEDIA PLAYER (Fixed 16:9)
                  Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        color: Colors.black,
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: hasVideo
                              ? (_isVideoInitialized &&
                                        _chewieController != null
                                    ? Chewie(controller: _chewieController!)
                                    : Container(
                                        color: Colors.black,
                                        child: Stack(
                                          children: [
                                            if (imageUrl.isNotEmpty)
                                              Opacity(
                                                opacity: 0.3,
                                                child: Image.network(
                                                  imageUrl,
                                                  width: double.infinity,
                                                  height: double.infinity,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            const Center(
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ))
                              : (imageUrl.isNotEmpty
                                    ? Image.network(imageUrl, fit: BoxFit.cover)
                                    : Center(
                                        child: Icon(
                                          _getIcon(
                                            widget.content['type'] ?? 'media',
                                          ),
                                          color: Colors.white.withOpacity(0.1),
                                          size: 60,
                                        ),
                                      )),
                        ),
                      ),
                    ],
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(25, 30, 25, 60),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                // Web parity: black text on a light-grey pill
                                // (bg-primary/10) with a soft drop shadow.
                                color: scheme.onSurface.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: scheme.onSurface.withOpacity(0.1),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    // Light-grey drop shadow (was a dark shadow).
                                    color: Colors.grey.withOpacity(0.35),
                                    blurRadius: 18,
                                    offset: const Offset(0, 7),
                                  ),
                                ],
                              ),
                              child: Text(
                                widget.content['type'].toString().toUpperCase(),
                                style: GoogleFonts.gelasio(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: scheme.onSurface,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Text(
                              formattedDate,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurface.withOpacity(0.68),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 25),

                        Text(
                          widget.content['title'].toString().toUpperCase(),
                          style: GoogleFonts.gelasio(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                            letterSpacing: -1,
                            height: 1.1,
                          ),
                        ),

                        const SizedBox(height: 30),

                        Text(
                          widget.content['description'] ??
                              'No description provided.',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: scheme.onSurface.withOpacity(0.6),
                            height: 1.8,
                            fontWeight: FontWeight.w400,
                          ),
                        ),

                        if (widget.content['content'] != null &&
                            widget.content['content']
                                .toString()
                                .isNotEmpty) ...[
                          const SizedBox(height: 20),
                          HtmlWidget(
                            widget.content['content'],
                            textStyle: GoogleFonts.inter(
                              fontSize: 15,
                              color: scheme.onSurface.withOpacity(0.6),
                              height: 1.8,
                            ),
                          ),
                        ],

                        // 📅 EVENT-SPECIFIC SECTIONS (only for type == 'event' and when API provides the fields)
                        if (widget.content['type']?.toString().toLowerCase() ==
                            'event')
                          ..._buildEventSections(apiClient),

                        const SizedBox(height: 60),

                        // 🔘 SHARE ARTICLE BUTTON (Bottom)
                        _buildShareButton(apiClient),

                        const SizedBox(height: 15),

                        // 🔘 CLOSE BUTTON
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: double.infinity,
                            height: 65,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: scheme.onSurface.withOpacity(0.1),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'CLOSE',
                                style: GoogleFonts.gelasio(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: scheme.onSurface.withOpacity(0.6),
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isBlack = false,
    bool isOverMedia = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isOverMedia
              ? Colors.black.withOpacity(0.3)
              : (isBlack ? const Color(0xFF141B3A) : scheme.surface),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isOverMedia
                ? Colors.white.withOpacity(0.1)
                : scheme.onSurface.withOpacity(0.05),
          ),
          boxShadow: isOverMedia
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
        ),
        child: Icon(
          icon,
          size: 20,
          color: isOverMedia
              ? Colors.white
              : (isBlack ? Colors.white : scheme.onSurface),
        ),
      ),
    );
  }

  Widget _buildShareButton(ApiClient apiClient) {
    return GestureDetector(
      onTap: () => _shareContent(apiClient),
      child: Container(
        width: double.infinity,
        height: 65,
        decoration: BoxDecoration(
          color: const Color(0xFF141B3A),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'SHARE THIS ARTICLE',
              style: GoogleFonts.gelasio(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(width: 15),
            const Icon(LucideIcons.share2, size: 20, color: Colors.white),
          ],
        ),
      ),
    );
  }

  // ─── EVENT-SPECIFIC SECTIONS ────────────────────────────────────────────────
  // Defensive: each section only renders when the API actually returns the field.
  // Mirrors guest_project_detail_screen.dart styling (Montserrat, rounded cards,
  // dark/light branch, M4Theme.premiumBlue accent, lucide icons).
  List<Widget> _buildEventSections(ApiClient apiClient) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final eventDate =
        widget.content['eventDate'] ?? widget.content['startTime'];
    final eventTime =
        widget.content['eventTime'] ?? widget.content['startTime'];
    final rawLocation = widget.content['location'];
    final location =
        (rawLocation is Map ? rawLocation['name'] : rawLocation) ??
        widget.content['venue'];
    final attendees = widget.content['attendees'] as List? ?? [];
    final attendeeCount = widget.content['attendeeCount'] ?? attendees.length;
    final rsvpUrl = widget.content['rsvpUrl'] ?? widget.content['registerUrl'];
    final eventStatus = widget.content['eventStatus']?.toString();

    final hasDate = eventDate != null && eventDate.toString().isNotEmpty;
    final hasTime = eventTime != null && eventTime.toString().isNotEmpty;
    final hasLocation = location != null && location.toString().isNotEmpty;
    final hasAttendees =
        attendees.isNotEmpty ||
        (attendeeCount is int
            ? attendeeCount > 0
            : (widget.content['attendeeCount'] != null));
    final hasRsvp = rsvpUrl != null && rsvpUrl.toString().isNotEmpty;
    final hasStatus = eventStatus != null && eventStatus.isNotEmpty;

    // If the API hasn't added event-specific fields yet, render nothing.
    if (!hasDate &&
        !hasTime &&
        !hasLocation &&
        !hasAttendees &&
        !hasRsvp &&
        !hasStatus) {
      return const [];
    }

    return [
      const SizedBox(height: 30),

      if (hasStatus) ...[
        _buildEventStatusBadge(eventStatus, isDark),
        const SizedBox(height: 20),
      ],

      if (hasDate || hasTime) ...[
        _buildEventDateTimeCard(eventDate, eventTime, isDark),
        const SizedBox(height: 16),
      ],

      if (hasLocation) ...[
        _buildEventLocation(location.toString(), isDark),
        const SizedBox(height: 16),
      ],

      if (hasAttendees) ...[
        _buildEventAttendees(attendees, attendeeCount, isDark),
        const SizedBox(height: 16),
      ],

      if (hasRsvp) ...[
        const SizedBox(height: 14),
        _buildRsvpButton(rsvpUrl.toString()),
      ],
    ];
  }

  String _formatEventDate(dynamic raw) {
    final parsed = DateTime.tryParse(raw?.toString() ?? '');
    if (parsed == null) return raw?.toString() ?? '';
    return DateFormat('EEEE, MMMM d, yyyy').format(parsed);
  }

  String _formatEventTime(dynamic raw) {
    final parsed = DateTime.tryParse(raw?.toString() ?? '');
    if (parsed == null) return raw?.toString() ?? '';
    String range = DateFormat('h:mm a').format(parsed);
    final endRaw = widget.content['endTime'] ?? widget.content['eventEndTime'];
    final end = DateTime.tryParse(endRaw?.toString() ?? '');
    if (end != null) range = '$range - ${DateFormat('h:mm a').format(end)}';
    return range;
  }

  Widget _buildEventStatusBadge(String status, bool isDark) {
    Color color;
    switch (status.toUpperCase()) {
      case 'TODAY':
        color = const Color(0xFFC5A35B);
        break;
      case 'ENDED':
        color = isDark ? Colors.white38 : const Color(0xFF155A4F);
        break;
      case 'CANCELLED':
        color = const Color(0xFFC65B46);
        break;
      case 'UPCOMING':
      default:
        color = M4Theme.premiumBlue;
        break;
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          status.toUpperCase(),
          style: GoogleFonts.gelasio(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard({required Widget child, required bool isDark}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : const Color(0xFFF4EFE3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: child,
    );
  }

  Widget _buildEventInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: M4Theme.premiumBlue.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: M4Theme.premiumBlue),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: GoogleFonts.gelasio(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white38 : const Color(0xFF155A4F),
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF155A4F),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEventDateTimeCard(
    dynamic eventDate,
    dynamic eventTime,
    bool isDark,
  ) {
    final hasDate = eventDate != null && eventDate.toString().isNotEmpty;
    final hasTime = eventTime != null && eventTime.toString().isNotEmpty;
    return _buildEventCard(
      isDark: isDark,
      child: Column(
        children: [
          if (hasDate)
            _buildEventInfoRow(
              icon: LucideIcons.calendar,
              label: 'Date',
              value: _formatEventDate(eventDate),
              isDark: isDark,
            ),
          if (hasDate && hasTime) const SizedBox(height: 18),
          if (hasTime)
            _buildEventInfoRow(
              icon: LucideIcons.clock,
              label: 'Time',
              value: _formatEventTime(eventTime),
              isDark: isDark,
            ),
        ],
      ),
    );
  }

  Widget _buildEventLocation(String location, bool isDark) {
    return GestureDetector(
      onTap: () => _launchUrl(
        'https://www.google.com/maps?q=${Uri.encodeComponent(location)}',
      ),
      child: _buildEventCard(
        isDark: isDark,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: M4Theme.premiumBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.mapPin,
                size: 20,
                color: M4Theme.premiumBlue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LOCATION',
                    style: GoogleFonts.gelasio(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white38 : const Color(0xFF155A4F),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    location,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF155A4F),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'VIEW ON MAPS ↗',
                    style: GoogleFonts.inter(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: M4Theme.premiumBlue,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventAttendees(
    List attendees,
    dynamic attendeeCount,
    bool isDark,
  ) {
    final count = attendeeCount is int
        ? attendeeCount
        : int.tryParse(attendeeCount?.toString() ?? '') ?? attendees.length;
    final visible = attendees.take(5).toList();
    return _buildEventCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.users,
                size: 16,
                color: M4Theme.premiumBlue,
              ),
              const SizedBox(width: 10),
              Text(
                '$count ATTENDING',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF155A4F),
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          if (visible.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: visible.map((a) {
                final name =
                    (a is Map ? (a['name'] ?? a['fullName']) : a)?.toString() ??
                    '';
                final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
                return Container(
                  margin: const EdgeInsets.only(right: 10),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: M4Theme.premiumBlue.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: M4Theme.premiumBlue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: M4Theme.premiumBlue,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRsvpButton(String rsvpUrl) {
    return GestureDetector(
      onTap: () => _launchUrl(rsvpUrl),
      child: Container(
        width: double.infinity,
        height: 65,
        decoration: BoxDecoration(
          color: const Color(0xFF141B3A),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'RSVP TO EVENT',
              style: GoogleFonts.gelasio(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(width: 15),
            const Icon(
              LucideIcons.calendarCheck,
              size: 20,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final apiClient = ref.read(apiClientProvider);
    final resolved = apiClient.resolveUrl(url);
    final uri = Uri.parse(resolved);
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: resolved.startsWith('http')
            ? LaunchMode.inAppBrowserView
            : LaunchMode.platformDefault,
      );
    }
  }

  IconData _getIcon(String type) {
    switch (type.toLowerCase()) {
      case 'media':
        return LucideIcons.playCircle;
      case 'highlight':
        return LucideIcons.zap;
      case 'blog':
        return LucideIcons.fileText;
      case 'event':
        return LucideIcons.calendar;
      default:
        return LucideIcons.image;
    }
  }
}

/// Web-parity video controls: play/time on the left, and sound + fullscreen +
/// 3-dot grouped together on the right — all in the bottom bar.
class _M4VideoControls extends StatefulWidget {
  const _M4VideoControls();

  @override
  State<_M4VideoControls> createState() => _M4VideoControlsState();
}

class _M4VideoControlsState extends State<_M4VideoControls> {
  ChewieController? _chewie;
  bool _visible = true;
  bool _muted = false;
  bool _menuOpen = false;
  bool _speedOpen = false;
  Timer? _hideTimer;

  VideoPlayerController get _vpc => _chewie!.videoPlayerController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _chewie = ChewieController.of(context);
    _startHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _vpc.value.isPlaying) setState(() => _visible = false);
    });
  }

  void _togglePlay() {
    setState(() {
      if (_vpc.value.isPlaying) {
        _vpc.pause();
      } else {
        _vpc.play();
        _startHideTimer();
      }
    });
  }

  void _toggleMute() {
    setState(() {
      _muted = !_muted;
      _vpc.setVolume(_muted ? 0 : 1);
    });
    _startHideTimer();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Widget _ctrlIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }

  // ─── 3-dot menu (web parity): a small WHITE popup shown OVER the video,
  // anchored bottom-right by the 3-dot — not a dark bottom sheet.
  void _openMenu() {
    _hideTimer?.cancel();
    setState(() {
      _menuOpen = true;
      _speedOpen = false;
      _visible = true;
    });
  }

  void _closeMenus() {
    setState(() {
      _menuOpen = false;
      _speedOpen = false;
    });
    _startHideTimer();
  }

  Widget _menuCard(List<Widget> rows) {
    return Container(
      constraints: const BoxConstraints(minWidth: 190),
      decoration: BoxDecoration(
        color: const Color(0xFFF4EFE3),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: rows),
    );
  }

  Widget _menuRow(IconData? icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 22,
              child: icon == null
                  ? null
                  : Icon(icon, size: 18, color: const Color(0xDD0C312B)),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.inter(
                color: const Color(0xDD0C312B),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _download() async {
    try {
      await launchUrl(
        Uri.parse(_vpc.dataSource),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {}
  }

  // Native PiP is wired in MainActivity + AndroidManifest; it only activates
  // after a full `flutter build apk` (the hot-patch deploy can't ship native
  // code). No-ops gracefully until then.
  Future<void> _enterPip() async {
    try {
      await const MethodChannel('m4/pip').invokeMethod('enter');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        // Tapping the video closes an open menu first, else toggles controls.
        if (_menuOpen || _speedOpen) {
          _closeMenus();
          return;
        }
        setState(() => _visible = !_visible);
        if (_visible) _startHideTimer();
      },
      child: AnimatedOpacity(
        opacity: (_visible || _menuOpen || _speedOpen) ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        child: Stack(
          children: [
            Container(color: Colors.black.withOpacity(0.25)),
            Center(
              child: GestureDetector(
                onTap: _togglePlay,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.35),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _vpc.value.isPlaying ? LucideIcons.pause : LucideIcons.play,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 8,
              child: ValueListenableBuilder<VideoPlayerValue>(
                valueListenable: _vpc,
                builder: (context, value, _) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _togglePlay,
                            child: Icon(
                              value.isPlaying
                                  ? LucideIcons.pause
                                  : LucideIcons.play,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${_fmt(value.position)} / ${_fmt(value.duration)}',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          // Right group: sound + fullscreen + 3-dot together.
                          _ctrlIcon(
                            _muted ? LucideIcons.volumeX : LucideIcons.volume2,
                            _toggleMute,
                          ),
                          const SizedBox(width: 16),
                          _ctrlIcon(
                            LucideIcons.maximize,
                            () => _chewie!.toggleFullScreen(),
                          ),
                          const SizedBox(width: 16),
                          _ctrlIcon(LucideIcons.moreVertical, _openMenu),
                        ],
                      ),
                      const SizedBox(height: 6),
                      VideoProgressIndicator(
                        _vpc,
                        allowScrubbing: true,
                        padding: EdgeInsets.zero,
                        colors: VideoProgressColors(
                          playedColor: Colors.white,
                          bufferedColor: Colors.white.withOpacity(0.4),
                          backgroundColor: Colors.white.withOpacity(0.2),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            // 3-dot popup — small white card over the video, bottom-right.
            if (_menuOpen || _speedOpen)
              Positioned(
                right: 12,
                bottom: 46,
                child: _menuOpen
                    ? _menuCard([
                        _menuRow(LucideIcons.download, 'Download', () {
                          _closeMenus();
                          _download();
                        }),
                        _menuRow(LucideIcons.gauge, 'Playback speed', () {
                          setState(() {
                            _menuOpen = false;
                            _speedOpen = true;
                          });
                        }),
                        _menuRow(
                          LucideIcons.pictureInPicture2,
                          'Picture in picture',
                          () {
                            _closeMenus();
                            _enterPip();
                          },
                        ),
                      ])
                    : _menuCard([
                        for (final s in const [0.5, 0.75, 1.0, 1.5, 2.0])
                          _menuRow(
                            (_vpc.value.playbackSpeed - s).abs() < 0.01
                                ? LucideIcons.check
                                : null,
                            s == 1.0 ? 'Normal' : '${s}x',
                            () {
                              _vpc.setPlaybackSpeed(s);
                              _closeMenus();
                            },
                          ),
                      ]),
              ),
          ],
        ),
      ),
    );
  }
}
