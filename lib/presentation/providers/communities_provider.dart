import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

class CommunitiesState {
  final List<dynamic> communities;
  final bool isLoading;
  final String? error;

  CommunitiesState({
    this.communities = const [],
    this.isLoading = false,
    this.error,
  });

  CommunitiesState copyWith({
    List<dynamic>? communities,
    bool? isLoading,
    String? error,
  }) {
    return CommunitiesState(
      communities: communities ?? this.communities,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class CommunitiesNotifier extends StateNotifier<CommunitiesState> {
  final Ref _ref;

  CommunitiesNotifier(this._ref) : super(CommunitiesState()) {
    fetchCommunities();
  }

  Future<void> fetchCommunities() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final apiClient = _ref.read(apiClientProvider);
      final response = await apiClient.getCommunities();
      
      if (response.data['status'] == true) {
        state = state.copyWith(
          communities: response.data['data'] ?? [],
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.data['message'] ?? 'Failed to load communities',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

final communitiesProvider = StateNotifierProvider<CommunitiesNotifier, CommunitiesState>((ref) {
  return CommunitiesNotifier(ref);
});
