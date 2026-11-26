import 'package:flutter/material.dart';

import '../core/dates.dart';
import '../core/jalali.dart';
import '../models/models.dart';
import 'theme.dart';

const List<String> _weekdayShort = ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'];

/// تقویم ماهانهٔ شمسی؛ هفته از شنبه شروع می‌شود.
class CalendarTab extends StatefulWidget {
  const CalendarTab({
    super.key,
    required this.profile,
    required this.families,
    required this.book,
    required this.onRefresh,
  });

  final Profile profile;
  final Map<String, Family> families;
  final ScheduleBook book;
  final Future<void> Function() onRefresh;

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    final j = Jalali.fromDate(tehranToday());
    _year = j.year;
    _month = j.month;
  }

  void _shiftMonth(int delta) {
    var m = _month + delta;
    var y = _year;
    while (m > 12) {
      m -= 12;
      y++;
    }
    while (m < 1) {
      m += 12;
      y--;
    }
    setState(() {
      _year = y;
      _month = m;
    });
  }

  String _name(String id) => widget.families[id]?.name ?? '—';

  void _showDay(DateTime date) {
    final entry = widget.book.on(date);
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final name = entry == null ? null : _name(entry.familyId);
        final block = widget.book.blockLengthAt(date);
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(Jalali.fromDate(date).formatWithWeekday(),
                  style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text('${date.year}/${date.month}/${date.day}',
                  textDirection: TextDirection.ltr),
              const SizedBox(height: 16),
              if (entry == null)
                const Text('برای این روز نوبتی ثبت نشده است.')
              else ...[
                Row(
                  children: [
                    CircleAvatar(radius: 8, backgroundColor: familyColor(name!)),
                    const SizedBox(width: 8),
                    Text('نوبت: $name',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                if (entry.familyId == widget.profile.familyId)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text('این روز نوبت خانوادهٔ شماست.'),
                  ),
                if (block > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('جزو یک نوبت ${toFa(block)} روزه'),
                  ),
                if ((entry.note ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(entry.note!),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// دکمهٔ گردِ ماه قبل/بعد. جهت فلش مستقل از راست‌به‌چپ بودن صفحه تنظیم شده:
  /// ماه قبل سمت راست (فلش به راست)، ماه بعد سمت چپ (فلش به چپ).
  Widget _arrowButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: headerColor.withAlpha(22),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(
              icon,
              color: headerColor,
              size: 26,
              textDirection: TextDirection.ltr,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = tehranToday();
    final first = Jalali(_year, _month, 1);
    final blanks = first.weekdayIndex;
    final length = Jalali.monthLength(_year, _month);
    final totalCells = ((blanks + length + 6) ~/ 7) * 7;

    final legend = widget.families.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _arrowButton(
                icon: Icons.chevron_right,
                tooltip: 'ماه قبل',
                onPressed: () => _shiftMonth(-1),
              ),
              Text(
                '${Jalali.monthNames[_month - 1]} ${toFa(_year)}',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              _arrowButton(
                icon: Icons.chevron_left,
                tooltip: 'ماه بعد',
                onPressed: () => _shiftMonth(1),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Center(
                    child: Text(
                      _weekdayShort[i],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: i >= 5 ? theme.colorScheme.error : null,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          GridView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: totalCells,
            itemBuilder: (context, index) {
              final day = index - blanks + 1;
              if (day < 1 || day > length) return const SizedBox.shrink();
              final date = Jalali(_year, _month, day).toDate();
              final entry = widget.book.on(date);
              final isToday = date == today;
              final mine = entry?.familyId == widget.profile.familyId;
              final name = entry == null ? null : _name(entry.familyId);
              final block = widget.book.blockLengthAt(date);

              // نوبت خانوادهٔ کاربر: رنگ پررنگ و نوشتهٔ سفید.
              // نوبت خانواده‌های دیگر: رنگ کم‌رنگ (۵۰٪ شفاف) و نوشتهٔ مشکی.
              Color bg;
              Color fg;
              if (name == null) {
                bg = theme.colorScheme.outline.withAlpha(25);
                fg = Colors.black87;
              } else if (mine) {
                bg = familyColor(name);
                fg = Colors.white;
              } else {
                bg = familyPale(name);
                fg = Colors.black;
              }
              return InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _showDay(date),
                child: Container(
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isToday ? Colors.black87 : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        toFa(day),
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: fg),
                      ),
                      if (name != null)
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(name,
                              style: TextStyle(fontSize: 10, color: fg)),
                        ),
                      if (block > 1)
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('${toFa(block)} روزه',
                              style: TextStyle(fontSize: 8, color: fg)),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              for (final f in legend)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(radius: 7, backgroundColor: familyColor(f.name)),
                    const SizedBox(width: 6),
                    Text(f.name),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'روزهای پررنگ با نوشتهٔ سفید نوبت خانوادهٔ شماست و روزهای کم‌رنگ مال خانواده‌های دیگر. دورِ روز امروز قاب دارد.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
