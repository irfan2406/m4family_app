import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
  final bool isDark;
  final bool showTime;
  final ValueChanged<DateTime> onChanged;

  const WheelDateTimePicker({
    super.key,
    required this.initial,
    this.minDate,
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

  // 0-indexed month values available for the currently selected year. With a
  // minDate, the min year excludes months before minDate.month (web
  // `availableMonths`); with no minDate, every month is always available.
  List<int> _availableMonthIdx() {
    final min = widget.minDate;
    if (min != null && _value.year == min.year) {
      return List.generate(12 - min.month + 1, (i) => min.month - 1 + i);
    }
    return List.generate(12, (i) => i);
  }

  // Day-of-month values available for the current year+month. With a
  // minDate, the min year+month excludes days before minDate.day (web
  // `availableDays`); with no minDate, every day in the month is available.
  List<int> _availableDays() {
    final total = _daysInMonth(_value.year, _value.month);
    final min = widget.minDate;
    if (min != null && _value.year == min.year && _value.month == min.month) {
      final count = total - min.day + 1;
      return List.generate(count < 1 ? 1 : count, (i) => min.day + i);
    }
    return List.generate(total, (i) => i + 1);
  }

  @override
  void initState() {
    super.initState();
    _value = widget.initial;
    final min = widget.minDate;
    _years = min != null
        ? List.generate(11, (i) => min.year + i)
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
    final min = widget.minDate;
    final year = _years[idx];
    var next = DateTime(
      year,
      _value.month,
      _value.day,
      _value.hour,
      _value.minute,
    );
    final months = (min != null && year == min.year)
        ? List.generate(12 - min.month + 1, (i) => min.month - 1 + i)
        : List.generate(12, (i) => i);
    if (!months.contains(next.month - 1)) {
      next = DateTime(year, months.first + 1, 1, next.hour, next.minute);
    }
    final maxDay = _daysInMonth(next.year, next.month);
    final dayFloor =
        (min != null && next.year == min.year && next.month == min.month)
        ? min.day
        : 1;
    if (next.day > maxDay) {
      next = DateTime(next.year, next.month, maxDay, next.hour, next.minute);
    }
    if (next.day < dayFloor) {
      next = DateTime(next.year, next.month, dayFloor, next.hour, next.minute);
    }
    _emit(next);
    _resyncMonthAndDay();
  }

  void _onMonth(int idx) {
    final min = widget.minDate;
    final months = _availableMonthIdx();
    final month = months[idx] + 1;
    var next = DateTime(
      _value.year,
      month,
      _value.day,
      _value.hour,
      _value.minute,
    );
    final maxDay = _daysInMonth(next.year, next.month);
    final dayFloor =
        (min != null && next.year == min.year && next.month == min.month)
        ? min.day
        : 1;
    if (next.day > maxDay) {
      next = DateTime(next.year, next.month, maxDay, next.hour, next.minute);
    }
    if (next.day < dayFloor) {
      next = DateTime(next.year, next.month, dayFloor, next.hour, next.minute);
    }
    _emit(next);
    _resyncMonthAndDay();
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

  Widget _wheel({
    required FixedExtentScrollController controller,
    required int count,
    required String Function(int) label,
    required ValueChanged<int> onChanged,
    double width = 44,
  }) {
    final isDark = widget.isDark;
    return SizedBox(
      width: width,
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
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black,
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
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
        ),
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.02),
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
                    color: (isDark ? Colors.white : Colors.black).withValues(
                      alpha: 0.1,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _wheel(
                controller: _dayCtrl,
                count: days.length,
                label: (i) => '${days[i]}',
                onChanged: _onDay,
                width: 40,
              ),
              _wheel(
                controller: _monthCtrl,
                count: months.length,
                label: (i) => _months[months[i]],
                onChanged: _onMonth,
                width: 56,
              ),
              _wheel(
                controller: _yearCtrl,
                count: _years.length,
                label: (i) => '${_years[i]}',
                onChanged: _onYear,
                width: 60,
              ),
              if (widget.showTime) ...[
                const SizedBox(width: 10),
                _wheel(
                  controller: _hourCtrl!,
                  count: 12,
                  label: (i) => '${i + 1}',
                  onChanged: _onHour,
                  width: 34,
                ),
                Text(
                  ':',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: (isDark ? Colors.white : Colors.black).withValues(
                      alpha: 0.3,
                    ),
                  ),
                ),
                _wheel(
                  controller: _minuteCtrl!,
                  count: 60,
                  label: (i) => i.toString().padLeft(2, '0'),
                  onChanged: _onMinute,
                  width: 34,
                ),
                _wheel(
                  controller: _ampmCtrl!,
                  count: 2,
                  label: (i) => i == 0 ? 'AM' : 'PM',
                  onChanged: _onAmPm,
                  width: 44,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
