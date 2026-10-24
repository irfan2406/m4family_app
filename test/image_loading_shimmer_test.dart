import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m4_mobile/presentation/widgets/image_loading_shimmer.dart';

/// The placeholder a card shows while its photo downloads.
void main() {
  Future<void> pump(WidgetTester tester, Widget child, {bool still = false}) =>
      tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: still),
            child: Scaffold(body: Center(child: child)),
          ),
        ),
      );

  LinearGradient gradient(WidgetTester tester) =>
      (tester
                      .widget<DecoratedBox>(
                        find.descendant(
                          of: find.byType(ImageLoadingShimmer),
                          matching: find.byType(DecoratedBox),
                        ),
                      )
                      .decoration
                  as BoxDecoration)
              .gradient!
          as LinearGradient;

  testWidgets('fills the photo frame it is given', (tester) async {
    await pump(
      tester,
      const SizedBox(width: 320, height: 180, child: ImageLoadingShimmer()),
    );
    expect(
      tester.getSize(find.byType(ImageLoadingShimmer)),
      const Size(320, 180),
    );
  });

  testWidgets('takes no space when the space is unbounded', (tester) async {
    await pump(
      tester,
      const Column(
        mainAxisSize: MainAxisSize.min,
        children: [ImageLoadingShimmer()],
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the light band moves across', (tester) async {
    await pump(
      tester,
      const SizedBox(width: 320, height: 180, child: ImageLoadingShimmer()),
    );
    final first = gradient(tester).begin;
    await tester.pump(const Duration(milliseconds: 500));
    expect(gradient(tester).begin, isNot(first));
  });

  testWidgets('stays still when the phone asks for reduced motion', (
    tester,
  ) async {
    await pump(
      tester,
      const SizedBox(width: 320, height: 180, child: ImageLoadingShimmer()),
      still: true,
    );
    final first = gradient(tester).begin;
    await tester.pump(const Duration(milliseconds: 500));
    expect(gradient(tester).begin, first);
  });
}
