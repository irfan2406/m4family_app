import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/providers/project_provider.dart';
import 'package:m4_mobile/presentation/screens/investor/investor_referral_screen.dart';

/// Investor REFERRAL & REWARDS > NEW REFERRAL > SELECT PROJECT.
///
/// The stock DropdownButton opened its menu ON TOP of the field, hiding the
/// SELECT PROJECT label and the field itself. The menu now opens just below
/// the field, exactly as wide as it, with the chosen project ticked — the same
/// menu the project pages use for PREFERRED CONFIGURATION.
class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(baseUrl: 'http://localhost');

  Response _ok(String path, dynamic data) => Response(
    requestOptions: RequestOptions(path: path),
    statusCode: 200,
    data: {'status': true, 'data': data},
  );

  @override
  Future<Response> getInvestorWallet() async =>
      _ok('/api/investor/wallet', {'balance': 0});

  @override
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async => _ok(path, const []);
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  // The three the screenshot showed.
  const projects = <dynamic>[
    {'_id': 'p1', 'title': 'Skai'},
    {'_id': 'p2', 'title': 'Ocean View'},
    {'_id': 'p3', 'title': 'Clédor'},
  ];

  Future<void> openReferralForm(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(411, 1200);
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: '/investor/referral',
      routes: [
        GoRoute(
          path: '/investor/referral',
          builder: (_, _) => const InvestorReferralScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(_FakeApiClient()),
          projectsProvider.overrideWith((ref) async => projects),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    await tester.tap(find.text('REFER FRIEND'));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    // The sheet's own subtitle — its title is 'NEW\nREFERRAL', one Text with a
    // hard break in it.
    expect(find.text('REFER & EARN REWARDS'), findsOneWidget);
  }

  Finder menuItem(String title) => find.descendant(
    of: find.byType(PopupMenuItem<String>),
    matching: find.text(title),
  );

  testWidgets('the menu opens below the field, as wide as it', (
    tester,
  ) async {
    await openReferralForm(tester);
    final field = find.text('SELECT PROJECT').last;
    final fieldBox = tester.getRect(
      find.ancestor(of: field, matching: find.byType(Container)).first,
    );

    await tester.tap(field);
    await tester.pumpAndSettle();

    for (final t in ['SKAI', 'OCEAN VIEW', 'CLÉDOR']) {
      expect(menuItem(t), findsOneWidget, reason: '$t is offered');
    }
    // The field and its label stay visible: the menu starts below the field.
    final first = tester.getRect(find.byType(PopupMenuItem<String>).first);
    expect(first.top, greaterThanOrEqualTo(fieldBox.bottom));
    // Same width as the field (within the item's own inset).
    final menu = tester.getRect(
      find.ancestor(
        of: find.byType(PopupMenuItem<String>).first,
        matching: find.byType(Material),
      ).first,
    );
    expect(menu.width, closeTo(fieldBox.width, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('picking a project fills the field and ticks it', (
    tester,
  ) async {
    await openReferralForm(tester);
    await tester.tap(find.text('SELECT PROJECT').last);
    await tester.pumpAndSettle();
    await tester.tap(menuItem('OCEAN VIEW'));
    await tester.pumpAndSettle();

    // Closed menu; the field now shows the choice.
    expect(find.byType(PopupMenuItem<String>), findsNothing);
    expect(find.text('OCEAN VIEW'), findsOneWidget);

    // Re-opened: the chosen project carries the tick.
    await tester.tap(find.text('OCEAN VIEW'));
    await tester.pumpAndSettle();
    final ticked = find.ancestor(
      of: find.byIcon(LucideIcons.check),
      matching: find.byType(PopupMenuItem<String>),
    );
    expect(ticked, findsOneWidget);
    expect(
      find.descendant(of: ticked, matching: find.text('OCEAN VIEW')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
