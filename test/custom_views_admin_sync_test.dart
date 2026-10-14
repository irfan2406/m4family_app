import 'package:cached_network_image/cached_network_image.dart';
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
import 'package:m4_mobile/presentation/screens/custom_views/guest_custom_views_screen.dart';
import 'package:m4_mobile/presentation/widgets/main_shell.dart';

/// Testing point 10: "changes made in Admin > Custom Views don't show in the
/// app". The server returns every admin change straight away; the app kept
/// the first copy it fetched for the whole session and showed built-in copy
/// instead of the admin's title, text and banner.
///
/// Per the backend: page copy from GET /api/config (customization_hero_title /
/// customization_description / customization_hero_image), categories and
/// options from GET /api/catalog/customization-options, the project/unit
/// setup from GET /api/custom-views/config (null data -> the generic list),
/// all re-read every time the screen opens or is pulled to refresh.
class _FakeApi extends ApiClient {
  _FakeApi() : super(baseUrl: 'http://api.example.com');

  Map<String, dynamic> config = {
    'customization_hero_title': 'Exquisite selection only for discerning few',
    'customization_description': 'Experience the pinnacle of luxury.',
    'customization_hero_image': '/uploads/media/hero.jpg',
  };
  List<dynamic> options = const [
    {
      '_id': 'c1',
      'title': 'Flooring',
      'options': [
        {'_id': 'o1', 'name': 'Living Tiles'},
        {'_id': 'o2', 'name': 'Marble Finish', 'image': ''},
        {'_id': 'o3', 'name': 'Bedroom Wood', 'image': '/uploads/media/w.jpg'},
      ],
    },
  ];
  Map<String, dynamic>? unitConfig;

  int configCalls = 0;
  int optionCalls = 0;
  int unitConfigCalls = 0;

  Response _ok(String path, Object? data, [String? message]) => Response(
    requestOptions: RequestOptions(path: path),
    statusCode: 200,
    data: {'status': true, if (message != null) 'message': message, 'data': data},
  );

  @override
  Future<Response> getPublicConfig() async {
    configCalls++;
    return _ok('/api/config', config);
  }

  @override
  Future<Response> getCustomizationOptions() async {
    optionCalls++;
    return _ok('/api/catalog/customization-options', options);
  }

  @override
  Future<Response> getCustomViewsConfig(String projectId, String config) async {
    unitConfigCalls++;
    return _ok(
      '/api/custom-views/config',
      unitConfig,
      unitConfig == null ? 'No specific config found, using defaults' : null,
    );
  }

  @override
  Future<Response> getMyCustomViews() async =>
      _ok('/api/custom-views/my', const []);

  @override
  Future<Response> getContent(
    String type, {
    String role = 'guest',
    String? projectId,
  }) async => _ok('/api/content', const []);
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

  String resolve(String? url) => (url == null || url.isEmpty)
      ? ''
      : url.startsWith('http')
      ? url
      : 'http://api.example.com$url';

  group('parseCustomizationPage', () {
    test('reads the admin title, text and banner', () {
      final page = parseCustomizationPage({
        'status': true,
        'data': {
          'customization_hero_title': ' Exquisite selection ',
          'customization_description': 'Bespoke finishes.',
          'customization_hero_image': '/uploads/media/hero.jpg',
          // Not used on any platform yet (backend note): ignored.
          'customization_hero_subtitle': 'Craft your living space',
          'customization_cta_text': 'Start Customising',
        },
      }, resolve);
      expect(page.title, 'Exquisite selection');
      expect(page.description, 'Bespoke finishes.');
      expect(page.heroImage, 'http://api.example.com/uploads/media/hero.jpg');
    });

    test('unset fields stay empty so the built-in copy is used', () {
      final page = parseCustomizationPage({
        'status': true,
        'data': <String, dynamic>{},
      }, resolve);
      expect(page.title, isEmpty);
      expect(page.description, isEmpty);
      expect(page.heroImage, isEmpty);
      expect(parseCustomizationPage(null, resolve).title, isEmpty);
    });
  });

