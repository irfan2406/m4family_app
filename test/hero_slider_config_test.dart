import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/providers/hero_slider_provider.dart';
import 'package:m4_mobile/presentation/providers/project_provider.dart';
import 'package:m4_mobile/presentation/screens/home/guest_dashboard_screen.dart'
    show GuestDashboardScreen, guestHomeCacheProvider, GuestHomeData;

/// The home hero has to follow the Admin Panel: the web reads
/// `GET /api/config` -> `data.heroSliderImages` and shows exactly those images,
/// while the app used to build its hero from the project catalog plus a bundled
/// asset, so an admin's edit never reached it.
class _FakeApiClient extends ApiClient {
  _FakeApiClient({this.config, this.configThrows = false})
    : super(baseUrl: 'http://api.example.com');

  final Map<String, dynamic>? config;
  final bool configThrows;
  int configCalls = 0;

  @override
  Future<Response> getPublicConfig() async {
    configCalls++;
    if (configThrows) {
      throw DioException(
        requestOptions: RequestOptions(path: '/api/config'),
        message: 'offline',
      );
    }
    return Response(
      requestOptions: RequestOptions(path: '/api/config'),
      statusCode: 200,
      data: config ?? {'status': true, 'data': <String, dynamic>{}},
    );
  }

  @override
  Future<Response> getCommunities() async => Response(
    requestOptions: RequestOptions(path: '/api/catalog/communities'),
    statusCode: 200,
    data: {'status': true, 'data': const []},
  );

  @override
  Future<Response> getContent(
    String type, {
    String role = 'guest',
    String? projectId,
  }) async => Response(
    requestOptions: RequestOptions(path: '/api/content'),
    statusCode: 200,
    data: {'status': true, 'data': const []},
  );
}

Map<String, dynamic> configWith(List<dynamic> images) => {
  'status': true,
  'data': {'heroSliderImages': images},
};

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('parseHeroSlides', () {
    String resolve(String? url) =>
        (url == null || url.isEmpty || url.startsWith('http'))
        ? (url ?? '')
        : 'http://api.example.com$url';

    test('resolves relative upload paths and keeps the admin label', () {
      final slides = parseHeroSlides(
        configWith([
          {'url': '/uploads/12345.jpg', 'label': 'Flagship Residential'},
          {'url': '/uploads/67890.jpg', 'label': 'Modern Living'},
        ]),
        resolve,
      );

      expect(slides, hasLength(2));
      expect(slides[0].url, 'http://api.example.com/uploads/12345.jpg');
      expect(slides[0].label, 'Flagship Residential');
      expect(slides[1].url, 'http://api.example.com/uploads/67890.jpg');
    });

    test('leaves absolute urls alone', () {
      final slides = parseHeroSlides(
        configWith([
          {'url': 'https://cdn.example.com/a.jpg'},
        ]),
        resolve,
      );
      expect(slides.single.url, 'https://cdn.example.com/a.jpg');
      expect(slides.single.label, '');
    });

    test('drops entries without a url instead of rendering a broken tile', () {
      final slides = parseHeroSlides(
        configWith([
          {'label': 'No image yet'},
          {'url': ''},
          {'url': '/uploads/ok.jpg'},
        ]),
        resolve,
      );
      expect(slides, hasLength(1));
      expect(slides.single.url, 'http://api.example.com/uploads/ok.jpg');
    });

    test('survives the round trip through the guest disk cache', () {
      // What _saveDiskCache writes and _loadDiskCache reads back. The cold
      // start path itself runs jsonDecode through compute(), whose isolate the
      // test binding does not drive, so the contract is checked here instead.
      final slides = parseHeroSlides(
        configWith([
          {'url': '/uploads/12345.jpg', 'label': 'Flagship Residential'},
        ]),
        resolve,
      );
      final encoded = jsonEncode([for (final s in slides) s.toJson()]);
      final restored = [
        for (final s in jsonDecode(encoded) as List) HeroSlide.fromCache(s),
      ];

      expect(restored.single.url, slides.single.url);
      expect(restored.single.label, 'Flagship Residential');
    });

    test('returns empty for a missing, empty or malformed field', () {
      expect(parseHeroSlides(configWith(const []), resolve), isEmpty);
      expect(parseHeroSlides({'status': true, 'data': {}}, resolve), isEmpty);
      expect(
        parseHeroSlides({
          'status': true,
          'data': {'heroSliderImages': 'nope'},
        }, resolve),
        isEmpty,
      );
      expect(parseHeroSlides(null, resolve), isEmpty);
    });
  });

  group('heroSliderProvider', () {
    test('reads GET /api/config', () async {
      final api = _FakeApiClient(
        config: configWith([
          {'url': '/uploads/12345.jpg', 'label': 'Flagship Residential'},
        ]),
      );
      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(api)],
      );
      addTearDown(container.dispose);

      final slides = await container.read(heroSliderProvider.future);
      expect(api.configCalls, 1);
      expect(slides.single.url, 'http://api.example.com/uploads/12345.jpg');
    });

    test(
      'an unreachable config leaves the dashboards on their fallback',
      () async {
        final container = ProviderContainer(
          overrides: [
            apiClientProvider.overrideWithValue(
              _FakeApiClient(configThrows: true),
            ),
          ],
        );
        addTearDown(container.dispose);

        expect(await container.read(heroSliderProvider.future), isEmpty);
      },
    );
  });

  group('guest home hero', () {
    Future<void> pump(WidgetTester tester, _FakeApiClient api) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(411, 1400);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(api),
            projectsProvider.overrideWith((ref) async => const <dynamic>[]),
            guestHomeCacheProvider.overrideWith(
              (ref) =>
                  const GuestHomeData(projects: [], communities: [], media: []),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: GuestDashboardScreen()),
          ),
        ),
      );
      // Not pumpAndSettle: the page carries entrance animations and a repeating
      // hero timer that would keep the scheduler busy forever.
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }
    }

    /// The urls the page actually handed to its network images.
    List<String> heroUrls(WidgetTester tester) => tester
        .widgetList<CachedNetworkImage>(find.byType(CachedNetworkImage))
        .map((w) => w.imageUrl)
        .where((url) => url.isNotEmpty)
        .toList();

    testWidgets('shows the admin slides when the config has them', (
      tester,
    ) async {
      await pump(
        tester,
        _FakeApiClient(
          config: configWith([
            {'url': '/uploads/12345.jpg', 'label': 'Flagship Residential'},
            {'url': '/uploads/67890.jpg', 'label': 'Modern Living'},
          ]),
        ),
      );

      expect(
        heroUrls(tester),
        contains('http://api.example.com/uploads/12345.jpg'),
        reason: 'the hero should render the admin slide, not a fallback',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('falls back to the bundled slides on an empty config', (
      tester,
    ) async {
      await pump(tester, _FakeApiClient(config: configWith(const [])));

      expect(
        heroUrls(tester).where((u) => u.contains('/uploads/')),
        isEmpty,
        reason: 'no admin slides were configured',
      );
      // The bundled artistic-impression slide is what the fallback leads with.
      expect(find.byType(Image), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
