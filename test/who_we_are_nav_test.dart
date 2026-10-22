import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/widgets/cp_bottom_nav.dart';
import 'package:m4_mobile/presentation/widgets/guest_main_shell.dart';
import 'package:m4_mobile/presentation/widgets/investor_bottom_nav.dart';
import 'package:m4_mobile/presentation/widgets/main_shell.dart';
import 'package:m4_mobile/presentation/widgets/navigation_pill.dart';

/// WHO WE ARE on every portal's bottom bar, as the guest portal has it.
///
/// It is a new tab at the END of each shell (so no existing tab index moves),
/// but it sits mid-bar; the bars map bar positions to shell tabs.
void main() {
  Future<List<int>> tapEach(
    WidgetTester tester,
    Widget Function(ValueChanged<int> onTap) bar,
  ) async {
    final taps = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(bottomNavigationBar: bar(taps.add)),
      ),
    );
    final icons = find.descendant(
      of: find.byType(Scaffold),
      matching: find.byType(Icon),
    );
    final count = tester.widgetList(icons).length;
    for (var i = 0; i < count; i++) {
      await tester.tap(icons.at(i));
      await tester.pump(const Duration(milliseconds: 300));
    }
    return taps;
  }

  List<IconData> barIcons(WidgetTester tester) => tester
      .widgetList<Icon>(find.byType(Icon))
      .map((i) => i.icon!)
      .toList();

  testWidgets('guest bar already carries it (unchanged)', (tester) async {
    expect(guestNavIcons[2], LucideIcons.info);
  });

  testWidgets('customer: Home, Explore, WHO WE ARE, Messages, Profile', (
    tester,
  ) async {
    final taps = await tapEach(
      tester,
      (onTap) => NavigationPill(currentIndex: 0, onTap: onTap),
    );
    expect(barIcons(tester), [
      LucideIcons.home,
      LucideIcons.compass,
      LucideIcons.info,
      LucideIcons.messageSquare,
      LucideIcons.user,
    ]);
    // Existing tabs keep their indices; WHO WE ARE is the shell's tab 10.
    expect(taps, [0, 1, NavigationPill.whoWeAreTab, 2, 3]);
    expect(NavigationPill.whoWeAreTab, 10);
  });

  testWidgets('investor: Home, Projects, WHO WE ARE, Support, Profile', (
    tester,
  ) async {
    final taps = await tapEach(
      tester,
      (onTap) => InvestorBottomNav(currentIndex: 0, onTap: onTap),
    );
    expect(barIcons(tester)[2], LucideIcons.info);
    expect(taps, [0, 1, InvestorBottomNav.whoWeAreTab, 2, 3]);
    expect(InvestorBottomNav.whoWeAreTab, 4);
  });

  testWidgets(
    'CP: Home, Tracker, Projects, WHO WE ARE, Support, Profile — six fit',
    (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(360, 800);
      addTearDown(tester.view.reset);
      final taps = await tapEach(
        tester,
        (onTap) => CpBottomNav(currentIndex: 0, onTap: onTap),
      );
      expect(barIcons(tester)[3], LucideIcons.info);
      expect(taps, [0, 1, 2, CpBottomNav.whoWeAreTab, 3, 4]);
      expect(CpBottomNav.whoWeAreTab, 5);
      // Every icon lies on screen, none clipped off the right edge.
      for (final icon in tester.widgetList<Icon>(find.byType(Icon))) {
        final r = tester.getRect(find.byWidget(icon));
        expect(r.left, greaterThanOrEqualTo(0));
        expect(r.right, lessThanOrEqualTo(360));
      }
      expect(tester.takeException(), isNull);
    },
  );

  test('customer: back from the WHO WE ARE tab goes Home', () {
    expect(
      backTargetIndex(
        current: NavigationPill.whoWeAreTab,
        previous: 7,
        tabCount: 11,
      ),
      0,
    );
  });
}
