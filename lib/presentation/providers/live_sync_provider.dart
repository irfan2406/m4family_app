import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The kinds of admin-managed data the app keeps in step with the server.
/// [LiveSyncScope] checks each one and reports which of them changed.
enum SyncTopic {
  /// Projects: `/api/catalog/projects` (lists, home cards, project pages).
  catalog,

  /// Site config: `/api/config` (home hero slider and other settings).
  config,

  /// Blog, media, events and highlights: `/api/content`.
  content,

  /// Communities: `/api/catalog/communities`.
  communities,

  /// Amenities and their icons: `/api/catalog/amenities`. The projects list
  /// carries amenities only as ids, so an icon replaced in admin changes this
  /// list and not [catalog]; project pages watch both.
  amenities,
}

/// One round of "the server says these topics changed". [version] goes up by
/// one per round, so every round is a new value even when the same topic
/// changes twice in a row.
@immutable
class LiveSyncEvent {
  const LiveSyncEvent(this.version, this.topics);

  final int version;
  final Set<SyncTopic> topics;

  bool touches(Set<SyncTopic> watched) => topics.any(watched.contains);
}

/// The latest admin-change round, published by [LiveSyncScope].
final liveSyncProvider = StateProvider<LiveSyncEvent>(
  (ref) => const LiveSyncEvent(0, <SyncTopic>{}),
);

/// Re-runs [reload] whenever the server reports a change in any of [topics],
/// so a screen that is already open shows an admin edit without being reopened.
///
/// Call it from `build` (like any `ref.listen`). [reload] should refresh the
/// screen in place, without showing a loading spinner over its current content.
void listenForAdminChanges(
  WidgetRef ref,
  Set<SyncTopic> topics,
  VoidCallback reload,
) {
  ref.listen<LiveSyncEvent>(liveSyncProvider, (previous, next) {
    if (next.touches(topics)) reload();
  });
}
