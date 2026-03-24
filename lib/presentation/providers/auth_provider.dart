import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final apiClientProvider = Provider((ref) => ApiClient(baseUrl: 'http://10.0.2.2:5009'));

enum AuthStatus { initial, loading, otpSent, authenticated, error }

class AuthState {
  final AuthStatus status;
  final String? error;
  final String? identifier;
  final String? devOtp;
  final String? role;

  AuthState({
    this.status = AuthStatus.initial,
    this.error,
    this.identifier,
    this.devOtp,
    this.role,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? error,
    String? identifier,
    String? devOtp,
    String? role,
  }) {
    return AuthState(
      status: status ?? this.status,
      error: error ?? this.error,
      identifier: identifier ?? this.identifier,
      devOtp: devOtp ?? this.devOtp,
      role: role ?? this.role,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthNotifier(this._apiClient) : super(AuthState());

  Future<void> sendOtp(String identifier, String role) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final response = await _apiClient.sendOtp(identifier, role);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final devOtp = response.data['data'] != null ? response.data['data']['devOtp']?.toString() : null;
        state = state.copyWith(
          status: AuthStatus.otpSent,
          identifier: identifier,
          devOtp: devOtp,
          role: role,
        );
      } else {
        state = state.copyWith(status: AuthStatus.error, error: 'Failed to send OTP');
      }
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, error: e.toString());
    }
  }

  Future<void> verifyOtp(String code) async {
    if (state.identifier == null) return;
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final response = await _apiClient.verifyOtp(state.identifier!, code, state.role ?? 'CUSTOMER');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final token = response.data['data']['accessToken']; 
        await _storage.write(key: 'jwt_token', value: token);
        state = state.copyWith(status: AuthStatus.authenticated);
      } else {
        state = state.copyWith(status: AuthStatus.error, error: 'Invalid OTP');
      }
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, error: e.toString());
    }
  }

  void reset() {
    state = AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthNotifier(apiClient);
});
