import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/core/utils/api_error.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final apiClientProvider = Provider(
  (ref) => ApiClient(
    baseUrl: dotenv.get(
      'API_URL',
      // Production backend (same host the web uses). The old 10.0.2.2 fallback
      // only works inside an emulator and breaks images/data on real devices.
      fallback: 'https://api.mym4family.com',
    ),
  ),
);

enum AuthStatus { initial, loading, otpSent, authenticated, error }

class AuthState {
  final AuthStatus status;
  final String? error;
  final String? identifier;
  final String? devOtp;
  final String? role;
  final Map<String, dynamic>? user;
  // True once the initial stored-token check has completed (prevents the
  // guest-shell flash on cold start while resolving the session).
  final bool bootstrapped;

  AuthState({
    this.status = AuthStatus.initial,
    this.error,
    this.identifier,
    this.devOtp,
    this.role,
    this.user,
    this.bootstrapped = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? error,
    String? identifier,
    String? devOtp,
    String? role,
    Map<String, dynamic>? user,
    bool? bootstrapped,
  }) {
    return AuthState(
      status: status ?? this.status,
      error: error ?? this.error,
      identifier: identifier ?? this.identifier,
      devOtp: devOtp ?? this.devOtp,
      role: role ?? this.role,
      user: user ?? this.user,
      bootstrapped: bootstrapped ?? this.bootstrapped,
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
    if (mounted) state = state.copyWith(bootstrapped: true);
  }

  /// Applies an already-known user payload (e.g. the body a PATCH /me returns)
  /// so the UI reflects a save immediately, without waiting on [fetchMe].
  void setUser(Map<String, dynamic> user) {
    if (!mounted) return;
    state = state.copyWith(status: AuthStatus.authenticated, user: user);
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
        final devOtp = response.data['data'] != null
            ? response.data['data']['devOtp']?.toString()
            : null;
        state = state.copyWith(
          status: AuthStatus.otpSent,
          identifier: identifier,
          devOtp: devOtp,
          role: role,
        );
      } else {
        state = state.copyWith(
          status: AuthStatus.error,
          error: 'Failed to send OTP',
        );
      }
    } catch (e) {
      // Was e.toString(), which dumped the raw DioException at the user.
      state = state.copyWith(
        status: AuthStatus.error,
        error: friendlyApiError(
          e,
          fallback:
              'Could not send the code. Please check the number and try again.',
        ),
      );
    }
  }

  /// Web `/auth/cp/login`: password + CP ID; rejects non-CP roles like the web client.
  Future<String?> loginCpWithPassword(
    String identifier,
    String password,
  ) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      final response = await _apiClient.loginWithPassword(
        identifier.trim(),
        password,
      );
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

  /// Web `/investor/login`: identifier (investorId / email / phone) + password; rejects non-investor roles.
  Future<String?> loginInvestorWithPassword(
    String identifier,
    String password,
  ) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      final response = await _apiClient.investorLogin(
        identifier.trim(),
        password,
      );
      final ok = response.statusCode == 200 && response.data['status'] == true;
      if (!ok) {
        final msg = response.data['message']?.toString() ?? 'Login failed';
        state = state.copyWith(status: AuthStatus.initial, error: null);
        return msg;
      }
      final data = response.data['data'];
      final role = data['user']?['role']?.toString().toLowerCase();
      if (role != 'investor') {
        state = state.copyWith(status: AuthStatus.initial, error: null);
        return 'Access denied. This portal is reserved for premium investors.';
      }
      // Investor login returns `token` (CP returns `accessToken`).
      final token = (data['token'] ?? data['accessToken'])?.toString();
      if (token == null || token.isEmpty) {
        state = state.copyWith(status: AuthStatus.initial, error: null);
        return 'Login failed: missing session token.';
      }
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
      final response = await _apiClient.verifyOtp(
        state.identifier!,
        code,
        state.role ?? 'CUSTOMER',
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Null-safe: a 200 with an unexpected shape used to throw here and then
        // surface as another raw exception instead of a readable message.
        final data = response.data is Map ? response.data['data'] : null;
        final token = (data is Map ? data['accessToken'] : null)?.toString();
        if (token == null || token.isEmpty) {
          state = state.copyWith(
            status: AuthStatus.error,
            error: 'Could not complete sign in. Please try again.',
          );
          return;
        }
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
      // Was e.toString(), which dumped the raw DioException at the user. A 400
      // here means a wrong/expired code; a 403 means the account isn't allowed
      // in this portal.
      state = state.copyWith(
        status: AuthStatus.error,
        error: friendlyApiError(
          e,
          fallback: 'That code is incorrect or has expired. Please try again.',
        ),
      );
    }
  }

  Future<void> logout() async {
    // Flip to the guest state FIRST so the UI switches to the guest shell
    // instantly — the token is then cleared in the background. Awaiting the
    // secure-storage (Android Keystore) delete before updating state stalls
    // logout by 100ms+ on real devices, which is the lag users noticed.
    //
    // Keep bootstrapped=true so `/home` resolves straight to the guest shell.
    // A fresh AuthState() defaults bootstrapped=false, which would trap
    // post-logout navigation on the cold-start SplashScreen.
    state = AuthState(status: AuthStatus.initial, bootstrapped: true);
    unawaited(_storage.delete(key: 'jwt_token'));
  }

  void reset() {
    state = AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthNotifier(apiClient);
});
