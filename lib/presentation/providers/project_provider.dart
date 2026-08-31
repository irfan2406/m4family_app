import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show compute;
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

// The guest home persists the last successful catalog payload to this file. The
// projects provider reuses its `projects` slice as a fallback so the Properties
// screen still shows data when the backend is slow or returns a 504 (the
// projects endpoint is bloated by a multi-MB base64 hero image and times out).
File get _homeCacheFile =>
    File('${Directory.systemTemp.path}/m4_guest_home_cache.json');

Future<List<dynamic>?> _loadCachedProjects() async {
  try {
    final f = _homeCacheFile;
    if (!await f.exists()) return null;
    // Multi-MB payload: decode on a background isolate so the first
    // frames are not blocked by parsing base64-laden JSON.
    final map = await compute(jsonDecode, await f.readAsString());
    final list = map is Map ? map['projects'] : null;
    return (list is List && list.isNotEmpty) ? list : null;
  } catch (_) {
    return null;
  }
}

/// Persists a freshly fetched catalog into the shared home cache.
///
/// Without this the live payload was thrown away whenever the grace window
/// below won the race (which it always does — the endpoint takes ~90s), so the
/// app stayed on [_placeholderProjects] forever. Those placeholders use slugs
/// as `_id` ('cledor', 'skai'), and submitting one to the API fails with
/// `Cast to ObjectId failed for value "cledor"` — every booking/visit against a
/// placeholder project was rejected. Saving the live payload lets the app heal
/// itself: the next read gets real projects with real ObjectIds.
Future<void> _saveCachedProjects(List<dynamic> projects) async {
  try {
    final f = _homeCacheFile;
    Map<String, dynamic> map = {};
    if (await f.exists()) {
      final decoded = await compute(jsonDecode, await f.readAsString());
      if (decoded is Map) map = Map<String, dynamic>.from(decoded);
    }
    // Merge — the guest home owns the communities/media slices of this file.
    map['projects'] = projects;
    await f.writeAsString(await compute(jsonEncode, map));
  } catch (_) {
    // Best-effort cache; never surface to the UI.
  }
}

// Shown when there is no cache AND the live projects call fails (the bloated
// base64 payload 504s). Prevents the Properties screen from dead-ending on the
// "COULDN'T LOAD" error state. Statuses span all three tabs so none is empty.
// Uses network image URLs (the list card can't render bundled assets).
List<dynamic> _placeholderProjects() => [
  {
    '_id': 'cledor',
    'title': 'Cledor',
    'status': 'Ongoing',
    'location': {'name': 'Mumbai'},
    'heroImages': [
      'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&q=80',
    ],
    'description':
        'A thoughtfully designed residential tower that blends modern architecture with timeless elegance.',
  },
  {
    '_id': 'skai',
    'title': 'Skai',
    'status': 'Ongoing',
    'location': {'name': 'Mumbai'},
    'heroImages': [
      'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&q=80',
    ],
    'description':
        'Elevated living with panoramic city views and world-class amenities.',
  },
  {
    '_id': 'urban-sanctuary',
    'title': 'Urban Sanctuary',
    'status': 'Upcoming',
    'location': {'name': 'Mumbai'},
    'heroImages': [
      'https://images.unsplash.com/photo-1484154218962-a197022b5858?auto=format&fit=crop&q=80',
    ],
    'description': 'A peaceful retreat in the heart of the city.',
  },
  {
    '_id': 'ocean-view',
    'title': 'Ocean View Residences',
    'status': 'Completed',
    'location': {'name': 'Mumbai'},
    'heroImages': [
      'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&q=80',
    ],
    'description': 'Where horizon meets home. Coastal elegance redefined.',
  },
];

