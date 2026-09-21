import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/providers/project_provider.dart';
import 'package:m4_mobile/presentation/screens/communities/community_detail_screen.dart';
import 'package:m4_mobile/presentation/screens/cp/cp_home_screen.dart';
import 'package:m4_mobile/presentation/screens/home/dashboard_screen.dart';
import 'package:m4_mobile/presentation/screens/home/guest_dashboard_screen.dart'
    show GuestDashboardScreen, guestHomeCacheProvider, GuestHomeData;
import 'package:m4_mobile/presentation/screens/investor/investor_home_screen.dart';
import 'package:m4_mobile/presentation/screens/projects/project_list_screen.dart';
import 'package:m4_mobile/presentation/screens/support/ticket_detail_screen.dart';
import 'package:m4_mobile/presentation/widgets/cp_sidebar_menu.dart';
import 'package:m4_mobile/presentation/widgets/guest_sidebar_menu.dart';
import 'package:m4_mobile/presentation/widgets/investor_sidebar_menu.dart';
import 'package:m4_mobile/presentation/widgets/m4_bottom_nav.dart';
import 'package:m4_mobile/presentation/widgets/side_menu_button.dart';
import 'package:m4_mobile/presentation/widgets/sidebar_menu.dart';
import 'package:m4_mobile/presentation/widgets/wheel_date_time_picker.dart';

import '../support/fake_webview_platform.dart';

/// Shared by the Android baseline and the iOS Liquid Glass goldens: the same
/// scenes, the same fake backend, the same frames — only the platform differs.
class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(baseUrl: 'http://api.example.com');

  Response _ok(String path, dynamic data) => Response(
    requestOptions: RequestOptions(path: path),
    statusCode: 200,
    data: {'status': true, 'data': data},
  );

  @override
  Future<Response> getCommunities() async =>
      _ok('/api/catalog/communities', _communities);

  @override
  Future<Response> getPublicConfig() async =>
      _ok('/api/config', <String, dynamic>{});

  @override
  Future<Response> getContent(
    String type, {
    String role = 'guest',
    String? projectId,
  }) async => _ok('/api/content', const []);

  @override
  Future<Response> getCommunityBySlug(String slug) async =>
      _ok('/api/catalog/communities/$slug', _communities.first);

  @override
  Future<Response> getProjectsByCommunity(String id) async =>
      _ok('/api/catalog/communities/$id/projects', _projects);

  @override
  Future<Response> getTicketDetail(String ticketId) async =>
      _ok('/api/tickets/$ticketId', _ticket);
}

