import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';

/// Loading spinners are brand green everywhere (they used to be gold, which
/// read as yellow): deep green on cream screens, light tagline green on the
/// deep-green showcase screens (investor/customer home, project list).
void main() {
  Future<Color?> spinnerColor(WidgetTester tester, ThemeData theme) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Builder(
          builder: (context) => Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                M4Theme.loaderGreen(context),
              ),
            ),
          ),
        ),
      ),
    );
    final w = tester.widget<CircularProgressIndicator>(
      find.byType(CircularProgressIndicator),
    );
    return w.valueColor?.value;
  }

  testWidgets('cream screens get the deep brand green', (tester) async {
    expect(
      await spinnerColor(tester, M4Theme.lightTheme),
      M4Theme.deepGreen,
    );
  });

  testWidgets('deep-green screens get the light tagline green', (
    tester,
  ) async {
    expect(
      await spinnerColor(tester, M4Theme.darkTheme),
      M4Theme.taglineAccent,
    );
  });

  test('never the old gold', () {
    expect(M4Theme.deepGreen, isNot(M4Theme.gold));
    expect(M4Theme.taglineAccent, isNot(M4Theme.gold));
  });
}
