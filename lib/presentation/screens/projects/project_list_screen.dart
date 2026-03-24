import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:m4_mobile/presentation/providers/project_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ProjectListScreen extends ConsumerWidget {
  const ProjectListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsProvider);
    final filteredProjects = ref.watch(filteredProjectsProvider);
    final currentFilter = ref.watch(projectFilterProvider);

    return Scaffold(
      backgroundColor: M4Theme.background,
      appBar: AppBar(
        title: const Text('PROJECTS'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.search, color: M4Theme.premiumBlue),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: ['All', 'Ongoing', 'Upcoming', 'Completed'].map((filter) {
                final isSelected = currentFilter == filter;
                return GestureDetector(
                  onTap: () => ref.read(projectFilterProvider.notifier).state = filter,
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? M4Theme.premiumBlue : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? M4Theme.premiumBlue : M4Theme.border,
                      ),
                    ),
                    child: Text(
                      filter.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? M4Theme.background : M4Theme.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Project List
          Expanded(
            child: projectsAsync.when(
              data: (projects) => ListView.builder(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                itemCount: filteredProjects.length,
                itemBuilder: (context, index) {
                  final project = filteredProjects[index];
                  return _ProjectListItem(project: project);
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator(color: M4Theme.premiumBlue)),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectListItem extends StatelessWidget {
  final dynamic project;
  const _ProjectListItem({required this.project});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: M4Theme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Project Image
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(
              project['heroImages']?[0] ?? 'https://via.placeholder.com/400x225',
              fit: BoxFit.cover,
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      project['status']?.toUpperCase() ?? 'STATUS',
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: M4Theme.premiumBlue,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      project['startingPrice'] ?? 'Price on request',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: M4Theme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  project['title'] ?? 'PROJECT TITLE',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: M4Theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(LucideIcons.mapPin, size: 12, color: M4Theme.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      project['location']?['name'] ?? 'Location',
                      style: const TextStyle(fontSize: 12, color: M4Theme.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }
}
