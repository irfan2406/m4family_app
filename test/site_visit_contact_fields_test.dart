import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/screens/projects/project_detail_screen.dart';

import 'support/fake_webview_platform.dart';

/// Project detail > BOOK A SITE VISIT / BOOK A VIDEO CALL.
///
/// The sheet had two arms. The General ("REQUEST DETAILS") arm asked for FULL
/// NAME / EMAIL / PHONE; the Site Visit + VC arm asked for none of them — it
/// read the name and phone straight off the logged-in profile and only revealed
/// a lone PHONE field when the profile had none. An investor booking a site
/// visit could not see, let alone correct, the details the lead carried.
///
/// These assert the three fields are on the visit sheet, that they arrive
/// prefilled from the profile, and that a blank required field is caught before
/// the request goes out (the API 400s on a missing phone, which the screen
/// reports as a misleading "Connection error").
class _FakeApiClient extends ApiClient {
  _FakeApiClient({required this.project}) : super(baseUrl: 'http://localhost');

  final Map<String, dynamic> project;

  /// Leads the screen actually submitted, so a test can assert one did NOT go
  /// out when validation should have stopped it.
  final List<Map<String, dynamic>> leads = [];

  Response _ok(String path, dynamic data) => Response(
    requestOptions: RequestOptions(path: path),
    statusCode: 200,
    data: {'status': true, 'data': data},
  );

  @override
  Future<Response> getProjectDetails(String id) async =>
      _ok('/api/projects/$id', project);

  @override
  Future<Response> getProjectUpdates(String id) async =>
      _ok('/api/projects/$id/updates', const []);

  @override
  Future<Response> getProjectInventory(String id) async =>
      _ok('/api/projects/$id/inventory', const []);

  @override
  Future<Response> getProjectProgress(String id) async =>
      _ok('/api/projects/$id/progress', const []);

  @override
  Future<Response> submitLead(Map<String, dynamic> body) async {
    leads.add(body);
    return _ok('/api/leads', body);
  }
}

/// Signed in without touching the real token check.
class _FixedAuth extends AuthNotifier {
  _FixedAuth(super.api, Map<String, dynamic> user) {
    state = AuthState(
      status: AuthStatus.authenticated,
      user: user,
      bootstrapped: true,
    );
  }
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    // The page embeds M4MapView, which builds a WebViewController in
    // initState; without a platform implementation that assertion fires while
    // the page is still mounting.
    installFakeWebViewPlatform();
    // AuthNotifier reads the stored token on construction; without a handler
    // that throws MissingPluginException before the screen ever builds.
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async => null,
    );
  });

  const project = <String, dynamic>{
    '_id': '000000000000000000000001',
    'title': 'Cledor',
    'description': 'A project.',
    'completion': 40,
  };

  /// Signs a user in with the given profile, opens the project page and taps
  /// through to the BOOK A SITE VISIT sheet.
  Future<_FakeApiClient> openSiteVisit(
    WidgetTester tester, {
    Map<String, dynamic>? user,
  }) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(411, 900);
    addTearDown(tester.view.reset);

    final api = _FakeApiClient(project: project);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(api),
          if (user != null)
            authProvider.overrideWith((ref) => _FixedAuth(api, user)),
        ],
        child: const MaterialApp(
          home: ProjectDetailScreen(
            projectId: '000000000000000000000001',
            projectData: project,
          ),
        ),
      ),
    );
    // The page's fetch is real async behind the fake client; let it land, then
    // pump frames by hand — the screen carries entrance animations that never
    // settle, so pumpAndSettle would hang.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }

    // "SITE VISIT · Book Tour" tile in the overview action row. The page
    // holds several scrollables (the hero and the amenity strips scroll
    // horizontally), so the outer one is named rather than searched for.
    final tile = find.text('Book Tour');
    await tester.scrollUntilVisible(
      tile,
      220,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 40,
    );
    await tester.tap(tile, warnIfMissed: false);
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    return api;
  }

  testWidgets('the site visit sheet asks for name, email and phone', (
    tester,
  ) async {
    await openSiteVisit(
      tester,
      user: const {'fullName': 'Asha Rao', 'phone': '', 'email': ''},
    );

    expect(find.text('BOOK A SITE VISIT'), findsOneWidget);
    // Placeholders inside the boxes, worded and ordered as the guest sheet
    // words them — no caps labels stacked above the fields.
    expect(find.text('Enter Full Name'), findsOneWidget);
    expect(find.text('Enter Email Address (Optional)'), findsOneWidget);
    expect(find.text('Enter Mobile Number'), findsOneWidget);
    // ...and no caps label above a box, which is what this sheet used to draw.
    expect(find.text('FULL NAME *'), findsNothing);
    expect(find.text('PHONE NUMBER *'), findsNothing);
    // The rest of the sheet is untouched.
    expect(find.text('PREFERRED CONFIGURATION *'), findsOneWidget);
    expect(find.text('VISIT TYPE'), findsOneWidget);
    expect(find.text('SCHEDULE'), findsOneWidget);
    expect(find.text('ADDITIONAL NOTES'), findsOneWidget);
  });

  testWidgets('the fields open empty so the placeholders are readable', (
    tester,
  ) async {
    await openSiteVisit(
      tester,
      user: const {
        'fullName': 'Asha Rao',
        'phone': '9876543210',
        'email': 'asha@example.com',
      },
    );

    // The sheet used to open prefilled from the profile. These boxes carry no
    // label of their own, so a prefilled value left three unlabelled greys.
    //
    // The absent VALUES are the real check: InputDecorator keeps the hint
    // widget mounted and merely fades it out, so finding the hint text proves
    // nothing on its own.
    expect(find.text('Asha Rao'), findsNothing);
    expect(find.text('9876543210'), findsNothing);
    expect(find.text('asha@example.com'), findsNothing);
    expect(find.text('Enter Full Name'), findsOneWidget);
    expect(find.text('Enter Email Address (Optional)'), findsOneWidget);
    expect(find.text('Enter Mobile Number'), findsOneWidget);
  });

  testWidgets('a blank phone is caught before the lead is submitted', (
    tester,
  ) async {
    final api = await openSiteVisit(
      tester,
      user: const {'fullName': 'Asha Rao', 'phone': '', 'email': ''},
    );

    await tester.tap(find.text('SUBMIT INQUIRY'), warnIfMissed: false);
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    // Stopped locally rather than 400ing at the API and surfacing as
    // "Connection error".
    expect(api.leads, isEmpty);
  });

  testWidgets('a typed number replaces the placeholder', (tester) async {
    await openSiteVisit(
      tester,
      user: const {
        'fullName': 'Asha Rao',
        'phone': '9876543210',
        'email': 'asha@example.com',
      },
    );

    // Typing into a box is what the lead will carry — the boxes are the only
    // place these details can come from now.
    await tester.enterText(
      find.widgetWithText(TextField, 'Enter Mobile Number'),
      '9000000001',
    );
    await tester.pump();

    expect(find.text('9000000001'), findsOneWidget);
  });
}
