import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m4_mobile/data/models/ticket_model.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

class SupportState {
  final List<TicketModel> tickets;
  final bool isLoading;
  final String? error;

  SupportState({
    this.tickets = const [],
    this.isLoading = false,
    this.error,
  });

  SupportState copyWith({
    List<TicketModel>? tickets,
    bool? isLoading,
    String? error,
  }) {
    return SupportState(
      tickets: tickets ?? this.tickets,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class SupportNotifier extends StateNotifier<SupportState> {
  final Ref _ref;

  SupportNotifier(this._ref) : super(SupportState());

  Future<void> fetchTickets() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final apiClient = _ref.read(apiClientProvider);
      final response = await apiClient.getTickets();
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final List<dynamic> data = response.data['data'] ?? [];
        final List<TicketModel> tickets = data
            .map((json) => TicketModel.fromJson(json))
            .toList();
        
        // Sort by date newest first
        tickets.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        state = state.copyWith(
          tickets: tickets,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load tickets',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<bool> createTicket({
    required String subject,
    required String category,
    required String message,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final apiClient = _ref.read(apiClientProvider);
      final response = await apiClient.createTicket({
        'subject': subject,
        'category': category,
        'message': message,
        'priority': 'Medium', // Default priority as seen in web
      });
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchTickets(); // Refresh list
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.data['message'] ?? 'Failed to create ticket',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }
}

final supportProvider = StateNotifierProvider<SupportNotifier, SupportState>((ref) {
  return SupportNotifier(ref);
});
