import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local snapshot of a saved project for the guest Saved tab.
class SavedProject {
  final String id;
  final String title;
  final String location;
  final String image;
  final String status;

  const SavedProject({
    required this.id,
    required this.title,
    required this.location,
    required this.image,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'location': location,
    'image': image,
    'status': status,
  };

  factory SavedProject.fromJson(Map<String, dynamic> json) => SavedProject(
    id: (json['id'] ?? '').toString(),
    title: (json['title'] ?? 'Project').toString(),
    location: (json['location'] ?? '').toString(),
    image: (json['image'] ?? '').toString(),
    status: (json['status'] ?? '').toString(),
  );

  factory SavedProject.fromProjectMap(Map<String, dynamic> project) {
    final id = (project['_id'] ?? project['id'] ?? '').toString();
    final image =
        (project['heroImage'] ??
                project['image'] ??
                project['thumbnail'] ??
                '')
            .toString();
    final loc = project['location'];
    final location = loc is Map
        ? (loc['name'] ?? loc['city'] ?? '').toString()
        : (loc ?? project['city'] ?? '').toString();
    return SavedProject(
      id: id,
      title: (project['title'] ?? project['name'] ?? 'Project').toString(),
      location: location,
      image: image,
      status: (project['status'] ?? '').toString(),
    );
  }
}

const _prefsKey = 'm4_guest_saved_projects';

class FavoritesNotifier extends StateNotifier<List<SavedProject>> {
  FavoritesNotifier() : super(const []) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return;
      final list = (jsonDecode(raw) as List<dynamic>)
          .whereType<Map>()
          .map((e) => SavedProject.fromJson(Map<String, dynamic>.from(e)))
          .where((p) => p.id.isNotEmpty)
          .toList();
      state = list;
    } catch (_) {
      // Keep empty list on corrupt cache.
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode(state.map((e) => e.toJson()).toList()),
    );
  }

  bool isSaved(String projectId) =>
      state.any((p) => p.id == projectId && projectId.isNotEmpty);

  Future<void> toggle(Map<String, dynamic> project) async {
    final snap = SavedProject.fromProjectMap(project);
    if (snap.id.isEmpty) return;
    if (isSaved(snap.id)) {
      state = state.where((p) => p.id != snap.id).toList();
    } else {
      state = [snap, ...state.where((p) => p.id != snap.id)];
    }
    await _persist();
  }

  Future<void> remove(String projectId) async {
    state = state.where((p) => p.id != projectId).toList();
    await _persist();
  }
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, List<SavedProject>>(
      (ref) => FavoritesNotifier(),
    );
