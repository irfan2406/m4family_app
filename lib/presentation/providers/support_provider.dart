import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m4_mobile/data/models/ticket_model.dart';
import 'package:m4_mobile/core/models/activity_log.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

class SupportState {
  final List<TicketModel> tickets;
  final List<ActivityLog> logs;
  final List<dynamic> documents;
  final bool isLoading;
  final String? error;

  SupportState({
    this.tickets = const [],
    this.logs = const [],
    this.documents = const [],
    this.isLoading = false,
    this.error,
  });

  SupportState copyWith({
    List<TicketModel>? tickets,
    List<ActivityLog>? logs,
    List<dynamic>? documents,
    bool? isLoading,
    String? error,
  }) {
    return SupportState(
      tickets: tickets ?? this.tickets,
      logs: logs ?? this.logs,
      documents: documents ?? this.documents,
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

  Future<void> fetchLogs() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final apiClient = _ref.read(apiClientProvider);
      final response = await apiClient.getLogs();
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final List<dynamic> data = response.data['data'] ?? [];
        final List<ActivityLog> logs = data
            .map((json) => ActivityLog.fromJson(json))
            .toList();
        
        state = state.copyWith(
          logs: logs,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load logs',
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
    List<String> attachments = const [],
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final apiClient = _ref.read(apiClientProvider);
      final response = await apiClient.createTicket({
        'subject': subject,
        'category': category,
        'message': message,
        'priority': 'Medium', // Default priority as seen in web
        'attachments': attachments,
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

  /// Fetch a single ticket (with its message thread). Returns the raw
  /// ticket map (`data`) or null on failure. The detail screen keeps its
  /// own local message list, mirroring the web page.
  Future<Map<String, dynamic>?> fetchTicketDetail(String id) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      final response = await apiClient.getTicketDetail(id);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'];
        if (data is Map<String, dynamic>) return data;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Post a message (optionally with an attachment URL) and return the
  /// refreshed ticket map, or null on failure.
  Future<Map<String, dynamic>?> sendMessage(
    String ticketId,
    String text, [
    String? attachmentUrl,
  ]) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      final response = await apiClient.postTicketMessage(
        ticketId,
        text: text,
        attachment: attachmentUrl,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'];
        if (data is Map<String, dynamic>) return data;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Upload a file then send it as an attachment message. Returns the
  /// refreshed ticket map, or null on failure.
  Future<Map<String, dynamic>?> uploadAndSendAttachment(
    String ticketId,
    String filePath, {
    String? caption,
  }) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      final uploadRes = await apiClient.uploadFile(filePath);
      final fileUrl = uploadRes.data?['data']?['fileUrl'] as String?;
      if (fileUrl == null || fileUrl.isEmpty) return null;
      return sendMessage(
        ticketId,
        (caption != null && caption.trim().isNotEmpty)
            ? caption.trim()
            : 'Sent an attachment',
        fileUrl,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> fetchDocuments() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final apiClient = _ref.read(apiClientProvider);
      final response = await apiClient.getMySupportDocuments();
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final List<dynamic> documents = response.data['data'] ?? [];
        state = state.copyWith(
          documents: documents,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load documents',
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

final supportProvider = StateNotifierProvider<SupportNotifier, SupportState>((ref) {
  return SupportNotifier(ref);
});
