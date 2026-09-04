import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/screens/profile/profile_screen.dart';

/// Customer portal > Profile.
///
/// MY FAMILY was removed from this screen. The investor profile keeps its own
/// entry, so this only pins the customer one — and pins that nothing around it
/// went with it.
class _FixedAuth extends AuthNotifier {
  _FixedAuth(super.api, Map<String, dynamic> user) {
    state = AuthState(user: user, bootstrapped: true);
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

  Future<void> pump(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(411, 1600);
    addTearDown(tester.view.reset);

    final api = ApiClient(baseUrl: 'http://localhost');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(api),
          authProvider.overrideWith(
            (ref) => _FixedAuth(api, {
              '_id': 'u1',
              'role': 'user',
              'fullName': 'Test Customer',
            }),
          ),
        ],
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  testWidgets('MY FAMILY is gone from the customer profile', (tester) async {
    await pump(tester);
    expect(tester.takeException(), isNull);

    expect(find.text('MY FAMILY'), findsNothing);
    expect(find.text('FAMILY'), findsNothing);
    expect(find.text('MANAGE YOUR FAMILY DETAILS'), findsNothing);
  });

  testWidgets('everything around it is untouched', (tester) async {
    await pump(tester);

    expect(find.text('PROPERTY SERVICES'), findsOneWidget);
    expect(find.text('MY PROPERTIES'), findsOneWidget);
    expect(find.text('MANAGEMENT & SUPPORT'), findsOneWidget);
    expect(find.text('MY CUSTOM VIEWS'), findsOneWidget);
    expect(find.text('M4 REFERRAL PROGRAM'), findsOneWidget);
  });
}
