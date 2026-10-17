import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/providers/project_provider.dart';
import 'package:m4_mobile/presentation/screens/cp/cp_home_screen.dart';
import 'package:m4_mobile/presentation/screens/home/dashboard_screen.dart';
import 'package:m4_mobile/presentation/screens/home/guest_dashboard_screen.dart'
    show GuestDashboardScreen, guestHomeCacheProvider, GuestHomeData;
import 'package:m4_mobile/presentation/screens/investor/investor_home_screen.dart';
import 'package:m4_mobile/presentation/widgets/home_image_card.dart';

/// Home > COMMUNITIES / PROPERTIES / MEDIA, every portal: one card design.
/// The picture is clean — no badge, name, status or arrow drawn on it — and a
/// separate panel beneath it carries the name (plus locality and status on
/// Properties) and the round arrow.
// PNG pictures on purpose: the image helpers show a PNG whole (as if it were a
// logo), which letterboxed the Mazgaon photo inside the card's frame.
const _community = {
  '_id': 'c1',
  'title': 'Mazgaon',
  'image': '/uploads/media/mazgaon.png',
};
const _project = {
  '_id': 'p1',
  'title': 'Clédor',
  'status': 'Ongoing',
  'location': {'name': 'Mazgaon'},
  'heroImage': '/uploads/media/cledor.png',
};
const _media = {
  '_id': 'm1',
  'title': 'Site Walkthrough',
  // The homes skip media without a picture.
  'thumbnail': '/uploads/media/walkthrough.png',
};

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(baseUrl: 'http://api.example.com');

  Response _ok(String path, Object? data) => Response(
    requestOptions: RequestOptions(path: path),
    statusCode: 200,
    data: {'status': true, 'data': data},
  );

  @override
  Future<Response> getCommunities() async =>
      _ok('/api/catalog/communities', const [_community]);

  @override
  Future<Response> getPublicConfig() async =>
      _ok('/api/config', <String, dynamic>{});

  @override
  Future<Response> getContent(
    String type, {
    String role = 'guest',
    String? projectId,
  }) async => _ok('/api/content', type == 'media' ? const [_media] : const []);
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  final portals = <String, Widget Function()>{
    'guest': () => const GuestDashboardScreen(),
    'customer': () => const DashboardScreen(),
    'cp': () => const CpHomeScreen(),
    'investor': () => const InvestorHomeScreen(),
  };
  // Tab label -> the name its first card carries.
  const tabs = {
    'COMMUNITIES': 'Mazgaon',
    'PROPERTIES': 'Clédor',
    'MEDIA': 'Site Walkthrough',
  };

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  for (final portal in portals.entries) {
    for (final tab in tabs.entries) {
      testWidgets('${portal.key} ${tab.key}: clean picture, panel beneath', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(411, 2400);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              apiClientProvider.overrideWithValue(_FakeApiClient()),
              projectsProvider.overrideWith((ref) async => const [_project]),
              guestHomeCacheProvider.overrideWith(
                (ref) => const GuestHomeData(
                  projects: [_project],
                  communities: [_community],
                  media: [_media],
                ),
              ),
            ],
            child: MaterialApp(home: Scaffold(body: portal.value())),
          ),
        );
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        await settle(tester);
        if (tab.key != 'COMMUNITIES') {
          // The tab row scrolls sideways; bring the tab into view first.
          await tester.ensureVisible(find.text(tab.key).first);
          await settle(tester);
          await tester.tap(find.text(tab.key).first);
          await settle(tester);
        }

        final card = find.byType(HomeImageCard).first;
        final cardRect = tester.getRect(card);

        // The whole photo is shown — never cropped — over a blurred copy that
        // fills the frame, so there are no empty strips either (PNG included).
        final fits = tester
            .widgetList<CachedNetworkImage>(
              find.descendant(of: card, matching: find.byType(CachedNetworkImage)),
            )
            .map((p) => p.fit)
            .toList();
        expect(fits, contains(BoxFit.contain), reason: 'the whole photo');
        expect(fits, contains(BoxFit.cover), reason: 'the filling backdrop');
        expect(
          find.descendant(of: card, matching: find.byType(ImageFiltered)),
          findsOneWidget,
          reason: 'the backdrop is blurred',
        );
        expect(cardRect.height, closeTo(HomeImageCard.rowHeight, 0.01));

        // Every word on the card sits below the picture, in the panel.
        final pictureBottom = cardRect.top + HomeImageCard.imageHeight;
        final texts = find.descendant(of: card, matching: find.byType(Text));
        expect(texts, findsWidgets);
        for (final t in texts.evaluate()) {
          expect(
            tester.getRect(find.byWidget(t.widget)).top,
            greaterThanOrEqualTo(pictureBottom),
            reason: '"${(t.widget as Text).data}" is drawn on the picture',
          );
        }
        expect(
          find.descendant(of: card, matching: find.text(tab.value)),
          findsOneWidget,
        );
        final arrow = find.descendant(
          of: card,
          matching: find.byIcon(LucideIcons.arrowRight),
        );
        expect(tester.getRect(arrow).top, greaterThanOrEqualTo(pictureBottom));

        if (tab.key == 'PROPERTIES') {
          // Locality and status move into the panel.
          expect(
            find.descendant(of: card, matching: find.text('MAZGAON')),
            findsOneWidget,
          );
          expect(
            find.descendant(of: card, matching: find.text('ONGOING')),
            findsOneWidget,
          );
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
}
