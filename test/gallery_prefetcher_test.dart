import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m4_mobile/presentation/widgets/gallery_prefetcher.dart';

/// Project galleries (Exterior / Interior, every portal) paused on each swipe:
/// the page being swiped to only started its multi-MB download and its decode
/// when it came on screen. GalleryPrefetcher fetches the pictures around the
/// current page ahead of time.
void main() {
  group('visit order', () {
    test('the page on screen, then outward both ways, three deep', () {
      expect(GalleryPrefetcher.visitOrder(5, 13).toList(), [
        5, 6, 4, 7, 3, 8, 2, //
      ]);
    });

    test('stops at the ends of the gallery', () {
      expect(GalleryPrefetcher.visitOrder(0, 13).toList(), [0, 1, 2, 3]);
      expect(GalleryPrefetcher.visitOrder(12, 13).toList(), [12, 11, 10, 9]);
      expect(GalleryPrefetcher.visitOrder(0, 1).toList(), [0]);
      expect(GalleryPrefetcher.visitOrder(1, 3).toList(), [1, 2, 0]);
    });
  });

  // The whole point: precaching only helps if it fills the cache entry the
  // page reads. The Customer gallery used to precache the bare network
  // provider — a full-size decode under a different key — so its pages still
  // decoded on every swipe.
  testWidgets('precaches the exact image the gallery page draws', (
    tester,
  ) async {
    const url = 'https://api.example.com/uploads/cledor-1.jpg';
    for (final width in [1080, 1600]) {
      await tester.pumpWidget(
        MaterialApp(
          home: CachedNetworkImage(imageUrl: url, memCacheWidth: width),
        ),
      );
      final drawn = tester.widget<Image>(find.byType(Image).first).image;
      final prefetched = GalleryPrefetcher(
        urls: const [url],
        memCacheWidth: width,
      ).provider(url);

      const config = ImageConfiguration.empty;
      expect(
        await prefetched.obtainKey(config),
        await drawn.obtainKey(config),
        reason: 'memCacheWidth $width: the precache must share the page key',
      );
      // And not the bare provider the old Customer code precached.
      expect(
        await CachedNetworkImageProvider(url).obtainKey(config),
        isNot(await drawn.obtainKey(config)),
      );
    }
  });

  group('fetching', () {
    late List<String> fetched;
    late GalleryPrefetcher prefetcher;
    final urls = [
      for (var i = 0; i < 13; i++) 'https://api.example.com/uploads/$i.jpg',
    ];

    String page(ImageProvider p) =>
        ((p as ResizeImage).imageProvider as CachedNetworkImageProvider).url
            .split('/')
            .last
            .replaceAll('.jpg', '');

    setUp(() {
      fetched = [];
      prefetcher = GalleryPrefetcher(
        urls: urls,
        memCacheWidth: 1080,
        precache: (provider, context) async => fetched.add(page(provider)),
      );
    });

    testWidgets('opening fetches around the opening page, nearest first', (
      tester,
    ) async {
      await tester.pumpWidget(const SizedBox());
      final context = tester.element(find.byType(SizedBox));

      prefetcher.open(context, 4);
      await tester.pump();

      expect(fetched, ['4', '5', '3', '6', '2', '7', '1']);
      prefetcher.close();
    });

    testWidgets('a swipe re-aims the fetch at the new page', (tester) async {
      await tester.pumpWidget(const SizedBox());
      final context = tester.element(find.byType(SizedBox));

      // A slow first fetch, so the swipe lands while it is in flight.
      final gate = <Future<void>>[];
      final slow = GalleryPrefetcher(
        urls: urls,
        memCacheWidth: 1080,
        precache: (provider, _) async {
          fetched.add(page(provider));
          if (gate.isEmpty) {
            gate.add(Future<void>.delayed(const Duration(seconds: 1)));
            await gate.first;
          }
        },
      );

      slow.open(context, 0);
      await tester.pump();
      expect(fetched, ['0']);

      slow.warm(context, 6); // the user swiped far ahead
      await tester.pump(const Duration(seconds: 2));

      // The walk from page 0 stopped; the walk from page 6 ran.
      expect(fetched, ['0', '6', '7', '5', '8', '4', '9', '3']);
      slow.close();
    });

    testWidgets('bundled assets and inline images are not fetched', (
      tester,
    ) async {
      await tester.pumpWidget(const SizedBox());
      final context = tester.element(find.byType(SizedBox));
      final seen = <String>[];
      final mixed = GalleryPrefetcher(
        urls: const [
          'asset:assets/hero_artistic.jpg',
          'https://api.example.com/uploads/a.jpg',
          'data:image/png;base64,AAAA',
        ],
        memCacheWidth: 1080,
        precache: (provider, _) async => seen.add(
          ((provider as ResizeImage).imageProvider
                  as CachedNetworkImageProvider)
              .url,
        ),
      );

      mixed.open(context, 0);
      await tester.pump();
      expect(seen, ['https://api.example.com/uploads/a.jpg']);
      mixed.close();
    });

    testWidgets('closing stops the fetch and restores the cache budget', (
      tester,
    ) async {
      await tester.pumpWidget(const SizedBox());
      final context = tester.element(find.byType(SizedBox));
      final cache = PaintingBinding.instance.imageCache;
      final before = cache.maximumSizeBytes;

      // Each fetch takes a second, so the gallery closes mid-walk.
      final slow = GalleryPrefetcher(
        urls: urls,
        memCacheWidth: 1080,
        precache: (provider, _) async {
          fetched.add(page(provider));
          await Future<void>.delayed(const Duration(seconds: 1));
        },
      );

      slow.open(context, 0);
      expect(cache.maximumSizeBytes, 256 << 20);
      await tester.pump();
      expect(fetched, ['0']);

      slow.close();
      expect(cache.maximumSizeBytes, before);
      await tester.pump(const Duration(seconds: 5));
      expect(fetched, ['0'], reason: 'nothing is fetched after closing');
    });
  });
}
