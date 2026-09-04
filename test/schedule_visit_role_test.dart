import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/providers/project_provider.dart';
import 'package:m4_mobile/presentation/screens/support/schedule_visit_screen.dart';

/// Support Hub > Schedule Visit is one screen behind three shells.
///
/// The CP web page for this entry is the longer SITE VISIT / PROTOCOL
/// VERIFICATION form — FULL NAME, PHONE NUMBER, SELECT PROJECT, HANDLED BY
/// (EMPLOYEE) — while the customer / investor page is the short one that
/// starts at SELECT PROPERTY. The screen picks by role, so both halves are
/// pinned here: the CP half is what was asked for, and the non-CP half is the
/// promise that nothing else moved.
class _FakeApiClient extends ApiClient {
  _FakeApiClient(this.employees) : super(baseUrl: 'http://localhost');

  final List<dynamic> employees;

  @override
  Future<Response> getCpEmployees() async => Response(
    requestOptions: RequestOptions(path: '/api/cp/employees'),
    statusCode: 200,
    data: {'status': true, 'data': employees},
  );
}

class _FixedAuth extends AuthNotifier {
  _FixedAuth(ApiClient api, Map<String, dynamic> user) : super(api) {
    state = AuthState(user: user, bootstrapped: true);
  }
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    // AuthNotifier reads the stored token on construction; without a handler
    // that throws MissingPluginException before the screen ever builds.
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async => null,
    );
  });

  Future<void> pumpAs(
    WidgetTester tester, {
    required String role,
    List<dynamic> employees = const [],
    double dp = 411,
    double textScale = 1.0,
  }) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = Size(dp, 1400);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(() {
      tester.view.reset();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });

    final api = _FakeApiClient(employees);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(api),
          authProvider.overrideWith(
            (ref) => _FixedAuth(api, {
              'role': role,
              'fullName': 'Deepak',
              'phone': '9721591890',
            }),
          ),
          projectsProvider.overrideWith((ref) async => const <dynamic>[]),
        ],
        child: const MaterialApp(home: ScheduleVisitScreen()),
      ),
    );
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  group('CP sees the web form', () {
    testWidgets('title, extra fields and project wording', (tester) async {
      await pumpAs(tester, role: 'cp');
      expect(tester.takeException(), isNull);

      expect(find.text('SITE VISIT'), findsOneWidget);
      expect(find.text('PROTOCOL VERIFICATION'), findsOneWidget);
      expect(find.text('FULL NAME'), findsOneWidget);
      expect(find.text('PHONE NUMBER'), findsOneWidget);
      expect(find.text('HANDLED BY (EMPLOYEE)'), findsOneWidget);
      // The CP page says PROJECT where the customer page says PROPERTY.
      expect(find.text('SELECT PROJECT'), findsOneWidget);
      expect(find.text('CHOOSE PROJECT'), findsOneWidget);
      expect(find.text('SELECT PROPERTY'), findsNothing);
    });

    testWidgets('name and number come pre-filled from the account', (
      tester,
    ) async {
      await pumpAs(tester, role: 'cp');
      expect(find.text('Deepak'), findsOneWidget);
      expect(find.text('9721591890'), findsOneWidget);
    });

    testWidgets('the employee list is offered when the partner has staff', (
      tester,
    ) async {
      await pumpAs(
        tester,
        role: 'cp',
        employees: [
          {'_id': 'e1', 'name': 'Ravi'},
        ],
      );
      expect(find.text('SELECT EMPLOYEE'), findsOneWidget);
      expect(find.text('NO EMPLOYEES ADDED'), findsNothing);
    });

    testWidgets('an empty roster says so instead of a dead control', (
      tester,
    ) async {
      await pumpAs(tester, role: 'cp');
      expect(find.text('NO EMPLOYEES ADDED'), findsOneWidget);
    });

    for (final dp in <double>[320, 360, 411]) {
      for (final scale in <double>[1.0, 1.3, 1.5]) {
        testWidgets('${dp.toInt()}dp @ ${scale}x lays out without overflow', (
          tester,
        ) async {
          await pumpAs(tester, role: 'cp', dp: dp, textScale: scale);
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  group('customer and investor are untouched', () {
    for (final role in <String>['user', 'investor']) {
      testWidgets('$role keeps the short form', (tester) async {
        // The tight case too: the short form must survive a small screen at a
        // large system font just as the CP one does.
        await pumpAs(tester, role: role, dp: 360, textScale: 1.5);
        expect(tester.takeException(), isNull);

        expect(find.text('SCHEDULE VISIT'), findsOneWidget);
        expect(find.text('PREMIUM PROTOCOL'), findsOneWidget);
        expect(find.text('SELECT PROPERTY'), findsOneWidget);
        expect(find.text('CHOOSE PROPERTY'), findsOneWidget);
        // None of the CP-only additions leak into the shorter form.
        expect(find.text('FULL NAME'), findsNothing);
        expect(find.text('PHONE NUMBER'), findsNothing);
        expect(find.text('HANDLED BY (EMPLOYEE)'), findsNothing);
        expect(find.text('SITE VISIT'), findsNothing);
      });
    }
  });
}
