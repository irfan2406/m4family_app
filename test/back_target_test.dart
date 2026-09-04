import 'package:flutter_test/flutter_test.dart';
import 'package:m4_mobile/presentation/widgets/main_shell.dart';

/// Customer shell: where the system back button lands.
///
/// MY CUSTOM VIEWS opens from the profile as tab 7, and the shell's PopScope
/// sent every non-zero tab to 0 — so back dropped the user on the dashboard
/// instead of the profile. Tabs 4+ now return to whatever opened them.
void main() {
  const tabCount = 10;

  int target(int current, int previous) =>
      backTargetIndex(current: current, previous: previous, tabCount: tabCount);

  group('sidebar / profile tabs return to their origin', () {
    test('My Custom Views opened from the profile goes back to the profile', () {
      // 7 = My Custom Views, 3 = Profile. This is the reported case.
      expect(target(7, 3), 3);
    });

    test('opened from Home, back goes Home', () {
      expect(target(7, 0), 0);
    });

    test('the wizard opened from My Custom Views goes back to it', () {
      // 6 = Custom Views wizard, 7 = My Custom Views.
      expect(target(6, 7), 7);
    });
  });

  group('the bottom bar is unchanged', () {
    for (final tab in [1, 2, 3]) {
      test('tab $tab still goes Home whatever the origin', () {
        expect(target(tab, 7), 0);
        expect(target(tab, 0), 0);
      });
    }

    test('Home itself stays Home', () {
      expect(target(0, 7), 0);
    });
  });

  group('a nonsensical origin falls back to Home', () {
    test('an origin equal to the current tab would be a no-op', () {
      expect(target(7, 7), 0);
    });

    test('out-of-range origins are ignored', () {
      expect(target(7, -1), 0);
      expect(target(7, tabCount), 0);
      expect(target(7, 999), 0);
    });
  });
}
