import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:m4_mobile/presentation/widgets/wheel_date_time_picker.dart';

/// Every date field in the app — Date of Birth included — opens the same
/// chooser: the bottom sheet with a "SELECT DATE & TIME" title, the
/// Day/Month/Year *and* Hour/Minute/AM-PM wheels, and CANCEL / CONFIRM.
/// Before this, Date of Birth used two other sheets: the same one with the
/// time columns hidden, and a separate widget with larger serif wheels.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> openChooser(WidgetTester tester, {required DateTime floor}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (ctx) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showM4DateTimeSheet(
                  ctx,
                  initial: floor,
                  minDate: floor,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('the chooser is the booking sheet, time columns and all', (
    tester,
  ) async {
    await openChooser(tester, floor: DateTime(2026, 9, 1, 14, 30));

    expect(find.text('SELECT DATE & TIME'), findsOneWidget);
    expect(find.text('SELECT DATE'), findsNothing);
    expect(find.text('CANCEL'), findsOneWidget);
    expect(find.text('CONFIRM'), findsOneWidget);

    // The time half of the sheet: an AM/PM column and the hour:minute colon.
    expect(find.text('AM'), findsOneWidget);
    expect(find.text('PM'), findsOneWidget);
    expect(find.text(':'), findsOneWidget);

    // The date half, opened on the floor.
    expect(find.text('SEP'), findsOneWidget);
    expect(find.text('2026'), findsOneWidget);
  });

  testWidgets('CONFIRM returns the floor when nothing is scrolled', (
    tester,
  ) async {
    DateTime? result;
    final floor = DateTime(2026, 9, 1, 14, 30);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (ctx) => Scaffold(
            body: Center(
              child: ElevatedButton(
                // An initial well before the floor — a saved birthdate, say.
                onPressed: () async => result = await showM4DateTimeSheet(
                  ctx,
                  initial: DateTime(2000, 7, 6),
                  minDate: floor,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CONFIRM'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.isBefore(floor), isFalse);
    expect(result, floor);
  });
}
