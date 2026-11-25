import 'package:flutter_test/flutter_test.dart';
import 'package:madarbozorg_family/core/dates.dart';
import 'package:madarbozorg_family/core/jalali.dart';

void main() {
  group('Jalali', () {
    test('شروع برنامه: ۵ آذر ۱۴۰۵ = ۲۶ نوامبر ۲۰۲۶', () {
      final j = Jalali.fromDate(DateTime.utc(2026, 11, 26));
      expect(j, const Jalali(1405, 9, 5));
      expect(const Jalali(1405, 9, 5).toDate(), DateTime.utc(2026, 11, 26));
    });

    test('پایان برنامه: ۲۹ اسفند ۱۴۰۶ = ۱۹ مارس ۲۰۲۸', () {
      expect(const Jalali(1406, 12, 29).toDate(), DateTime.utc(2028, 3, 19));
      expect(Jalali.fromDate(DateTime.utc(2028, 3, 19)),
          const Jalali(1406, 12, 29));
    });

    test('نوروز ۱۴۰۵ = ۲۱ مارس ۲۰۲۶', () {
      expect(const Jalali(1405, 1, 1).toDate(), DateTime.utc(2026, 3, 21));
    });

    test('امروز نمونه: ۴ آذر ۱۴۰۵ = ۲۵ نوامبر ۲۰۲۶', () {
      expect(Jalali.fromDate(DateTime.utc(2026, 11, 25)),
          const Jalali(1405, 9, 4));
    });

    test('سال کبیسه', () {
      expect(Jalali.isLeapYear(1403), isTrue);
      expect(Jalali.isLeapYear(1404), isFalse);
      expect(Jalali.isLeapYear(1405), isFalse);
      expect(Jalali.isLeapYear(1406), isFalse);
      expect(Jalali.isLeapYear(1407), isFalse);
      expect(Jalali.isLeapYear(1408), isTrue);
    });

    test('طول ماه‌ها در ۱۴۰۵', () {
      final lengths = [for (var m = 1; m <= 12; m++) Jalali.monthLength(1405, m)];
      expect(lengths, [31, 31, 31, 31, 31, 31, 30, 30, 30, 30, 30, 29]);
    });

    test('روز هفته: شنبه = ۰ و جمعه = ۶', () {
      expect(const Jalali(1405, 9, 5).weekdayIndex, 5); // پنجشنبه
      expect(const Jalali(1405, 9, 6).weekdayIndex, 6); // جمعه
      expect(const Jalali(1405, 9, 7).weekdayIndex, 0); // شنبه
      expect(const Jalali(1405, 9, 5).weekdayName, 'پنجشنبه');
    });

    test('رفت‌وبرگشت روزانه از ۲۰۲۰ تا ۲۰۳۵', () {
      var d = DateTime.utc(2020, 1, 1);
      final end = DateTime.utc(2035, 1, 1);
      while (d.isBefore(end)) {
        final j = Jalali.fromDate(d);
        expect(j.toDate(), d, reason: 'تاریخ $d');
        expect(j.month >= 1 && j.month <= 12, isTrue);
        expect(j.day >= 1 && j.day <= Jalali.monthLength(j.year, j.month),
            isTrue);
        d = addDays(d, 1);
      }
    });

    test('ارقام فارسی و قالب‌بندی', () {
      expect(toFa(1405), '۱۴۰۵');
      expect(const Jalali(1405, 9, 5).format(), '۵ آذر ۱۴۰۵');
      expect(const Jalali(1405, 9, 5).formatWithWeekday(), 'پنجشنبه ۵ آذر ۱۴۰۵');
    });
  });

  group('dates', () {
    test('تاریخ امروز به وقت تهران', () {
      // ۲۰:۳۰ UTC یعنی ۰۰:۰۰ روز بعد در تهران
      expect(tehranToday(DateTime.utc(2026, 11, 25, 20, 30)),
          DateTime.utc(2026, 11, 26));
      expect(tehranToday(DateTime.utc(2026, 11, 25, 20, 29)),
          DateTime.utc(2026, 11, 25));
    });

    test('iso رفت‌وبرگشت', () {
      expect(isoDate(DateTime.utc(2026, 3, 5)), '2026-03-05');
      expect(parseIsoDate('2026-03-05'), DateTime.utc(2026, 3, 5));
    });

    test('متن روزهای باقی‌مانده', () {
      expect(relativeDaysText(0), 'امروز');
      expect(relativeDaysText(1), 'فردا');
      expect(relativeDaysText(12), '۱۲ روز دیگر');
    });
  });
}
