import '../core/dates.dart';

class Family {
  const Family({required this.id, required this.name});

  final String id;
  final String name;

  factory Family.fromMap(Map<String, dynamic> m) =>
      Family(id: m['id'] as String, name: m['name'] as String);
}

class Profile {
  const Profile({
    required this.id,
    required this.familyId,
    required this.username,
    required this.displayName,
    required this.isAdmin,
    required this.mustChangePassword,
  });

  final String id;
  final String familyId;
  final String username;
  final String displayName;
  final bool isAdmin;
  final bool mustChangePassword;

  factory Profile.fromMap(Map<String, dynamic> m) => Profile(
        id: m['id'] as String,
        familyId: m['family_id'] as String,
        username: m['username'] as String,
        displayName: (m['display_name'] as String?) ?? (m['username'] as String),
        isAdmin: (m['is_admin'] as bool?) ?? false,
        mustChangePassword: (m['must_change_password'] as bool?) ?? false,
      );
}

class ScheduleEntry {
  const ScheduleEntry({
    required this.date,
    required this.familyId,
    this.note,
  });

  final DateTime date;
  final String familyId;
  final String? note;

  factory ScheduleEntry.fromMap(Map<String, dynamic> m) => ScheduleEntry(
        date: parseIsoDate(m['visit_date'] as String),
        familyId: m['family_id'] as String,
        note: m['note'] as String?,
      );
}

/// مجموعهٔ نوبت‌ها با پرس‌وجوهای مورد نیاز داشبورد و تقویم.
class ScheduleBook {
  ScheduleBook(Iterable<ScheduleEntry> entries)
      : _sorted = (entries.toList()..sort((a, b) => a.date.compareTo(b.date))),
        _byDate = {for (final e in entries) isoDate(e.date): e};

  final List<ScheduleEntry> _sorted;
  final Map<String, ScheduleEntry> _byDate;

  bool get isEmpty => _sorted.isEmpty;
  int get length => _sorted.length;

  /// همهٔ نوبت‌ها به ترتیب تاریخ (فقط‌خواندنی).
  List<ScheduleEntry> get entries => List.unmodifiable(_sorted);

  ScheduleEntry? on(DateTime day) => _byDate[isoDate(day)];

  /// نوبت‌های بعدی یک خانواده، کاملاً بعد از [after].
  List<ScheduleEntry> upcomingFor(
    String familyId,
    DateTime after, {
    int limit = 3,
  }) {
    final result = <ScheduleEntry>[];
    for (final e in _sorted) {
      if (e.date.isAfter(after) && e.familyId == familyId) {
        result.add(e);
        if (result.length >= limit) break;
      }
    }
    return result;
  }

  /// طول بلوک روزهای پشت‌سرهم یک خانواده که [day] در آن قرار دارد
  /// (۱ = نوبت یک‌روزه، ۲ = نوبت دوروزه، ...). اگر نوبتی نباشد ۰.
  int blockLengthAt(DateTime day) {
    final entry = on(day);
    if (entry == null) return 0;
    var length = 1;
    var back = addDays(day, -1);
    while (on(back)?.familyId == entry.familyId) {
      length++;
      back = addDays(back, -1);
    }
    var forward = addDays(day, 1);
    while (on(forward)?.familyId == entry.familyId) {
      length++;
      forward = addDays(forward, 1);
    }
    return length;
  }
}
