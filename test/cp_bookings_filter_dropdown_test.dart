import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/screens/cp/cp_my_bookings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// CP CLIENT BOOKINGS > the ALL PROJECTS filter.
///
/// The open menu read as a dirty grey slab floating over the header. The fill
/// was never the problem — this theme's canvasColor is already the same cream
/// as colorScheme.surface, so an unset `dropdownColor` rendered correctly. What
/// made it look broken was the selected row underneath a `Theme.focusColor`
/// overlay, 0x1F000000 by default: 12% black over cream. On top of that the
/// menu had square corners between two 16-radius boxes and the default
/// elevation 8.
///
/// The focus colour is the subtle part: on a touch device the framework paints
/// that row from `Theme.of(context).focusColor` (material/dropdown.dart:238)
/// and never reads `DropdownButton.focusColor`, which only reaches the closed
/// button (dropdown.dart:1768) — so setting the property would look like a fix
/// and change nothing. The theme has to be overridden above the button.
class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(baseUrl: 'http://localhost');

  @override
  Future<Response> getCpBookings() async => Response(
    requestOptions: RequestOptions(path: '/api/cp/bookings'),
    statusCode: 200,
    // Two projects, so the filter has something to filter by.
    data: {
      'status': true,
      'data': [
        {'_id': 'b1', 'projectName': 'Skai', 'clientName': 'A'},
        {'_id': 'b2', 'projectName': 'Ocean View', 'clientName': 'B'},
      ],
    },
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<ThemeData> pumpBookings(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(411, 900);
    addTearDown(tester.view.reset);

    final theme = M4Theme.lightTheme;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(_FakeApiClient())],
        child: MaterialApp(theme: theme, home: const CpMyBookingsScreen()),
      ),
    );
    // The load runs from a post-frame callback and awaits SharedPreferences
    // plus the fake client.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    return theme;
  }

  testWidgets('the filter menu is shaped like the row it drops from', (
    tester,
  ) async {
    await pumpBookings(tester);

    final dropdown = tester.widget<DropdownButton<String>>(
      find.byType(DropdownButton<String>),
    );
    // Square corners between the 16-radius search box and its own 16-radius
    // button.
    expect(dropdown.borderRadius, BorderRadius.circular(16));
    // 8 is the default, and its shadow fell across the header above.
    expect(dropdown.elevation, 3);
    // So a long project list cannot cover the page.
    expect(dropdown.menuMaxHeight, 280);
  });

  testWidgets('the menu fill is left to the theme, which is already cream', (
    tester,
  ) async {
    final theme = await pumpBookings(tester);

    // Recorded because it is easy to "fix" the menu colour that never needed
    // fixing: unset, the framework uses canvasColor, and here that is the same
    // cream as every surface on the page.
    expect(theme.canvasColor, theme.colorScheme.surface);
    expect(theme.canvasColor, const Color(0xFFF4EFE3));
  });

  testWidgets('the selected row is tinted, not slabbed in default grey', (
    tester,
  ) async {
    final theme = await pumpBookings(tester);

    // The framework reads this off the ambient theme, so the override has to be
    // an ancestor of the button for the menu to pick it up.
    final override = tester.widget<Theme>(
      find
          .ancestor(
            of: find.byType(DropdownButton<String>),
            matching: find.byType(Theme),
          )
          .first,
    );
    expect(
      override.data.focusColor,
      theme.colorScheme.onSurface.withValues(alpha: 0.06),
    );
    expect(override.data.focusColor, isNot(theme.focusColor));
  });
}
