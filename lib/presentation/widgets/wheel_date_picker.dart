import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const List<String> _kMonths = [
  'JAN',
  'FEB',
  'MAR',
  'APR',
  'MAY',
  'JUN',
  'JUL',
  'AUG',
  'SEP',
  'OCT',
  'NOV',
  'DEC',
];

/// M4 wheel date picker — a bottom sheet with a "SELECT DATE" title, three
/// day / month / year wheels (day · abbreviated-month · year, highlighted
/// centre row) and CANCEL / CONFIRM buttons. Returns the chosen date, or null
/// if cancelled.
Future<DateTime?> showWheelDatePicker(
  BuildContext context, {
  required DateTime initial,
  DateTime? maximum,
  int minYear = 1940,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _WheelDatePickerSheet(
      initial: initial,
      maximum: maximum ?? DateTime.now(),
      minYear: minYear,
    ),
  );
}

class _WheelDatePickerSheet extends StatefulWidget {
  final DateTime initial;
  final DateTime maximum;
  final int minYear;
  const _WheelDatePickerSheet({
    required this.initial,
    required this.maximum,
    required this.minYear,
  });

  @override
  State<_WheelDatePickerSheet> createState() => _WheelDatePickerSheetState();
}

class _WheelDatePickerSheetState extends State<_WheelDatePickerSheet> {
  late int _day; // 1-31
  late int _month; // 1-12
  late int _year;
  late final int _maxYear;
  late final FixedExtentScrollController _dayCtrl;
  late final FixedExtentScrollController _monthCtrl;
  late final FixedExtentScrollController _yearCtrl;

  static const double _itemExtent = 46;

  @override
  void initState() {
    super.initState();
    _maxYear = widget.maximum.year;
    _year = widget.initial.year.clamp(widget.minYear, _maxYear);
    _month = widget.initial.month;
    _day = widget.initial.day;
    _dayCtrl = FixedExtentScrollController(initialItem: _day - 1);
    _monthCtrl = FixedExtentScrollController(initialItem: _month - 1);
    _yearCtrl = FixedExtentScrollController(
      initialItem: _year - widget.minYear,
    );
  }

  @override
  void dispose() {
    _dayCtrl.dispose();
    _monthCtrl.dispose();
    _yearCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? Colors.white : Color(0xFF0C312B);
    final years = List<int>.generate(
      _maxYear - widget.minYear + 1,
      (i) => widget.minYear + i,
    );

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141B3A) : const Color(0xFFF4EFE3),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: fg.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 24, 25, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'SELECT DATE',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                    color: fg,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: _itemExtent * 4,
              child: Stack(
                children: [
                  // Highlighted centre band.
                  Center(
                    child: Container(
                      height: _itemExtent,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: fg.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _wheel(
                          controller: _dayCtrl,
                          count: 31,
                          label: (i) => '${i + 1}',
                          onChanged: (i) => setState(() => _day = i + 1),
                          fg: fg,
                        ),
                      ),
                      Expanded(
                        child: _wheel(
                          controller: _monthCtrl,
                          count: 12,
                          label: (i) => _kMonths[i],
                          onChanged: (i) => setState(() => _month = i + 1),
                          fg: fg,
                        ),
                      ),
                      Expanded(
                        child: _wheel(
                          controller: _yearCtrl,
                          count: years.length,
                          label: (i) => '${years[i]}',
                          onChanged: (i) => setState(() => _year = years[i]),
                          fg: fg,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: fg.withValues(alpha: 0.15)),
                        ),
                        child: Text(
                          'CANCEL',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1,
                            color: fg,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        // Clamp the day to the chosen month's length.
                        final maxDay = DateTime(_year, _month + 1, 0).day;
                        final d = _day > maxDay ? maxDay : _day;
                        Navigator.pop(context, DateTime(_year, _month, d));
                      },
                      child: Container(
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF141B3A),
                        ),
                        child: Text(
                          'CONFIRM',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1,
                            color: isDark ? Colors.black : const Color(0xFFF4EFE3),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _wheel({
    required FixedExtentScrollController controller,
    required int count,
    required String Function(int) label,
    required void Function(int) onChanged,
    required Color fg,
  }) {
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: _itemExtent,
      physics: const FixedExtentScrollPhysics(),
      perspective: 0.003,
      diameterRatio: 1.7,
      overAndUnderCenterOpacity: 0.25,
      onSelectedItemChanged: onChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: count,
        builder: (ctx, i) => Center(
          child: Text(
            label(i),
            style: GoogleFonts.gelasio(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}
