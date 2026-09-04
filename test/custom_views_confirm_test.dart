import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/providers/custom_views_provider.dart';
import 'package:m4_mobile/presentation/providers/project_provider.dart';
import 'package:m4_mobile/presentation/screens/custom_views/custom_views_screen.dart';

/// CONFIRM SELECTIONS on the customer Custom Views wizard.
///
/// POST /api/custom-views answers
///   400 {"status":false,"message":"Space and selections are required"}
/// when `space` is missing. The materials step falls back to a literal
/// 'Full Unit' when no space was chosen, so the summary reads
/// "FULL UNIT / FLOORING" while selections['space'] is still null — the save
/// then failed and the catch replaced the reason with one opaque line.
class _RecordingApi extends ApiClient {
  _RecordingApi({this.throwWith, this.body})
    : super(baseUrl: 'http://localhost');

  final Object? throwWith;
  final Map<String, dynamic>? body;
  final List<Map<String, dynamic>> calls = [];

  @override
  Future<Response> submitCustomViews(Map<String, dynamic> data) async {
    calls.add(data);
    // A real round trip, so a second tap has a window to land in.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (throwWith != null) throw throwWith!;
    return Response(
      requestOptions: RequestOptions(path: '/api/custom-views'),
      statusCode: 200,
      data: body ?? {'status': true},
    );
  }
}

/// The 400 the live API returns for a missing space.
DioException get _spaceRequired => DioException(
  requestOptions: RequestOptions(path: '/api/custom-views'),
  response: Response(
    requestOptions: RequestOptions(path: '/api/custom-views'),
    statusCode: 400,
    data: {
      'status': false,
      'message': 'Space and selections are required',
    },
  ),
  type: DioExceptionType.badResponse,
);

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async => null,
    );
  });

  /// The wizard sitting on its final step, with materials recorded under the
  /// 'Full Unit' fallback and no `space` key — exactly the reported state.
  Future<void> pumpAtSummary(
    WidgetTester tester,
    ApiClient api, {
    Map<String, dynamic>? selections,
  }) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(411, 2400);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(api),
          projectsProvider.overrideWith(
            (ref) async => const [
              {'_id': 'p1', 'title': 'Clédor'},
            ],
          ),
          customViewsStepProvider.overrideWith((ref) => 3),
          customViewsProjectProvider.overrideWith((ref) => 'p1'),
          customViewsUnitProvider.overrideWith((ref) => '1 BHK'),
          customViewsUnitNumberProvider.overrideWith((ref) => 'A-0101'),
          customViewsSelectionsProvider.overrideWith(
            (ref) =>
                selections ??
                {'Full Unit': {}, 'Full Unit/FLOORING': 'LIVING TILES'},
          ),
        ],
        child: const MaterialApp(home: CustomViewsScreen()),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  testWidgets('sends a space even when none was picked', (tester) async {
    final api = _RecordingApi();
    await pumpAtSummary(tester, api);

    expect(find.text('CONFIRM SELECTIONS'), findsOneWidget);
    await tester.tap(find.text('CONFIRM SELECTIONS'));
    await tester.pump();
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(api.calls, hasLength(1));
    final space = api.calls.single['space'];
    // The API rejects a null or empty space outright.
    expect(space, isNotNull);
    expect(space.toString().trim(), isNotEmpty);
    expect(space, 'Full Unit');
  });

  testWidgets('a chosen space is sent unchanged', (tester) async {
    final api = _RecordingApi();
    await pumpAtSummary(
      tester,
      api,
      selections: {
        'spaces': ['Living Room', 'Kitchen'],
        'space': 'Living Room, Kitchen',
        'Living Room/FLOORING': 'LIVING TILES',
      },
    );

    await tester.tap(find.text('CONFIRM SELECTIONS'));
    await tester.pump();
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(api.calls.single['space'], 'Living Room, Kitchen');
  });

  testWidgets('spaces without a joined space string still send one', (
    tester,
  ) async {
    final api = _RecordingApi();
    await pumpAtSummary(
      tester,
      api,
      selections: {
        'spaces': ['Bedroom'],
        'Bedroom/FLOORING': 'OAK',
      },
    );

    await tester.tap(find.text('CONFIRM SELECTIONS'));
    await tester.pump();
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(api.calls.single['space'], 'Bedroom');
  });

  testWidgets('repeat taps fire one request, not one per tap', (tester) async {
    final api = _RecordingApi();
    await pumpAtSummary(tester, api);

    final button = find.text('CONFIRM SELECTIONS');
    await tester.tap(button);
    await tester.pump();

    // Hammer it while the first request is still in flight.
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('SAVING…'), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 20));
    }
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(api.calls, hasLength(1));
  });

  testWidgets('the tap is acknowledged before the request returns', (
    tester,
  ) async {
    final api = _RecordingApi();
    await pumpAtSummary(tester, api);

    await tester.tap(find.text('CONFIRM SELECTIONS'));
    await tester.pump();

    // Immediately, before the 300ms round trip completes.
    expect(find.text('Saving your selections…'), findsOneWidget);
    expect(find.text('SAVING…'), findsOneWidget);

    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.text('Selections successfully saved!'), findsOneWidget);
    // The progress notice was replaced, not left queued behind the result.
    expect(find.text('Saving your selections…'), findsNothing);
  });

  testWidgets('a failure shows what the server said', (tester) async {
    final api = _RecordingApi(throwWith: _spaceRequired);
    await pumpAtSummary(tester, api);

    await tester.tap(find.text('CONFIRM SELECTIONS'));
    await tester.pump();
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(find.text('Space and selections are required'), findsOneWidget);
    // ...and the button is usable again rather than stuck on SAVING.
    expect(find.text('CONFIRM SELECTIONS'), findsOneWidget);
  });

  testWidgets('a 200 that reports failure is no longer silent', (tester) async {
    final api = _RecordingApi(
      body: {'status': false, 'message': 'Unit already customised'},
    );
    await pumpAtSummary(tester, api);

    await tester.tap(find.text('CONFIRM SELECTIONS'));
    await tester.pump();
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(find.text('Unit already customised'), findsOneWidget);
  });
}
