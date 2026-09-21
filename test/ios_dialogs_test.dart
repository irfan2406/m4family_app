import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m4_mobile/presentation/widgets/ios/ios_dialogs.dart';

/// showM4Dialog: Android is plain showDialog; iOS presents the same dialog
/// (or its native alert) the iOS way, with the same results and dismissal.
void main() {
  late Route<dynamic> shownRoute;
  late Object? result;

  Future<void> open(
    WidgetTester tester, {
    bool barrierDismissible = true,
    bool withAlert = true,
    ThemeData? localTheme,
  }) async {
    result = 'unset';
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (appContext) {
            final Widget opener = Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await showM4Dialog<bool>(
                    context: context,
                    barrierDismissible: barrierDismissible,
                    iosAlert: withAlert
                        ? (ctx) => M4IosAlert(
                            title: 'Log out',
                            message: 'Sign out?',
                            actions: [
                              M4IosAlertAction(
                                'Cancel',
                                isDefault: true,
                                onPressed: () => Navigator.pop(ctx, false),
                              ),
                              M4IosAlertAction(
                                'Log out',
                                isDestructive: true,
                                onPressed: () => Navigator.pop(ctx, true),
                              ),
                            ],
                          )
                        : null,
                    builder: (ctx) {
                      shownRoute = ModalRoute.of(ctx)!;
                      return AlertDialog(
                        title: Text(
                          'material dialog',
                          style: TextStyle(
                            color: Theme.of(ctx).colorScheme.primary,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Log out'),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: const Text('open'),
              ),
            );
            return Scaffold(
              body: localTheme == null
                  ? opener
                  : Theme(data: localTheme, child: opener),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  final android = TargetPlatformVariant.only(TargetPlatform.android);
  final iOS = TargetPlatformVariant.only(TargetPlatform.iOS);

  group('android', () {
    testWidgets('is the Material dialog, with the same results', (
      tester,
    ) async {
      await open(tester);
      expect(find.text('material dialog'), findsOneWidget);
      expect(find.byType(CupertinoAlertDialog), findsNothing);
      expect(shownRoute, isA<DialogRoute<bool>>());

      await tester.tap(find.text('Log out'));
      await tester.pumpAndSettle();
      expect(result, isTrue);
    }, variant: android);

    testWidgets('dismisses on an outside tap like showDialog', (tester) async {
      await open(tester);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.text('material dialog'), findsNothing);
      expect(result, isNull);
    }, variant: android);
  });

  group('iOS', () {
    testWidgets('a confirmation is the native alert, same answers', (
      tester,
    ) async {
      await open(tester);
      expect(find.byType(CupertinoAlertDialog), findsOneWidget);
      expect(find.text('material dialog'), findsNothing);
      expect(find.text('Log out'), findsNWidgets(2)); // title + button
      expect(find.text('Sign out?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(result, isFalse);

      await open(tester);
      await tester.tap(find.text('Log out').last);
      await tester.pumpAndSettle();
      expect(result, isTrue);
    }, variant: iOS);

    testWidgets('outside tap behaves exactly as on Android', (tester) async {
      await open(tester);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.byType(CupertinoAlertDialog), findsNothing);
      expect(result, isNull);

      await open(tester, barrierDismissible: false);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.byType(CupertinoAlertDialog), findsOneWidget);
    }, variant: iOS);

    testWidgets('a rich dialog keeps its content, presented the iOS way', (
      tester,
    ) async {
      await open(tester, withAlert: false);
      expect(find.text('material dialog'), findsOneWidget);
      expect(shownRoute, isA<CupertinoDialogRoute<bool>>());

      await tester.tap(find.text('Log out'));
      await tester.pumpAndSettle();
      expect(result, isTrue);
    }, variant: iOS);

    testWidgets('carries the local theme over, as showDialog does', (
      tester,
    ) async {
      const brand = Color(0xFF15271E);
      await open(
        tester,
        withAlert: false,
        localTheme: ThemeData(
          colorScheme: const ColorScheme.light(primary: brand),
        ),
      );
      final title = tester.widget<Text>(find.text('material dialog'));
      expect(title.style?.color, brand);
    }, variant: iOS);
  });
}
