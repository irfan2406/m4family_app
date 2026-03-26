import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

final projectsProvider = FutureProvider<List<dynamic>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.getProjects();
  if (response.statusCode == 200 || response.statusCode == 201) {
    return response.data['data'] ?? []; 
  } else {
    throw Exception('Failed to load projects');
  }
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

// Layout provider: true = Grid (Large Cards), false = List (Compact Rows)
final projectLayoutProvider = StateProvider<bool>((ref) => true);

final filteredProjectsProvider = Provider<List<dynamic>>((ref) {
  final projectsAsync = ref.watch(projectsProvider);
  final statusFilter = ref.watch(projectFilterProvider);
  final selectedLocs = ref.watch(selectedLocationsProvider);
  final selectedBudgets = ref.watch(selectedBudgetsProvider);
  final selectedTypes = ref.watch(selectedTypesProvider);

  return projectsAsync.when(
    data: (projects) {
      return projects.where((p) {
        // Status Filter
        final matchesStatus = statusFilter == 'All' || p['status']?.toLowerCase() == statusFilter.toLowerCase();
        
        // Location Filter
        final matchesLoc = selectedLocs.isEmpty || selectedLocs.contains(p['location']?['name']?.toString());
        
        // Type Filter
        final matchesType = selectedTypes.isEmpty || selectedTypes.contains(p['category']?['name']?.toString());

        // Budget Filter (Simple string match for now as per web logic)
        bool matchesBudget = selectedBudgets.isEmpty;
        if (!matchesBudget) {
          final price = p['startingPrice']?.toString() ?? '';
          matchesBudget = selectedBudgets.any((b) => price.contains(b.split(' ')[0]));
        }

        return matchesStatus && matchesLoc && matchesType && matchesBudget;
      }).toList();
    },
    loading: () => [],
    error: (e, s) => [],
  );
});