  group('customViewsConfigProvider', () {
    ProviderContainer containerFor(_FakeApi api) {
      final c = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(api),
          customViewsProjectProvider.overrideWith((ref) => 'p1'),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('null data falls back to the generic list (returns null)', () async {
      final api = _FakeApi();
      expect(await containerFor(api).read(customViewsConfigProvider.future), isNull);
      expect(api.unitConfigCalls, 1);
    });

    test('a specific setup is used when the server has one', () async {
      final api = _FakeApi()
        ..unitConfig = {
          'categories': [
            {'title': 'Flooring', 'spaces': const []},
          ],
        };
      final cfg = await containerFor(api).read(customViewsConfigProvider.future);
      expect((cfg!['categories'] as List).single['title'], 'Flooring');
    });
  });

  group('wizard (customer)', () {
    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
    }

    Future<void> pump(WidgetTester tester, _FakeApi api, {int step = 0}) async {
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
            customViewsStepProvider.overrideWith((ref) => step),
          ],
          child: const MaterialApp(home: CustomViewsScreen()),
        ),
      );
      await settle(tester);
    }

    testWidgets('shows the admin title, text and banner', (tester) async {
      final api = _FakeApi();
      await pump(tester, api);

      // A first open fetches each source once, not twice.
      expect(api.configCalls, 1);

      expect(
        find.text('EXQUISITE SELECTION ONLY FOR DISCERNING FEW'),
        findsOneWidget,
      );
      expect(find.text('YOUR LEGACY'), findsNothing);
      expect(find.text('Experience the pinnacle of luxury.'), findsOneWidget);
      final banner = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage).first,
      );
      expect(banner.imageUrl, 'http://api.example.com/uploads/media/hero.jpg');
      expect(tester.takeException(), isNull);
    });

    testWidgets('nothing set in admin: the built-in copy and banner', (
      tester,
    ) async {
      await pump(tester, _FakeApi()..config = <String, dynamic>{});

      expect(find.text('YOUR LEGACY'), findsOneWidget);
      expect(find.textContaining('Your home is a reflection'), findsOneWidget);
      expect(find.byType(CachedNetworkImage), findsNothing);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Image &&
              w.image is AssetImage &&
              (w.image as AssetImage).assetName == 'assets/custom_view_1.png',
        ),
        findsOneWidget,
      );
    });

    testWidgets('opening the shell tab again re-reads the admin data', (
      tester,
    ) async {
      final api = _FakeApi();
      await pump(tester, api);
      final element = tester.element(find.byType(CustomViewsScreen));
      final container = ProviderScope.containerOf(element);
      container.read(navigationProvider.notifier).state = 0;
      await settle(tester);
      final before = (api.configCalls, api.optionCalls);

      // The admin edits the page while the app is open.
      api.config = {...api.config, 'customization_hero_title': 'New Title'};
      container.read(navigationProvider.notifier).state = 6;
      await settle(tester);

      expect(api.configCalls, greaterThan(before.$1));
      expect(api.optionCalls, greaterThan(before.$2));
      expect(find.text('NEW TITLE'), findsOneWidget);
    });

    testWidgets('opening the screen again re-reads, not the session copy', (
      tester,
    ) async {
      final api = _FakeApi();
      await pump(tester, api);
      final calls = api.configCalls;

      api.config = {...api.config, 'customization_hero_title': 'Reopened'};
      Navigator.of(
        tester.element(find.byType(CustomViewsScreen)),
      ).push(MaterialPageRoute(builder: (_) => const CustomViewsScreen()));
      await settle(tester);

      expect(api.configCalls, greaterThan(calls));
      expect(find.text('REOPENED'), findsOneWidget);
    });

    testWidgets('pull to refresh re-reads the admin data', (tester) async {
      final api = _FakeApi();
      await pump(tester, api);
      final before = (api.configCalls, api.optionCalls);

      api.config = {...api.config, 'customization_hero_title': 'Pulled'};
      await tester.fling(
        find.byType(SingleChildScrollView).first,
        const Offset(0, 400),
        1000,
      );
      await settle(tester);

      expect(api.configCalls, greaterThan(before.$1));
      expect(api.optionCalls, greaterThan(before.$2));
      expect(find.text('PULLED'), findsOneWidget);
    });

    testWidgets('option images: placeholder when empty, uploads resolved', (
      tester,
    ) async {
      await pump(tester, _FakeApi(), step: 2);

      expect(find.text('LIVING TILES'), findsWidgets);
      final networkUrls = tester
          .widgetList<Image>(find.byType(Image))
          .map((w) => w.image)
          .whereType<NetworkImage>()
          .map((i) => i.url)
          .toList();
      // Only the option that has an image asks for one, at a full URL.
      expect(networkUrls, ['http://api.example.com/uploads/media/w.jpg']);
      expect(tester.takeException(), isNull);
    });
  });

  group('Custom Views page (guest / CP / investor)', () {
    Future<void> pump(WidgetTester tester, _FakeApi api) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(411, 2400);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [apiClientProvider.overrideWithValue(api)],
          child: const MaterialApp(home: GuestCustomViewsScreen()),
        ),
      );
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }
    }

    testWidgets('shows the admin title and text', (tester) async {
      final api = _FakeApi();
      await pump(tester, api);
      expect(api.configCalls, 1, reason: 'a first open fetches once');
      expect(
        find.text('EXQUISITE SELECTION ONLY FOR DISCERNING FEW'),
        findsOneWidget,
      );
      expect(find.text('Experience the pinnacle of luxury.'), findsOneWidget);
      expect(find.text('DESIGN\nYOUR\nDESTINY'), findsNothing);
    });

    testWidgets('nothing set in admin: the built-in copy', (tester) async {
      await pump(tester, _FakeApi()..config = <String, dynamic>{});
      expect(find.text('DESIGN\nYOUR\nDESTINY'), findsOneWidget);
      expect(
        find.textContaining('Experience the future of home personalisation'),
        findsOneWidget,
      );
    });

    testWidgets('pull to refresh re-reads the admin copy', (tester) async {
      final api = _FakeApi();
      await pump(tester, api);
      final calls = api.configCalls;

      api.config = {...api.config, 'customization_description': 'Updated.'};
      await tester.fling(
        find.byType(CustomScrollView),
        // RefreshIndicator arms after a quarter of the viewport.
        const Offset(0, 1000),
        1000,
      );
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }

      expect(api.configCalls, greaterThan(calls));
      expect(find.text('Updated.'), findsOneWidget);
    });
  });
}
