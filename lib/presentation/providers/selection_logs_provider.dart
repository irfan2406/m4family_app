import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

class SelectionLogsState {
  final List<dynamic> logs;
  final bool isLoading;
  final String? error;

  SelectionLogsState({
    this.logs = const [],
    this.isLoading = false,
    this.error,
  });

  SelectionLogsState copyWith({
    List<dynamic>? logs,
    bool? isLoading,
    String? error,
  }) {
    return SelectionLogsState(
      logs: logs ?? this.logs,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class SelectionLogsNotifier extends StateNotifier<SelectionLogsState> {
  final Ref _ref;

  SelectionLogsNotifier(this._ref) : super(SelectionLogsState());

  Future<void> fetchLogs() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final apiClient = _ref.read(apiClientProvider);
      final response = await apiClient.getMyCustomViews();
      
      if (response.data['status'] == true) {
        state = state.copyWith(
          logs: response.data['data'] ?? [],
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.data['message'] ?? 'Failed to load selection logs',
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

final selectionLogsProvider = StateNotifierProvider<SelectionLogsNotifier, SelectionLogsState>((ref) {
  return SelectionLogsNotifier(ref);
});
