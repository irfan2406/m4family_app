import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

final projectsProvider = FutureProvider<List<dynamic>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  // The backend can be slow to cold-start; retry timeouts with backoff so the
  // first (waking) request doesn't surface a hard error to the user.
  Object? lastError;
  for (var attempt = 0; attempt < 3; attempt++) {
    try {
      final response = await apiClient.getProjects();
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data['data'] ?? [];
      }
      throw Exception('Failed to load projects (${response.statusCode})');
    } on DioException catch (e) {
      lastError = e;
      final retryable =
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError;
      if (!retryable || attempt == 2) rethrow;
      await Future.delayed(Duration(seconds: 2 * (attempt + 1)));
    }
  }
  throw lastError ?? Exception('Failed to load projects');
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

      // Web parity: render in creation order (oldest → newest). The web list
      // shows CLÉDOR → CLEDOR ELITE → DING DONG; the raw API order the app got
      // was newest-first. Sort by createdAt (fallback Mongo _id, which encodes
      // creation time) ascending to match the web's serial order.
      filtered.sort((a, b) {
        final ka = (a['createdAt'] ?? a['_id'] ?? '').toString();
        final kb = (b['createdAt'] ?? b['_id'] ?? '').toString();
        return ka.compareTo(kb);
      });
      return filtered;
    },
    loading: () => [],
    error: (e, s) => [],
  );
});
