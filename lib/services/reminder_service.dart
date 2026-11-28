import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/reminder.dart';

/// اعلان‌های محلی اندروید (حتی وقتی برنامه بسته است).
///
/// همهٔ زمان‌ها با `inexactAllowWhileIdle` برنامه‌ریزی می‌شوند؛ این روش به مجوز
/// «آلارم دقیق» نیاز ندارد و ممکن است اعلان چند دقیقه دیرتر برسد.
class ReminderService {
  ReminderService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static const String _channelId = 'turn_reminders';
  // شناسه‌های اعلان‌های نوبت کمتر از این حد هستند؛ اعلان یادداشت‌ها شناسهٔ جدا دارد.
  static const int _turnNotificationIdLimit = 1000000;

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      'یادآوری نوبت',
      channelDescription: 'یادآوری نوبت‌های خانوادهٔ شما',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_stat_notify',
      // تصویر آیکن برنامه کنار متن اعلان (فایل را اسکریپت ساخت اضافه می‌کند).
      largeIcon: DrawableResourceAndroidBitmap('notification_large_icon'),
    ),
  );

  static Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('ic_stat_notify'),
    );
    await _plugin.initialize(settings);
    _ready = true;
  }

  static AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  /// آیا کاربر اجازهٔ نمایش اعلان را داده است؟
  static Future<bool> notificationsAllowed() async {
    try {
      await init();
      return await _android?.areNotificationsEnabled() ?? false;
    } catch (_) {
      return false;
    }
  }

  /// درخواست مجوز اعلان (اندروید ۱۳ به بالا). اگر کاربر قبلاً «رد» را دو بار زده باشد،
  /// سیستم دیگر پنجره‌ای نشان نمی‌دهد و باید از تنظیمات گوشی فعال شود.
  static Future<bool> requestPermission() async {
    try {
      await init();
      return await _android?.requestNotificationsPermission() ?? false;
    } catch (_) {
      return false;
    }
  }

  /// فقط یادآورهای نوبت را پاک می‌کند تا اعلان‌های یادداشت خانوادگی باقی بمانند.
  static Future<void> _cancelTurnReminders() async {
    final pending = await _plugin.pendingNotificationRequests();
    for (final request in pending) {
      if (request.id >= 0 && request.id < _turnNotificationIdLimit) {
        await _plugin.cancel(request.id);
      }
    }
  }

  /// یادآورهای نوبت را از نو برنامه‌ریزی می‌کند و اعلان‌های یادداشت را نگه می‌دارد.
  /// تعداد اعلان‌های برنامه‌ریزی‌شده را برمی‌گرداند.
  static Future<int> replaceAll(List<PlannedReminder> items) async {
    await init();
    await _cancelTurnReminders();
    final tehran = tz.getLocation('Asia/Tehran');
    var count = 0;
    for (final r in items) {
      // fireAt «ساعت دیوار» تهران است؛ ۳:۳۰ کم می‌کنیم تا لحظهٔ واقعی (UTC) به دست آید.
      final instant = DateTime.utc(
        r.fireAt.year,
        r.fireAt.month,
        r.fireAt.day,
        r.fireAt.hour,
        r.fireAt.minute,
      ).subtract(const Duration(hours: 3, minutes: 30));
      await _plugin.zonedSchedule(
        r.id,
        r.title,
        r.body,
        tz.TZDateTime.from(instant, tehran),
        _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      count++;
    }
    return count;
  }

  static Future<void> cancelAll() async {
    try {
      await init();
      await _cancelTurnReminders();
    } catch (_) {
      // نبودن اعلان برای لغو، خطای مهمی نیست.
    }
  }

  /// اعلان آزمایشی فوری برای اطمینان از کار کردن اعلان‌ها و نمایش درست فارسی.
  static Future<bool> showTest() async {
    try {
      await init();
      await _plugin.show(
        999999,
        'آزمایش یادآوری',
        'اگر این پیام را می‌بینید، اعلان‌های برنامه درست کار می‌کنند.',
        _details,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
