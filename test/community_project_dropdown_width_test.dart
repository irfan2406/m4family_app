import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/screens/communities/community_detail_screen.dart';

import 'support/fake_webview_platform.dart';

/// Community detail > EXPRESS INTEREST > the project picker.
///
/// The menu was given `BoxConstraints(minWidth: 240)` — a floor with no
/// ceiling — so PopupMenuButton sized it to its content and stopped at 240
/// while the trigger runs the full width of the form. Anchored at the trigger's
/// left edge, that left a narrow box covering about half the field with a
/// ragged gap down its right, which is why it read as a stray popup instead of
/// the field's own list.
class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(baseUrl: 'http://localhost');

  Response _ok(String path, dynamic data) => Response(
    requestOptions: RequestOptions(path: path),
    statusCode: 200,
    data: {'status': true, 'data': data},
  );

  @override
  Future<Response> getCommunityBySlug(String slug) async => _ok(
    '/api/catalog/communities/$slug',
    const {'_id': 'c1', 'title': 'Test Community'},
  );

  @override
  Future<Response> getProjectsByCommunity(String id) async =>
      // Two projects, so the list has real entries under the "Any" row.
      _ok('/api/catalog/communities/$id/projects', const [
        {'_id': 'p1', 'title': 'Skai'},
        {'_id': 'p2', 'title': 'Ocean View'},
      ]);
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    // The page embeds M4MapView, which builds a WebViewController in initState.
    installFakeWebViewPlatform();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async => null,
    );
  });

  testWidgets('the open list is as wide as the field it drops from', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(411, 1000);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(_FakeApiClient())],
        child: const MaterialApp(
          home: CommunityDetailScreen(
            community: {'_id': 'c1', 'slug': 'c1', 'title': 'Test Community'},
          ),
        ),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }

    // The closed trigger, down in the EXPRESS INTEREST form.
    final trigger = find.byType(PopupMenuButton<String>);
    // Not scrollUntilVisible: the page is one non-lazy Column in a scroll
    // view, so the finder already matches while the widget is far off-screen
    // and it scrolls nothing.
    await tester.ensureVisible(trigger);
    await tester.pump(const Duration(milliseconds: 300));
    final triggerWidth = tester.getSize(trigger).width;
    expect(triggerWidth, greaterThan(240));

    await tester.tap(trigger);
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    // Every row spans the trigger, so the menu's edges line up with it. They
    // used to stop at 240 regardless of how wide the field was.
    final rows = find.byType(PopupMenuItem<String>);
    expect(rows, findsWidgets);
    for (var i = 0; i < tester.widgetList(rows).length; i++) {
      expect(tester.getSize(rows.at(i)).width, triggerWidth);
    }
  });

  testWidgets('the rows clear the minimum touch target', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(411, 1000);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(_FakeApiClient())],
        child: const MaterialApp(
          home: CommunityDetailScreen(
            community: {'_id': 'c1', 'slug': 'c1', 'title': 'Test Community'},
          ),
        ),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }

    final trigger = find.byType(PopupMenuButton<String>);
    // Not scrollUntilVisible: the page is one non-lazy Column in a scroll
    // view, so the finder already matches while the widget is far off-screen
    // and it scrolls nothing.
    await tester.ensureVisible(trigger);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(trigger);
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    // Was 40 — under the 48 a finger needs, and cramped for a list.
    final row = tester.widget<PopupMenuItem<String>>(
      find.byType(PopupMenuItem<String>).first,
    );
    expect(row.height, 46);
  });
}
