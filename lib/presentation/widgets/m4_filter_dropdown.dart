import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// One choice in an [M4FilterDropdown]: its value, label and colour dot.
class M4FilterOption<T> {
  const M4FilterOption({
    required this.value,
    required this.label,
    required this.color,
  });

  final T value;
  final String label;

  /// The dot beside the label — e.g. a status's own colour.
  final Color color;
}

/// The app's filter dropdown: a rounded pill showing the current choice (its
/// colour dot, label and a chevron) that opens a cream menu card — a small
/// heading, then each option with its colour dot; the selected one sits on a
/// soft tinted row with a check.
class M4FilterDropdown<T> extends StatelessWidget {
  const M4FilterDropdown({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    this.heading = 'FILTER BY STATUS',
    this.height = 48,
  });

  final T value;
  final List<M4FilterOption<T>> options;
  final ValueChanged<T> onChanged;

  /// Small spaced-caps title at the top of the open menu.
  final String heading;

  /// Matches the search field beside it.
  final double height;

  // App palette.
  static const Color _cream = Color(0xFFF4EFE3);
  static const Color _deepGreen = Color(0xFF0C312B);

  M4FilterOption<T> get _current => options.firstWhere(
    (o) => o.value == value,
    orElse: () => options.first,
  );

  Future<void> _open(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final ink = isDark ? Colors.white : _deepGreen;
    final box = context.findRenderObject() as RenderBox;
    final overlay =
        Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final topLeft = box.localToGlobal(
      Offset(0, box.size.height + 8),
      ancestor: overlay,
    );
    final bottomRight = box.localToGlobal(
      box.size.bottomRight(Offset.zero),
      ancestor: overlay,
    );
    final position = RelativeRect.fromRect(
      Rect.fromPoints(topLeft, bottomRight),
      Offset.zero & overlay.size,
    );

    final picked = await showMenu<T>(
      context: context,
      position: position,
      color: isDark ? scheme.surface : _cream,
      surfaceTintColor: Colors.transparent,
      elevation: 14,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      constraints: const BoxConstraints(minWidth: 230, maxWidth: 260),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: ink.withValues(alpha: 0.08)),
      ),
      menuPadding: const EdgeInsets.symmetric(vertical: 8),
      items: [
        PopupMenuItem<T>(
          enabled: false,
          height: 36,
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 4),
          child: Text(
            heading,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
              color: ink.withValues(alpha: 0.5),
            ),
          ),
        ),
        for (final o in options)
          PopupMenuItem<T>(
            value: o.value,
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _OptionRow(
              label: o.label,
              color: o.color,
              selected: o.value == value,
              ink: ink,
            ),
          ),
      ],
    );
    if (picked != null && picked != value) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final ink = isDark ? Colors.white : _deepGreen;
    final current = _current;

    return Builder(
      builder: (context) => Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _open(context),
          child: Ink(
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: ink.withValues(alpha: 0.12)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Dot(color: current.color),
                const SizedBox(width: 10),
                Text(
                  current.label.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: ink,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: ink.withValues(alpha: 0.07),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(LucideIcons.chevronDown, size: 14, color: ink),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.label,
    required this.color,
    required this.selected,
    required this.ink,
  });

  final String label;
  final Color color;
  final bool selected;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: selected ? ink.withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _Dot(color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 1.1,
                color: ink.withValues(alpha: selected ? 1 : 0.8),
              ),
            ),
          ),
          if (selected) Icon(LucideIcons.check, size: 16, color: ink),
        ],
      ),
    );
  }
}

/// A status dot with a soft halo of its own colour.
class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        shape: BoxShape.circle,
      ),
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
