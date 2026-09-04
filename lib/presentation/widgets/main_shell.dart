import 'package:m4_mobile/presentation/widgets/nav_swipe.dart';
import 'package:flutter/material.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';
import 'package:m4_mobile/presentation/screens/home/dashboard_screen.dart';
import 'package:m4_mobile/presentation/screens/projects/project_list_screen.dart';
import 'package:m4_mobile/presentation/screens/communities/community_list_screen.dart';
import 'package:m4_mobile/presentation/screens/custom_views/custom_views_screen.dart';
import 'package:m4_mobile/presentation/screens/notifications/notification_list_screen.dart';
import 'package:m4_mobile/presentation/screens/support/support_screen.dart';
import 'package:m4_mobile/presentation/screens/profile/profile_screen.dart';
import 'package:m4_mobile/presentation/screens/custom_views/my_custom_views_screen.dart';
import 'package:m4_mobile/presentation/screens/selection_logs/selection_logs_screen.dart';
import 'package:m4_mobile/presentation/widgets/navigation_pill.dart';
import 'package:m4_mobile/presentation/widgets/sidebar_menu.dart';
import 'package:m4_mobile/presentation/widgets/conditional_drawer.dart';
import 'package:m4_mobile/presentation/screens/content/content_hub_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final navigationProvider = StateProvider<int>((ref) => 0);
final previousNavigationProvider = StateProvider<int>((ref) => 0);

/// Where the system back button lands from tab [current].
///
/// Tabs 0-3 are the bottom bar, and back from those goes Home as it always
/// has. Tabs 4 and up are opened from the sidebar or a profile tile, so they
/// return to whatever opened them — [previous], recorded by the opener — and
/// only fall back to Home when that is missing or nonsensical. Sending those
/// to Home unconditionally is what made MY CUSTOM VIEWS, opened from the
/// profile, drop the user on the dashboard.
int backTargetIndex({
  required int current,
  required int previous,
  required int tabCount,
}) {
  if (current == 0) return 0;
  if (current >= 4 &&
      previous != current &&
      previous >= 0 &&
      previous < tabCount) {
    return previous;
  }
  return 0;
}

final inquiryScrollTriggerProvider = StateProvider<int>((ref) => 0);
final contentHubTypeProvider = StateProvider<String>((ref) => 'media');

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  bool _isDrawerOpen = false;

  final List<Widget> _screens = [
    const DashboardScreen(), // 0: Home
    const ProjectListScreen(), // 1: Compass (Projects)
    const SupportScreen(), // 2: MessageSquare (Support)
    const ProfileScreen(), // 3: User (Profile)
    const CommunityListScreen(), // 4: Sidebar only
    const NotificationListScreen(), // 5: Notifications (Sidebar)
    const CustomViewsScreen(), // 6: Custom Views (Sidebar)
    const MyCustomViewsScreen(), // 7: My Custom Views (Sidebar)
    const SelectionLogsScreen(), // 8: Personalisation Logs
    Consumer(
      builder: (context, ref, _) =>
          ContentHubScreen(type: ref.watch(contentHubTypeProvider)),
    ), // 9: Content Hub
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(navigationProvider);
    // Home (0) & Projects (1) are the deep-green "showcase" screens (white
    // typography); other tabs stay cream with green typography.
    Widget showcase(int i, Widget child) =>
        (i <= 1) ? Theme(data: M4Theme.darkTheme, child: child) : child;

    final ThemeData navTheme = currentIndex <= 1
        ? M4Theme.darkTheme
        : M4Theme.lightTheme;

    return PopScope(
      canPop: currentIndex == 0,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (currentIndex == 0) return;
        ref.read(navigationProvider.notifier).state = backTargetIndex(
          current: currentIndex,
          previous: ref.read(previousNavigationProvider),
          tabCount: _screens.length,
        );
      },
      child: Scaffold(
        extendBody: true,
        backgroundColor: navTheme.scaffoldBackgroundColor,
        drawer: const ConditionalDrawer(),
        onDrawerChanged: (isOpen) {
          setState(() {
            _isDrawerOpen = isOpen;
          });
        },
        body: Stack(
          children: [
            // The pill floats above the content, so reserve its footprint: the
            // screens add it as a bottom inset and the last card clears the nav.
            MediaQuery(
              data: MediaQuery.of(context).copyWith(
                padding: MediaQuery.of(context).padding.copyWith(
                  bottom: MediaQuery.of(context).padding.bottom + 80,
                ),
              ),
              child: NavSwipe(
                index: currentIndex,
                count: _screens.length,
                onIndexChanged: (i) =>
                    ref.read(navigationProvider.notifier).state = i,
                child: IndexedStack(
                  index: currentIndex,
                  children: [
                    for (int i = 0; i < _screens.length; i++)
                      showcase(i, _screens[i]),
                  ],
                ),
              ),
            ),
            if (!_isDrawerOpen)
              Align(
                alignment: Alignment.bottomCenter,
                child: Theme(
                  data: navTheme,
                  child: NavigationPill(
                    currentIndex: currentIndex,
                    onTap: (index) {
                      ref.read(navigationProvider.notifier).state = index;
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('Coming Soon: $title')),
    );
  }
}
