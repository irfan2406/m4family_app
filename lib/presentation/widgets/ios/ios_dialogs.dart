import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:m4_mobile/core/platform/m4_platform.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';

/// Shows a dialog: [showDialog] on Android, the iOS dialog presentation on iOS.
///
/// Android: exactly `showDialog(context, builder, …)` with the same arguments
/// the call site always passed — nothing about the Android dialog changes.
///
/// iOS: the same dialog arrives the iOS way — the alert's spring zoom and
/// fade, and the iOS dimming — or, when [iosAlert] is given, the native iOS
/// alert that it builds. Themes are carried over and the safe area applied
/// just as [showDialog] does, so the content colours and lays out the same.
/// Tapping outside dismisses on iOS exactly when it does on Android.
Future<T?> showM4Dialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  WidgetBuilder? iosAlert,
  bool barrierDismissible = true,
  Color? barrierColor,
  bool useSafeArea = true,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
}) {
  if (!M4Platform.isIOS) {
    return showDialog<T>(
      context: context,
      builder: builder,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      useSafeArea: useSafeArea,
      useRootNavigator: useRootNavigator,
      routeSettings: routeSettings,
    );
  }

  final NavigatorState navigator = Navigator.of(
    context,
    rootNavigator: useRootNavigator,
  );
  final CapturedThemes themes = InheritedTheme.capture(
    from: context,
    to: navigator.context,
  );
  final WidgetBuilder content = iosAlert ?? builder;
  return navigator.push<T>(
    CupertinoDialogRoute<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      settings: routeSettings,
      builder: (dialogContext) {
        Widget dialog = themes.wrap(Builder(builder: content));
        if (useSafeArea) dialog = SafeArea(child: dialog);
        return dialog;
      },
    ),
  );
}

/// One button of an [M4IosAlert].
class M4IosAlertAction {
  const M4IosAlertAction(
    this.label, {
    required this.onPressed,
    this.isDestructive = false,
    this.isDefault = false,
  });

  final String label;
  final VoidCallback onPressed;

  /// Drawn in the M4 destructive coral.
  final bool isDestructive;

  /// Drawn in the heavier weight iOS gives the preferred choice.
  final bool isDefault;
}

/// iOS: the native alert, carrying a dialog's own title, message and buttons.
///
/// Buttons take the M4 palette rather than the iOS system blue and red: the
/// theme's primary green for ordinary choices, the M4 coral for destructive
/// ones.
class M4IosAlert extends StatelessWidget {
  const M4IosAlert({
    super.key,
    required this.title,
    this.message,
    required this.actions,
    this.brightness,
  });

  final String title;
  final String? message;
  final List<M4IosAlertAction> actions;

  /// Forces a light or dark alert, for dialogs whose Android design fixes its
  /// tones rather than following the ambient theme. Null follows the theme.
  final Brightness? brightness;

  @override
  Widget build(BuildContext context) {
    final Color destructive = Theme.of(context).colorScheme.error;
    final Widget alert = CupertinoAlertDialog(
      title: Text(title),
      content: message == null ? null : Text(message!),
      actions: [
        for (final action in actions)
          CupertinoDialogAction(
            onPressed: action.onPressed,
            isDefaultAction: action.isDefault,
            isDestructiveAction: action.isDestructive,
            textStyle: action.isDestructive
                ? TextStyle(color: destructive)
                : null,
            child: Text(action.label),
          ),
      ],
    );
    if (brightness == null) return alert;
    // A forced tone brings its own M4 primary, or cream buttons could land
    // on a light alert opened from a dark screen.
    return CupertinoTheme(
      data: CupertinoTheme.of(context).copyWith(
        brightness: brightness,
        primaryColor: brightness == Brightness.dark
            ? M4Theme.darkPrimary
            : M4Theme.lightPrimary,
      ),
      child: alert,
    );
  }
}
