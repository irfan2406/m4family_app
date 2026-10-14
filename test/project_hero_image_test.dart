import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/core/utils/media_url.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/screens/projects/guest_project_detail_screen.dart';
import 'package:m4_mobile/presentation/screens/projects/project_detail_screen.dart';

import 'goldens/golden_harness.dart' show setUpGoldenHarness;

/// Project cards and banners show `heroImage`, the Project Master Image the
/// admin picks (backend). The old `bannerImage` / `coverImage` / `thumbnail` /
/// `heroImages` fields were demo stock photos and have been removed from all
/// projects, so the app must not read them even if an old record still has
/// them.
const _master = '/uploads/media/master.jpg';

const _project = {
  '_id': 'p1',
  'title': 'Clédor',
  'location': {'name': 'Mazgaon'},
  'heroImage': _master,
  // Old demo fields, as a stale cached record might still carry them.
  'bannerImage': '/uploads/media/old-banner.jpg',
  'coverImage': '/uploads/media/old-cover.jpg',
  'thumbnail': '/uploads/media/old-thumb.jpg',
  'heroImages': ['/uploads/media/old-hero-1.jpg'],
};

class _Api extends ApiClient {
  _Api() : super(baseUrl: 'http://api.example.com');
  Response _ok(String p, Object? d) => Response(
    requestOptions: RequestOptions(path: p),
    statusCode: 200,
    data: {'status': true, 'data': d},
  );
  @override
  Future<Response> getProjectDetails(String id) async => _ok('/d', _project);
  @override
  Future<Response> getProjectUpdates(String id) async => _ok('/u', const []);
  @override
  Future<Response> getProjectInventory(String id) async => _ok('/i', const []);
  @override
  Future<Response> getProjectProgress(String id) async => _ok('/p', const []);
}

void main() {
  group('projectHeroUrl', () {
    test('uses the Project Master Image', () {
      expect(projectHeroUrl(_project), _master);
    });

    test('never falls back to the removed demo fields', () {
      expect(
        projectHeroUrl({
          'bannerImage': '/uploads/media/b.jpg',
          'coverImage': '/uploads/media/c.jpg',
          'thumbnail': '/uploads/media/t.jpg',
          'heroImages': ['/uploads/media/h.jpg'],
        }),
        isEmpty,
        reason: 'no master image -> the branded placeholder, not demo stock',
      );
    });

    test('a project with no master image falls back to its own gallery', () {
      expect(
        projectHeroUrl({
          'heroImage': '',
          'coverImage': '/uploads/media/c.jpg',
          'exteriorImages': ['/uploads/media/ext.jpg'],
        }),
        '/uploads/media/ext.jpg',
      );
    });

    test('stock photography is still refused', () {
      expect(
        projectHeroUrl({'heroImage': 'https://images.unsplash.com/photo-1'}),
        isEmpty,
      );
    });
  });

  group('project banner', () {
    setUpAll(setUpGoldenHarness);

    final screens = <String, Widget>{
      'guest detail': const GuestProjectDetailScreen(
        projectId: 'p1',
        projectData: _project,
      ),
      'detail': const ProjectDetailScreen(projectId: 'p1', projectData: _project),
    };

    for (final e in screens.entries) {
      testWidgets('${e.key} shows the master image, none of the old ones', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(411, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [apiClientProvider.overrideWithValue(_Api())],
            child: MaterialApp(home: e.value),
          ),
        );
        for (var i = 0; i < 4; i++) {
          await tester.pump(const Duration(milliseconds: 300));
        }

        final urls = tester
            .widgetList<CachedNetworkImage>(find.byType(CachedNetworkImage))
            .map((w) => w.imageUrl)
            .toList();
        expect(urls, contains('http://api.example.com$_master'));
        expect(
          urls.where((u) => u.contains('/old-')),
          isEmpty,
          reason: 'the removed demo fields must not be shown',
        );
      });
    }
  });
}
