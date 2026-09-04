import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';

/// Each sign-in screen accepts only its own accounts.
///
/// POST /api/auth/send-otp answers 200 with a devOtp for an identifier that has
/// no account at all, so the `role` a gateway sends is never validated against
/// anything — a Channel Partner's number typed into the customer PHONE GATEWAY
/// produced a valid CP session and opened the CP portal. The account's real
/// role is now checked against the gateway it arrived through, and a mismatch
/// is refused outright with the token discarded.
class _FakeApi extends ApiClient {
  _FakeApi({required this.meBody, this.verifyUser})
    : super(baseUrl: 'http://localhost');

  final dynamic meBody;
  final Map<String, dynamic>? verifyUser;

  @override
  Future<Response> sendOtp(String identifier, String role) async => Response(
    requestOptions: RequestOptions(path: '/api/auth/send-otp'),
    statusCode: 200,
    data: {
      'status': true,
      'data': {'devOtp': '123456'},
    },
  );

  @override
  Future<Response> verifyOtp(
    String identifier,
    String code,
    String role,
  ) async => Response(
    requestOptions: RequestOptions(path: '/api/auth/verify-otp'),
    statusCode: 200,
    data: {
      'status': true,
      'data': {
        'accessToken': 'test-token',
        if (verifyUser != null) 'user': verifyUser,
      },
    },
  );

  @override
  Future<Response> getCurrentUser() async => Response(
    requestOptions: RequestOptions(path: '/api/auth/me'),
    statusCode: 200,
    data: meBody,
  );
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  /// Records what the notifier leaves in secure storage, so a refused sign-in
  /// can be shown to leave no token behind.
  late Map<String, String?> store;

  setUp(() {
    store = <String, String?>{};
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async {
        final args = (call.arguments as Map?) ?? const {};
        final key = args['key']?.toString();
        switch (call.method) {
          case 'write':
            if (key != null) store[key] = args['value']?.toString();
            return null;
          case 'read':
            return key == null ? null : store[key];
          case 'delete':
            if (key != null) store.remove(key);
            return null;
          default:
            return null;
        }
      },
    );
  });

  Future<AuthState> signInThrough(String gateway, ApiClient api) async {
    final notifier = AuthNotifier(api);
    await notifier.sendOtp('+919999999999', gateway);
    await notifier.verifyOtp('123456');
    return notifier.state;
  }

  ApiClient apiFor(String role) => _FakeApi(
    meBody: {
      'status': true,
      'data': {'_id': 'u1', 'role': role, 'fullName': 'Test'},
    },
  );

  group('customer gateway', () {
    test('refuses a Channel Partner number', () async {
      final state = await signInThrough('CUSTOMER', apiFor('cp'));

      expect(state.status, AuthStatus.error);
      expect(state.status, isNot(AuthStatus.authenticated));
      expect(state.error, contains('Channel Partner'));
      // Nothing signed in, and no token left behind for the next cold start.
      expect(state.user, isNull);
      expect(store['jwt_token'], isNull);
    });

    test('refuses an Investor number', () async {
      final state = await signInThrough('CUSTOMER', apiFor('investor'));

      expect(state.status, AuthStatus.error);
      expect(state.error, contains('Investor'));
      expect(store['jwt_token'], isNull);
    });

    test('lets a real customer in', () async {
      final state = await signInThrough('CUSTOMER', apiFor('user'));

      expect(state.status, AuthStatus.authenticated);
      expect(state.user?['role'], 'user');
      expect(store['jwt_token'], 'test-token');
    });

    test('lets a customer in when the role reads "customer"', () async {
      final state = await signInThrough('CUSTOMER', apiFor('customer'));
      expect(state.status, AuthStatus.authenticated);
    });
  });

  group('investor gateway', () {
    test('lets an investor in', () async {
      final state = await signInThrough('INVESTOR', apiFor('investor'));

      expect(state.status, AuthStatus.authenticated);
      expect(state.user?['role'], 'investor');
      expect(state.role, 'investor');
    });

    test('refuses a Channel Partner number', () async {
      final state = await signInThrough('INVESTOR', apiFor('cp'));

      expect(state.status, AuthStatus.error);
      expect(store['jwt_token'], isNull);
    });

    test('refuses a plain customer number', () async {
      final state = await signInThrough('INVESTOR', apiFor('user'));

      expect(state.status, AuthStatus.error);
      expect(store['jwt_token'], isNull);
    });
  });

  test('an unresolvable account is refused rather than assumed a customer', () async {
    // A 200 carrying no account. This used to be stored as the user, leaving
    // the role null — and a null role falls through to the customer portal.
    final state = await signInThrough(
      'CUSTOMER',
      _FakeApi(meBody: {'status': true, 'data': null}),
    );

    expect(state.status, AuthStatus.error);
    expect(state.user, isNull);
    expect(store['jwt_token'], isNull);
  });

  test('the account from verify-otp is used when /me carries none', () async {
    // verify-otp returns the account too, so a thin /me response must not lose
    // the role and let a CP through the customer gateway.
    final state = await signInThrough(
      'CUSTOMER',
      _FakeApi(
        meBody: {'status': true, 'data': null},
        verifyUser: {'_id': 'u4', 'role': 'cp'},
      ),
    );

    expect(state.status, AuthStatus.error);
    expect(state.error, contains('Channel Partner'));
    expect(store['jwt_token'], isNull);
  });
}
