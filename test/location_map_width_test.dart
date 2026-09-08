import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/screens/projects/guest_project_detail_screen.dart';
import 'package:m4_mobile/presentation/screens/projects/project_detail_screen.dart';
import 'package:m4_mobile/presentation/widgets/m4_map_view.dart';

import 'support/fake_webview_platform.dart';

/// Project detail > LOCATION.
///
/// The map card was narrower on the signed-in page than on the guest one. Not
/// the map's height — `M4MapView` is 300 high in both — but its width: the
/// section already sits inside the page's `Padding(horizontal: 24)`, the same
/// one the CONTACT card above it uses, and `_buildLocation` wrapped the map in
/// another 24 a side on top of that. The card came out inset 48 while
/// everything around it stayed at 24, which reads as a smaller card.
///
/// This pumps both pages against the same project and compares the rendered
/// map widths, so the two can't drift apart again.
class _FakeApiClient extends ApiClient {
  _FakeApiClient({required this.project}) : super(baseUrl: 'http://localhost');

  final Map<String, dynamic> project;

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
    // Both pages embed M4MapView, which builds a WebViewController in
    // initState.
    installFakeWebViewPlatform();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async => null,
    );
  });

  const dp = 411.0;
  const project = <String, dynamic>{
    '_id': '000000000000000000000001',
    'title': 'Cledor',
    'description': 'A project.',
    'location': 'Mazgaon, Mumbai',
    'completion': 40,
  };

  /// Pumps [page], scrolls the LOCATION map into view and returns its width.
  Future<double> mapWidth(WidgetTester tester, Widget page) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(dp, 900);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(_FakeApiClient(project: project)),
          authProvider.overrideWith(
            (ref) => _FixedAuth(_FakeApiClient(project: project), const {
              'fullName': 'Asha Rao',
              'phone': '9876543210',
            }),
          ),
        ],
        child: MaterialApp(home: page),
      ),
    );
    // The fetch is real async behind the fake client; let it land, then pump
    // frames by hand — both pages carry entrance animations that never settle.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }

    final map = find.byType(M4MapView);
    await tester.scrollUntilVisible(
      map,
      240,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 60,
    );
    return tester.getSize(map).width;
  }

  testWidgets('the signed-in map card is as wide as the guest one', (
    tester,
  ) async {
    final signedIn = await mapWidth(
      tester,
      const ProjectDetailScreen(
        projectId: '000000000000000000000001',
        projectData: project,
      ),
    );
    final guest = await mapWidth(
      tester,
      const GuestProjectDetailScreen(
        projectId: '000000000000000000000001',
        projectData: project,
      ),
    );

    expect(signedIn, guest);
    // Both sit in the page's own horizontal 24 and nothing else. The signed-in
    // page used to come out 48 a side, i.e. 48px narrower than this.
    expect(guest, dp - 48);
  });
}
