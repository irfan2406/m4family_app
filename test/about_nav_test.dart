import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/screens/about/about_screen.dart';
import 'package:m4_mobile/presentation/widgets/navigation_pill.dart';

/// Guest portal > WHO WE ARE.
///
/// The screen drew its own NavigationPill whenever Navigator.canPop() was true.
/// Its own comment says the intent is "shown only when pushed standalone (from
/// the menu), not when embedded as a shell tab" — but canPop() does not test
/// that: as the guest shell's About tab the surrounding navigator can still
/// pop, so a second 4-icon pill appeared above the shell's own 5-icon one.
/// The widget already carried an `embedded` flag; the nav now honours it.
void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async => null,
    );
  });

  /// Puts the screen behind a pushed route so Navigator.canPop() is true —
  /// which is the situation inside a shell, and what used to trigger the pill.
  Future<void> pump(WidgetTester tester, {required bool embedded}) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(360, 2000);
    addTearDown(tester.view.reset);

    final navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(
            ApiClient(baseUrl: 'http://localhost'),
          ),
        ],
        child: MaterialApp(
          navigatorKey: navKey,
          home: const Scaffold(body: Center(child: Text('ROOT'))),
        ),
      ),
    );

    navKey.currentState!.push(
      MaterialPageRoute(builder: (_) => AboutScreen(embedded: embedded)),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(navKey.currentState!.canPop(), isTrue);
  }

  testWidgets('embedded as a shell tab: draws no pill of its own', (
    tester,
  ) async {
    await pump(tester, embedded: true);

    // The shell supplies the only nav; a second one here is the reported bug.
    expect(find.byType(NavigationPill), findsNothing);
    expect(find.text('WHO WE ARE'), findsOneWidget);
  });

  testWidgets('pushed standalone: keeps its own pill', (tester) async {
    await pump(tester, embedded: false);

    // Opened from the menu there is no shell underneath, so it still needs one.
    expect(find.byType(NavigationPill), findsOneWidget);
  });
}
