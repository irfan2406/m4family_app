import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/core/services/push_notifications.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/widgets/push_notifications_scope.dart';

/// Tapping a phone pop-up opens that portal's Notifications page, or the
/// ticket chat for a support reply — and a tap that launched the app waits
/// for the splash to hand over to /home before opening anything.
class _FakeApi extends ApiClient {
  _FakeApi() : super(baseUrl: 'http://localhost');

  int notificationFetches = 0;

  @override
  Future<Response> getNotifications() async {
    notificationFetches++;
    return Response(
      requestOptions: RequestOptions(path: '/api/notifications'),
      statusCode: 200,
      data: {'status': true, 'data': const []},
    );
  }
}

class _FixedAuth extends AuthNotifier {
  _FixedAuth(super.api, Map<String, dynamic>? user) {
    state = AuthState(
      status: user == null ? AuthStatus.initial : AuthStatus.authenticated,
      user: user,
      bootstrapped: true,
    );
  }
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async => null,
    );
  });

  Widget page(GoRouterState s) =>
      Scaffold(body: Text('page ${s.uri.path}'));

  Future<GoRouter> pump(
    WidgetTester tester, {
    Map<String, dynamic>? user,
    String initial = '/home',
  }) async {
    final api = _FakeApi();
    final router = GoRouter(
      initialLocation: initial,
      routes: [
        for (final p in [
          '/onboarding',
          '/home',
          '/notifications',
          '/support/tickets/:id',
          '/investor/notifications',
          '/investor/support/tickets/:id',
          '/cp/notifications',
          '/cp/support/tickets/:id',
        ])
          GoRoute(path: p, builder: (_, s) => page(s)),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(api),
          authProvider.overrideWith((ref) => _FixedAuth(api, user)),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          builder: (context, child) => PushNotificationsScope(
            router: router,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  Future<void> tap(WidgetTester tester, Map<String, dynamic> data) async {
    PushNotifications.debugTap(data);
    await tester.pumpAndSettle();
  }

  const reply = {'type': 'TICKET_REPLY', 'ticketId': 't42'};
  const announcement = {'type': 'ANNOUNCEMENT'};

  for (final (role, prefix) in [
    ('user', ''),
    ('investor', '/investor'),
    ('cp', '/cp'),
  ]) {
    testWidgets('$role: support reply opens its ticket chat', (tester) async {
      await pump(tester, user: {'_id': 'u1', 'role': role});
      await tap(tester, reply);
      expect(find.text('page $prefix/support/tickets/t42'), findsOneWidget);
    });

    testWidgets('$role: anything else opens Notifications', (tester) async {
      await pump(tester, user: {'_id': 'u1', 'role': role});
      await tap(tester, announcement);
      expect(find.text('page $prefix/notifications'), findsOneWidget);
    });
  }

  testWidgets('a reply without a ticket id falls back to Notifications', (
    tester,
  ) async {
    await pump(tester, user: {'_id': 'u1', 'role': 'investor'});
    await tap(tester, {'type': 'TICKET_REPLY'});
    expect(find.text('page /investor/notifications'), findsOneWidget);
  });

  testWidgets('a tap that launched the app waits for /home', (tester) async {
    final router = await pump(
      tester,
      user: {'_id': 'u1', 'role': 'cp'},
      initial: '/onboarding',
    );
    await tap(tester, reply);
    // Still on the splash: opening now would be replaced by its go('/home').
    expect(find.text('page /onboarding'), findsOneWidget);

    router.go('/home');
    await tester.pumpAndSettle();
    expect(find.text('page /cp/support/tickets/t42'), findsOneWidget);
  });

  testWidgets('signed out: a tap opens nothing', (tester) async {
    await pump(tester);
    await tap(tester, reply);
    expect(find.text('page /home'), findsOneWidget);
  });
}
