import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/core/platform/m4_platform.dart';
import 'package:m4_mobile/core/theme/app_theme.dart';

/// Shows a bottom sheet: [showModalBottomSheet] on Android, the iOS sheet
/// presentation on iOS.
///
/// Android: exactly `showModalBottomSheet(context, builder, …)` with the same
/// arguments the call site always passed — nothing about the Android sheet
/// changes.
///
/// iOS: the same M4 sheet rises with the motion and dimming iOS gives its own
/// modal popups. Or, when [iosActionSheet] is given, the native iOS action
/// sheet it builds — for sheets that are just a list of choices.
Future<T?> showM4Sheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  WidgetBuilder? iosActionSheet,
  Color? backgroundColor,
  ShapeBorder? shape,
  bool isScrollControlled = false,
}) {
  if (!M4Platform.isIOS) {
    return showModalBottomSheet<T>(
      context: context,
      builder: builder,
      backgroundColor: backgroundColor,
      shape: shape,
      isScrollControlled: isScrollControlled,
    );
  }

  final Color dim = CupertinoDynamicColor.resolve(
    kCupertinoModalBarrierColor,
    context,
  );

  if (iosActionSheet != null) {
    // Same navigator the Android sheet uses, and the same themes.
    final NavigatorState navigator = Navigator.of(context);
    final CapturedThemes themes = InheritedTheme.capture(
      from: context,
      to: navigator.context,
    );
    return showCupertinoModalPopup<T>(
      context: context,
      useRootNavigator: false,
      barrierColor: dim,
      builder: (popupContext) => themes.wrap(Builder(builder: iosActionSheet)),
    );
  }

  return showModalBottomSheet<T>(
    context: context,
    builder: builder,
    backgroundColor: backgroundColor,
    shape: shape,
    isScrollControlled: isScrollControlled,
    barrierColor: dim,
    // The timing and curves of iOS's own modal popups (CupertinoModalPopupRoute).
    sheetAnimationStyle: AnimationStyle(
      duration: const Duration(milliseconds: 335),
      reverseDuration: const Duration(milliseconds: 335),
      curve: Curves.linearToEaseOut,
      reverseCurve: Curves.linearToEaseOut.flipped,
    ),
  );
}

/// One choice of an [M4IosActionSheet].
class M4IosSheetAction {
  const M4IosSheetAction(
    this.label, {
    required this.onPressed,
    this.selected = false,
  });

  final String label;
  final VoidCallback onPressed;

  /// The current choice: drawn bold with a check, as the M4 sheet marks it.
  final bool selected;
}

/// iOS: the native action sheet, carrying a sheet's own title and choices.
/// Cancel closes it without choosing — the same as dismissing the M4 sheet.
class M4IosActionSheet extends StatelessWidget {
  const M4IosActionSheet({
    super.key,
    this.title,
    this.message,
    required this.actions,
    this.brightness,
  });

  final String? title;
  final String? message;
  final List<M4IosSheetAction> actions;

  /// Forces a light or dark sheet, for sheets whose Android design fixes its
  /// tones rather than following the ambient theme. Null follows the theme.
  final Brightness? brightness;

  @override
  Widget build(BuildContext context) {
    if (brightness == null) return _sheet(context);
    // A forced tone brings its own M4 primary, as [M4IosAlert] does.
    return CupertinoTheme(
      data: CupertinoTheme.of(context).copyWith(
        brightness: brightness,
        primaryColor: brightness == Brightness.dark
            ? M4Theme.darkPrimary
            : M4Theme.lightPrimary,
      ),
      child: Builder(builder: _sheet),
    );
  }

  Widget _sheet(BuildContext context) {
    final Color tint = CupertinoTheme.of(context).primaryColor;
    return CupertinoActionSheet(
      title: title == null ? null : Text(title!),
      message: message == null ? null : Text(message!),
      actions: [
        for (final action in actions)
          CupertinoActionSheetAction(
            onPressed: action.onPressed,
            isDefaultAction: action.selected,
            child: action.selected
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(child: Text(action.label)),
                      const SizedBox(width: 8),
                      Icon(LucideIcons.check, size: 18, color: tint),
                    ],
                  )
                : Text(action.label),
          ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
    );
  }
}
