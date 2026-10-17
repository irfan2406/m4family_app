import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/screens/support/contact_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'support/fake_webview_platform.dart';

/// GET IN TOUCH WITH US > the phone field.
///
/// Its placeholder was a real-looking number, `+91 98653 21250 *`. A hint that
/// reads like a value makes the field look pre-filled, and a plausible number
/// sitting in a contact form is worse than merely confusing — it reads as
/// somebody's actual number. It now prompts instead.
void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    // The page embeds M4MapView, which builds a WebViewController in initState.
    installFakeWebViewPlatform();
    // Its PortalBottomNav watches authProvider, and AuthNotifier reads the
    // stored token on construction.
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async => null,
    );
    // ApiClient names the app in every request's User-Agent, read through
    // package_info_plus. On the test host that lookup does real file I/O,
    // which never completes under the test's fake clock — so the page's
    // config request never left and it sat on its spinner. A fixed value
    // stands in, as the real phone answers instantly.
    PackageInfo.setMockInitialValues(
      appName: 'M4 Family',
      packageName: 'com.m4family.m4_mobile',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  testWidgets('the phone field prompts instead of showing a number', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(411, 900);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(
            ApiClient(baseUrl: 'http://localhost'),
          ),
        ],
        child: const MaterialApp(home: ContactScreen()),
      ),
    );
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(find.text('Enter Number *'), findsOneWidget);
    expect(find.text('+91 98653 21250 *'), findsNothing);
    // The fields either side of it are untouched.
    expect(find.text('Full Name *'), findsOneWidget);
    expect(find.text('Email *'), findsOneWidget);
    expect(find.text('Message'), findsOneWidget);
  });
}
