import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/screens/cp/cp_referral_screen.dart';

/// PDF A11: referral points are given by the admin only. A closed referral
/// shows "REWARD PENDING" until the admin rewards it.
class _FakeApi extends ApiClient {
  _FakeApi() : super(baseUrl: 'http://api.example.com');

  Response _ok(String path, Object? data) => Response(
    requestOptions: RequestOptions(path: path),
    statusCode: 200,
    data: {'status': true, 'data': data},
  );

  @override
  Future<Response> getCpWallet() async =>
      _ok('/api/cp/wallet', {'balance': 0});

  @override
  Future<Response> getCpReferrals() async => _ok('/api/cp/referrals', [
    {'name': 'Asha', 'status': 'CLOSED'},
    {'name': 'Bilal', 'status': 'BOOKING_DONE'},
    {'name': 'Chetan', 'status': 'REWARDED', 'pointsEarned': 1500},
    {'name': 'Divya', 'status': 'REWARDED'},
    {'name': 'Esha', 'status': 'NEW'},
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

  testWidgets('closed referrals wait for the admin; rewarded show points', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(411, 3000);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(_FakeApi())],
        child: const MaterialApp(home: CpReferralScreen()),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    // CLOSED and BOOKING_DONE: no points yet.
    expect(find.text('REWARD PENDING'), findsNWidgets(2));
    expect(find.text('CLOSED'), findsNothing);
    expect(find.text('BOOKING_DONE'), findsNothing);
    // REWARDED: the admin's points when sent.
    expect(find.text('REWARDED · +1,500 PTS'), findsOneWidget);
    expect(find.text('REWARDED'), findsOneWidget);
    // Other statuses unchanged.
    expect(find.text('NEW'), findsOneWidget);
    // Never a made-up amount.
    expect(find.textContaining('10,000'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
