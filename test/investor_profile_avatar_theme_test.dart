import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/screens/investor/investor_profile_details_screen.dart';

/// Investor MY PROFILE.
///
/// Two defects, both in this one screen:
///
/// 1. The 96x96 avatar asked CachedNetworkImage for `memCacheWidth: 192` AND
///    `memCacheHeight: 192`. Giving both resizes the source into that exact box
///    and discards its aspect ratio, so `BoxFit.cover` has nothing left to crop
///    and any non-square photo renders squeezed.
///
/// 2. The screen was the last one still drawing its accents in gold
///    (`0xFFC5A35B`). Its CP twin already uses the ink green in the same
///    places, and two foregrounds had to flip with the fill or they would be
///    invisible on it.
const _gold = Color(0xFFC5A35B);
const _ink = Color(0xFF0C312B);

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(baseUrl: 'http://localhost');

  @override
  Future<Response> getCurrentUser() async => Response(
    requestOptions: RequestOptions(path: '/api/auth/me'),
    statusCode: 200,
    data: {
      'status': true,
      'data': {
        'fullName': 'Irfan Khan',
        'email': 'ik638418@gmail.com',
        'phone': '8356808468',
        // Deliberately not square: the shape that showed the stretch.
        'avatarUrl': 'https://example.invalid/wide-avatar.png',
      },
    },
  );
}

class _FixedAuth extends AuthNotifier {
  _FixedAuth(super.api) {
    state = AuthState(
      status: AuthStatus.authenticated,
      user: const {'fullName': 'Irfan Khan'},
      bootstrapped: true,
    );
  }
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

  Future<void> pumpProfile(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(411, 1400);
    addTearDown(tester.view.reset);

    final api = _FakeApiClient();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(api),
          authProvider.overrideWith((ref) => _FixedAuth(api)),
        ],
        child: const MaterialApp(home: InvestorProfileDetailsScreen()),
      ),
    );
    // _load runs from a post-frame callback and awaits the fake client.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  /// Every colour this widget subtree paints with, so a stray gold can be
  /// caught wherever it is set rather than one property at a time.
  Set<Color> paintedColours(WidgetTester tester) {
    final colours = <Color>{};
    for (final w in tester.allWidgets) {
      if (w is Icon && w.color != null) colours.add(w.color!);
      if (w is Text && w.style?.color != null) colours.add(w.style!.color!);
      if (w is Material && w.color != null) colours.add(w.color!);
      if (w is Container) {
        final d = w.decoration;
        if (d is BoxDecoration) {
          if (d.color != null) colours.add(d.color!);
          final g = d.gradient;
          if (g is LinearGradient) colours.addAll(g.colors);
          final b = d.border;
          if (b is Border) colours.add(b.top.color);
          for (final s in d.boxShadow ?? const <BoxShadow>[]) {
            colours.add(s.color);
          }
        }
      }
    }
    return colours;
  }

  testWidgets('the avatar is not squeezed into a square', (tester) async {
    await pumpProfile(tester);

    final img = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    // Width alone: the decoder keeps the source's proportions and BoxFit.cover
    // does the cropping. Setting height too is what flattened the photo.
    expect(img.memCacheWidth, isNotNull);
    expect(img.memCacheHeight, isNull);
    expect(img.fit, BoxFit.cover);
  });

  testWidgets('nothing on the page is painted gold', (tester) async {
    await pumpProfile(tester);

    // The gold was used at full strength and at several alphas, so the match
    // is on RGB with the alpha masked off.
    int rgb(Color c) => c.toARGB32() & 0x00FFFFFF;
    final golds = paintedColours(tester).where((c) => rgb(c) == rgb(_gold));
    expect(golds, isEmpty);
    // ...and the ink green took its place.
    expect(paintedColours(tester).any((c) => rgb(c) == rgb(_ink)), isTrue);
  });

  testWidgets('the edit-mode foregrounds flip with the fill', (tester) async {
    await pumpProfile(tester);

    await tester.tap(find.byIcon(LucideIcons.edit2));
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    // Both sat dark-on-gold. On a green fill that reads as nothing at all.
    final camera = tester.widget<Icon>(find.byIcon(LucideIcons.camera));
    expect(camera.color, Colors.white);
    final save = tester.widget<Text>(find.text('SAVE CHANGES'));
    expect(save.style?.color, Colors.white);
  });
}
