import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workmanager/workmanager.dart';

import '../config/app_config.dart';
import '../models/note.dart';
import 'notes_service.dart';

/// اعلان یادداشت‌های خصوصی (کانال جدا از یادآوری نوبت).
class NoteAlerts {
  NoteAlerts._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'family_notes',
      'یادداشت‌ها',
      channelDescription: 'یادداشت‌های خصوصی که خانواده‌های دیگر برای شما می‌فرستند',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_stat_notify',
      // تصویر آیکن برنامه کنار متن اعلان (فایل را اسکریپت ساخت اضافه می‌کند).
      largeIcon: DrawableResourceAndroidBitmap('notification_large_icon'),
    ),
  );

  static Future<void> init() async {
    if (_ready) return;
    await _plugin.initialize(const InitializationSettings(
      android: AndroidInitializationSettings('ic_stat_notify'),
    ));
    _ready = true;
  }

  static Future<void> show({
    required String noteId,
    required String title,
    required String body,
  }) async {
    await init();
    // شناسهٔ پایدار از UUID یادداشت ساخته می‌شود تا اعلان تکراری جایگزین شود.
    final compactId = noteId.replaceAll('-', '');
    final suffix = int.tryParse(
          compactId.substring(compactId.length - 8),
          radix: 16,
        ) ??
        0;
    final id = 1000000000 + (suffix % 1000000);
    await _plugin.show(id, title, body, _details);
  }
}

/// یادداشت‌های خصوصی جدید برای خانوادهٔ کاربر را می‌گیرد و اعلان می‌دهد.
/// Supabase باید قبلاً مقداردهی اولیه شده باشد.
Future<void> checkNewPrivateNotes() async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return;

  final profile =
      await client.from('profiles').select('family_id').eq('id', user.id).single();
  final myFamily = profile['family_id'] as String;

  final previous = await NotesService.lastSeen(user.id);
  // در اولین اجرای پس‌زمینه، پیام‌های تازهٔ ۲۰ دقیقهٔ گذشته را هم بررسی کن.
  final last = previous ??
      DateTime.now().toUtc().subtract(const Duration(minutes: 20));

  final rows = await client
      .from('notes')
      .select('id, author_id, author_family_id, to_family_id, body, created_at')
      .eq('to_family_id', myFamily)
      .gt('created_at', last.toIso8601String())
      .order('created_at', ascending: true)
      .limit(20);
  if (rows.isEmpty) {
    if (previous == null) {
      await NotesService.saveLastSeen(user.id, DateTime.now().toUtc());
    }
    return;
  }

  final familyRows = await client.from('families').select('id, name');
  final names = <String, String>{
    for (final f in familyRows) f['id'] as String: f['name'] as String,
  };

  var newest = last;
  for (final row in rows) {
    final note = Note.fromMap(row);
    if (note.createdAt.isAfter(newest)) newest = note.createdAt;
    if (note.authorFamilyId == myFamily) continue;
    final from = names[note.authorFamilyId];
    final body =
        note.body.length > 120 ? '${note.body.substring(0, 120)}…' : note.body;
    await NoteAlerts.show(
      noteId: note.id,
      title: from == null
          ? 'یادداشت خصوصی جدید'
          : 'یادداشت خصوصی از خانوادهٔ $from',
      body: body,
    );
  }
  await NotesService.saveLastSeen(user.id, newest);
}

/// نقطهٔ ورودی کار پس‌زمینه (در یک محیط جدا از برنامه اجرا می‌شود).
@pragma('vm:entry-point')
void notesCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabasePublishableKey,
      );
      await NoteAlerts.init();
      await checkNewPrivateNotes();
    } catch (_) {
      // خطای شبکه یا نشست منقضی‌شده: دفعهٔ بعد دوباره تلاش می‌شود.
    }
    return true;
  });
}

/// بررسی دوره‌ای (حداقل هر ۱۵ دقیقه، طبق محدودیت اندروید) را ثبت می‌کند.
Future<void> registerNotesChecker() async {
  await Workmanager().initialize(notesCallbackDispatcher);
  await Workmanager().registerPeriodicTask(
    'notes-check',
    'notes-check',
    frequency: const Duration(minutes: 15),
    constraints: Constraints(networkType: NetworkType.connected),
  );
}
