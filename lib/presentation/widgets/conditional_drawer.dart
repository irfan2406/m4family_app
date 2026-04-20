import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/widgets/sidebar_menu.dart';
import 'package:m4_mobile/presentation/widgets/guest_sidebar_menu.dart';
import 'package:m4_mobile/presentation/widgets/cp_sidebar_menu.dart';

class ConditionalDrawer extends ConsumerWidget {
  const ConditionalDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    
    final role = authState.user?['role']?.toString().toLowerCase();
    if (role == 'cp') return const CpSidebarMenu();

    // If user is authenticated, show the User Sidebar.
    // If guest (user is null), show the Guest Sidebar.
    if (authState.user != null) {
      return const SidebarMenu();
    } else {
      return const GuestSidebarMenu();
    }
  }
}