const _communities = [
  {
    '_id': 'c1',
    'slug': 'mazgaon',
    'title': 'Mazgaon',
    'overview': 'A community in the making, rising above the harbour',
    'image': '/uploads/c1.jpg',
  },
  {
    '_id': 'c2',
    'slug': 'worli',
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

const _ticket = {
  '_id': '6a70ae0000000000006a70ae',
  'ticketId': 'TICK-6A70AE',
  'subject': 'Inquiry: Clédor',
  'status': 'open',
  'messages': [
    {'message': 'hii', 'sender': 'user', 'createdAt': '2026-09-18T08:13:00Z'},
  ],
};

/// One screen or component to capture.
class GoldenScene {
  const GoldenScene(
    this.name,
    this.build, {
    this.size = const Size(390, 1600),
    this.act,
  });

  final String name;
  final Widget Function() build;
  final Size size;

  /// An optional interaction once the scene has settled — opening a dialog.
  final Future<void> Function(WidgetTester tester)? act;
}

/// Scrolls [text] into view and taps it.
Future<void> Function(WidgetTester) _tapText(String text) => (tester) async {
  final target = find.text(text);
  await tester.ensureVisible(target);
  await tester.pump();
  await tester.tap(target);
};

Widget _onSurface(ThemeData Function() theme, Widget child) => Builder(
  builder: (context) {
    final data = theme();
    return Theme(
      data: data,
      child: Scaffold(
        backgroundColor: data.scaffoldBackgroundColor,
        body: Align(alignment: Alignment.bottomCenter, child: child),
      ),
    );
  },
);

/// Every scene, built lazily so each is created on its own platform.
final List<GoldenScene> goldenScenes = [
  GoldenScene(
    'nav_cream_4',
    () => _onSurface(
      () => M4Theme.lightTheme,
      M4BottomNav(
        icons: const [
          LucideIcons.home,
          LucideIcons.compass,
          LucideIcons.messageSquare,
          LucideIcons.user,
        ],
        currentIndex: 0,
        onTap: (_) {},
      ),
    ),
    size: const Size(390, 200),
  ),
  GoldenScene(
    'nav_green_5',
    () => _onSurface(
      () => M4Theme.darkTheme,
      M4BottomNav(
        icons: const [
          LucideIcons.home,
          LucideIcons.barChart3,
          LucideIcons.compass,
          LucideIcons.messageSquare,
          LucideIcons.user,
        ],
        currentIndex: 2,
        onTap: (_) {},
      ),
    ),
    size: const Size(390, 200),
  ),
  GoldenScene(
    'nav_none',
    () => _onSurface(
      () => M4Theme.lightTheme,
      M4BottomNav(
        icons: const [LucideIcons.home, LucideIcons.user],
        currentIndex: -1,
        onTap: (_) {},
      ),
    ),
    size: const Size(390, 200),
  ),
  GoldenScene(
    'home_guest',
    () => Theme(
      data: M4Theme.darkTheme,
      child: const Scaffold(body: GuestDashboardScreen()),
    ),
  ),
  GoldenScene('home_customer', () => const DashboardScreen()),
  GoldenScene('home_cp', () => const Scaffold(body: CpHomeScreen())),
  GoldenScene(
    'home_investor',
    () => const Scaffold(body: InvestorHomeScreen()),
  ),
  GoldenScene('project_list', () => const ProjectListScreen()),
  GoldenScene(
    'community_detail',
    () => const CommunityDetailScreen(
      community: {'_id': 'c1', 'slug': 'c1', 'title': 'Mazgaon'},
    ),
  ),
  GoldenScene(
    'ticket_detail',
    () => const TicketDetailScreen(
      ticketId: '6a70ae0000000000006a70ae',
      initialTicket: _ticket,
    ),
    size: const Size(390, 844),
  ),
  GoldenScene(
    'sidebar_guest',
    () => const Scaffold(body: GuestSidebarMenu()),
    size: const Size(390, 844),
  ),
  GoldenScene(
    'sidebar_customer',
    () => const Scaffold(body: SidebarMenu()),
    size: const Size(390, 844),
  ),
  GoldenScene(
    'sidebar_cp',
    () => const Scaffold(body: CpSidebarMenu()),
    size: const Size(390, 844),
  ),
  GoldenScene(
    'sidebar_investor',
    () => const Scaffold(body: InvestorSidebarMenu()),
    size: const Size(390, 844),
  ),
  GoldenScene(
    'side_menu_button',
    () => const Scaffold(body: Center(child: SideMenuButton())),
    size: const Size(200, 120),
  ),
  GoldenScene(
    'dialog_exit_guest',
    () => const Scaffold(body: GuestSidebarMenu()),
    size: const Size(390, 844),
    act: _tapText('EXIT APP'),
  ),
  GoldenScene(
    'dialog_logout_customer',
    () => const Scaffold(body: SidebarMenu()),
    size: const Size(390, 844),
    act: _tapText('LOG OUT'),
  ),
  GoldenScene(
    'dialog_logout_cp',
    () => const Scaffold(body: CpSidebarMenu()),
    size: const Size(390, 844),
    act: _tapText('LOGOUT'),
  ),
  GoldenScene(
    'dialog_logout_investor',
    () => const Scaffold(body: InvestorSidebarMenu()),
    size: const Size(390, 844),
    act: _tapText('LOGOUT'),
  ),
  GoldenScene(
    'sheet_datetime',
    () => Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () => showM4DateTimeSheet(
              context,
              initial: DateTime(2026, 9, 21, 10, 30),
            ),
            child: const Text('pick'),
          ),
        ),
      ),
    ),
    size: const Size(390, 844),
    act: _tapText('pick'),
  ),
  GoldenScene(
    'sheet_project_filter',
    () => const ProjectListScreen(),
    size: const Size(390, 844),
    act: (tester) async {
      await tester.tap(find.byIcon(LucideIcons.slidersHorizontal));
    },
  ),
];

/// Registers the platform plumbing the scenes need. Call from setUpAll.
void setUpGoldenHarness() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  installFakeWebViewPlatform();
  binding.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
    (call) async => null,
  );
}

/// Runs [body] with [platform] as the target platform.
///
/// google_fonts cannot load its fonts here (no network, none bundled) and
/// rethrows into the zone once real async runs. Text still lays out in the
/// fallback font, identically on every run, so those errors — and only
/// those — are ignored. Anything else fails the test, straight away.
Future<void> runOnPlatform(
  TargetPlatform platform,
  Future<void> Function() body, {
  String? reason,
}) async {
  final unexpected = <Object>[];
  Object? failure;
  StackTrace? failureStack;
  debugDefaultTargetPlatformOverride = platform;
  try {
    await runZonedGuarded(
      () async {
        // An error cannot leave the guarded zone through the returned future
        // (awaiting it would hang), so a failed expectation is caught in here
        // and rethrown below.
        try {
          await body();
        } catch (error, stack) {
          failure = error;
          failureStack = stack;
        }
      },
      (error, stack) {
        if (error.toString().contains('allowRuntimeFetching is false')) return;
        unexpected.add(error);
      },
    );
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
  if (failure != null) Error.throwWithStackTrace(failure!, failureStack!);
  expect(unexpected, isEmpty, reason: reason);
}

/// Renders [scene] on [platform] and compares it with [goldenPath].
Future<void> renderGolden(
  WidgetTester tester, {
  required TargetPlatform platform,
  required GoldenScene scene,
  required String goldenPath,
}) {
  return runOnPlatform(platform, () async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = scene.size;
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
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: M4Theme.lightTheme,
          home: scene.build(),
        ),
      ),
    );
    // A fixed number of frames, not pumpAndSettle: the homes run hero timers
    // and entrance animations, and fake time keeps this exactly repeatable.
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    if (scene.act != null) {
      await scene.act!(tester);
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }
    }

    await expectLater(find.byType(MaterialApp), matchesGoldenFile(goldenPath));
  }, reason: 'errors while rendering ${scene.name}');
}
