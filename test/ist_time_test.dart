import 'package:flutter_test/flutter_test.dart';
import 'package:m4_mobile/core/utils/ist_time.dart';

/// PDF p9: partner visit times are sent in India time.
void main() {
  // 05:00 UTC is 10:30 in India.
  final instant = DateTime.utc(2026, 10, 25, 5, 0);

  test('date and time read as India wall clock', () {
    expect(istDate(instant), '2026-10-25');
    expect(istTime(instant), '10:30 AM');
  });

  test('timestamp carries the +05:30 offset (same instant)', () {
    final s = istIsoTimestamp(instant);
    expect(s, '2026-10-25T10:30:00+05:30');
    expect(DateTime.parse(s).toUtc(), instant);
  });

  test('a time late in the UTC day lands on the next India date', () {
    // 20:00 UTC = 01:30 next day in India.
    final late = DateTime.utc(2026, 10, 25, 20, 0);
    expect(istDate(late), '2026-10-26');
    expect(istTime(late), '1:30 AM');
  });

  test('a phone-local time gives the same answer as its UTC instant', () {
    final local = instant.toLocal();
    expect(istIsoTimestamp(local), istIsoTimestamp(instant));
  });
}
