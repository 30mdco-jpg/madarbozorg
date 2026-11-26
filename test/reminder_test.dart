import 'package:flutter_test/flutter_test.dart';
import 'package:madarbozorg_family/core/dates.dart';
import 'package:madarbozorg_family/models/models.dart';
import 'package:madarbozorg_family/models/reminder.dart';

ScheduleEntry e(String iso, String family) =>
    ScheduleEntry(date: parseIsoDate(iso), familyId: family);

String hm(DateTime d) =>
    '${isoDate(d)} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

void main() {
  final book = ScheduleBook([
    e('2026-11-27', 'B'),
    e('2026-11-28', 'A'),
    e('2026-11-29', 'A'),
    e('2026-12-01', 'B'),
    e('2026-12-03', 'A'),
  ]);

  const defaults = ReminderPrefs.defaults;

  List<PlannedReminder> planFor(String family, DateTime now,
          {ReminderPrefs prefs = defaults, int horizon = 90}) =>
      planReminders(
        book: book,
        familyId: family,
        nowTehran: now,
        prefs: prefs,
        horizonDays: horizon,
      );

  group('planReminders', () {
    final now = DateTime.utc(2026, 11, 26, 10, 0);

    test('پیش‌فرض: شب قبل ۲۰:۰۰ و صبح روز نوبت ۰۸:۰۰', () {
      final plan = planFor('A', now);
      expect(plan.map((p) => hm(p.fireAt)).toList(), [
        '2026-11-27 20:00',
        '2026-11-28 08:00',
        '2026-12-02 20:00',
        '2026-12-03 08:00',
      ]);
    });

    test('نوبت دوروزه فقط قبل از روز اول یادآوری می‌شود', () {
      final plan = planFor('A', now);
      expect(plan.where((p) => isoDate(p.turnStart) == '2026-11-29'), isEmpty);
      expect(plan.first.blockLength, 2);
      expect(plan.first.turnStart, parseIsoDate('2026-11-28'));
    });

    test('متن فارسی اعلان', () {
      final first = planFor('A', now).first;
      expect(first.title, 'یادآوری نوبت');
      expect(first.body,
          'فردا نوبت خانوادهٔ شماست؛ شنبه ۷ آذر ۱۴۰۵ (نوبت ۲ روزه)');
      expect(first.fireText, '۶ آذر ۱۴۰۵، ساعت ۲۰:۰۰');
      final sameDay = planFor('A', now)[1];
      expect(sameDay.body.startsWith('امروز نوبت خانوادهٔ شماست'), isTrue);
    });

    test('شناسه‌ها یکتا هستند', () {
      final ids = planFor('A', now).map((p) => p.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('اعلانِ گذشته ساخته نمی‌شود', () {
      final late = DateTime.utc(2026, 11, 27, 21, 0);
      expect(planFor('A', late).length, 3);
      final turnDayMorningPassed = DateTime.utc(2026, 11, 28, 9, 0);
      expect(planFor('A', turnDayMorningPassed).map((p) => hm(p.fireAt)).toList(),
          ['2026-12-02 20:00', '2026-12-03 08:00']);
    });

    test('وسط نوبت دوروزه برای همان نوبت اعلان جدید نمی‌آید', () {
      final secondDay = DateTime.utc(2026, 11, 29, 7, 0);
      expect(planFor('A', secondDay).map((p) => hm(p.fireAt)).toList(),
          ['2026-12-02 20:00', '2026-12-03 08:00']);
    });

    test('فقط نوبت‌های همان خانواده', () {
      final plan = planFor('B', now);
      expect(plan.map((p) => hm(p.fireAt)).toList(), [
        '2026-11-26 20:00',
        '2026-11-27 08:00',
        '2026-11-30 20:00',
        '2026-12-01 08:00',
      ]);
    });

    test('افق زمانی', () {
      final plan = planFor('A', now, horizon: 3);
      expect(plan.length, 2);
      expect(plan.every((p) => isoDate(p.turnStart) == '2026-11-28'), isTrue);
    });

    test('خاموش بودن یا نبودن قاعده', () {
      expect(planFor('A', now, prefs: defaults.copyWith(enabled: false)), isEmpty);
      expect(planFor('A', now, prefs: defaults.copyWith(rules: const [])), isEmpty);
    });

    test('قاعدهٔ سفارشی: دو روز قبل ساعت ۰۹:۳۰', () {
      const custom = ReminderPrefs(
        enabled: true,
        rules: [ReminderRule(daysBefore: 2, hour: 9, minute: 30)],
      );
      // ۲۶ نوامبر ۰۹:۳۰ (برای نوبت ۲۸ نوامبر) قبل از «اکنون» است و ساخته نمی‌شود.
      expect(planFor('A', now, prefs: custom).map((p) => hm(p.fireAt)).toList(),
          ['2026-12-01 09:30']);
    });
  });

  group('ReminderPrefs', () {
    test('بدون ردیف در دیتابیس، پیش‌فرض‌ها', () {
      final p = ReminderPrefs.fromRow(null);
      expect(p.enabled, isTrue);
      expect(p.rules, ReminderPrefs.defaults.rules);
    });

    test('قاعدهٔ خراب یا تکراری نادیده گرفته می‌شود', () {
      final p = ReminderPrefs.fromRow({
        'reminders_enabled': false,
        'reminder_rules': [
          {'daysBefore': 2, 'time': '09:30'},
          {'daysBefore': 99, 'time': '09:30'},
          'خراب',
          {'daysBefore': 2, 'time': '09:30'},
        ],
      });
      expect(p.enabled, isFalse);
      expect(p.rules, const [ReminderRule(daysBefore: 2, hour: 9, minute: 30)]);
    });

    test('رفت‌وبرگشت به ردیف دیتابیس', () {
      final again = ReminderPrefs.fromRow(ReminderPrefs.defaults.toRow());
      expect(again.rules, ReminderPrefs.defaults.rules);
      expect(again.enabled, ReminderPrefs.defaults.enabled);
    });

    test('توضیح فارسی قاعده', () {
      expect(const ReminderRule(daysBefore: 1, hour: 20, minute: 0).description,
          'یک روز قبل، ساعت ۲۰:۰۰');
      expect(const ReminderRule(daysBefore: 0, hour: 8, minute: 5).description,
          'همان روز نوبت، ساعت ۰۸:۰۵');
    });
  });

  test('ساعت تهران', () {
    expect(tehranNow(DateTime.utc(2026, 11, 25, 20, 30)),
        DateTime.utc(2026, 11, 26, 0, 0));
  });
}
