/// تقویم شمسی (جلالی). الگوریتم بر پایهٔ jalaali و با داده‌های واقعی برنامه
/// (۴۸۰ روز از ۵ آذر ۱۴۰۵ تا ۲۹ اسفند ۱۴۰۶) و رفت‌وبرگشت روزانه صحت‌سنجی شده است.
class Jalali {
  const Jalali(this.year, this.month, this.day);

  final int year;
  final int month;
  final int day;

  static const List<String> monthNames = [
    'فروردین',
    'اردیبهشت',
    'خرداد',
    'تیر',
    'مرداد',
    'شهریور',
    'مهر',
    'آبان',
    'آذر',
    'دی',
    'بهمن',
    'اسفند',
  ];

  /// هفته از شنبه شروع می‌شود (اندیس ۰ = شنبه، ۶ = جمعه).
  static const List<String> weekdayNames = [
    'شنبه',
    'یکشنبه',
    'دوشنبه',
    'سه‌شنبه',
    'چهارشنبه',
    'پنجشنبه',
    'جمعه',
  ];

  factory Jalali.fromDate(DateTime d) => _d2j(_g2d(d.year, d.month, d.day));

  /// تاریخ میلادی متناظر (به‌صورت UTC و بدون ساعت).
  DateTime toDate() {
    final g = _d2g(_j2d(year, month, day));
    return DateTime.utc(g[0], g[1], g[2]);
  }

  /// ۰ = شنبه ... ۶ = جمعه
  int get weekdayIndex => (toDate().weekday + 1) % 7;

  String get monthName => monthNames[month - 1];
  String get weekdayName => weekdayNames[weekdayIndex];

  static bool isLeapYear(int y) => _jalCal(y).leap == 0;

  static int monthLength(int y, int m) {
    if (m <= 6) return 31;
    if (m <= 11) return 30;
    return isLeapYear(y) ? 30 : 29;
  }

  /// مثلاً «۵ آذر ۱۴۰۵»
  String format() => '${toFa(day)} $monthName ${toFa(year)}';

  /// مثلاً «پنجشنبه ۵ آذر ۱۴۰۵»
  String formatWithWeekday() => '$weekdayName ${format()}';

  @override
  bool operator ==(Object other) =>
      other is Jalali &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => '$year/$month/$day';
}

/// تبدیل ارقام انگلیسی به فارسی.
String toFa(Object value) {
  const digits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
  final buffer = StringBuffer();
  for (final unit in value.toString().codeUnits) {
    final i = unit - 48;
    buffer.write((i >= 0 && i <= 9) ? digits[i] : String.fromCharCode(unit));
  }
  return buffer.toString();
}

// ---------------------------------------------------------------------------
// جزئیات الگوریتم (تقسیم صحیح به سمت صفر، مشابه jalaali-js)
// ---------------------------------------------------------------------------

int _div(int a, int b) => a ~/ b;
int _mod(int a, int b) => a - (a ~/ b) * b;

const List<int> _breaks = [
  -61, 9, 38, 199, 426, 686, 756, 818, 1111, 1181, //
  1210, 1635, 2060, 2097, 2192, 2262, 2324, 2394, 2456, 3178,
];

class _JalCal {
  const _JalCal(this.leap, this.gy, this.march);
  final int leap;
  final int gy;
  final int march;
}

_JalCal _jalCal(int jy) {
  final bl = _breaks.length;
  final gy = jy + 621;
  var leapJ = -14;
  var jp = _breaks[0];
  var jump = 0;
  if (jy < jp || jy >= _breaks[bl - 1]) {
    throw ArgumentError('سال شمسی نامعتبر: $jy');
  }
  for (var i = 1; i < bl; i++) {
    final jm = _breaks[i];
    jump = jm - jp;
    if (jy < jm) break;
    leapJ += _div(jump, 33) * 8 + _div(_mod(jump, 33), 4);
    jp = jm;
  }
  var n = jy - jp;
  leapJ += _div(n, 33) * 8 + _div(_mod(n, 33) + 3, 4);
  if (_mod(jump, 33) == 4 && jump - n == 4) leapJ += 1;
  final leapG = _div(gy, 4) - _div((_div(gy, 100) + 1) * 3, 4) - 150;
  final march = 20 + leapJ - leapG;
  if (jump - n < 6) n = n - jump + _div(jump + 4, 33) * 33;
  var leap = _mod(_mod(n + 1, 33) - 1, 4);
  if (leap == -1) leap = 4;
  return _JalCal(leap, gy, march);
}

int _g2d(int gy, int gm, int gd) {
  var d = _div((gy + _div(gm - 8, 6) + 100100) * 1461, 4) +
      _div(153 * _mod(gm + 9, 12) + 2, 5) +
      gd -
      34840408;
  d = d - _div(_div(gy + 100100 + _div(gm - 8, 6), 100) * 3, 4) + 752;
  return d;
}

List<int> _d2g(int jdn) {
  var j = 4 * jdn + 139361631;
  j = j + _div(_div(4 * jdn + 183187720, 146097) * 3, 4) * 4 - 3908;
  final i = _div(_mod(j, 1461), 4) * 5 + 308;
  final gd = _div(_mod(i, 153), 5) + 1;
  final gm = _mod(_div(i, 153), 12) + 1;
  final gy = _div(j, 1461) - 100100 + _div(8 - gm, 6);
  return [gy, gm, gd];
}

int _j2d(int jy, int jm, int jd) {
  final r = _jalCal(jy);
  return _g2d(r.gy, 3, r.march) +
      (jm - 1) * 31 -
      _div(jm, 7) * (jm - 7) +
      jd -
      1;
}

Jalali _d2j(int jdn) {
  final gy = _d2g(jdn)[0];
  var jy = gy - 621;
  final r = _jalCal(jy);
  final jdn1f = _g2d(gy, 3, r.march);
  var k = jdn - jdn1f;
  if (k >= 0) {
    if (k <= 185) {
      return Jalali(jy, 1 + _div(k, 31), _mod(k, 31) + 1);
    }
    k -= 186;
  } else {
    jy -= 1;
    k += 179;
    if (r.leap == 1) k += 1;
  }
  return Jalali(jy, 7 + _div(k, 30), _mod(k, 30) + 1);
}
