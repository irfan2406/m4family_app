import 'package:flutter/widgets.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// The home-card USP highlights for a project, read from the backend
/// `highlights` array (e.g. ["Prime Location", "20 min from Airport"]) — the
/// same field the web renders. Falls back to the two defaults the web ships
/// when a project has none, so the row is never empty.
List<String> projectHighlights(dynamic project) {
  final raw = (project is Map) ? project['highlights'] : null;
  if (raw is List) {
    final list = raw
        .map((e) => e.toString().trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (list.isNotEmpty) return list;
  }
  return const ['Prime Location', '20 min from Airport'];
}

/// Icon for a highlight label — keyword-mapped to match the web's icon set
/// (location -> pin, distance/airport -> device, furnished -> building, ...).
IconData highlightIcon(String label) {
  final s = label.toLowerCase();
  if (s.contains('location') ||
      s.contains('prime') ||
      s.contains('view') ||
      s.contains('sea') ||
      s.contains('front')) {
    return LucideIcons.mapPin;
  }
  if (s.contains('airport') ||
      s.contains('min') ||
      s.contains('metro') ||
      s.contains('station') ||
      s.contains('drive') ||
      s.contains('km')) {
    return LucideIcons.smartphone;
  }
  if (s.contains('furnish')) return LucideIcons.building2;
  if (s.contains('secur') || s.contains('gate') || s.contains('safe')) {
    return LucideIcons.shieldCheck;
  }
  if (s.contains('park')) return LucideIcons.car;
  return LucideIcons.checkCircle2;
}
