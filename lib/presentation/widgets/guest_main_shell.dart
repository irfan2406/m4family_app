import 'package:m4_mobile/presentation/widgets/guest_sidebar_menu.dart';
import 'package:m4_mobile/presentation/widgets/nav_swipe.dart';
import 'package:m4_mobile/presentation/widgets/nav_style.dart';
import 'package:m4_mobile/presentation/widgets/m4_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:m4_mobile/presentation/screens/home/guest_dashboard_screen.dart';
import 'package:m4_mobile/presentation/screens/projects/project_list_screen.dart';
import 'package:m4_mobile/presentation/screens/about/about_screen.dart';
import 'package:m4_mobile/presentation/screens/careers/careers_screen.dart';
import 'package:m4_mobile/presentation/screens/support/contact_screen.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final guestNavigationProvider = StateProvider<int>((ref) => 0);
final drawerOpenProvider = StateProvider<bool>((ref) => false);

// Bumped when the user taps "Enquiry" in the menu; the guest home watches this
// and scrolls to its "Register Your Interest" form.
final scrollToRegisterProvider = StateProvider<int>((ref) => 0);

class GuestMainShell extends ConsumerWidget {
  const GuestMainShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(guestNavigationProvider);
    final isDrawerOpen = ref.watch(drawerOpenProvider);
    // The keyboard covers the floating nav pill, so while it is up the pill is
    // hidden and the space it reserves is given back to the content.
    final bool keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    // Home (0) & Properties (1) are the deep-green "showcase" screens (white
    // typography); the info tabs stay cream with green typography.
    Widget showcase(Widget child) =>
        Theme(data: M4Theme.darkTheme, child: child);

    final List<Widget> screens = [
      showcase(const GuestDashboardScreen()), // 0: Home     — green
      showcase(
        const ProjectListScreen(guestMode: true, embedded: true),
      ), // 1: Projects — green
      const AboutScreen(embedded: true), // 2: About    — cream
      const CareersScreen(embedded: true), // 3: Careers  — cream
      const ContactScreen(embedded: true), // 4: Contact  — cream
    ];

    // Nav pill follows the active tab's surface: green on the showcase tabs,
    // cream on the info tabs, navy in dark mode.
    final ThemeData navTheme = currentIndex <= 1
        ? M4Theme.darkTheme
        : M4Theme.lightTheme;

    return Scaffold(
      backgroundColor: navTheme.scaffoldBackgroundColor,
      drawer: const GuestSidebarMenu(),
      onDrawerChanged: (isOpen) =>
          ref.read(drawerOpenProvider.notifier).state = isOpen,
      body: Stack(
        children: [
          // The pill floats above the content, so tell the screens how much
          // room it takes: their scroll views add this as bottom inset and the
          // last card can scroll clear of the nav instead of hiding under it.
          //
          // With the keyboard up the pill is hidden, so the reserve is dropped
          // — otherwise a focused text field sits ~92px above the keyboard with
          // dead space under it.
          MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: MediaQuery.of(context).padding.copyWith(
                bottom: keyboardOpen
                    ? MediaQuery.of(context).padding.bottom
                    : MediaQuery.of(context).padding.bottom + _navFootprint,
              ),
            ),
            child: NavSwipe(
              index: currentIndex,
              count: screens.length,
              onIndexChanged: (i) =>
                  ref.read(guestNavigationProvider.notifier).state = i,
              child: IndexedStack(index: currentIndex, children: screens),
            ),
          ),
          if (!isDrawerOpen && !keyboardOpen)
            Align(
              alignment: Alignment.bottomCenter,
              // Under the active tab's surface theme, so the bar knows whether
              // it sits on a green showcase screen (translucent white disc) or
              // a cream info screen (solid green disc).
              child: Theme(
                data: navTheme,
                child: M4BottomNav(
                  icons: _guestIcons,
                  currentIndex: currentIndex,
                  onTap: (index) =>
                      ref.read(guestNavigationProvider.notifier).state = index,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Guest tab glyphs, in tab order. The bar itself is M4BottomNav — the one
// component every portal renders.
const List<IconData> _guestIcons = <IconData>[
  LucideIcons.home,
  LucideIcons.building2,
  LucideIcons.info,
  LucideIcons.briefcase,
  LucideIcons.headphones,
];

/// Height the floating pill occupies: the bar plus its bottom float margin.
const double _navFootprint = M4Nav.height + M4Nav.bottomInset + 4;
