import 'package:flutter_test/flutter_test.dart';
import 'package:m4_mobile/presentation/providers/amenity_catalog.dart';

/// A project page opens on the projects LIST's copy, whose amenities are bare
/// ids. The catalogue turns them into real amenities from the first frame, so
/// the grid never shows stand-in glyphs that then change into the icons.
void main() {
  const lobbyId = '6a9a75ff6916b80947fba11d';
  const liftId = '6ac4a87c3b73407ca8492e6f';
  const unknownId = '6ac5f8b4a6f2797def45892a';

  setUpAll(() {
    AmenityCatalog.remember([
      {
        '_id': lobbyId,
        'name': 'lobby',
        'icon': '/uploads/media/med-1791270918178-583577208.png',
      },
      {
        '_id': liftId,
        'name': 'Lift Lobby',
        'icon': '/uploads/media/med-1791365943396-497007505.png',
      },
    ]);
  });

  test('ids from the projects list become the real amenities', () {
    final resolved = AmenityCatalog.resolve([lobbyId, liftId]);
    expect(resolved.map((a) => (a as Map)['name']), ['lobby', 'Lift Lobby']);
    expect((resolved.first as Map)['icon'], contains('med-1791270918178'));
  });

  test('full records and plain names pass through unchanged', () {
    final record = {'_id': 'x', 'name': 'Gym', 'icon': ''};
    expect(AmenityCatalog.resolve([record, 'Pool']), [record, 'Pool']);
  });

  test('an id the catalogue does not know yet is left out, never shown raw',
      () {
    final resolved = AmenityCatalog.resolve([lobbyId, unknownId]);
    expect(resolved, hasLength(1));
    expect(AmenityCatalog.hasUnresolved([lobbyId, unknownId]), isTrue);
    expect(AmenityCatalog.hasUnresolved([lobbyId, liftId]), isFalse);
  });

  test('nothing at all stays nothing', () {
    expect(AmenityCatalog.resolve(null), isEmpty);
    expect(AmenityCatalog.hasUnresolved(null), isFalse);
  });
}
