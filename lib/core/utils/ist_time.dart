/// India Standard Time (UTC+5:30, no daylight saving) — the time zone the M4
/// server and CRM work in. Visit dates and times are always sent in it,
/// whatever time zone the phone itself is set to.
library;

import 'package:intl/intl.dart';

const Duration _istOffset = Duration(hours: 5, minutes: 30);

/// [t]'s wall clock in India (returned as a UTC-flagged value whose fields
/// read as the India date and time).
DateTime istWallClock(DateTime t) => t.toUtc().add(_istOffset);

/// The India date of [t], e.g. `2026-10-25`.
String istDate(DateTime t) => DateFormat('yyyy-MM-dd').format(istWallClock(t));

/// The India time of [t], e.g. `10:30 AM`.
String istTime(DateTime t) => DateFormat('h:mm a').format(istWallClock(t));

/// [t] as an ISO-8601 timestamp in India time with its offset, e.g.
/// `2026-10-25T10:30:00+05:30` — the same instant, unambiguous to the server.
/// (A bare `toIso8601String()` of a phone-local time carries no offset, so a
/// server running in UTC read 10:30 India time as 10:30 UTC — 4 PM in India.)
String istIsoTimestamp(DateTime t) =>
    "${DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(istWallClock(t))}+05:30";
