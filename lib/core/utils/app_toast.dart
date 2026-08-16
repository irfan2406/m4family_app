import 'package:flutter/material.dart';

/// Root messenger key so toasts can be shown from anywhere — including places
/// with no [BuildContext] (global error handlers, zone guards). Wired into
/// [MaterialApp.router] via `scaffoldMessengerKey`.
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// Centralised, consistently-styled app toasts.
///
/// The only globally-enforced style here is [AppToast.error]: a red snackbar
/// with white text used for every error / failure / validation / API / network
/// / auth / unexpected-exception path. Success / info helpers are provided for
/// convenience and do NOT replace any existing success/info snackbars.
class AppToast {
  AppToast._();

  /// Error red with strong contrast against white text.
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color successColor = Color(0xFF2E7D32);
  static const Color infoColor = Color(0xFF323232);

  // Collapse rapid duplicate error toasts (e.g. a global handler and a screen
  // both reacting to the same failure) into one.
  static DateTime? _lastAt;
  static String? _lastMsg;

  /// Red error toast. Safe to call from anywhere, with or without a context.
  static void error(String? message) {
    final msg = (message == null || message.trim().isEmpty)
        ? 'Something went wrong. Please try again.'
        : message.trim();

    final now = DateTime.now();
    if (_lastMsg == msg &&
        _lastAt != null &&
        now.difference(_lastAt!).inMilliseconds < 900) {
      _lastAt = now;
      return;
    }
    _lastAt = now;
    _lastMsg = msg;

    _show(msg, background: errorColor, icon: Icons.error_outline);
  }

  static void success(String message) =>
      _show(message, background: successColor, icon: Icons.check_circle_outline);

  static void info(String message) =>
      _show(message, background: infoColor, icon: Icons.info_outline);

  static void _show(
    String message, {
    required Color background,
    required IconData icon,
  }) {
    void present() {
      final messenger = rootScaffoldMessengerKey.currentState;
      if (messenger == null) return;
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: background,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
    }

    // Scheduling post-frame makes this safe to call during build / error phases.
    WidgetsBinding.instance.addPostFrameCallback((_) => present());
  }
}
