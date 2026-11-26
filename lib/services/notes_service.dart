import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/note.dart';

const String _noteColumns =
    'id, author_id, author_family_id, to_family_id, body, created_at';

class NotesService {
  SupabaseClient get _client => Supabase.instance.client;

  static const int maxLength = 500;
  static const int retentionDays = 30;

  /// یادداشت‌های ۳۰ روز اخیر که کاربر مجاز به دیدنشان است (قواعد امنیتی در دیتابیس).
  Future<List<Note>> fetchNotes() async {
    final since = DateTime.now()
        .toUtc()
        .subtract(const Duration(days: retentionDays))
        .toIso8601String();
    final rows = await _client
        .from('notes')
        .select(_noteColumns)
        .gte('created_at', since)
        .order('created_at', ascending: false)
        .limit(200);
    return rows.map<Note>((r) => Note.fromMap(r)).toList();
  }

  Future<void> sendNote({
    required String authorFamilyId,
    required String body,
    String? toFamilyId,
  }) async {
    await _client.from('notes').insert({
      'author_family_id': authorFamilyId,
      'to_family_id': toFamilyId,
      'body': body,
    });
  }

  Future<void> deleteNote(String id) async {
    await _client.from('notes').delete().eq('id', id);
  }

  // --- زمان آخرین یادداشتی که برای این کاربر اعلان/نمایش داده شده ---

  static String _seenKey(String userId) => 'notes_last_seen_$userId';

  static Future<DateTime?> lastSeen(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_seenKey(userId));
    return value == null ? null : DateTime.tryParse(value)?.toUtc();
  }

  static Future<void> saveLastSeen(String userId, DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_seenKey(userId), time.toUtc().toIso8601String());
  }

  /// وقتی کاربر تب یادداشت‌ها را می‌بیند، یادداشت‌های خصوصی قبلی دیگر اعلان نمی‌گیرند.
  static Future<void> markSeen({
    required String userId,
    required String familyId,
    required List<Note> notes,
  }) async {
    var newest = await lastSeen(userId) ?? DateTime.now().toUtc();
    for (final n in notes) {
      if (n.toFamilyId == familyId && n.createdAt.isAfter(newest)) {
        newest = n.createdAt;
      }
    }
    await saveLastSeen(userId, newest);
  }
}
