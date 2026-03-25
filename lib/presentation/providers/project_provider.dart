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

// Filter provider
final projectFilterProvider = StateProvider<String>((ref) => 'Ongoing');

// Layout provider: true = Grid (Large Cards), false = List (Compact Rows)
final projectLayoutProvider = StateProvider<bool>((ref) => true);

final filteredProjectsProvider = Provider<List<dynamic>>((ref) {
  final projectsAsync = ref.watch(projectsProvider);
  final filter = ref.watch(projectFilterProvider);

  return projectsAsync.when(
    data: (projects) {
      if (filter == 'All') return projects;
      return projects.where((p) => p['status']?.toLowerCase() == filter.toLowerCase()).toList();
    },
    loading: () => [],
    error: (e, s) => [],
  );
});
