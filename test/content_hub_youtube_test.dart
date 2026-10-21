import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/widgets/content_hub_card.dart';
import 'package:m4_mobile/presentation/widgets/youtube_embed.dart';

/// CONTENT HUB (Media, Highlights, Events, Blog): the list card is
/// YouTube-shaped (16:9 picture, all text in a thin strip below it), and a
/// post whose videoUrl is a YouTube link plays in the app.
void main() {
  group('youTubeVideoId reads the links admins paste', () {
    const id = 'nHAqvPGjis4';
    for (final link in [
      // The live "Cledor Site Update" highlight, share-sheet tracking and all.
      'https://youtu.be/nHAqvPGjis4?si=LgXuxBYgvcvf0hw-',
      'https://www.youtube.com/watch?v=nHAqvPGjis4',
      'https://m.youtube.com/watch?v=nHAqvPGjis4&t=42s',
      'youtube.com/watch?v=nHAqvPGjis4',
      'https://www.youtube.com/embed/nHAqvPGjis4',
      'https://www.youtube.com/shorts/nHAqvPGjis4',
      'https://www.youtube.com/live/nHAqvPGjis4?feature=share',
      'https://www.youtube-nocookie.com/embed/nHAqvPGjis4',
    ]) {
      test(link, () => expect(youTubeVideoId(link), id));
    }

    for (final notYouTube in [
      null,
      '',
      'https://m4group.in/cledor-site-update/',
      'https://cdn.example.com/clip.mp4',
      'https://www.youtube.com/@m4group',
      'https://youtu.be/',
    ]) {
      test('not a video: $notYouTube', () {
        expect(youTubeVideoId(notYouTube), isNull);
      });
    }
  });

  group('contentPostDate', () {
    test('reads as day/month/year, e.g. 21/10/26', () {
      final local = DateTime(2026, 10, 21, 13, 23);
      expect(contentPostDate(local.toIso8601String()), '21/10/26');
    });
    test('a UTC time is shown in the phone''s time zone', () {
      const raw = '2026-10-21T07:53:54.477Z';
      expect(
        contentPostDate(raw),
        DateFormat('dd/MM/yy').format(DateTime.parse(raw).toLocal()),
      );
    });
    test('no date shows none, not today''s', () {
      expect(contentPostDate(null), '');
      expect(contentPostDate(''), '');
    });
  });

  testWidgets(
    'the card is a full-width 16:9 picture with a thin text strip below',
    (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(411, 900);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(
              ApiClient(baseUrl: 'http://localhost'),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: ContentHubCard(
                    item: const {
                      'title': 'Cledor Site Update',
                      'type': 'highlight',
                      'description': 'Cledor Mazgaon',
                      'image': '',
                      'videoUrl': 'https://youtu.be/nHAqvPGjis4',
                      'createdAt': '2026-10-21T07:53:54.477Z',
                    },
                    typeLabel: 'highlight',
                    placeholderIcon: LucideIcons.zap,
                    onTap: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      final picture = tester.getRect(find.byType(AspectRatio));
      final card = tester.getRect(find.byType(ContentHubCard));
      // Inside the card's 1px hairline border on each side.
      expect(picture.width, card.width - 2, reason: 'picture spans the card');
      expect(picture.width / picture.height, closeTo(16 / 9, 0.01));
      expect(
        picture.top,
        card.top + 1,
        reason: 'picture is the top of the card',
      );

      // Every line of text sits below the picture.
      for (final text in [
        'HIGHLIGHT',
        DateFormat('dd/MM/yy').format(
          DateTime.parse('2026-10-21T07:53:54.477Z').toLocal(),
        ),
        'CLEDOR SITE UPDATE',
        'Cledor Mazgaon',
      ]) {
        expect(
          tester.getRect(find.text(text)).top,
          greaterThanOrEqualTo(picture.bottom),
          reason: '$text is below the picture',
        );
      }

      // A thin strip: under the picture there is only ~60px of text (the
      // card also carries its 16px bottom margin and a 1px border top and
      // bottom).
      expect(card.height - picture.height - 16 - 2, lessThan(64));

      // The picture is clean: no play mark and no blurred copy behind it.
      expect(find.byIcon(LucideIcons.play), findsNothing);
      expect(find.byType(ImageFiltered), findsNothing);
    },
  );
}
