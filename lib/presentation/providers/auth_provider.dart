import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final apiClientProvider = Provider((ref) => ApiClient(baseUrl: dotenv.get('API_URL', fallback: 'http://10.0.2.2:5009')));

enum AuthStatus { initial, loading, otpSent, authenticated, error }

class AuthState {
  final AuthStatus status;
  final String? error;
  final String? identifier;
  final String? devOtp;
  final String? role;
  final Map<String, dynamic>? user;

  AuthState({
    this.status = AuthStatus.initial,
    this.error,
    this.identifier,
    this.devOtp,
    this.role,
    this.user,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? error,
    String? identifier,
    String? devOtp,
    String? role,
    Map<String, dynamic>? user,
  }) {
    return AuthState(
      status: status ?? this.status,
      error: error ?? this.error,
      identifier: identifier ?? this.identifier,
      devOtp: devOtp ?? this.devOtp,
      role: role ?? this.role,
      user: user ?? this.user,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthNotifier(this._apiClient) : super(AuthState()) {
    _checkToken();
  }

  Future<void> _checkToken() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token != null) {
      await fetchMe();
    }
  }

  Future<void> fetchMe() async {
    try {
      final response = await _apiClient.getCurrentUser();
      if (response.statusCode == 200 || response.statusCode == 201) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: response.data['data'] ?? response.data,
        );
      }
    } catch (_) {
      // If fetchMe fails, might need to logout but for now just ignore
    }
  }

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

  /// Web `/auth/cp/login`: password + CP ID; rejects non-CP roles like the web client.
  Future<String?> loginCpWithPassword(String identifier, String password) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      final response = await _apiClient.loginWithPassword(identifier.trim(), password);
      final ok = response.statusCode == 200 && response.data['status'] == true;
      if (!ok) {
        final msg = response.data['message']?.toString() ?? 'Login failed';
        state = state.copyWith(status: AuthStatus.initial, error: null);
        return msg;
      }
      final data = response.data['data'];
      final role = data['user']?['role']?.toString().toLowerCase();
      if (role != 'cp') {
        state = state.copyWith(status: AuthStatus.initial, error: null);
        return 'Access denied. Channel Partner account required under this ID.';
      }
      final token = data['accessToken'] as String;
      await _storage.write(key: 'jwt_token', value: token);
      final userResponse = await _apiClient.getCurrentUser();
      final raw = userResponse.data['data'] ?? userResponse.data;
      Map<String, dynamic>? userMap;
      if (raw is Map<String, dynamic>) {
        userMap = raw;
      } else if (raw is Map) {
        userMap = Map<String, dynamic>.from(raw);
      }
      state = state.copyWith(status: AuthStatus.authenticated, user: userMap);
      return null;
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = data is Map ? data['message']?.toString() : null;
      state = state.copyWith(status: AuthStatus.initial, error: null);
      return msg ?? e.message ?? 'Login failed';
    } catch (e) {
      state = state.copyWith(status: AuthStatus.initial, error: null);
      return e.toString();
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
        
        // Fetch user data FIRST
        final userResponse = await _apiClient.getCurrentUser();
        final userData = userResponse.data['data'] ?? userResponse.data;
        
        // THEN update state with BOTH status and user
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: userData,
        );
      } else {
        state = state.copyWith(status: AuthStatus.error, error: 'Invalid OTP');
      }
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, error: e.toString());
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    state = AuthState(status: AuthStatus.initial);
  }

  void reset() {
    state = AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthNotifier(apiClient);
});
