import 'jalali.dart';

/// ابزارهای تاریخ. همهٔ تاریخ‌های «روزی» به‌صورت UTC و بدون ساعت نگه‌داری می‌شوند
/// تا مشکل ساعت تابستانی یا منطقهٔ زمانی دستگاه پیش نیاید.
String isoDate(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

DateTime parseIsoDate(String s) {
  final p = s.split('-');
  return DateTime.utc(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}

/// تاریخ امروز به وقت تهران (UTC+3:30، بدون ساعت تابستانی).
DateTime tehranToday([DateTime? nowUtc]) {
  final t = (nowUtc ?? DateTime.now().toUtc())
      .add(const Duration(hours: 3, minutes: 30));
  return DateTime.utc(t.year, t.month, t.day);
}

/// «ساعت دیوار» تهران، به‌صورت DateTime با برچسب UTC (فقط برای مقایسه و محاسبه).
DateTime tehranNow([DateTime? nowUtc]) =>
    (nowUtc ?? DateTime.now().toUtc()).add(const Duration(hours: 3, minutes: 30));

DateTime addDays(DateTime d, int n) => DateTime.utc(d.year, d.month, d.day + n);

int daysBetween(DateTime from, DateTime to) => to.difference(from).inDays;

String relativeDaysText(int days) {
  if (days <= 0) return 'امروز';
  if (days == 1) return 'فردا';
  return '${toFa(days)} روز دیگر';
}
