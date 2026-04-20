import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m4_mobile/presentation/providers/cp_shell_provider.dart';
import 'package:m4_mobile/presentation/widgets/cp_main_shell.dart';

/// Ensures CP bottom navigation is visible by entering the CP shell
/// and selecting the requested tab index.
class CpShellEntryScreen extends ConsumerStatefulWidget {
  final int index;
  const CpShellEntryScreen({super.key, required this.index});

  @override
  ConsumerState<CpShellEntryScreen> createState() => _CpShellEntryScreenState();
}

class _CpShellEntryScreenState extends ConsumerState<CpShellEntryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cpNavigationIndexProvider.notifier).state = widget.index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return const CpMainShell();
  }
}

