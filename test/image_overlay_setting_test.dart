import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/providers/image_overlay_provider.dart';
import 'package:m4_mobile/presentation/providers/project_provider.dart';
import 'package:m4_mobile/presentation/screens/home/guest_dashboard_screen.dart'
    show GuestDashboardScreen, guestHomeCacheProvider, GuestHomeData;
import 'package:m4_mobile/presentation/widgets/image_overlay_label.dart';

/// Issue 11: the "Artistic Impression" label must follow the Admin Panel's
/// Settings > Image Overlay (`GET /api/config` -> `data.overlayEnabled` /
/// `data.overlayText`) instead of always being drawn on project images.
class _FakeApiClient extends ApiClient {
  _FakeApiClient({this.config, this.configThrows = false})
    : super(baseUrl: 'http://api.example.com');

  Map<String, dynamic>? config;
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

Map<String, dynamic> overlayConfig(
  Object? enabled, {
  String? text = 'Artistic Impression',
  List<dynamic> slides = const [],
}) => {
  'status': true,
  'data': {
    'heroSliderImages': slides,
    if (enabled != null) 'overlayEnabled': enabled,
    if (text != null) 'overlayText': text,
  },
};

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('parseImageOverlay', () {
    test('ON: enabled with the configured text', () {
      final overlay = parseImageOverlay(overlayConfig(true));
      expect(overlay.enabled, isTrue);
      expect(overlay.text, 'Artistic Impression');
      expect(overlay.label, 'ARTISTIC IMPRESSION');
    });

    test('OFF: disabled when the admin switched it off', () {
      expect(parseImageOverlay(overlayConfig(false)).enabled, isFalse);
    });

    test('only an explicit true turns it on', () {
      expect(parseImageOverlay(overlayConfig(null)).enabled, isFalse);
      expect(parseImageOverlay(overlayConfig('false')).enabled, isFalse);
      expect(parseImageOverlay(overlayConfig(1)).enabled, isFalse);
      expect(parseImageOverlay(overlayConfig('yes')).enabled, isFalse);
      expect(parseImageOverlay(overlayConfig('true')).enabled, isTrue);
      expect(parseImageOverlay({'status': true}).enabled, isFalse);
      expect(parseImageOverlay(null).enabled, isFalse);
    });

    test('uses the admin text, defaulting a blank one', () {
      expect(
        parseImageOverlay(overlayConfig(true, text: 'Render Only')).label,
        'RENDER ONLY',
      );
      expect(
        parseImageOverlay(overlayConfig(true, text: '  ')).text,
        kDefaultImageOverlayText,
      );
      expect(
        parseImageOverlay(overlayConfig(true, text: null)).text,
        kDefaultImageOverlayText,
      );
    });
  });

  group('imageOverlayProvider', () {
    test('reads the saved setting from GET /api/config', () async {
      final api = _FakeApiClient(config: overlayConfig(true));
      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(api)],
      );
      addTearDown(container.dispose);

      final overlay = await container.read(imageOverlayProvider.future);
      expect(api.configCalls, 1);
      expect(overlay.enabled, isTrue);
    });

    test('an unreachable config leaves the label off', () async {
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(
            _FakeApiClient(configThrows: true),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(
        (await container.read(imageOverlayProvider.future)).enabled,
        isFalse,
      );
    });
  });

  group('ImageOverlayLabel', () {
    Future<void> pump(WidgetTester tester, _FakeApiClient api) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [apiClientProvider.overrideWithValue(api)],
          child: MaterialApp(
            home: Stack(
              children: [
                Positioned(
                  top: 16,
                  right: 16,
                  child: ImageOverlayLabel(builder: (label) => Text(label)),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('setting ON shows the label', (tester) async {
      await pump(tester, _FakeApiClient(config: overlayConfig(true)));
      expect(find.text('ARTISTIC IMPRESSION'), findsOneWidget);
    });

    testWidgets('setting OFF shows no label at all', (tester) async {
      await pump(tester, _FakeApiClient(config: overlayConfig(false)));
      expect(find.text('ARTISTIC IMPRESSION'), findsNothing);
      expect(find.textContaining('IMPRESSION'), findsNothing);
    });

    testWidgets('nothing is drawn before the setting is known', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            imageOverlayProvider.overrideWith(
              (ref) => Completer<ImageOverlaySetting>().future,
            ),
          ],
          child: MaterialApp(
            home: ImageOverlayLabel(builder: (label) => Text(label)),
          ),
        ),
      );
      expect(find.text('ARTISTIC IMPRESSION'), findsNothing);
    });

    testWidgets('an admin change shows once the config is re-read', (
      tester,
    ) async {
      final api = _FakeApiClient(config: overlayConfig(false));
      await pump(tester, api);
      expect(find.text('ARTISTIC IMPRESSION'), findsNothing);

      // What LiveSyncScope does when /api/config changes.
      api.config = overlayConfig(true);
      ProviderScope.containerOf(
        tester.element(find.byType(Stack)),
      ).invalidate(imageOverlayProvider);
      for (var i = 0; i < 3; i++) {
        await tester.pump();
      }
      expect(find.text('ARTISTIC IMPRESSION'), findsOneWidget);

      api.config = overlayConfig(false);
      ProviderScope.containerOf(
        tester.element(find.byType(Stack)),
      ).invalidate(imageOverlayProvider);
      for (var i = 0; i < 3; i++) {
        await tester.pump();
      }
      expect(find.text('ARTISTIC IMPRESSION'), findsNothing);
    });
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

    const slides = [
      {'url': '/uploads/12345.jpg', 'label': 'Flagship Residential'},
    ];

    testWidgets('setting ON: the hero carries the label', (tester) async {
      await pump(
        tester,
        _FakeApiClient(config: overlayConfig(true, slides: slides)),
      );
      expect(find.text('ARTISTIC IMPRESSION'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('setting OFF: no label anywhere on the page', (tester) async {
      await pump(
        tester,
        _FakeApiClient(config: overlayConfig(false, slides: slides)),
      );
      expect(find.textContaining('IMPRESSION'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
