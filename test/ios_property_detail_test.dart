import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/screens/projects/guest_project_detail_screen.dart';
import 'package:m4_mobile/presentation/screens/projects/project_detail_screen.dart';
import 'package:m4_mobile/presentation/widgets/luxury_amenity_icon.dart';
import 'package:m4_mobile/presentation/widgets/m4_map_view.dart';

import 'goldens/golden_harness.dart' show runOnPlatform, setUpGoldenHarness;
import 'support/fake_webview_platform.dart';

/// The property detail screen: the amenity icon comes from the backend on
/// both platforms, the floating BOOK NOW bar and the CONTACT card are gone,
/// and the map page gets the base URL iOS needs to load the embed (Android
/// passes none, exactly as before).
const _iconUrl = 'https://files.example.com/m4/lobby.jpeg';

const _project = {
  '_id': 'p1',
  'title': 'Clédor',
  'location': {'name': 'Mazgaon', 'region': 'Mumbai, India'},
  'amenities': [
    {'_id': 'a1', 'name': 'lobby', 'icon': _iconUrl, 'category': 'General'},
  ],
};

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(baseUrl: 'http://api.example.com');

  Response _ok(String path, dynamic data) => Response(
    requestOptions: RequestOptions(path: path),
    statusCode: 200,
    data: {'status': true, 'data': data},
  );

  @override
  Future<Response> getProjectDetails(String id) async =>
      _ok('/api/catalog/projects/$id', _project);

  @override
  Future<Response> getProjectUpdates(String id) async => _ok('/updates', []);

  @override
  Future<Response> getProjectInventory(String id) async =>
      _ok('/inventory', []);

  @override
  Future<Response> getProjectProgress(String id) async => _ok('/progress', []);
}

void main() {
  setUpAll(setUpGoldenHarness);
  setUp(loadedHtml.clear);

  final android = TargetPlatformVariant.only(TargetPlatform.android);
  final iOS = TargetPlatformVariant.only(TargetPlatform.iOS);

  group('amenity icons', () {
    test('the backend icon is read from the amenity, when it has one', () {
      expect(amenityIconUrl((_project['amenities']! as List).first), _iconUrl);
      expect(amenityIconUrl({'name': 'lobby'}), isNull);
      expect(amenityIconUrl({'name': 'lobby', 'icon': '   '}), isNull);
      expect(amenityIconUrl('lobby'), isNull);
    });

    // The guest and customer portals show the same property detail; CP and
    // investor already drew the uploaded icon on both platforms.
    const screens = <String, Widget>{
      'guest': GuestProjectDetailScreen(projectId: 'p1', projectData: _project),
      'customer': ProjectDetailScreen(projectId: 'p1', projectData: _project),
    };

    Future<void> openDetail(WidgetTester tester, [Widget? screen]) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [apiClientProvider.overrideWithValue(_FakeApiClient())],
          child: MaterialApp(home: screen ?? screens['guest']!),
        ),
      );
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }
    }

    Finder backendIcon() => find.byWidgetPredicate(
      (w) => w is CachedNetworkImage && w.imageUrl == _iconUrl,
    );

    for (final entry in screens.entries) {
      testWidgets('iOS draws the uploaded icon on the ${entry.key} screen', (
        tester,
      ) async {
        await runOnPlatform(TargetPlatform.iOS, () async {
          await openDetail(tester, entry.value);
          expect(backendIcon(), findsOneWidget);
        });
      }, variant: iOS);

      testWidgets(
        'android draws the uploaded icon on the ${entry.key} screen',
        (tester) async {
          await runOnPlatform(TargetPlatform.android, () async {
            await openDetail(tester, entry.value);
            expect(backendIcon(), findsOneWidget);
          });
        },
        variant: android,
      );
    }

    for (final entry in screens.entries) {
      testWidgets('the ${entry.key} amenity cell carries no outline', (
        tester,
      ) async {
        await runOnPlatform(TargetPlatform.android, () async {
          await openDetail(tester, entry.value);
          final cell = tester.widget<Container>(
            find
                .ancestor(
                  of: find.text('lobby'),
                  matching: find.byType(Container),
                )
                .first,
          );
          expect((cell.decoration! as BoxDecoration).border, isNull);
        });
      }, variant: android);
    }

    testWidgets('iOS: no floating BOOK NOW bar, however far it scrolls', (
      tester,
    ) async {
      await runOnPlatform(TargetPlatform.iOS, () async {
        await openDetail(tester);
        await _scroll(tester);
        expect(find.text('BOOK NOW'), findsNothing);
      });
    }, variant: iOS);

    testWidgets(
      'android: no floating BOOK NOW bar, however far it scrolls',
      (tester) async {
        await runOnPlatform(TargetPlatform.android, () async {
          await openDetail(tester);
          await _scroll(tester);
          expect(find.text('BOOK NOW'), findsNothing);
        });
      },
      variant: android,
    );
  });

  group('the CONTACT card is gone', () {
    for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
      testWidgets(
        '${platform.name}: no "interested in this project" card',
        (tester) async {
          await runOnPlatform(platform, () async {
            tester.view.physicalSize = const Size(1170, 2532);
            tester.view.devicePixelRatio = 3;
            addTearDown(tester.view.reset);
            await tester.pumpWidget(
              ProviderScope(
                overrides: [
                  apiClientProvider.overrideWithValue(_FakeApiClient()),
                ],
                child: const MaterialApp(
                  home: ProjectDetailScreen(
                    projectId: 'p1',
                    projectData: _project,
                  ),
                ),
              ),
            );
            for (var i = 0; i < 4; i++) {
              await tester.pump(const Duration(milliseconds: 300));
            }
            // The page builds every section at once, so a card that still
            // existed would be found even before it scrolls into view.
            expect(find.text('INTERESTED IN THIS PROJECT?'), findsNothing);
            expect(find.text('BOOK YOUR UNIT NOW'), findsNothing);
            expect(find.text('CONTACT'), findsNothing);
          });
        },
        variant: platform == TargetPlatform.iOS ? iOS : android,
      );
    }
  });

  group('map', () {
    Future<void> pumpMap(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: M4MapView(query: 'Mazgaon, Mumbai', onOpen: () {}),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('iOS gives the page a base URL, so the embed loads', (
      tester,
    ) async {
      await runOnPlatform(TargetPlatform.iOS, () async {
        await pumpMap(tester);
        expect(loadedHtml, hasLength(1));
        expect(loadedHtml.single.baseUrl, M4MapView.iosBaseUrl);
        expect(loadedHtml.single.html, contains('<iframe'));
        expect(loadedHtml.single.html, contains('Mazgaon'));
      });
    }, variant: iOS);

    testWidgets('android loads exactly as before, with no base URL', (
      tester,
    ) async {
      await runOnPlatform(TargetPlatform.android, () async {
        await pumpMap(tester);
        expect(loadedHtml, hasLength(1));
        expect(loadedHtml.single.baseUrl, isNull);
        expect(loadedHtml.single.html, contains('<iframe'));
      });
    }, variant: android);
  });
}

/// Scrolls the page well past the point where the bar used to appear.
Future<void> _scroll(WidgetTester tester) async {
  await tester.drag(
    find.byType(SingleChildScrollView).first,
    const Offset(0, -600),
  );
  for (var i = 0; i < 3; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
}
