import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/providers/project_provider.dart';
import 'package:m4_mobile/presentation/screens/home/guest_dashboard_screen.dart'
    show guestHomeCacheProvider, GuestHomeData;
import 'package:m4_mobile/presentation/screens/investor/investor_home_screen.dart';

/// Investor home > COMMUNITIES.
///
/// Same defect the CP and guest homes had: GET /api/catalog/communities answers
/// 200 with `"data": []`, so the tab drew a horizontal ListView with itemCount
/// 0 inside a fixed SizedBox(height: 360) — 360px of blank green under the tab
/// row, indistinguishable from a page that had failed to load.
///
/// The client is faked rather than pointed at a dead host: real socket I/O
/// never completes under the test binding's clock, and a fake lets the
/// populated case be checked too — the fix must not become "always show the
/// empty state".
class _FakeApiClient extends ApiClient {
  _FakeApiClient(this.rows) : super(baseUrl: 'http://localhost');

  final List<dynamic> rows;

  Response _ok(String path, List<dynamic> data) => Response(
    requestOptions: RequestOptions(path: path),
    statusCode: 200,
    data: {'status': true, 'data': data},
  );

  @override
  Future<Response> getCommunities() async =>
      _ok('/api/catalog/communities', rows);

  @override
  Future<Response> getContent(
    String type, {
    String role = 'guest',
    String? projectId,
  }) async => _ok('/api/content', const []);
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> pumpAt(
    WidgetTester tester,
    double dp,
    double textScale, {
    List<dynamic> communities = const [],
  }) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = Size(dp, 900);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(() {
      tester.view.reset();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(_FakeApiClient(communities)),
          projectsProvider.overrideWith((ref) async => const <dynamic>[]),
          // Seeded so the page is past its loading gate on the first frame.
          // Otherwise the gate is lifted by a disk-cache read plus a compute()
          // isolate, neither of which the test binding's clock drives, and the
          // screen under test never builds at all.
          guestHomeCacheProvider.overrideWith(
            (ref) =>
                const GuestHomeData(projects: [], communities: [], media: []),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: InvestorHomeScreen())),
      ),
    );
    // _fetchData first awaits a real dart:io cache-file probe, which the test
    // binding's fake clock does not drive — runAsync lets that (and the fake
    // client's futures behind it) actually complete before we look.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    // Not pumpAndSettle: the page carries entrance animations and a repeating
    // hero timer that would keep the scheduler busy forever.
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  for (final dp in <double>[320, 360, 411]) {
    for (final scale in <double>[1.0, 1.5]) {
      testWidgets('${dp.toInt()}dp @ ${scale}x: an empty tab says so', (
        tester,
      ) async {
        await pumpAt(tester, dp, scale);
        expect(tester.takeException(), isNull);
        // Past the spinner and on the real page...
        expect(find.text('COMMUNITIES'), findsOneWidget);
        // ...and the strip explains itself instead of sitting blank.
        expect(find.text('NO COMMUNITIES YET'), findsOneWidget);
      });
    }
  }

  testWidgets('a community from the backend still renders its card', (
    tester,
  ) async {
    await pumpAt(
      tester,
      411,
      1.0,
      communities: [
        {'_id': 'c1', 'title': 'Test Community', 'status': 'ONGOING'},
      ],
    );
    expect(tester.takeException(), isNull);
    expect(find.text('COMMUNITIES'), findsOneWidget);
    // The guard against "fixed" by always drawing the empty state.
    expect(find.text('NO COMMUNITIES YET'), findsNothing);
  });
}
