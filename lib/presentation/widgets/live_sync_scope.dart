import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/providers/custom_views_provider.dart';
import 'package:m4_mobile/presentation/providers/hero_slider_provider.dart';
import 'package:m4_mobile/presentation/providers/image_overlay_provider.dart';
import 'package:m4_mobile/presentation/providers/live_sync_provider.dart';
import 'package:m4_mobile/presentation/providers/project_provider.dart';

/// Keeps admin-managed data in step with the server while the app is open.
///
/// On launch, whenever the app returns to the foreground, and every
/// [checkInterval] while it stays open, it asks the server whether projects,
/// site config, content, communities or amenities changed. The checks are cheap:
/// projects, config, content and amenities are revalidated with their ETag, so an
/// unchanged topic costs an empty `304 Not Modified`. Communities are compared by each
/// community's `updatedAt` instead, because their payload carries a
/// `projectCount` that differs on every request (a backend bug), which makes
/// their ETag useless as a change signal.
///
/// Project detail endpoints are deliberately never polled: each request bumps
/// the project's `views` counter (so its ETag is new every time), and an open
/// page re-checking it would inflate views. Pages watch [SyncTopic.amenities]
/// for their amenity icons instead.
///
/// When a topic changed, the shared providers are refreshed and a
/// [LiveSyncEvent] is published; open screens that call [listenForAdminChanges]
/// reload in place. The first round only records the baseline.
class LiveSyncScope extends ConsumerStatefulWidget {
  const LiveSyncScope({super.key, required this.child});

  final Widget child;

  // 10s: a round is 5 small requests, almost all empty 304s. Much shorter
  // keeps the phone's radio awake (battery) and loads the API for little gain;
  // instant updates are meant to come from server push, not a faster poll.
  static const Duration checkInterval = Duration(seconds: 10);

  @override
  ConsumerState<LiveSyncScope> createState() => _LiveSyncScopeState();
}

class _LiveSyncScopeState extends ConsumerState<LiveSyncScope>
    with WidgetsBindingObserver {
  static const Map<SyncTopic, String> _paths = {
    SyncTopic.catalog: '/api/catalog/projects',
    SyncTopic.config: '/api/config',
    SyncTopic.content: '/api/content',
    SyncTopic.communities: '/api/catalog/communities',
    SyncTopic.amenities: '/api/catalog/amenities',
  };

  /// Last ETag (for communities, the fingerprint) seen per topic.
  final Map<SyncTopic, String> _marks = {};
  Timer? _timer;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
    // Record the baseline once the first frame is up.
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _check();
      _startTimer();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      // No polling while the app is in the background.
      _timer?.cancel();
      _timer = null;
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(LiveSyncScope.checkInterval, (_) => _check());
  }

  Future<void> _check() async {
    if (_checking || !mounted) return;
    _checking = true;
    try {
      final changed = <SyncTopic>{};
      for (final topic in SyncTopic.values) {
        if (await _changed(topic)) changed.add(topic);
      }
      if (changed.isNotEmpty && mounted) _publish(changed);
    } finally {
      _checking = false;
    }
  }

  /// Whether [topic] changed since the last check. Never throws: being offline
  /// or a failed request just means "no news".
  Future<bool> _changed(SyncTopic topic) async {
    final previous = _marks[topic];
    final useEtag = topic != SyncTopic.communities;
    try {
      final res = await ref
          .read(apiClientProvider)
          .dio
          .get<dynamic>(
            _paths[topic]!,
            options: Options(
              headers: {
                if (useEtag && previous != null) 'If-None-Match': previous,
              },
              receiveTimeout: const Duration(seconds: 20),
              // 304 Not Modified is the normal "nothing changed" answer.
              validateStatus: (s) => s != null && s < 500,
            ),
          );
      if (res.statusCode != 200) return false;
      final mark = useEtag
          ? res.headers.value('etag')
          : _communitiesFingerprint(res.data);
      if (mark == null) return false;
      _marks[topic] = mark;
      return previous != null && previous != mark;
    } catch (_) {
      return false;
    }
  }

  /// `_id:updatedAt` of every community, sorted. Ignores `projectCount`, which
  /// the server currently returns differently on each request.
  static String? _communitiesFingerprint(dynamic body) {
    final list = body is Map ? body['data'] : null;
    if (list is! List) return null;
    final parts = [
      for (final c in list)
        if (c is Map) '${c['_id']}:${c['updatedAt']}',
    ]..sort();
    return parts.join('|');
  }

  void _publish(Set<SyncTopic> changed) {
    if (changed.contains(SyncTopic.catalog)) {
      // Drop the memoised catalog first, or the refresh could be handed the
      // copy fetched just before the change.
      forgetCatalogMemo();
      ref.invalidate(projectsProvider);
    }
    if (changed.contains(SyncTopic.config)) {
      ref.invalidate(heroSliderProvider);
      ref.invalidate(imageOverlayProvider);
      ref.invalidate(customizationPageProvider);
    }
    final current = ref.read(liveSyncProvider);
    ref.read(liveSyncProvider.notifier).state = LiveSyncEvent(
      current.version + 1,
      changed,
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
