import 'package:flutter/material.dart';
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
import 'package:flutter_riverpod/flutter_riverpod.dart';

final navigationProvider = StateProvider<int>((ref) => 0);
final inquiryScrollTriggerProvider = StateProvider<int>((ref) => 0);

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {

  final List<Widget> _screens = [
    const DashboardScreen(), // 0: Home
    const ProjectListScreen(), // 1: Compass (Projects)
    const SupportScreen(), // 2: MessageSquare (Support)
    const ProfileScreen(), // 3: User (Profile)
    const CommunityListScreen(), // 4: Sidebar only
    const NotificationListScreen(), // 5: Notifications (Sidebar)
    CustomViewsScreen(), // 6: Custom Views (Sidebar)
    MyCustomViewsScreen(), // 7: My Custom Views (Sidebar)
    const SelectionLogsScreen(), // 8: Personalisation Logs
  ];



  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(navigationProvider);
    
    return PopScope(
      canPop: currentIndex == 0,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (currentIndex != 0) {
          ref.read(navigationProvider.notifier).state = 0;
        }
      },
      child: Scaffold(
        drawer: const SidebarMenu(),
        body: Stack(
          children: [
            IndexedStack(
              index: currentIndex,
              children: _screens,
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: NavigationPill(
                currentIndex: currentIndex,
                onTap: (index) {
                  ref.read(navigationProvider.notifier).state = index;
                },
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
