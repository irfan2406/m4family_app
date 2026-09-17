import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/providers/project_provider.dart';
import 'package:m4_mobile/presentation/screens/cp/cp_home_screen.dart';
import 'package:m4_mobile/presentation/screens/home/guest_dashboard_screen.dart'
    show GuestDashboardScreen, guestHomeCacheProvider, GuestHomeData;
import 'package:m4_mobile/presentation/screens/investor/investor_home_screen.dart';
import 'package:m4_mobile/presentation/screens/projects/project_list_screen.dart';

/// Every card thumbnail in the app is a 16:9 frame — the YouTube thumbnail
/// ratio — so a project looks the same width-for-height in Guest, Customer, CP
/// and Investor. The cards used to carry flat pixel heights (180, 200, 250,
/// 280, 350, a 4/3 hero), each of which is only 16:9 at one particular screen
/// width, so the same photo was cropped differently in every portal.
///
/// The card widths and row heights are chosen so that the frame is what
/// decides the size. If someone changes one without the other, the ratio drifts
/// and these tests say so.
const _ratio = 16 / 9;

class _FakeApiClient extends ApiClient {
  _FakeApiClient(this.communities) : super(baseUrl: 'http://localhost');

  final List<dynamic> communities;

  @override
  Future<Response> getCommunities() async => Response(
    requestOptions: RequestOptions(path: '/api/catalog/communities'),
    statusCode: 200,
    data: {'status': true, 'message': 'ok', 'data': communities},
  );
}

/// Deliberately long: a title that wraps is what used to overflow a 16:9 tile.
const _title = 'Mazgaon Harbour Residences';
const _titleCaps = 'MAZGAON HARBOUR RESIDENCES';

const _community = {
  '_id': 'c1',
  'title': _title,
  'name': _title,
  'status': 'ONGOING',
  'overview':
      'A landmark address in the heart of South Mumbai with sweeping harbour views',
  'image': '',
};

const _project = {
  '_id': 'p1',
  'title': _title,
  'name': _title,
  'status': 'ONGOING',
  'location': {'name': 'Mazgaon'},
  'heroImage': '',
  'thumbnail': '',
};

/// The card is the nearest [Stack] around the title: the layer stack whose
/// size is the thumbnail frame, and so the ratio the user actually sees.
/// (Its own clip is a ClipRRect on some cards and clipBehavior on others.)
void expectSixteenByNine(
  WidgetTester tester,
  String label, {
  // Communities and Media upper-case the name; the Properties card prints it
  // as it comes from the backend.
  String text = _titleCaps,
}) {
  final title = find.text(text);
  expect(title, findsWidgets, reason: '$label: card did not render');

  final card = find.ancestor(of: title.first, matching: find.byType(Stack));
  expect(card, findsWidgets, reason: '$label: no card stack around the title');

  final rect = tester.getRect(card.first);
  expect(
    rect.width / rect.height,
    closeTo(_ratio, 0.01),
    reason:
        '$label: thumbnail is ${rect.width.toStringAsFixed(1)}x'
        '${rect.height.toStringAsFixed(1)}, not 16:9',
  );
}

/// Sweeps the whole rendered page: every 16:9 frame the screens declare has to
/// actually lay out at 16:9. A frame whose parent forces a different height —
/// a hand-sized row, a PageView, a leftover fixed SizedBox — silently loses the
/// ratio, and that is exactly what this catches.
void expectEveryFrameIsSixteenByNine(WidgetTester tester, String label) {
  final frames = find.byWidgetPredicate(
    (w) => w is AspectRatio && (w.aspectRatio - _ratio).abs() < 0.001,
  );
  final count = frames.evaluate().length;
  expect(count, greaterThan(0), reason: '$label: no 16:9 frames rendered');

  for (var i = 0; i < count; i++) {
    final rect = tester.getRect(frames.at(i));
    if (rect.width == 0 || rect.height == 0) continue; // offstage
    expect(
      rect.width / rect.height,
      closeTo(_ratio, 0.01),
      reason:
          '$label: frame $i laid out ${rect.width.toStringAsFixed(1)}x'
          '${rect.height.toStringAsFixed(1)}, not 16:9',
    );
  }
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> pump(WidgetTester tester, Widget screen, double dp) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = Size(dp, 1400);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(
            _FakeApiClient(const [_community]),
          ),
          projectsProvider.overrideWith((ref) async => const [_project]),
          // Seeded so the page is past its loading gate on the first frame:
          // the gate is lifted by a disk-cache read plus a compute() isolate,
          // neither of which the test binding's clock drives.
          guestHomeCacheProvider.overrideWith(
            (ref) => const GuestHomeData(
              projects: [_project],
              communities: [_community],
              media: [_project],
            ),
          ),
        ],
        child: MaterialApp(home: Scaffold(body: screen)),
      ),
    );
    // Not pumpAndSettle: these pages carry entrance animations and a repeating
    // hero timer that would keep the scheduler busy forever.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  Future<void> openTab(WidgetTester tester, String tab) async {
    await tester.tap(find.text(tab).first, warnIfMissed: false);
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  // 320dp is the narrowest handset the app supports, 411dp a common large one.
  for (final dp in <double>[320, 360, 411]) {
    final at = '${dp.toInt()}dp';

    for (final portal in <String, Widget Function()>{
      'guest': () => const GuestDashboardScreen(),
      'cp': () => const CpHomeScreen(),
      'investor': () => const InvestorHomeScreen(),
    }.entries) {
      testWidgets('$at: ${portal.key} home tiles are 16:9', (tester) async {
        await pump(tester, portal.value(), dp);
        expectSixteenByNine(tester, '${portal.key}/communities @ $at');

        await openTab(tester, 'MEDIA');
        expectSixteenByNine(tester, '${portal.key}/media @ $at');

        await openTab(tester, 'PROPERTIES');
        expectSixteenByNine(
          tester,
          '${portal.key}/properties @ $at',
          text: _title,
        );

        // Hero carousel, Featured Property card and every other frame the page
        // declares.
        expectEveryFrameIsSixteenByNine(tester, '${portal.key} @ $at');

        // Two matches: the section heading and the kicker inside the card.
        // Without this the sweep above would pass on a page where the Featured
        // Property card never rendered at all.
        expect(
          find.text('FEATURED PROPERTY'),
          findsNWidgets(2),
          reason: '${portal.key} @ $at: Featured Property card did not render',
        );

        // A wrapping title used to overflow the shorter tile with a hard error.
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('$at: the properties list card is 16:9', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = Size(dp, 1400);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(_FakeApiClient(const [])),
            projectsProvider.overrideWith((ref) async => const [_project]),
          ],
          child: const MaterialApp(home: ProjectListScreen()),
        ),
      );
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }

      expectSixteenByNine(tester, 'properties list @ $at');
      expect(tester.takeException(), isNull);
    });
  }
}
