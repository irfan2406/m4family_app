import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/widgets/m4_filter_dropdown.dart';

/// CP SUCCESS PIPELINE > the status filter (ALL / PENDING / …).
void main() {
  testWidgets('opens a menu of every status and reports the pick', (
    tester,
  ) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    var value = 'All';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topRight,
            child: StatefulBuilder(
              builder: (context, setState) => M4FilterDropdown<String>(
                value: value,
                options: const [
                  M4FilterOption(value: 'All', label: 'All', color: Colors.green),
                  M4FilterOption(
                    value: 'Pending',
                    label: 'Pending',
                    color: Colors.amber,
                  ),
                  M4FilterOption(
                    value: 'Cancelled',
                    label: 'Cancelled',
                    color: Colors.red,
                  ),
                ],
                onChanged: (v) => setState(() => value = v),
              ),
            ),
          ),
        ),
      ),
    );

    // Closed: the pill shows the current choice.
    expect(find.text('ALL'), findsOneWidget);
    expect(find.text('PENDING'), findsNothing);

    await tester.tap(find.text('ALL'));
    await tester.pumpAndSettle();
    expect(find.text('FILTER BY STATUS'), findsOneWidget);
    expect(find.text('PENDING'), findsOneWidget);
    expect(find.text('CANCELLED'), findsOneWidget);
    // The current choice carries the check.
    expect(find.byIcon(LucideIcons.check), findsOneWidget);

    await tester.tap(find.text('PENDING'));
    await tester.pumpAndSettle();
    expect(value, 'Pending');
    expect(find.text('FILTER BY STATUS'), findsNothing);
    expect(find.text('PENDING'), findsOneWidget); // now on the pill
    expect(tester.takeException(), isNull);
  });
}
