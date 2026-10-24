import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/screens/cp/cp_profile_screen.dart';

/// PDF p11, partner profile: firm logo, firm name, RERA (optional), employees.
class _FakeApi extends ApiClient {
  _FakeApi({this.avatar = ''}) : super(baseUrl: 'http://api.example.com');

  final String avatar;

  Response _ok(String path, Object? data) => Response(
    requestOptions: RequestOptions(path: path),
    statusCode: 200,
    data: {'status': true, 'data': data},
  );

  @override
  Future<Response> getCurrentUser() async => _ok('/api/auth/me', {
    'fullName': 'Rahul Mehta',
    'companyName': 'Skyline Realty',
    'avatarUrl': avatar,
    'email': 'rahul@example.com',
    'role': 'cp',
  });

  @override
  Future<Response> getCpEmployees() async => _ok('/api/cp/employees', [
    {'name': 'Priya'},
    {'name': 'Amit'},
    {'name': 'Neha'},
    {'name': 'Karan'},
  ]);
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async => null,
    );
  });

  Future<void> pump(WidgetTester tester, _FakeApi api) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(411, 2400);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(api)],
        child: const MaterialApp(home: CpProfileScreen()),
      ),
    );
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  testWidgets('no logo uploaded: the firm initials, never a stock photo', (
    tester,
  ) async {
    await pump(tester, _FakeApi());

    expect(find.text('SR'), findsOneWidget); // Skyline Realty
    final urls = tester
        .widgetList<CachedNetworkImage>(find.byType(CachedNetworkImage))
        .map((w) => w.imageUrl);
    expect(urls.where((u) => u.contains('unsplash')), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an uploaded logo is shown', (tester) async {
    await pump(tester, _FakeApi(avatar: '/uploads/media/logo.png'));

    expect(find.text('SR'), findsNothing);
    final urls = tester
        .widgetList<CachedNetworkImage>(find.byType(CachedNetworkImage))
        .map((w) => w.imageUrl);
    expect(urls, contains('http://api.example.com/uploads/media/logo.png'));
  });

  testWidgets('the team is summarised on the profile', (tester) async {
    await pump(tester, _FakeApi());

    expect(find.text('EMPLOYEE MANAGEMENT'), findsOneWidget);
    expect(find.text('4 employees · Priya, Amit, Neha +1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
