import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/widgets/ios/ios_sheets.dart';

/// showM4Sheet: Android is plain showModalBottomSheet; iOS raises the same
/// sheet the iOS way, or — for a list of choices — the native action sheet,
/// running the same callbacks.
void main() {
  final android = TargetPlatformVariant.only(TargetPlatform.android);
  final iOS = TargetPlatformVariant.only(TargetPlatform.iOS);

  late Route<dynamic> shownRoute;
  late List<String> picked;
  late Object? result;

  Future<void> open(WidgetTester tester, {bool withActionSheet = true}) async {
    picked = [];
    result = 'unset';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showM4Sheet<String>(
                  context: context,
                  backgroundColor: Colors.transparent,
                  iosActionSheet: withActionSheet
                      ? (ctx) => M4IosActionSheet(
                          title: 'Update status',
                          actions: [
                            for (final s in ['NEW', 'LOST'])
                              M4IosSheetAction(
                                s,
                                selected: s == 'NEW',
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  picked.add(s);
                                },
                              ),
                          ],
                        )
                      : null,
                  builder: (ctx) {
                    shownRoute = ModalRoute.of(ctx)!;
                    return Container(
                      height: 200,
                      color: const Color(0xFFF4EFE3),
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx, 'LOST'),
                        child: const Text('m4 sheet'),
                      ),
                    );
                  },
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('android: the Material sheet, unchanged', (tester) async {
    await open(tester);
    expect(find.text('m4 sheet'), findsOneWidget);
    expect(find.byType(CupertinoActionSheet), findsNothing);
    final route = shownRoute as ModalBottomSheetRoute<String>;
    expect(route.barrierColor, Colors.black54);
    expect(route.transitionDuration, const Duration(milliseconds: 250));

    await tester.tap(find.text('m4 sheet'));
    await tester.pumpAndSettle();
    expect(result, 'LOST');
  }, variant: android);

  testWidgets('iOS: a list of choices is the native action sheet', (
    tester,
  ) async {
    await open(tester);
    expect(find.byType(CupertinoActionSheet), findsOneWidget);
    expect(find.text('m4 sheet'), findsNothing);
    expect(find.text('Update status'), findsOneWidget);
    // The current choice carries the check the M4 sheet shows.
    expect(find.byIcon(LucideIcons.check), findsOneWidget);

    await tester.tap(find.text('LOST'));
    await tester.pumpAndSettle();
    expect(picked, ['LOST']);
    expect(find.byType(CupertinoActionSheet), findsNothing);
  }, variant: iOS);

  testWidgets('iOS: Cancel closes without choosing', (tester) async {
    await open(tester);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(picked, isEmpty);
    expect(result, isNull);
  }, variant: iOS);

  testWidgets('iOS: other sheets keep their content, with iOS motion', (
    tester,
  ) async {
    await open(tester, withActionSheet: false);
    expect(find.text('m4 sheet'), findsOneWidget);
    final route = shownRoute as ModalBottomSheetRoute<String>;
    expect(route.transitionDuration, const Duration(milliseconds: 335));
    expect(route.barrierColor, isNot(Colors.black54));

    await tester.tap(find.text('m4 sheet'));
    await tester.pumpAndSettle();
    expect(result, 'LOST');
  }, variant: iOS);
}
