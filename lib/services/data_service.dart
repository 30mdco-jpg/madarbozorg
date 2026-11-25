import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';

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
}
