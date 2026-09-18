import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/providers/project_provider.dart';
import 'package:m4_mobile/presentation/screens/cp/cp_home_screen.dart';
import 'package:m4_mobile/presentation/screens/home/dashboard_screen.dart';
import 'package:m4_mobile/presentation/screens/home/guest_dashboard_screen.dart'
    show GuestDashboardScreen, guestHomeCacheProvider, GuestHomeData;
import 'package:m4_mobile/presentation/screens/investor/investor_home_screen.dart';

/// The home Communities and Media cards are one design, and the Guest home is
/// its reference: the Investor, CP and Customer homes must draw exactly the
/// same card. Each card is reduced to a fingerprint of everything the user can
/// see — size, corners, shadow, scrim, every text's style and where it sits,
/// the arrow — and every portal's fingerprint must equal the Guest one.
///
/// The words themselves are left out on purpose: each portal fills its Media
/// row from its own source (the Investor home uses fixed placeholders), and the
/// cards being the same is about how they are drawn, not what they say.
class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(baseUrl: 'http://api.example.com');

  @override
  Future<Response> getCommunities() async => Response(
    requestOptions: RequestOptions(path: '/api/catalog/communities'),
    statusCode: 200,
    data: {'status': true, 'data': _communities},
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

const _communities = [
  {
    '_id': 'c1',
    'title': 'Mazgaon',
    'overview': 'A community in the making, rising above the harbour',
    'image': '/uploads/c1.jpg',
  },
  {
    '_id': 'c2',
    'title': 'Worli',
    'overview': 'Sea-facing towers on the western edge of the city',
    'image': '/uploads/c2.jpg',
  },
];

const _projects = [
  {
    '_id': 'p1',
    'title': 'Skai',
    'status': 'Upcoming',
    'location': {'name': 'Mazgaon'},
    'heroImage': '/uploads/p1.jpg',
  },
  {
    '_id': 'p2',
    'title': 'Cledor',
    'status': 'Ongoing',
    'location': {'name': 'Mazgaon'},
    'heroImage': '/uploads/p2.jpg',
  },
];

String _c(Color? c) =>
    c == null ? '-' : '#${c.toARGB32().toRadixString(16).padLeft(8, '0')}';

String _style(TextStyle? s) =>
    '${s?.fontFamily} ${s?.fontSize} ${s?.fontWeight} ${_c(s?.color)} '
    'ls=${s?.letterSpacing} h=${s?.height}';

/// Everything about one card a user can see, as sorted lines.
List<String> fingerprint(WidgetTester tester, Finder clip) {
  final lines = <String>[];
  final card = tester.getRect(clip);
  lines.add(
    'card ${card.width.toStringAsFixed(1)}x${card.height.toStringAsFixed(1)}',
  );

  final clipWidget = tester.widget<ClipRRect>(clip);
  lines.add('clip radius ${clipWidget.borderRadius}');

  // The decorated box that carries the corners, shadow and margin.
  final box = tester.widget<Container>(
    find.ancestor(of: clip, matching: find.byType(Container)).first,
  );
  final deco = box.decoration as BoxDecoration?;
  lines.add('box radius ${deco?.borderRadius} margin ${box.margin}');
  for (final s in deco?.boxShadow ?? const <BoxShadow>[]) {
    lines.add('shadow ${_c(s.color)} blur ${s.blurRadius} ${s.offset}');
  }

  // Press feedback wraps the card.
  final scale = find.ancestor(
    of: clip,
    matching: find.byWidgetPredicate(
      (w) => w.runtimeType.toString() == '_ScaleButton',
    ),
  );
  lines.add('press-scale ${scale.evaluate().isNotEmpty}');

  final inside = find.descendant(
    of: clip,
    matching: find.byWidgetPredicate((_) => true),
  );
  for (final e in inside.evaluate()) {
    final w = e.widget;
    final r = tester.getRect(find.byWidget(w).first);
    final left = (r.left - card.left).toStringAsFixed(1);
    final bottom = (card.bottom - r.bottom).toStringAsFixed(1);
    if (w is AspectRatio)
      lines.add('aspect ${w.aspectRatio.toStringAsFixed(4)}');
    if (w is Text) {
      lines.add(
        'text ${_style(w.style)} max=${w.maxLines} of=${w.overflow} '
        'at left=$left bottom=$bottom',
      );
    }
    if (w is Icon) {
      lines.add(
        'icon ${w.icon?.codePoint} ${w.size} ${_c(w.color)} '
        'at left=$left bottom=$bottom',
      );
    }
    if (w is Container && w.decoration is BoxDecoration) {
      final d = w.decoration! as BoxDecoration;
      final g = d.gradient;
      if (g is LinearGradient) {
        lines.add(
          'gradient ${g.begin}->${g.end} stops=${g.stops} '
          '${g.colors.map(_c).join(",")}',
        );
      }
      if (d.shape == BoxShape.circle) {
        lines.add(
          'circle ${r.width}x${r.height} ${_c(d.color)} '
          '${d.boxShadow?.map((s) => "${_c(s.color)}/${s.blurRadius}/${s.offset}").join(",")} '
          'at left=$left bottom=$bottom',
        );
      }
    }
  }
  return lines..sort();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> pump(WidgetTester tester, Widget screen) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(411, 2000);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(_FakeApiClient()),
          projectsProvider.overrideWith((ref) async => _projects),
          guestHomeCacheProvider.overrideWith(
            (ref) => const GuestHomeData(
              projects: _projects,
              communities: _communities,
              media: [],
            ),
          ),
        ],
        child: MaterialApp(home: Scaffold(body: screen)),
      ),
    );
    // Not pumpAndSettle: the homes run entrance animations and hero timers.
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  Future<void> openTab(WidgetTester tester, String tab) async {
    await tester.tap(find.text(tab).first, warnIfMissed: false);
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  /// The home cards are the 320-wide clipped tiles; the leftmost is the first.
  Finder firstCard(WidgetTester tester) {
    final clips =
        find.byWidgetPredicate((w) => w is ClipRRect).evaluate().where((e) {
          final r = tester.getRect(find.byWidget(e.widget).first);
          return (r.width - 320).abs() < 0.5 && (r.height - 180).abs() < 0.5;
        }).toList()..sort(
          (a, b) => tester
              .getRect(find.byWidget(a.widget).first)
              .left
              .compareTo(tester.getRect(find.byWidget(b.widget).first).left),
        );
    expect(clips, isNotEmpty, reason: 'no 320x180 card on screen');
    return find.byWidget(clips.first.widget).first;
  }

  final portals = <String, Widget Function()>{
    'guest': () => const GuestDashboardScreen(),
    'cp': () => const CpHomeScreen(),
    'investor': () => const InvestorHomeScreen(),
    'customer': () => const DashboardScreen(),
  };

  for (final tab in ['COMMUNITIES', 'MEDIA']) {
    testWidgets('$tab cards match the Guest card in every portal', (
      tester,
    ) async {
      final prints = <String, List<String>>{};
      final gaps = <String, double>{};
      for (final entry in portals.entries) {
        await pump(tester, entry.value());
        if (tab != 'COMMUNITIES') await openTab(tester, tab);
        final card = firstCard(tester);
        prints[entry.key] = fingerprint(tester, card);

        // The gap to the next card is the card's own right margin.
        final box = tester.widget<Container>(
          find.ancestor(of: card, matching: find.byType(Container)).first,
        );
        gaps[entry.key] = (box.margin as EdgeInsets?)?.right ?? -1;

        await tester.pumpWidget(const SizedBox());
      }

      final guest = prints['guest']!;
      for (final portal in ['cp', 'investor', 'customer']) {
        expect(
          prints[portal],
          guest,
          reason: '$portal $tab card differs from the Guest card',
        );
        expect(gaps[portal], gaps['guest'], reason: '$portal card spacing');
      }
      expect(tester.takeException(), isNull);
    });
  }
}
