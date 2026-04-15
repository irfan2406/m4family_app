import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

class ContentState {
  final List<Map<String, dynamic>> items;
  final bool isLoading;
  final String? error;

  const ContentState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  ContentState copyWith({
    List<Map<String, dynamic>>? items,
    bool? isLoading,
    String? error,
  }) {
    return ContentState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ContentNotifier extends StateNotifier<ContentState> {
  final Ref ref;

  ContentNotifier(this.ref) : super(const ContentState());

  Future<void> fetchContent(String type, {String role = 'guest'}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.getContent(type, role: role);
      if (response.data['status'] == true) {
        final List<dynamic> raw = response.data['data'] ?? [];
        state = state.copyWith(
          items: raw.map((e) => Map<String, dynamic>.from(e)).toList(),
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false, error: 'Failed to load content');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final contentProvider =
    StateNotifierProvider.family<ContentNotifier, ContentState, String>(
  (ref, type) => ContentNotifier(ref),
);
