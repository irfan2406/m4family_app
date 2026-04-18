import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bottom tab index for [CpMainShell]: 0 Home, 1 Dashboard, 2 Tracker, 3 Hub, 4 Support, 5 Profile.
final cpNavigationIndexProvider = StateProvider<int>((ref) => 0);

/// Increment to scroll [CpHomeScreen] partner inquiry into view (sidebar quick action).
final cpInquiryScrollTriggerProvider = StateProvider<int>((ref) => 0);