final projectsProvider = FutureProvider<List<dynamic>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);

  // Live fetch with cold-start timeout retries. Throws on final failure.
  Future<List<dynamic>> fetchLive() async {
    Object? lastError;
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final response = await apiClient.getProjects();
        if (response.statusCode == 200 || response.statusCode == 201) {
          return (response.data['data'] ?? []) as List<dynamic>;
        }
        throw Exception('Failed to load projects (${response.statusCode})');
      } on DioException catch (e) {
        lastError = e;
        final retryable =
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.connectionError;
        // Stop after the last attempt, or immediately on a non-timeout error
        // (e.g. a 504) — retrying a 60s gateway timeout just makes users wait.
        if (!retryable || attempt == 2) break;
        await Future.delayed(Duration(seconds: 2 * (attempt + 1)));
      } catch (e) {
        lastError = e;
        break;
      }
    }
    throw lastError ?? Exception('Failed to load projects');
  }

  // Fallback shown while / instead of the live data: the last cached payload,
  // else placeholder projects (so the screen never dead-ends on an error and
  // never spins for a minute while the bloated endpoint times out).
  final cached = await _loadCachedProjects();
  final fallback = cached ?? _placeholderProjects();
  // True when the only thing we can show is the placeholder set, whose ids are
  // slugs — anything booked against those is rejected server-side.
  final servingPlaceholders = cached == null;

  var disposed = false;
  ref.onDispose(() => disposed = true);

  // Stale-while-revalidate: race the live fetch against a short grace window.
  // If it wins with fresh data, use it; if the backend is slow or 504s (the
  // projects payload is bloated by a multi-MB base64 hero), return the fallback
  // at ~8s instead of blocking until fetchLive exhausts all its retries (~60s+).
  final live = fetchLive()
      .then<List<dynamic>?>((v) => v)
      .catchError((_) => null);

  // Let the live fetch finish even when the grace window wins, and PERSIST it.
  // Previously its result was simply dropped, so the app never obtained real
  // projects and stayed on the slug-id placeholders — which made every booking
  // fail with `Cast to ObjectId failed for value "cledor"`. Now the next read
  // (or app start) picks up real projects with real ObjectIds.
  unawaited(
    live.then((data) async {
      if (data == null || data.isEmpty) return;
      await _saveCachedProjects(data);
      // If all we could show was placeholders, swap them for the real catalog
      // as soon as it lands — without this the session stayed on slug ids and
      // every booking failed until the app was restarted. Guarded on
      // `servingPlaceholders` so a re-run (which now reads a real cache) can't
      // invalidate itself again and loop.
      if (servingPlaceholders && !disposed) ref.invalidateSelf();
    }),
  );

  final result = await Future.any<List<dynamic>?>([
    live,
    Future<List<dynamic>?>.delayed(const Duration(seconds: 8), () => null),
  ]);
  return result ?? fallback;
});

// Helper Providers for unique filter values
final projectLocationsProvider = Provider<List<String>>((ref) {
  final projects = ref.watch(projectsProvider).value ?? [];
  final locations = projects
      .map((p) => p['location']?['name']?.toString() ?? '')
      .where((name) => name.isNotEmpty)
      .toSet()
      .toList();
  locations.sort();
  return locations;
});

final projectCategoriesProvider = Provider<List<String>>((ref) {
  final projects = ref.watch(projectsProvider).value ?? [];
  final categories = projects
      .map((p) => p['category']?['name']?.toString() ?? '')
      .where((name) => name.isNotEmpty)
      .toSet()
      .toList();
  categories.sort();
  return categories;
});

// Filter State Providers
final projectFilterProvider = StateProvider<String>((ref) => 'Ongoing');
final selectedLocationsProvider = StateProvider<List<String>>((ref) => []);
final selectedBudgetsProvider = StateProvider<List<String>>((ref) => []);
final selectedTypesProvider = StateProvider<List<String>>((ref) => []);
final selectedConfigsProvider = StateProvider<List<String>>((ref) => []);
final selectedAreasProvider = StateProvider<List<String>>((ref) => []);

