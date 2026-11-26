import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';
import '../models/reminder.dart';

class DataService {
  SupabaseClient get _client => Supabase.instance.client;

  Future<Profile> fetchMyProfile() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw StateError('نشست معتبر وجود ندارد.');
    }
    final row = await _client.from('profiles').select().eq('id', uid).single();
    return Profile.fromMap(row);
  }

  Future<List<Family>> fetchFamilies() async {
    final rows = await _client.from('families').select('id, name');
    return rows.map<Family>((r) => Family.fromMap(r)).toList();
  }

  Future<ScheduleBook> fetchSchedule() async {
    final rows = await _client
        .from('schedules')
        .select('visit_date, family_id, note')
        .order('visit_date', ascending: true);
    return ScheduleBook(rows.map<ScheduleEntry>((r) => ScheduleEntry.fromMap(r)));
  }

  /// تنظیمات یادآوری حساب؛ اگر هنوز ثبت نشده باشد، پیش‌فرض‌ها.
  Future<ReminderPrefs> fetchReminderPrefs(String userId) async {
    final row = await _client
        .from('notification_preferences')
        .select('reminders_enabled, reminder_rules')
        .eq('user_id', userId)
        .maybeSingle();
    return ReminderPrefs.fromRow(row);
  }

  /// ذخیرهٔ تنظیمات. چون مجوز UPDATE روی ستون user_id بسته است، به‌جای upsert
  /// اول به‌روزرسانی و در صورت نبودن ردیف، درج انجام می‌شود.
  Future<void> saveReminderPrefs(String userId, ReminderPrefs prefs) async {
    final values = {
      ...prefs.toRow(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    final updated = await _client
        .from('notification_preferences')
        .update(values)
        .eq('user_id', userId)
        .select('user_id');
    if (updated.isEmpty) {
      await _client.from('notification_preferences').insert({
        'user_id': userId,
        ...prefs.toRow(),
      });
    }
  }
}
