import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/providers/project_provider.dart';
import 'package:m4_mobile/presentation/screens/home/dashboard_screen.dart';

/// The Customer portal's COMMUNITIES card used to pin two titles to Unsplash
/// stock photos, so Mazgaon showed a villa while the web showed the Mazagon
/// Dock skyline the Admin Panel had published for it. The card has to render
/// the community's own `image`, like every other portal and like the web.
class _FakeApiClient extends ApiClient {
  _FakeApiClient(this.communities) : super(baseUrl: 'http://api.example.com');

  final List<dynamic> communities;

  @override
  Future<Response> getCommunities() async => Response(
    requestOptions: RequestOptions(path: '/api/catalog/communities'),
    statusCode: 200,
    data: {'status': true, 'data': communities},
  );

  @override
  Future<Response> getPublicConfig() async => Response(
    requestOptions: RequestOptions(path: '/api/config'),
    statusCode: 200,
    data: {'status': true, 'data': <String, dynamic>{}},
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

/// The shape the live catalog returns: one community, one relative image path.
const _mazgaon = {
  '_id': 'c1',
  'title': 'Mazgaon',
  'overview': 'A community in the making',
  'image': '/uploads/media/med-1789549981827-392922099.jpg',
};

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<List<String>> pumpAndCollectUrls(
    WidgetTester tester,
    List<dynamic> communities,
  ) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(411, 1600);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(_FakeApiClient(communities)),
          projectsProvider.overrideWith((ref) async => const <dynamic>[]),
        ],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );
    // Not pumpAndSettle: the page carries entrance animations and repeating
    // timers that would keep the scheduler busy forever.
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }

    return tester
        .widgetList<CachedNetworkImage>(find.byType(CachedNetworkImage))
        .map((w) => w.imageUrl)
        .toList();
  }

  testWidgets('Mazgaon renders the image the backend published', (
    tester,
  ) async {
    final urls = await pumpAndCollectUrls(tester, const [_mazgaon]);

    expect(
      urls,
      contains(
        'http://api.example.com/uploads/media/med-1789549981827-392922099.jpg',
      ),
      reason: 'the card must show the community image, not a stock photo',
    );
    expect(
      urls.where((u) => u.contains('photo-1512917774080')),
      isEmpty,
      reason: 'the old hardcoded Mazgaon stock photo must be gone',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a community with no image still falls back to stock', (
    tester,
  ) async {
    final urls = await pumpAndCollectUrls(tester, const [
      {'_id': 'c2', 'title': 'Mazgaon', 'overview': 'No artwork yet'},
    ]);

    expect(
      urls.where((u) => u.contains('/uploads/')),
      isEmpty,
      reason: 'there is no backend image to show',
    );
    expect(
      urls.where((u) => u.contains('images.unsplash.com')),
      isNotEmpty,
      reason: 'the card still needs something to draw',
    );
    expect(tester.takeException(), isNull);
  });
}
