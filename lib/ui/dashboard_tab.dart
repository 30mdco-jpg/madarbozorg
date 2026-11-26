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
    final today = tehranToday();
    final todayEntry = book.on(today);
    final tomorrowEntry = book.on(addDays(today, 1));
    final upcoming = book.upcomingFor(profile.familyId, today, limit: 4);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          _TurnCard(
            title: 'امروز',
            date: today,
            entry: todayEntry,
            name: todayEntry == null ? null : _name(todayEntry.familyId),
            highlight: todayEntry?.familyId == profile.familyId,
            highlightText: 'امروز نوبت شماست',
            block: book.blockLengthAt(today),
          ),
          const SizedBox(height: 14),
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
          const Text(
            'نوبت‌های بعدیِ خانوادهٔ شما',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
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
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFDE3E7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.event_available,
                        color: Color(0xFFE5384F),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Jalali.fromDate(e.date).formatWithWeekday(),
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            relativeDaysText(daysBetween(today, e.date)),
                            style: const TextStyle(
                              color: Color(0xFFB00020),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (book.blockLengthAt(e.date) > 1)
                      Text('${toFa(book.blockLengthAt(e.date))} روزه'),
                  ],
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
    final dark = name == null ? Colors.blueGrey : familyColor(name!);
    final light = name == null ? const Color(0xFFE0E4EA) : familyShade(name!).light;
    final bodyText = textOn(light);
    final note = entry?.note ?? '';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: dark,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                '$title : ${Jalali.fromDate(date).formatWithWeekday()}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              width: double.infinity,
              color: light,
              padding: const EdgeInsets.all(16),
              child: entry == null
                  ? Text(
                      'برای این روز نوبتی ثبت نشده است.',
                      style: TextStyle(color: bodyText),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  'نوبت: $name',
                                  style: TextStyle(
                                    color: bodyText,
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (block > 0)
                                Text(
                                  'نوبت ${toFa(block)} روزه',
                                  style: TextStyle(color: bodyText, fontSize: 15),
                                ),
                              if (highlight)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    highlightText,
                                    style: TextStyle(
                                      color: bodyText,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              if (note.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    note,
                                    style: TextStyle(color: bodyText),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const CalendarGlyph(size: 84),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// آیکون تقویم و ساعت که با کد کشیده می‌شود.
class CalendarGlyph extends StatelessWidget {
  const CalendarGlyph({super.key, this.size = 84});

  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size(size, size), painter: _CalendarPainter());
}

class _CalendarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    const line = Color(0xFF3B6AA0);
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(s * 0.04, s * 0.12, s * 0.8, s * 0.72),
      Radius.circular(s * 0.08),
    );
    canvas.drawRRect(body, Paint()..color = const Color(0xFFE6EEF7));
    canvas.save();
    canvas.clipRRect(body);
    canvas.drawRect(
      Rect.fromLTWH(s * 0.04, s * 0.12, s * 0.8, s * 0.17),
      Paint()..color = line,
    );
    canvas.restore();
    canvas.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.03
        ..color = line,
    );
    final ring = Paint()..color = const Color(0xFF8FA9C9);
    for (var i = 0; i < 4; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(s * (0.14 + i * 0.18), s * 0.04, s * 0.06, s * 0.14),
          Radius.circular(s * 0.03),
        ),
        ring,
      );
    }
    final cell = Paint()..color = const Color(0xFF7F9CC0);
    final accent = Paint()..color = const Color(0xFFF26B1D);
    for (var r = 0; r < 3; r++) {
      for (var c = 0; c < 4; c++) {
        canvas.drawRect(
          Rect.fromLTWH(
            s * (0.12 + c * 0.17),
            s * (0.37 + r * 0.14),
            s * 0.11,
            s * 0.09,
          ),
          (r == 0 && c == 1) ? accent : cell,
        );
      }
    }
    final center = Offset(s * 0.72, s * 0.72);
    final radius = s * 0.26;
    canvas.drawCircle(center, radius, Paint()..color = Colors.white);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.035
        ..color = const Color(0xFF2F5C93),
    );
    final hand = Paint()
      ..color = const Color(0xFF2F5C93)
      ..strokeWidth = s * 0.03
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, Offset(center.dx, center.dy - radius * 0.6), hand);
    canvas.drawLine(
      center,
      Offset(center.dx + radius * 0.45, center.dy + radius * 0.2),
      hand,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
