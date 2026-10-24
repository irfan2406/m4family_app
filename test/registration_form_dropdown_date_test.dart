import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:m4_mobile/presentation/widgets/project_registration_form.dart';

/// REGISTER YOUR INTEREST (customer, investor and guest project pages):
/// the configuration is a dropdown, and the date opens the app's own
/// date & time sheet, not Android's calendar dialog.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> pump(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(411, 2000);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ProjectRegistrationForm(onSubmit: (_) async => true),
          ),
        ),
      ),
    );
  }

  testWidgets('configuration is one dropdown field, not a row of buttons', (
    tester,
  ) async {
    await pump(tester);

    // Closed: only the chosen configuration shows.
    expect(find.text('1 BHK'), findsOneWidget);
    expect(find.text('3 BHK'), findsNothing);
    expect(find.text('PENTHOUSE'), findsNothing);

    await tester.tap(find.text('1 BHK'));
    await tester.pumpAndSettle();
    for (final c in ['2 BHK', '3 BHK', '4 BHK', 'PENTHOUSE']) {
      expect(find.text(c), findsOneWidget, reason: '$c is offered');
    }

    await tester.tap(find.text('3 BHK'));
    await tester.pumpAndSettle();
    expect(find.text('3 BHK'), findsOneWidget);
    expect(find.text('PENTHOUSE'), findsNothing, reason: 'menu closed');
    expect(tester.takeException(), isNull);
  });

  testWidgets('date & time opens the app sheet, from tomorrow', (tester) async {
    await pump(tester);

    await tester.tap(find.text('Select date & time'));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsNothing);
    expect(find.text('SELECT DATE & TIME'), findsOneWidget);

    // CONFIRM without scrolling: the earliest allowed slot is tomorrow.
    await tester.tap(find.text('CONFIRM'));
    await tester.pumpAndSettle();
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    expect(
      find.textContaining(
        '${const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][tomorrow.weekday - 1]},',
      ),
      findsOneWidget,
    );
    expect(find.text('Select date & time'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
