import 'package:flutter/material.dart';

import '../core/dates.dart';
import '../core/jalali.dart';
import '../models/models.dart';
import 'theme.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({
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

  String _name(String familyId) => families[familyId]?.name ?? '—';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = tehranToday();
    final todayEntry = book.on(today);
    final tomorrowEntry = book.on(addDays(today, 1));
    final upcoming = book.upcomingFor(profile.familyId, today, limit: 4);
    final myName = _name(profile.familyId);
    final mineToday = todayEntry?.familyId == profile.familyId;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'خانوادهٔ $myName',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Chip(
                avatar: Icon(
                  profile.isAdmin ? Icons.admin_panel_settings : Icons.person,
                  size: 18,
                ),
                label: Text(profile.isAdmin ? 'مدیر برنامه' : 'عضو'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _TurnCard(
            title: 'امروز',
            date: today,
            entry: todayEntry,
            name: todayEntry == null ? null : _name(todayEntry.familyId),
            highlight: mineToday,
            highlightText: 'امروز نوبت شماست',
            block: book.blockLengthAt(today),
          ),
          const SizedBox(height: 12),
          _TurnCard(
            title: 'فردا',
            date: addDays(today, 1),
            entry: tomorrowEntry,
            name: tomorrowEntry == null ? null : _name(tomorrowEntry.familyId),
            highlight: tomorrowEntry?.familyId == profile.familyId,
            highlightText: 'فردا نوبت شماست',
            block: book.blockLengthAt(addDays(today, 1)),
          ),
          const SizedBox(height: 20),
          Text('نوبت‌های بعدیِ خانوادهٔ شما', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (upcoming.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('نوبت آیندهٔ ثبت‌شده‌ای برای خانوادهٔ شما وجود ندارد.'),
              ),
            )
          else
            for (final e in upcoming)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.event_available),
                  title: Text(Jalali.fromDate(e.date).formatWithWeekday()),
                  subtitle: Text(relativeDaysText(daysBetween(today, e.date))),
                  trailing: book.blockLengthAt(e.date) > 1
                      ? Text('${toFa(book.blockLengthAt(e.date))} روزه')
                      : null,
                ),
              ),
        ],
      ),
    );
  }
}

class _TurnCard extends StatelessWidget {
  const _TurnCard({
    required this.title,
    required this.date,
    required this.entry,
    required this.name,
    required this.highlight,
    required this.highlightText,
    required this.block,
  });

  final String title;
  final DateTime date;
  final ScheduleEntry? entry;
  final String? name;
  final bool highlight;
  final String highlightText;
  final int block;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTahereh = name == 'طاهره';
    final color = name == null ? theme.colorScheme.outline : familyColor(name!);
    // کارت طاهره: زمینهٔ هلویی (fe8a7b) با کادر و نوشتهٔ قرمز تیره (b12411)
    final accent = isTahereh ? taherehDarkColor : color;
    return Card(
      color: isTahereh
          ? taherehLightColor.withAlpha(highlight ? 255 : 150)
          : color.withAlpha(highlight ? 70 : 28),
      shape: isTahereh
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: taherehDarkColor, width: 2.5),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(Jalali.fromDate(date).formatWithWeekday()),
            const SizedBox(height: 8),
            if (entry == null)
              const Text('برای این روز نوبتی ثبت نشده است.')
            else ...[
              Text(
                'نوبت: $name',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold, color: accent),
              ),
              if (block > 1) Text('نوبت ${toFa(block)} روزه'),
              if (highlight)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    highlightText,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              if ((entry!.note ?? '').isNotEmpty) Text(entry!.note!),
            ],
          ],
        ),
      ),
    );
  }
}
