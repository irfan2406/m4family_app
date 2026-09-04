import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/providers/project_provider.dart';
import 'package:m4_mobile/presentation/screens/projects/project_list_screen.dart';

/// CP portal > Properties.
///
/// The CP shell mounts the same ProjectListScreen the guest shell does, only
/// with cpCatalogMode: true — that flag changes the drawer, the header and the
/// detail route, never the data or the status filter. The catalog holds one
/// project, Clédor, with status "Ongoing" (capitalised), and the ONGOING tab
/// reported no matches, so this pins the two things that could cause that:
/// the capitalisation, and CP mode itself.
class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(baseUrl: 'http://localhost');
}

/// Exactly the row GET /api/catalog/projects returns today.
const _cledor = {
  '_id': '68b1a0f1c2d3e4f5a6b7c8d9',
  'title': 'Clédor',
  'status': 'Ongoing',
  'location': {'name': 'Mazgaon'},
  'createdAt': '2025-08-29T10:00:00.000Z',
};

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async => null,
    );
  });

  Future<void> pump(
    WidgetTester tester, {
    required bool cpMode,
    List<dynamic> catalog = const [_cledor],
  }) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(411, 1400);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(_FakeApiClient()),
          projectsProvider.overrideWith((ref) async => catalog),
        ],
        child: MaterialApp(home: ProjectListScreen(cpCatalogMode: cpMode)),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  testWidgets('CP mode lists the Ongoing project rather than "no matches"', (
    tester,
  ) async {
    await pump(tester, cpMode: true);
    expect(tester.takeException(), isNull);

    // The CP header is the one from the screenshot.
    expect(find.text('M4 PROPERTIES'), findsOneWidget);
    // "Ongoing" from the API vs the ONGOING tab: the compare is lowercased on
    // both sides, so the capitalisation must not matter.
    expect(find.text('NO ARCHITECTURAL MATCHES'), findsNothing);
    expect(find.textContaining('CLÉDOR', findRichText: true), findsWidgets);
  });

  testWidgets('guest mode lists it too — the flag changes no data', (
    tester,
  ) async {
    await pump(tester, cpMode: false);
    expect(tester.takeException(), isNull);
    expect(find.text('NO ARCHITECTURAL MATCHES'), findsNothing);
  });

  testWidgets('a genuinely empty catalog still shows the empty state', (
    tester,
  ) async {
    await pump(tester, cpMode: true, catalog: const []);
    expect(tester.takeException(), isNull);
    expect(find.text('NO ARCHITECTURAL MATCHES'), findsOneWidget);
  });

  testWidgets('a filter hiding everything says so, and clears', (tester) async {
    // The REFINE SEARCH filters are global StateProviders that outlive the
    // sheet and the tab, so one left on empties every status with no sign of
    // why. This is the case that looked like "properties are not loading".
    late WidgetRef captured;
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(411, 1400);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(_FakeApiClient()),
          projectsProvider.overrideWith((ref) async => const [_cledor]),
          // Clédor is in Mazgaon, so this hides it.
          selectedLocationsProvider.overrideWith((ref) => ['WORLI']),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            captured = ref;
            return const MaterialApp(
              home: ProjectListScreen(cpCatalogMode: true),
            );
          },
        ),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }

    expect(find.text('NO ARCHITECTURAL MATCHES'), findsOneWidget);
    expect(
      find.text('Your refine-search filters are hiding every property here.'),
      findsOneWidget,
    );
    expect(find.text('CLEAR FILTERS'), findsOneWidget);

    await tester.tap(find.text('CLEAR FILTERS'));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }

    // The property comes back, and the filter state really was reset.
    expect(find.text('NO ARCHITECTURAL MATCHES'), findsNothing);
    expect(captured.read(selectedLocationsProvider), isEmpty);
  });

  testWidgets('an empty catalog keeps the original wording, no clear button', (
    tester,
  ) async {
    await pump(tester, cpMode: true, catalog: const []);
    expect(find.text('Try expanding your search criteria.'), findsOneWidget);
    expect(find.text('CLEAR FILTERS'), findsNothing);
  });

  testWidgets('a lowercase status from the backend also matches', (
    tester,
  ) async {
    await pump(
      tester,
      cpMode: true,
      catalog: const [
        {
          '_id': '68b1a0f1c2d3e4f5a6b7c8d9',
          'title': 'Clédor',
          'status': 'ongoing',
          'location': {'name': 'Mazgaon'},
        },
      ],
    );
    expect(find.text('NO ARCHITECTURAL MATCHES'), findsNothing);
  });
}
