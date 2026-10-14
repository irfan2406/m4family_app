import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/core/utils/media_url.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/screens/about/about_screen.dart';
import 'package:m4_mobile/presentation/widgets/guest_main_shell.dart';

/// About M4 (testing point 8): GET /api/cms/about-us, fresh on every open.
/// `media` = [main banner, living room, kitchen], each an uploaded path
/// (loaded from the media bucket), "removed" (hidden) or empty (the app's
/// default picture). `pillars[].icon` is an icon name or an uploaded picture.
const _bucket = 'https://pub-5a1384bd1cd04b29bc2523807d384a92.r2.dev/m4/';

class _FakeApi extends ApiClient {
  _FakeApi(this.page) : super(baseUrl: 'http://api.example.com');

  Map<String, dynamic> page;
  int calls = 0;

  @override
  Future<Response> getCmsPage(String slug, {String portal = 'guest'}) async {
    calls++;
    return Response(
      requestOptions: RequestOptions(path: '/api/cms/$slug'),
      statusCode: 200,
      data: {'status': true, 'data': page},
    );
  }
}

Map<String, dynamic> _page(List<dynamic> media, {List<dynamic>? pillars}) => {
  'title': 'About M4',
  'media': media,
  'pillars':
      pillars ??
      [
        {'title': 'TRANSPARENCY', 'desc': 'd', 'icon': 'ShieldCheck'},
        {'title': 'TIMELY DELIVERY', 'desc': 'd', 'icon': 'Eye'},
        {'title': 'TOUCH', 'desc': 'd', 'icon': 'Milestone'},
        {'title': 'TRUST', 'desc': 'd', 'icon': 'Heart'},
      ],
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

  test('uploads load straight from the media bucket', () {
    expect(
      directUploadUrl('/uploads/media/med-1.jpg'),
      '${_bucket}med-1.jpg',
    );
    expect(directUploadUrl('/uploads/other/x.jpg'), isEmpty);
    expect(directUploadUrl('removed'), isEmpty);
    expect(directUploadUrl(''), isEmpty);
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  Future<void> pump(
    WidgetTester tester,
    _FakeApi api, {
    bool embedded = true,
  }) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(411, 3000);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(api)],
        child: MaterialApp(home: AboutScreen(embedded: embedded)),
      ),
    );
    await settle(tester);
  }

  Future<void> openStep(WidgetTester tester, String label) async {
    await tester.tap(find.text(label).first);
    await settle(tester);
  }

  List<String> networkUrls(WidgetTester tester) => tester
      .widgetList<CachedNetworkImage>(find.byType(CachedNetworkImage))
      .map((w) => w.imageUrl)
      .toList();

  bool hasAsset(WidgetTester tester, String name) => tester
      .widgetList<Image>(find.byType(Image))
      .any((w) => w.image is AssetImage && (w.image as AssetImage).assetName == name);

  group('main banner (media[0])', () {
    testWidgets('an upload is shown, from the media bucket', (tester) async {
      await pump(tester, _FakeApi(_page(['/uploads/media/banner.jpg'])));
      expect(networkUrls(tester), contains('${_bucket}banner.jpg'));
      expect(find.text('OUR STORY'), findsOneWidget);
    });

    testWidgets('"removed" hides it', (tester) async {
      await pump(tester, _FakeApi(_page(['removed'])));
      expect(networkUrls(tester), isEmpty);
      expect(find.text('M4'), findsNothing, reason: 'no banner, no panel');
      expect(find.text('OUR STORY'), findsOneWidget);
    });

    testWidgets('empty shows the app default', (tester) async {
      await pump(tester, _FakeApi(_page([''])));
      expect(networkUrls(tester), isEmpty);
      expect(find.text('M4'), findsOneWidget, reason: 'the branded panel');
    });
  });

  group('living room (media[1]) and kitchen (media[2])', () {
    testWidgets('both uploads shown side by side', (tester) async {
      await pump(
        tester,
        _FakeApi(_page(['', '/uploads/media/living.jpg', '/uploads/media/kitchen.jpg'])),
      );
      await openStep(tester, 'CUSTOM VIEWS');
      final urls = networkUrls(tester);
      expect(urls, contains('${_bucket}living.jpg'));
      expect(urls, contains('${_bucket}kitchen.jpg'));
      final living = tester.getRect(
        find.byWidgetPredicate(
          (w) => w is CachedNetworkImage && w.imageUrl == '${_bucket}living.jpg',
        ),
      );
      final kitchen = tester.getRect(
        find.byWidgetPredicate(
          (w) => w is CachedNetworkImage && w.imageUrl == '${_bucket}kitchen.jpg',
        ),
      );
      expect(living.top, kitchen.top);
      expect(living.right, lessThan(kitchen.left));
    });

    testWidgets('empty: the defaults; "removed": hidden', (tester) async {
      // The live record: living room uploaded, kitchen removed.
      await pump(
        tester,
        _FakeApi(_page(['', '', 'removed'])),
      );
      await openStep(tester, 'CUSTOM VIEWS');
      expect(networkUrls(tester), isEmpty);
      expect(hasAsset(tester, 'assets/custom_view_1.png'), isTrue);
      // The kitchen was removed, so only the living room's default shows.
      expect(find.text('M4'), findsNothing);
    });

    testWidgets('an empty kitchen shows the branded default', (tester) async {
      await pump(tester, _FakeApi(_page(['', 'removed', ''])));
      await openStep(tester, 'CUSTOM VIEWS');
      expect(hasAsset(tester, 'assets/custom_view_1.png'), isFalse);
      expect(find.text('M4'), findsOneWidget);
    });

    testWidgets('both removed: no pictures at all', (tester) async {
      await pump(tester, _FakeApi(_page(['', 'removed', 'removed'])));
      await openStep(tester, 'CUSTOM VIEWS');
      expect(networkUrls(tester), isEmpty);
      expect(hasAsset(tester, 'assets/custom_view_1.png'), isFalse);
      expect(find.text('M4'), findsNothing);
    });
  });

  group('pillar icons', () {
    testWidgets('names map to icons', (tester) async {
      await pump(tester, _FakeApi(_page([''])));
      await openStep(tester, '4 PILLARS');
      expect(find.byIcon(LucideIcons.heart), findsOneWidget);
      expect(find.byIcon(LucideIcons.milestone), findsWidgets);
    });

    testWidgets('an uploaded picture, removed and empty', (tester) async {
      await pump(
        tester,
        _FakeApi(
          _page(
            [''],
            pillars: [
              {'title': 'A', 'desc': 'd', 'icon': '/uploads/media/i.png'},
              {'title': 'B', 'desc': 'd', 'icon': 'removed'},
              {'title': 'C', 'desc': 'd', 'icon': ''},
              {'title': 'D', 'desc': 'd', 'icon': 'Heart'},
            ],
          ),
        ),
      );
      await openStep(tester, '4 PILLARS');
      expect(networkUrls(tester), contains('${_bucket}i.png'));
      // C is empty -> its default (the 3rd pillar's milestone icon).
      final tiles = tester
          .widgetList<Icon>(find.byType(Icon))
          .map((i) => i.icon)
          .toList();
      expect(tiles, contains(LucideIcons.heart));
      expect(
        find.byIcon(LucideIcons.helpCircle),
        findsNothing,
        reason: 'no unknown-icon "?" for a path or a blank',
      );
    });
  });

  group('fresh on every open', () {
    testWidgets('the guest About tab re-reads when opened again', (
      tester,
    ) async {
      final api = _FakeApi(_page(['/uploads/media/old.jpg']));
      await pump(tester, api);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(AboutScreen)),
      );
      container.read(guestNavigationProvider.notifier).state = 2;
      await settle(tester);
      container.read(guestNavigationProvider.notifier).state = 0;
      await settle(tester);
      final calls = api.calls;

      api.page = _page(['/uploads/media/new.jpg']);
      container.read(guestNavigationProvider.notifier).state = 2;
      await settle(tester);

      expect(api.calls, calls + 1);
      expect(networkUrls(tester), contains('${_bucket}new.jpg'));
    });

    testWidgets('opened from a menu: loads on open', (tester) async {
      final api = _FakeApi(_page(['/uploads/media/a.jpg']));
      await pump(tester, api, embedded: false);
      expect(api.calls, 1);
    });
  });
}
