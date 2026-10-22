import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/presentation/widgets/construction_updates.dart';

/// CONSTRUCTION PROGRESS, month by month: one card per phase per month.
void main() {
  // The backend stamps the upload time into every file name.
  String upload(DateTime t) =>
      '/uploads/media/med-${t.millisecondsSinceEpoch}-123.png';

  group('which month a progress photo belongs to', () {
    test('an explicit month field wins', () {
      expect(
        constructionPhotoMonth({
          'url': upload(DateTime(2026, 10, 21)),
          'month': '2026-01',
        }),
        DateTime(2026, 1),
      );
    });

    test('a month written in the caption', () {
      for (final caption in [
        'January 2026',
        'Jan 2026 – slab casting',
        '01/2026',
        '2026-01',
        'JAN-26',
      ]) {
        expect(
          constructionPhotoMonth({
            'url': upload(DateTime(2026, 10, 21)),
            'caption': caption,
          }),
          DateTime(2026, 1),
          reason: caption,
        );
      }
    });

    test('otherwise the upload time in the file name', () {
      // SKAI's live Demolition photo, uploaded 21 Oct 2026.
      expect(
        constructionPhotoMonth({
          'url': '/uploads/media/med-1792566253109-5109868.png',
          'caption': '',
        }),
        DateTime(2026, 10),
      );
    });

    test('nothing to go on: no month', () {
      expect(constructionPhotoMonth({'url': 'https://x.test/a.jpg'}), isNull);
    });
  });

  group('cards', () {
    test('one phase with photos from three months makes three cards, '
        'month by month from the earliest', () {
      final months = constructionMonths([
        {
          'phaseName': 'STRUCTURAL',
          'phaseOrder': 1,
          'images': [
            {'url': upload(DateTime(2025, 12, 3))},
            {'url': upload(DateTime(2026, 1, 9))},
            {'url': upload(DateTime(2026, 1, 20))},
            {'url': upload(DateTime(2026, 2, 14))},
          ],
        },
      ]);
      expect(months.map((m) => m.month), [
        DateTime(2025, 12),
        DateTime(2026, 1),
        DateTime(2026, 2),
      ]);
      // January's two photos share one card, newest first.
      expect(months[1].images, [
        upload(DateTime(2026, 1, 20)),
        upload(DateTime(2026, 1, 9)),
      ]);
    });

    test('every card of one phase comes before the next phase'
        's', () {
      final months = constructionMonths([
        {
          'phaseName': 'MEAP',
          'phaseOrder': 3,
          'images': [
            {'url': upload(DateTime(2026, 10, 2))},
          ],
        },
        {
          'phaseName': 'DEMOLITION',
          'phaseOrder': 1,
          'images': [
            {'url': upload(DateTime(2026, 10, 21))},
            {'url': upload(DateTime(2026, 9, 5))},
          ],
        },
        {
          'phaseName': 'FOUNDATION',
          'phaseOrder': 2,
          'images': [
            {'url': upload(DateTime(2025, 6, 9))},
          ],
        },
      ]);
      expect(
        months.map(
          (m) => '${m.phase['phaseName']} ${m.month!.year}-${m.month!.month}',
        ),
        [
          'DEMOLITION 2026-9',
          'DEMOLITION 2026-10',
          'FOUNDATION 2025-6',
          'MEAP 2026-10',
        ],
      );
    });

    test('a phase with no photo still gets its card, dated by its update', () {
      final months = constructionMonths([
        {
          'phaseName': 'MEP',
          'images': [],
          'updatedAt': '2026-10-01T12:24:05.856Z',
        },
      ]);
      expect(months.single.images, isEmpty);
      expect(months.single.month, DateTime(2026, 10));
    });

    test('a stand-in phase the app built itself is never dated', () {
      final months = constructionMonths([
        {
          'phaseName': 'Foundation',
          'undated': true,
          'images': [upload(DateTime(2026, 3, 1))],
        },
      ]);
      expect(months.single.month, isNull);
      expect(months.single.images, hasLength(1));
    });
  });

  testWidgets('one row of cards; the year rail and arrows move through it', (
    tester,
  ) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(400, 900);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ConstructionUpdates(
              projectTitle: 'Clédor',
              phases: [
                {
                  'phaseName': 'STRUCTURAL',
                  'status': 'In Progress',
                  'progressPercent': 40,
                  'images': [
                    {'url': upload(DateTime(2025, 11, 5))},
                    {'url': upload(DateTime(2026, 1, 9))},
                  ],
                },
              ],
              resolveUrl: (raw) => 'http://localhost$raw',
              onOpenGallery: (_) {},
            ),
          ),
        ),
      ),
    );

    // Opens on the first card (the earliest month).
    expect(find.text('2025'), findsOneWidget);
    expect(find.text('2026'), findsOneWidget);
    expect(find.text('NOVEMBER 2025'), findsOneWidget);
    expect(find.text('Clédor'), findsWidgets);
    // No gallery icon on the photo.
    expect(find.byIcon(LucideIcons.image), findsNothing);

    // The year rail jumps to that year's first card.
    await tester.tap(find.text('2026'));
    await tester.pumpAndSettle();
    expect(find.text('JANUARY 2026'), findsOneWidget);

    // And the ‹ arrow slides back.
    await tester.tap(find.byIcon(LucideIcons.chevronLeft));
    await tester.pumpAndSettle();
    expect(find.text('NOVEMBER 2025'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
