import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/screens/communities/community_projects_screen.dart';

/// Community > "Discover all projects in this community": each project card is
/// a YouTube-style 16:9 thumbnail. The 16:9 frame used to wrap the card's 16dp
/// bottom margin as well, so the visible card came out 16dp short of the ratio
/// (about 1.95:1 on a phone). This measures the card the user actually sees.
class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(baseUrl: 'http://api.example.com');

  @override
  Future<Response> getCommunityBySlug(String slug) async => Response(
    requestOptions: RequestOptions(path: '/api/catalog/communities/$slug'),
    statusCode: 200,
    data: {
      'status': true,
      'data': {'_id': 'c1', 'title': 'Mazgaon', 'slug': slug},
    },
  );

  @override
  Future<Response> getProjectsByCommunity(String communityId) async => Response(
    requestOptions: RequestOptions(path: '/api/catalog/projects'),
    statusCode: 200,
    data: {
      'status': true,
      // The three projects in the screenshot, with a starting price on the
      // first so the tallest text block is covered.
      'data': [
        {
          '_id': 'p1',
          'title': 'SKAI',
          'status': 'Upcoming',
          'location': {'name': 'Mazgaon'},
          'startingPrice': '₹ 4.5 Cr',
          'heroImage': '/uploads/skai.jpg',
        },
        {
          '_id': 'p2',
          'title': 'Ocean View',
          'status': 'Completed',
          'location': {'name': 'Mazgaon'},
          'heroImage': '/uploads/ocean.jpg',
        },
        {
          '_id': 'p3',
          'title': 'Clédor',
          'status': 'Ongoing',
          'location': {'name': 'Mazgaon'},
          'heroImage': '/uploads/cledor.jpg',
        },
      ],
    },
  );
}

const _screen =
    'lib/presentation/screens/communities/community_projects_screen.dart';

/// Source line span of a top-level class in [_screen], so errors can be pinned
/// to the widget that raised them via their creation location.
({int start, int end}) _classSpan(String name) {
  final lines = File(_screen).readAsLinesSync();
  final start = lines.indexWhere((l) => l.startsWith('class $name ')) + 1;
  final next = lines.indexWhere((l) => l.startsWith('class '), start);
  return (start: start, end: next == -1 ? lines.length : next);
}

/// The [_screen] lines an error's creation locations point at.
Set<int> _errorLines(FlutterErrorDetails e) => RegExp(
  r'community_projects_screen\.dart:(\d+)',
).allMatches(e.toString()).map((m) => int.parse(m.group(1)!)).toSet();

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  // 320dp is the narrowest handset the app supports, 411dp a common large one.
  for (final dp in <double>[320, 360, 411]) {
    testWidgets('${dp.toInt()}dp: every project card is exactly 16:9', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = Size(dp, 2400);
      addTearDown(tester.view.reset);

      // The page's pinned header declares a 76dp extent but its content is
      // shorter, an invalid sliver geometry: with assertions on, the viewport
      // rejects it and never lays the list out. That is a header problem,
      // outside the card. A 1.3 text scale makes the header content fill its
      // 76dp so the list lays out here. It does not bear on what is measured —
      // the card's size comes from its width alone, through the 16:9 frame.
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final errors = <FlutterErrorDetails>[];
      final previousOnError = FlutterError.onError;
      FlutterError.onError = errors.add;
      final cards = <String, Rect>{};
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [apiClientProvider.overrideWithValue(_FakeApiClient())],
            child: const MaterialApp(
              home: CommunityProjectsListScreen(slug: 'mazgaon'),
            ),
          ),
        );
        // Not pumpAndSettle: the cards fade in on a staggered animation.
        for (var i = 0; i < 8; i++) {
          await tester.pump(const Duration(milliseconds: 300));
        }

        for (final title in ['SKAI', 'OCEAN VIEW', 'CLÉDOR']) {
          final text = find.text(title);
          expect(text, findsOneWidget, reason: '$title card did not render');
          // The card's layer stack fills the rounded, clipped card exactly, so
          // its size is the thumbnail the user sees (the gap excluded).
          cards[title] = tester.getRect(
            find.ancestor(of: text, matching: find.byType(Stack)).first,
          );
        }
      } finally {
        FlutterError.onError = previousOnError;
      }

      for (final MapEntry(key: title, value: card) in cards.entries) {
        expect(
          card.width / card.height,
          closeTo(16 / 9, 0.01),
          reason:
              '$title @ ${dp.toInt()}dp is '
              '${card.width.toStringAsFixed(1)}x'
              '${card.height.toStringAsFixed(1)}, not 16:9',
        );
      }

      // The only errors allowed are the header's, which the text scale above
      // provokes. Nothing may come from the card.
      final header = _classSpan('_GlassHeaderDelegate');
      final card = _classSpan('_ProjectCard');
      for (final e in errors) {
        final lines = _errorLines(e);
        expect(
          lines.any((l) => l >= card.start && l < card.end),
          isFalse,
          reason: 'the project card raised: ${e.exceptionAsString()}',
        );
        expect(
          lines.isNotEmpty &&
              lines.every((l) => l >= header.start && l < header.end),
          isTrue,
          reason:
              'unexpected error outside the header: ${e.exceptionAsString()}',
        );
      }
    });
  }
}
