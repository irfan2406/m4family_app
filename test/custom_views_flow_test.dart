import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/providers/custom_views_provider.dart';
import 'package:m4_mobile/presentation/screens/custom_views/my_custom_views_screen.dart';
import 'package:m4_mobile/presentation/widgets/main_shell.dart';

/// Customer portal, Custom Views flow.
///
/// START PERSONALISATION on the Portfolio Suite opened the wizard on step 0,
/// ALLOTTED — but this entry always carries an allotted unit: the project, unit
/// number and config are set from the booking right before the jump, and the
/// wizard then locks them ("Your project and unit configuration are locked for
/// this booking"). It now opens on SELECT SPACE, step 1, the rule the wizard
/// already states for itself when a unit context is known.
///
/// The Portfolio Suite appears two ways — as shell tab 7, and pushed as a route
/// from MY PROPERTIES > CUSTOMISE UNIT — so the hand-off is checked both ways.
/// Switching a shell tab from underneath a pushed route would leave that route
/// on screen, so the pushed case has to push the wizard instead.
class _FakeApi extends ApiClient {
  _FakeApi({this.extraUnitFields = const {}})
    : super(baseUrl: 'http://localhost');

  /// Whatever the unit record carries beyond the basics, e.g. block / wing.
  final Map<String, dynamic> extraUnitFields;

  @override
  Future<Response> getMyUnits() async => Response(
    requestOptions: RequestOptions(path: '/api/customization/my-units'),
    statusCode: 200,
    data: {
      'status': true,
      'data': [
        {
          // A real ObjectId: the card renders the last 8 characters of it.
          'bookingId': '6a9a6a18742c26308828ee3c',
          'projectId': 'p1',
          'projectName': 'Clédor',
          'unitNumber': 'A-0101',
          'config': '1 BHK',
          'customizationStatus': 'NOT_STARTED',
          'modificationCount': 0,
          ...extraUnitFields,
        },
      ],
    },
  );

  @override
  Future<Response> getMyCustomViews() async => Response(
    requestOptions: RequestOptions(path: '/api/custom-views/my'),
    statusCode: 200,
    data: {'status': true, 'data': const []},
  );
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async => null,
    );
  });

  /// [pushed] mirrors arriving from MY PROPERTIES (the suite sits on a pushed
  /// route); otherwise it is the shell tab, with nothing to pop back to.
  Future<WidgetRef> pump(
    WidgetTester tester, {
    required bool pushed,
    Map<String, dynamic> extraUnitFields = const {},
  }) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(411, 1600);
    addTearDown(tester.view.reset);

    late WidgetRef captured;
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => pushed
              ? const Scaffold(body: Center(child: Text('ORIGIN')))
              : const MyCustomViewsScreen(),
        ),
        GoRoute(
          path: '/my-custom-views',
          builder: (context, state) => const MyCustomViewsScreen(),
        ),
        GoRoute(
          path: '/custom-views',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('WIZARD'))),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(
            _FakeApi(extraUnitFields: extraUnitFields),
          ),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            captured = ref;
            return MaterialApp.router(routerConfig: router);
          },
        ),
      ),
    );
    await tester.pump();
    if (pushed) {
      router.push('/my-custom-views');
      await tester.pump();
    }
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    return captured;
  }

  testWidgets('as a shell tab: opens the wizard on SELECT SPACE', (
    tester,
  ) async {
    final ref = await pump(tester, pushed: false);

    expect(find.text('A-0101'), findsOneWidget);
    expect(find.text('START PERSONALISATION'), findsOneWidget);
    expect(ref.read(customViewsStepProvider), 0);

    await tester.tap(find.text('START PERSONALISATION'));
    await tester.pump(const Duration(milliseconds: 300));

    // Step 1 is SELECT SPACE; step 0 is the ALLOTTED step this flow skips.
    expect(ref.read(customViewsStepProvider), 1);
    // 6 is the wizard tab, 7 the Portfolio Suite it came from — the origin the
    // system back button now honours.
    expect(ref.read(navigationProvider), 6);
    expect(ref.read(previousNavigationProvider), 7);

    // The unit context really was carried over, which is what makes skipping
    // the ALLOTTED step correct.
    expect(ref.read(customViewsProjectProvider), 'p1');
    expect(ref.read(customViewsUnitNumberProvider), 'A-0101');
    expect(ref.read(customViewsUnitProvider), '1 BHK');
  });

  testWidgets('pushed from MY PROPERTIES: pushes the wizard, same step', (
    tester,
  ) async {
    final ref = await pump(tester, pushed: true);

    expect(find.text('START PERSONALISATION'), findsOneWidget);

    await tester.tap(find.text('START PERSONALISATION'));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }

    expect(ref.read(customViewsStepProvider), 1);
    // The wizard is on screen as its own route rather than a tab swapped in
    // underneath this one.
    expect(find.text('WIZARD'), findsOneWidget);
  });

  group('Block / Tower and Wing reach the summary', () {
    // These two rows read customViewsBlockProvider / customViewsWingProvider,
    // and this route never populated them — so they rendered N/A whatever the
    // record held.
    testWidgets('block and wing are carried from the unit', (tester) async {
      final ref = await pump(
        tester,
        pushed: false,
        extraUnitFields: const {'block': 'B', 'wing': 'West'},
      );

      await tester.tap(find.text('START PERSONALISATION'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(ref.read(customViewsBlockProvider), 'B');
      expect(ref.read(customViewsWingProvider), 'West');
    });

    testWidgets('a unit that names it "tower" is read too', (tester) async {
      // /api/inventory stores a unit's block as `tower`.
      final ref = await pump(
        tester,
        pushed: false,
        extraUnitFields: const {'tower': 'Tower A'},
      );

      await tester.tap(find.text('START PERSONALISATION'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(ref.read(customViewsBlockProvider), 'Tower A');
    });

    testWidgets('a record with neither leaves them unset, so N/A is honest', (
      tester,
    ) async {
      final ref = await pump(tester, pushed: false);

      await tester.tap(find.text('START PERSONALISATION'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(ref.read(customViewsBlockProvider), isNull);
      expect(ref.read(customViewsWingProvider), isNull);
    });

    testWidgets('blank and literal N/A values do not become the answer', (
      tester,
    ) async {
      final ref = await pump(
        tester,
        pushed: false,
        extraUnitFields: const {'block': '  ', 'wing': 'N/A', 'tower': 'T2'},
      );

      await tester.tap(find.text('START PERSONALISATION'));
      await tester.pump(const Duration(milliseconds: 300));

      // An empty block falls through to the tower...
      expect(ref.read(customViewsBlockProvider), 'T2');
      // ...and a literal "N/A" is treated as absent rather than printed back.
      expect(ref.read(customViewsWingProvider), isNull);
    });
  });
}
