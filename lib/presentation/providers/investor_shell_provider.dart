import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bottom tab index for [InvestorMainShell]: 0 Home, 1 Projects, 2 Support, 3 Profile.
final investorNavigationIndexProvider = StateProvider<int>((ref) => 0);
