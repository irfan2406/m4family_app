import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bottom tab index for [InvestorMainShell]: 0 Home, 1 Projects, 2 Support, 3 Profile.
final investorNavigationIndexProvider = StateProvider<int>((ref) => 0);

/// Bumped by the sidebar "Enquiry" quick action; the investor home listens and
/// scrolls its "Register Your Interest" form into view.
final investorInquiryScrollTriggerProvider = StateProvider<int>((ref) => 0);
