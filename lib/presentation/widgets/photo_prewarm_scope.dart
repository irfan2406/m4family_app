import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m4_mobile/core/utils/image_prewarm.dart';
import 'package:m4_mobile/core/utils/media_url.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/providers/live_sync_provider.dart';
import 'package:m4_mobile/presentation/providers/project_provider.dart';

/// Starts downloading every project's card photo as soon as the app opens.
///
/// The backend serves full-size originals (1.5–6 MB each), which take 5–15 s
/// to arrive on a phone; until then a card shows its loading placeholder. The
/// home screens already warm their first few cards, but only once their own
/// data is in, and the Properties list warmed nothing. Here the shared
/// catalog is read at start-up and each project's Master Image (`heroImage`,
/// the picture every project card shows) goes into the shared disk cache —
/// so by the time Properties or a home tab is opened, the photos are usually
/// already on the phone and appear at once.
///
/// Downloads run one at a time (see [prewarmImages]) and a URL already being
/// fetched by a screen is shared, not downloaded twice. When the admin edits
/// projects (live sync) the new photos are warmed too.
class PhotoPrewarmScope extends ConsumerStatefulWidget {
  const PhotoPrewarmScope({super.key, required this.child});

  final Widget child;

  /// Enough for every card a person is likely to scroll to.
  static const int maxProjects = 12;

  @override
  ConsumerState<PhotoPrewarmScope> createState() => _PhotoPrewarmScopeState();
}

class _PhotoPrewarmScopeState extends ConsumerState<PhotoPrewarmScope> {
  /// URLs already queued this session, so a catalog refresh only adds new ones.
  final Set<String> _queued = {};

  @override
  void initState() {
    super.initState();
    // After the first frame, so start-up itself is never delayed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(projectsProvider.future).then(_warm, onError: (_) {});
    });
  }

  void _warm(List<dynamic> projects) {
    if (!mounted) return;
    final api = ref.read(apiClientProvider);
    final urls = <String>[];
    for (final p in projects.take(PhotoPrewarmScope.maxProjects)) {
      final hero = projectHeroUrl(p);
      if (hero.isEmpty) continue;
      final url = api.resolveUrl(hero);
      if (url.startsWith('http') && _queued.add(url)) urls.add(url);
    }
    prewarmImages(urls);
  }

  @override
  Widget build(BuildContext context) {
    // A fresh catalog (first load, or an admin edit) may carry new photos.
    ref.listen<AsyncValue<List<dynamic>>>(projectsProvider, (_, next) {
      final projects = next.valueOrNull;
      if (projects != null) _warm(projects);
    });
    listenForAdminChanges(ref, const {SyncTopic.catalog}, () {
      ref.read(projectsProvider.future).then(_warm, onError: (_) {});
    });
    return widget.child;
  }
}
