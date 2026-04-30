import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

class MyCustomViewsState {
  final List<dynamic> units;
  final List<dynamic> history;
  final bool isLoadingUnits;
  final bool isLoadingHistory;
  final String? error;

  MyCustomViewsState({
    this.units = const [],
    this.history = const [],
    this.isLoadingUnits = false,
    this.isLoadingHistory = false,
    this.error,
  });

  MyCustomViewsState copyWith({
    List<dynamic>? units,
    List<dynamic>? history,
    bool? isLoadingUnits,
    bool? isLoadingHistory,
    String? error,
  }) {
    return MyCustomViewsState(
      units: units ?? this.units,
      history: history ?? this.history,
      isLoadingUnits: isLoadingUnits ?? this.isLoadingUnits,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      error: error,
    );
  }
}

class MyCustomViewsNotifier extends StateNotifier<MyCustomViewsState> {
  final Ref _ref;

  MyCustomViewsNotifier(this._ref) : super(MyCustomViewsState());

  Future<void> fetchAll() async {
    await Future.wait([
      fetchUnits(),
      fetchHistory(),
    ]);
  }

  Future<void> fetchUnits() async {
    state = state.copyWith(isLoadingUnits: true, error: null);
    try {
      final apiClient = _ref.read(apiClientProvider);
      final response = await apiClient.getMyUnits();
      
      if (response.data['status'] == true) {
        state = state.copyWith(
          units: response.data['data'] ?? [],
          isLoadingUnits: false,
        );
      } else {
        state = state.copyWith(
          isLoadingUnits: false,
          error: response.data['message'],
        );
      }
    } catch (e) {
      state = state.copyWith(isLoadingUnits: false, error: e.toString());
    }
  }

  Future<void> fetchHistory() async {
    state = state.copyWith(isLoadingHistory: true, error: null);
    try {
      final apiClient = _ref.read(apiClientProvider);
      final response = await apiClient.getMyCustomViews();
      
      if (response.data['status'] == true) {
        state = state.copyWith(
          history: response.data['data'] ?? [],
          isLoadingHistory: false,
        );
      } else {
        state = state.copyWith(
          isLoadingHistory: false,
          error: response.data['message'],
        );
      }
    } catch (e) {
      state = state.copyWith(isLoadingHistory: false, error: e.toString());
    }
  }
}

final myCustomViewsProvider = StateNotifierProvider<MyCustomViewsNotifier, MyCustomViewsState>((ref) {
  return MyCustomViewsNotifier(ref);
});
