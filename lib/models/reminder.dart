import '../core/dates.dart';
import '../core/jalali.dart';
import 'models.dart';

/// یک قاعدهٔ یادآوری: «چند روز قبل از شروع نوبت، چه ساعتی».
class ReminderRule {
  const ReminderRule({
    required this.daysBefore,
    required this.hour,
    required this.minute,
  });

  final int daysBefore; // ۰ = همان روز نوبت
  final int hour;
  final int minute;

  String get timeText =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  Map<String, dynamic> toJson() => {'daysBefore': daysBefore, 'time': timeText};

  /// اگر داده خراب بود `null` برمی‌گرداند.
  static ReminderRule? tryFromJson(Object? raw) {
    if (raw is! Map) return null;
    final days = raw['daysBefore'];
    final time = raw['time'];
    if (days is! int || time is! String) return null;
    final parts = time.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    if (days < 0 || days > 14 || h < 0 || h > 23 || m < 0 || m > 59) return null;
    return ReminderRule(daysBefore: days, hour: h, minute: m);
  }

  String get daysLabel {
    switch (daysBefore) {
      case 0:
        return 'همان روز نوبت';
      case 1:
        return 'یک روز قبل';
      case 2:
        return 'دو روز قبل';
      case 3:
        return 'سه روز قبل';
      case 7:
        return 'یک هفته قبل';
      default:
        return '${toFa(daysBefore)} روز قبل';
    }
  }

  String get description => '$daysLabel، ساعت ${toFa(timeText)}';

  @override
  bool operator ==(Object other) =>
      other is ReminderRule &&
      other.daysBefore == daysBefore &&
      other.hour == hour &&
      other.minute == minute;

  @override
  int get hashCode => Object.hash(daysBefore, hour, minute);
}

/// تنظیمات یادآوری هر حساب (روی سرور ذخیره می‌شود تا روی چند گوشی یکسان باشد).
class ReminderPrefs {
  const ReminderPrefs({required this.enabled, required this.rules});

  final bool enabled;
  final List<ReminderRule> rules;

  static const int maxRules = 4;

  static const ReminderPrefs defaults = ReminderPrefs(
    enabled: true,
    rules: [
      ReminderRule(daysBefore: 1, hour: 20, minute: 0),
      ReminderRule(daysBefore: 0, hour: 8, minute: 0),
    ],
  );

  ReminderPrefs copyWith({bool? enabled, List<ReminderRule>? rules}) =>
      ReminderPrefs(enabled: enabled ?? this.enabled, rules: rules ?? this.rules);

  factory ReminderPrefs.fromRow(Map<String, dynamic>? row) {
    if (row == null) return defaults;
    final enabled = row['reminders_enabled'];
    final rawRules = row['reminder_rules'];
    final rules = <ReminderRule>[];
    if (rawRules is List) {
      for (final r in rawRules) {
        final rule = ReminderRule.tryFromJson(r);
        if (rule != null && !rules.contains(rule)) rules.add(rule);
      }
    }
    return ReminderPrefs(enabled: enabled is bool ? enabled : true, rules: rules);
  }

  Map<String, dynamic> toRow() => {
        'reminders_enabled': enabled,
        'reminder_rules': rules.map((r) => r.toJson()).toList(),
      };
}

/// یک اعلان برنامه‌ریزی‌شده. [fireAt] «ساعت دیوار» تهران با برچسب UTC است.
class PlannedReminder {
  const PlannedReminder({
    required this.id,
    required this.fireAt,
    required this.turnStart,
    required this.daysBefore,
    required this.blockLength,
  });

  final int id;
  final DateTime fireAt;
  final DateTime turnStart;
  final int daysBefore;
  final int blockLength;

  String get title => 'یادآوری نوبت';

  String get body {
    final when = daysBefore == 0
        ? 'امروز'
        : (daysBefore == 1 ? 'فردا' : '${toFa(daysBefore)} روز دیگر');
    final span = blockLength > 1 ? ' (نوبت ${toFa(blockLength)} روزه)' : '';
    return '$when نوبت خانوادهٔ شماست؛ '
        '${Jalali.fromDate(turnStart).formatWithWeekday()}$span';
  }

  /// مثلاً «۴ آذر ۱۴۰۵، ساعت ۲۰:۰۰»
  String get fireText {
    final hh = fireAt.hour.toString().padLeft(2, '0');
    final mm = fireAt.minute.toString().padLeft(2, '0');
    return '${Jalali.fromDate(fireAt).format()}، ساعت ${toFa('$hh:$mm')}';
  }
}

/// برنامه‌ریزی یادآورها (تابع خالص و قابل تست).
///
/// - فقط برای نوبت‌های خانوادهٔ [familyId] و از «امروز» تا [horizonDays] روز بعد.
/// - نوبت چندروزهٔ پشت‌سرهم (مثل پنجشنبه‌وجمعه) فقط یک بار، قبل از روز اول، یادآوری می‌شود.
/// - اعلانی که زمانش گذشته باشد ساخته نمی‌شود.
List<PlannedReminder> planReminders({
  required ScheduleBook book,
  required String familyId,
  required DateTime nowTehran,
  required ReminderPrefs prefs,
  int horizonDays = 90,
}) {
  if (!prefs.enabled || prefs.rules.isEmpty) return const [];

  final today = DateTime.utc(nowTehran.year, nowTehran.month, nowTehran.day);
  final limit = addDays(today, horizonDays);
  final epoch = DateTime.utc(2020, 1, 1);
  final result = <PlannedReminder>[];

  for (final entry in book.entries) {
    if (entry.familyId != familyId) continue;
    if (entry.date.isBefore(today) || entry.date.isAfter(limit)) continue;
    if (book.on(addDays(entry.date, -1))?.familyId == familyId) continue;

    final block = book.blockLengthAt(entry.date);
    final epochDay = entry.date.difference(epoch).inDays.abs();
    for (var i = 0; i < prefs.rules.length; i++) {
      final rule = prefs.rules[i];
      final day = addDays(entry.date, -rule.daysBefore);
      final fire = DateTime.utc(day.year, day.month, day.day, rule.hour, rule.minute);
      if (!fire.isAfter(nowTehran)) continue;
      result.add(PlannedReminder(
        id: epochDay * 8 + i,
        fireAt: fire,
        turnStart: entry.date,
        daysBefore: rule.daysBefore,
        blockLength: block,
      ));
    }
  }
  result.sort((a, b) => a.fireAt.compareTo(b.fireAt));
  return result;
}
