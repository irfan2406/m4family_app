import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/screens/investor/investor_referral_screen.dart';

/// Investor REFERRAL & REWARDS > the REFERRALS and CLOSED counts.
///
/// All three stat tiles were plain Containers with no gesture on them, so the
/// counts were inert. Both pages they should open were already built and
/// already routed — `/investor/referral/active` (web's "Active Referrals —
/// Lead Matrix") and `/investor/referral/closed` — but nothing in the app ever
/// pushed either, so both screens were unreachable. POINTS has no page of its
/// own and stays inert.
///
/// A stub stands in for the destination: this asserts the tap navigates, not
/// what the destination renders (that screen fetches on its own).
class _FakeApiClient extends ApiClient {
  _FakeApiClient(this.referrals) : super(baseUrl: 'http://localhost');

  final List<dynamic> referrals;

  Response _ok(String path, dynamic data) => Response(
    requestOptions: RequestOptions(path: path),
    statusCode: 200,
    data: {'status': true, 'data': data},
  );

  @override
  Future<Response> getInvestorWallet() async =>
      _ok('/api/investor/wallet', {'balance': 0});

  @override
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    if (path == '/api/investor/referrals') return _ok(path, referrals);
    return _ok(path, const []);
  }
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  // One open referral, shaped as /api/investor/referrals returns it. Its
  // LEAD_CREATED status is not in the closed set, so it counts as active on
  // both the stat and the page behind it.
  const referrals = <dynamic>[
    {
      'referralName': 'Shivanand Chaurasiya',
      'projectName': 'Ocean View',
      'status': 'LEAD_CREATED',
      'referralCode': 'REF-OCEAN-000023',
    },
  ];

  Future<GoRouter> pumpReferral(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(411, 900);
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: '/investor/referral',
      routes: [
        GoRoute(
          path: '/investor/referral',
          builder: (_, _) => const InvestorReferralScreen(),
        ),
        GoRoute(
          path: '/investor/referral/active',
          builder: (_, _) =>
              const Scaffold(body: Center(child: Text('ACTIVE-LIST-STUB'))),
        ),
        GoRoute(
          path: '/investor/referral/closed',
          builder: (_, _) =>
              const Scaffold(body: Center(child: Text('CLOSED-LIST-STUB'))),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(_FakeApiClient(referrals)),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    // _load runs from a post-frame callback and awaits the fake client, so let
    // the microtasks drain before pumping the loaded page.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    return router;
  }

  testWidgets('tapping the REFERRALS count opens the active referrals page', (
    tester,
  ) async {
    await pumpReferral(tester);

    // Past the spinner, and the count reflects the one open referral.
    expect(find.text('REFERRALS'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.text('REFERRALS'));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    // It used to sit there doing nothing.
    expect(find.text('ACTIVE-LIST-STUB'), findsOneWidget);
  });

  testWidgets('tapping the CLOSED count opens the closed referrals page', (
    tester,
  ) async {
    await pumpReferral(tester);

    expect(find.text('CLOSED'), findsOneWidget);

    await tester.tap(find.text('CLOSED'));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    // Its route and screen were built but unlinked, same as the active one.
    // A zero count still opens the page — it draws its own empty state.
    expect(find.text('CLOSED-LIST-STUB'), findsOneWidget);
  });

  testWidgets('POINTS is left alone', (tester) async {
    final router = await pumpReferral(tester);

    await tester.tap(find.text('POINTS'));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    // It had no gesture before and still has none — REDEEM REWARDS below is
    // what spends points.
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      '/investor/referral',
    );
  });
}
