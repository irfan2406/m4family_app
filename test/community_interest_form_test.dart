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

/// Community detail > EXPRESS INTEREST, which every portal opens (Guest, CP,
/// Investor and Customer all route to this one screen).
///
/// The form no longer carries the "Any Project / Property" picker. Nothing
/// else about it changes: the other fields and their spacing stay, and the
/// lead still posts exactly what it posted when no project was picked — the
/// community's name as both the subject and the project.
class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(baseUrl: 'http://localhost');

  final leads = <Map<String, dynamic>>[];

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
      _ok('/api/catalog/communities/$id/projects', const [
        {'_id': 'p1', 'title': 'Skai'},
        {'_id': 'p2', 'title': 'Ocean View'},
      ]);

  @override
  Future<Response> submitLead(Map<String, dynamic> data) async {
    leads.add(data);
    return _ok('/api/leads', data);
  }
}

/// The decorated box of a form field — what the user sees as the field. The
/// TextField itself sits 1dp inside the box's border.
Rect fieldBox(WidgetTester tester, String hint) => tester.getRect(
  find
      .ancestor(
        of: find.ancestor(
          of: find.text(hint),
          matching: find.byType(TextField),
        ),
        matching: find.byType(Container),
      )
      .first,
);

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

  Future<_FakeApiClient> pump(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(411, 1000);
    addTearDown(tester.view.reset);

    final api = _FakeApiClient();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(api)],
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
    return api;
  }

  testWidgets('the form has no project picker, and keeps every other field', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Any Project / Property'), findsNothing);
    expect(find.byType(PopupMenuButton<String>), findsNothing);

    for (final field in [
      'Enter Full Name',
      'Enter Email Address',
      'Enter Mobile Number',
      'Enter City and Country',
      'REGISTER INTEREST',
    ]) {
      expect(find.text(field), findsOneWidget, reason: '$field is missing');
    }

    // The picker sat between the email/mobile row and the city field; with it
    // gone those two are 12 apart, the same gap as between the other fields.
    final email = fieldBox(tester, 'Enter Email Address');
    final city = fieldBox(tester, 'Enter City and Country');
    final name = fieldBox(tester, 'Enter Full Name');
    expect(city.top - email.bottom, email.top - name.bottom);
    expect(city.top - email.bottom, 12);

    expect(tester.takeException(), isNull);
  });

  testWidgets('the lead posts what an unpicked project always posted', (
    tester,
  ) async {
    final api = await pump(tester);

    Future<void> type(String hint, String text) async {
      final field = find.ancestor(
        of: find.text(hint),
        matching: find.byType(TextField),
      );
      await tester.ensureVisible(field);
      await tester.enterText(field, text);
    }

    await type('Enter Full Name', 'Asha Rao');
    await type('Enter Email Address', 'asha@example.com');
    await type('Enter Mobile Number', '9876543210');

    final submit = find.text('REGISTER INTEREST');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }

    expect(api.leads, hasLength(1));
    expect(api.leads.single, {
      'name': 'Asha Rao',
      'email': 'asha@example.com',
      'phone': '9876543210',
      'location': '',
      'interest': 'Buying',
      'message': 'Expressing interest in community: Test Community',
      'projectName': 'Test Community',
      'source': 'online',
    });
  });
}
