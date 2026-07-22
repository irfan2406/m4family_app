import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:m4_mobile/core/utils/project_highlights.dart';

void main() {
  test('reads the backend highlights array (exact strings from the live API)', () {
    final project = {
      'title': 'Cledor',
      'highlights': ['Prime Location', '20 min from Airport'],
    };
    expect(projectHighlights(project), ['Prime Location', '20 min from Airport']);
  });

  test('falls back to the web defaults when highlights are missing/empty', () {
    expect(projectHighlights({'title': 'X'}), [
      'Prime Location',
      '20 min from Airport',
    ]);
    expect(projectHighlights({'highlights': <dynamic>[]}), [
      'Prime Location',
      '20 min from Airport',
    ]);
    expect(projectHighlights(null), [
      'Prime Location',
      '20 min from Airport',
    ]);
  });

  test('trims blanks and keeps real entries', () {
    expect(
      projectHighlights({'highlights': ['  Sea View  ', '', '  ']}),
      ['Sea View'],
    );
  });

  test('icons match the web set (location -> pin, airport -> device)', () {
    expect(highlightIcon('Prime Location'), LucideIcons.mapPin);
    expect(highlightIcon('20 min from Airport'), LucideIcons.smartphone);
    expect(highlightIcon('Fully Furnished'), LucideIcons.building2);
    expect(highlightIcon('Something else'), LucideIcons.checkCircle2);
  });
}
