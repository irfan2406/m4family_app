import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The one M4 date/time chooser: a bottom sheet with a drag handle, a
/// left-aligned title, [WheelDateTimePicker] and CANCEL / CONFIRM — the exact
/// sheet every booking flow shows. Returns the chosen moment, or null when
/// cancelled.
///
/// Every date field in the app routes through this, so a Date of Birth sheet
/// and a site-visit sheet are the same control.
Future<DateTime?> showM4DateTimeSheet(
  BuildContext context, {
  required DateTime initial,
  DateTime? minDate,
  DateTime? maxDate,
  bool showTime = true,
  String title = 'SELECT DATE & TIME',
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  // CONFIRM hands back [temp], which only moves when a wheel is scrolled — so
  // an out-of-range [initial] would otherwise be returned unchanged.
  var temp = initial;
  if (minDate != null && temp.isBefore(minDate)) temp = minDate;
  if (maxDate != null && temp.isAfter(maxDate)) temp = maxDate;
  return showModalBottomSheet<DateTime>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetCtx) => Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141B3A) : const Color(0xFFF4EFE3),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : const Color(0xFF0C312B))
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: isDark ? Colors.white : const Color(0xFF155A4F),
              ),
            ),
          ),
          const SizedBox(height: 8),
          WheelDateTimePicker(
            initial: temp,
            minDate: minDate,
            maxDate: maxDate,
            isDark: isDark,
            showTime: showTime,
            onChanged: (dt) => temp = dt,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(sheetCtx),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: BorderSide(
                      color: (isDark ? Colors.white : const Color(0xFF0C312B))
                          .withValues(alpha: 0.2),
                    ),
                    foregroundColor: isDark
                        ? Colors.white
                        : const Color(0xFF0C312B),
                  ),
                  child: Text(
                    'CANCEL',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(sheetCtx, temp),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: isDark
                        ? Colors.white
                        : const Color(0xFF0C312B),
                    foregroundColor: isDark
                        ? Colors.black
                        : const Color(0xFFF4EFE3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'CONFIRM',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

/// Custom absolute Day/Month/Year (+ optional Hour/Min/AM-PM) wheel picker
/// matching web's `IOSDateTimePicker` — Cupertino's own `dateAndTime` mode
/// always shows relative labels ("Today", weekday names) with no way to
/// disable that, so this rolls its own wheels the same way the web's
/// `WheelPicker` does.
///
/// [minDate] mirrors the web's optional `minDate` prop:
///  - when set (booking/scheduling flows), the year list is an 11-year window
///    starting at `minDate.year`, and day/month wheels exclude values before
///    `minDate` in that same year/month (so you can't schedule in the past).
///  - when null (e.g. a Date of Birth field), the year list is a ~110-year
///    window centered on today with no day/month clamping — matching the
///    web's own `else` branch for date pickers with no `minDate`.
///
/// [showTime] hides the Hour/Min/AM-PM wheels for date-only fields (web's
/// `mode="date"`), matching `IOSDateTimePicker`'s `mode !== "time"` split.
///
/// Shared across every CP form (video call, site visit, profile settings)
/// that needs a wheel date/date-time picker matching the web exactly.
class WheelDateTimePicker extends StatefulWidget {
  final DateTime initial;
  final DateTime? minDate;

  /// Mirror of [minDate] for fields that cannot run into the future — a Date
  /// of Birth. Caps the year list at its year and, on that year, the month and
  /// day wheels at its month and day. Null (every scheduling picker) leaves
  /// the upper end unbounded, exactly as before.
  final DateTime? maxDate;
  final bool isDark;
  final bool showTime;
  final ValueChanged<DateTime> onChanged;

  const WheelDateTimePicker({
    super.key,
    required this.initial,
    this.minDate,
    this.maxDate,
    required this.isDark,
    this.showTime = true,
    required this.onChanged,
  });

  @override
  State<WheelDateTimePicker> createState() => _WheelDateTimePickerState();
}

class _WheelDateTimePickerState extends State<WheelDateTimePicker> {
  static const _months = [
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

  late DateTime _value;
  late List<int> _years;
  late FixedExtentScrollController _dayCtrl;
  late FixedExtentScrollController _monthCtrl;
  late FixedExtentScrollController _yearCtrl;
  FixedExtentScrollController? _hourCtrl;
  FixedExtentScrollController? _minuteCtrl;
  FixedExtentScrollController? _ampmCtrl;

  int _daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

  // 0-indexed month values available for [year]. With a minDate, its own year
  // excludes months before minDate.month (web `availableMonths`); with a
  // maxDate, its own year excludes months after maxDate.month. With neither,
  // every month is available. Takes the year as an argument because the
  // year/month handlers need the list for the year being moved TO, before
  // _value has been updated.
  List<int> _monthIdxFor(int year) {
    final min = widget.minDate;
    final max = widget.maxDate;
    final first = (min != null && year == min.year) ? min.month : 1;
    final last = (max != null && year == max.year) ? max.month : 12;
    final count = last - first + 1;
    return List.generate(count < 1 ? 1 : count, (i) => first - 1 + i);
  }

  // Day-of-month values available for [year]/[month], bounded the same way
  // (web `availableDays`) and never past the real length of the month.
  List<int> _daysFor(int year, int month) {
    final total = _daysInMonth(year, month);
    final min = widget.minDate;
    final max = widget.maxDate;
    final first = (min != null && year == min.year && month == min.month)
        ? min.day
        : 1;
    var last = total;
    if (max != null &&
        year == max.year &&
        month == max.month &&
        max.day < last) {
      last = max.day;
    }
    final count = last - first + 1;
    return List.generate(count < 1 ? 1 : count, (i) => first + i);
  }

  List<int> _availableMonthIdx() => _monthIdxFor(_value.year);

  List<int> _availableDays() => _daysFor(_value.year, _value.month);

  @override
  void initState() {
    super.initState();
    _value = widget.initial;
    final min = widget.minDate;
    final max = widget.maxDate;
    if (min != null && _value.isBefore(min)) _value = min;
    if (max != null && _value.isAfter(max)) _value = max;
    _years = min != null
        ? List.generate(11, (i) => min.year + i)
        : max != null
        // Bounded above (a birthdate): end the list at the maximum's year
        // rather than running ten years past today.
        ? List.generate(101, (i) => (max.year - 100) + i)
        : List.generate(111, (i) => (DateTime.now().year - 100) + i);

    final months = _availableMonthIdx();
    final days = _availableDays();

    _yearCtrl = FixedExtentScrollController(
      initialItem: _years.indexOf(_value.year).clamp(0, _years.length - 1),
    );
    _monthCtrl = FixedExtentScrollController(
      initialItem: months.indexOf(_value.month - 1).clamp(0, months.length - 1),
    );
    _dayCtrl = FixedExtentScrollController(
      initialItem: days.indexOf(_value.day).clamp(0, days.length - 1),
    );

    if (widget.showTime) {
      final h12 = _value.hour % 12 == 0 ? 12 : _value.hour % 12;
      _hourCtrl = FixedExtentScrollController(initialItem: h12 - 1);
      _minuteCtrl = FixedExtentScrollController(initialItem: _value.minute);
      _ampmCtrl = FixedExtentScrollController(
        initialItem: _value.hour >= 12 ? 1 : 0,
      );
    }
  }

  @override
  void dispose() {
    _yearCtrl.dispose();
    _monthCtrl.dispose();
    _dayCtrl.dispose();
    _hourCtrl?.dispose();
    _minuteCtrl?.dispose();
    _ampmCtrl?.dispose();
    super.dispose();
  }

  void _emit(DateTime next) {
    // Never hand back a moment before the minimum. The year/month/day wheels
    // already exclude past dates, but the hour/minute/AM-PM wheels are
    // unfiltered — so on the minimum day itself an earlier time is still
    // reachable (e.g. a 30-minute-out video call slot at 10:00 when it is
    // already 12:30). Clamp here so every caller is covered.
    final min = widget.minDate;
    if (min != null && next.isBefore(min)) next = min;
    // The same in the other direction, for a bounded-above field: the day
    // wheels stop at the maximum but the time wheels do not.
    final max = widget.maxDate;
    if (max != null && next.isAfter(max)) next = max;
    setState(() => _value = next);
    widget.onChanged(_value);
  }

  // Re-sync a wheel's physical scroll position with `_value` after its item
  // list may have changed length/composition (year/month changes can shrink
  // or shift the month/day lists out from under the currently-scrolled wheel).
  void _resyncMonthAndDay() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final months = _availableMonthIdx();
      final days = _availableDays();
      final mi = months.indexOf(_value.month - 1);
      final di = days.indexOf(_value.day);
      if (mi != -1 && _monthCtrl.hasClients) _monthCtrl.jumpToItem(mi);
      if (di != -1 && _dayCtrl.hasClients) _dayCtrl.jumpToItem(di);
    });
  }

  void _onYear(int idx) {
    final year = _years[idx];
    var next = DateTime(
      year,
      _value.month,
      _value.day,
      _value.hour,
      _value.minute,
    );
    final months = _monthIdxFor(year);
    if (!months.contains(next.month - 1)) {
      next = DateTime(year, months.first + 1, 1, next.hour, next.minute);
    }
    next = _clampDayInto(next);
    _emit(next);
    _resyncMonthAndDay();
  }

  void _onMonth(int idx) {
    final months = _availableMonthIdx();
    final month = months[idx] + 1;
    var next = DateTime(
      _value.year,
      month,
      _value.day,
      _value.hour,
      _value.minute,
    );
    next = _clampDayInto(next);
    _emit(next);
    _resyncMonthAndDay();
  }

  // Pull [next]'s day inside the range its (possibly just changed) year and
  // month allow — the shared tail of _onYear and _onMonth.
  DateTime _clampDayInto(DateTime next) {
    final days = _daysFor(next.year, next.month);
    if (next.day > days.last) {
      return DateTime(next.year, next.month, days.last, next.hour, next.minute);
    }
    if (next.day < days.first) {
      return DateTime(
        next.year,
        next.month,
        days.first,
        next.hour,
        next.minute,
      );
    }
    return next;
  }

  void _onDay(int idx) {
    final days = _availableDays();
    _emit(
      DateTime(
        _value.year,
        _value.month,
        days[idx],
        _value.hour,
        _value.minute,
      ),
    );
  }

  void _onHour(int idx) {
    final h12 = idx + 1;
    final isPM = _value.hour >= 12;
    final hour24 = (h12 % 12) + (isPM ? 12 : 0);
    _emit(
      DateTime(_value.year, _value.month, _value.day, hour24, _value.minute),
    );
  }

  void _onMinute(int idx) {
    _emit(DateTime(_value.year, _value.month, _value.day, _value.hour, idx));
  }

  void _onAmPm(int idx) {
    final isPM = idx == 1;
    final h12 = _value.hour % 12 == 0 ? 12 : _value.hour % 12;
    final hour24 = (h12 % 12) + (isPM ? 12 : 0);
    _emit(
      DateTime(_value.year, _value.month, _value.day, hour24, _value.minute),
    );
  }

  // [flex] is the column's share of the row, keeping the old fixed widths as
  // proportions so the wheels look the same but can never outgrow the box.
  Widget _wheel({
    required FixedExtentScrollController controller,
    required int count,
    required String Function(int) label,
    required ValueChanged<int> onChanged,
    int flex = 44,
  }) {
    final isDark = widget.isDark;
    return Expanded(
      flex: flex,
      child: CupertinoPicker(
        scrollController: controller,
        itemExtent: 36,
        squeeze: 1.1,
        selectionOverlay: const SizedBox.shrink(),
        onSelectedItemChanged: onChanged,
        children: List.generate(
          count,
          (i) => Center(
            child: Text(
              label(i),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : const Color(0xFF155A4F),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final months = _availableMonthIdx();
    final days = _availableDays();

    return Container(
      height: 190,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isDark ? Colors.white : const Color(0xFF0C312B)).withValues(
            alpha: 0.08,
          ),
        ),
        color: (isDark ? Colors.white : const Color(0xFF0C312B)).withValues(
          alpha: 0.02,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          IgnorePointer(
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                border: Border.symmetric(
                  horizontal: BorderSide(
                    color: (isDark ? Colors.white : const Color(0xFF0C312B))
                        .withValues(alpha: 0.1),
                  ),
                ),
              ),
            ),
          ),
          // The columns share the width instead of each claiming a fixed
          // number of pixels: the fixed set added up to more than the box on a
          // 361dp screen (Realme GT 60) and pushed AM/PM past the edge.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _wheel(
                controller: _dayCtrl,
                count: days.length,
                label: (i) => '${days[i]}',
                onChanged: _onDay,
                flex: 40,
              ),
              _wheel(
                controller: _monthCtrl,
                count: months.length,
                label: (i) => _months[months[i]],
                onChanged: _onMonth,
                flex: 56,
              ),
              _wheel(
                controller: _yearCtrl,
                count: _years.length,
                label: (i) => '${_years[i]}',
                onChanged: _onYear,
                flex: 60,
              ),
              if (widget.showTime) ...[
                const SizedBox(width: 10),
                _wheel(
                  controller: _hourCtrl!,
                  count: 12,
                  label: (i) => '${i + 1}',
                  onChanged: _onHour,
                  flex: 34,
                ),
                Text(
                  ':',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: (isDark ? Colors.white : const Color(0xFF0C312B))
                        .withValues(alpha: 0.68),
                  ),
                ),
                _wheel(
                  controller: _minuteCtrl!,
                  count: 60,
                  label: (i) => i.toString().padLeft(2, '0'),
                  onChanged: _onMinute,
                  flex: 34,
                ),
                _wheel(
                  controller: _ampmCtrl!,
                  count: 2,
                  label: (i) => i == 0 ? 'AM' : 'PM',
                  onChanged: _onAmPm,
                  flex: 44,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
