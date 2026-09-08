import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/providers/project_provider.dart';
import 'package:m4_mobile/presentation/screens/investor/investor_referral_screen.dart';

/// Investor REFERRAL & REWARDS > NEW REFERRAL > SELECT PROJECT.
///
/// The open menu looked nothing like the sheet holding it: square corners
/// against 16-radius fields, a flat grey slab under the first row, and the
/// default elevation 8 dropping a heavy shadow across the form beneath.
///
/// The grey row is the part worth pinning down. On a touch device the framework
/// paints the selected item with `Theme.of(context).focusColor` directly
/// (material/dropdown.dart:238) and never consults `DropdownButton.focusColor`,
/// which only reaches the closed button (dropdown.dart:1768) — so the property
/// is not the fix and setting it would look right while changing nothing. The
/// theme has to be overridden for this subtree instead, which is what these
/// assert.
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

  testWidgets('the project menu is styled like the sheet around it', (
    tester,
  ) async {
    await openReferralForm(tester);

    final dropdown = tester.widget<DropdownButton<String>>(
      find.byType(DropdownButton<String>),
    );
    // Square corners against 16-radius input boxes.
    expect(dropdown.borderRadius, BorderRadius.circular(16));
    // Default 8 threw a heavy shadow over the fields below.
    expect(dropdown.elevation, 3);
    // A longer project list used to be free to cover the whole form.
    expect(dropdown.menuMaxHeight, 280);
  });

  testWidgets('the selected row is tinted, not slabbed in default grey', (
    tester,
  ) async {
    await openReferralForm(tester);

    // The framework reads this off the ambient theme, so the override has to be
    // an ancestor of the button for the menu to pick it up.
    final theme = tester.widget<Theme>(
      find
          .ancestor(
            of: find.byType(DropdownButton<String>),
            matching: find.byType(Theme),
          )
          .first,
    );
    // The ink the input boxes are filled with — not Material's default grey.
    expect(
      theme.data.focusColor,
      const Color(0xFF0C312B).withValues(alpha: 0.06),
    );
    expect(theme.data.focusColor, isNot(ThemeData().focusColor));
  });
}