// Layout provider: true = Grid (Large Cards), false = List (Compact Rows)
final projectLayoutProvider = StateProvider<bool>((ref) => true);

final filteredProjectsProvider = Provider<List<dynamic>>((ref) {
  final projectsAsync = ref.watch(projectsProvider);
  final statusFilter = ref.watch(projectFilterProvider);
  final selectedLocs = ref.watch(selectedLocationsProvider);
  final selectedBudgets = ref.watch(selectedBudgetsProvider);
  final selectedTypes = ref.watch(selectedTypesProvider);
  final selectedConfigs = ref.watch(selectedConfigsProvider);
  final selectedAreas = ref.watch(selectedAreasProvider);

  return projectsAsync.when(
    data: (projects) {
      final filtered = projects.where((p) {
        // 1. Status Filter (Ongoing/Upcoming/Completed)
        final status = p['status']?.toString().toLowerCase() ?? '';
        final matchesStatus =
            statusFilter == 'All' || status == statusFilter.toLowerCase();

        // 2. Location Filter (Case-insensitive)
        final projectLoc =
            p['location']?['name']?.toString().toUpperCase() ?? '';
        final matchesLoc =
            selectedLocs.isEmpty ||
            selectedLocs.any(
              (loc) =>
                  projectLoc == loc.toUpperCase() ||
                  projectLoc.contains(loc.toUpperCase()),
            );

        // 3. Configuration Filter (e.g. "2 BHK") - searches in title, description and config fields if any
        bool matchesConfig = selectedConfigs.isEmpty;
        if (!matchesConfig) {
          final title = p['title']?.toString().toUpperCase() ?? '';
          final desc = p['description']?.toString().toUpperCase() ?? '';
          matchesConfig = selectedConfigs.any(
            (c) =>
                title.contains(c.toUpperCase()) ||
                desc.contains(c.toUpperCase()),
          );
        }

        // 4. Area Filter (e.g. "< 1000") - searches in description
        bool matchesArea = selectedAreas.isEmpty;
        if (!matchesArea) {
          final desc = p['description']?.toString().toUpperCase() ?? '';
          // Handle simple numeric matching or range matching
          matchesArea = selectedAreas.any((a) {
            final firstWord = a.split(' ')[0].toUpperCase();
            return desc.contains(firstWord) || desc.contains(a.toUpperCase());
          });
        }

        // 5. Legacy Filters (Budget/Type)
        final matchesType =
            selectedTypes.isEmpty ||
            selectedTypes.any(
              (t) =>
                  p['category']?['name']?.toString().toUpperCase() ==
                  t.toUpperCase(),
            );
        bool matchesBudget = selectedBudgets.isEmpty;
        if (!matchesBudget) {
          final price = p['startingPrice']?.toString().toUpperCase() ?? '';
          matchesBudget = selectedBudgets.any(
            (b) => price.contains(b.split(' ')[0].toUpperCase()),
          );
        }

        return matchesStatus &&
            matchesLoc &&
            matchesType &&
            matchesBudget &&
            matchesConfig &&
            matchesArea;
      }).toList();

      // Web parity: newest first. The catalog already returns createdAt
      // DESCENDING (Skyline Heights → Cledor → skai → Clédor → Ocean View →
      // M4 Aura Heights) and the web CP list renders exactly that order, so a
      // newly added project lands at the top. This used to sort ASCENDING to
      // match an older web build; the live web now shows the reverse, which
      // is why the app listed CLÉDOR first where the web starts at SKYLINE
      // HEIGHTS. Sort explicitly rather than trusting arrival order, keyed on
      // createdAt (falling back to the Mongo _id, which encodes create time).
      filtered.sort((a, b) {
        final ka = (a['createdAt'] ?? a['_id'] ?? '').toString();
        final kb = (b['createdAt'] ?? b['_id'] ?? '').toString();
        return kb.compareTo(ka);
      });
      return filtered;
    },
    loading: () => [],
    error: (e, s) => [],
  );
});
