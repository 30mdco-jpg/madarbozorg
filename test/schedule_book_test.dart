import 'package:flutter_test/flutter_test.dart';
import 'package:madarbozorg_family/core/dates.dart';
import 'package:madarbozorg_family/models/models.dart';

ScheduleEntry e(String iso, String family) =>
    ScheduleEntry(date: parseIsoDate(iso), familyId: family);

void main() {
  final book = ScheduleBook([
    e('2026-11-26', 'A'),
    e('2026-11-27', 'A'),
    e('2026-11-28', 'B'),
    e('2026-11-29', 'C'),
    e('2026-11-30', 'B'),
  ]);

  test('نوبت هر روز', () {
    expect(book.on(parseIsoDate('2026-11-28'))?.familyId, 'B');
    expect(book.on(parseIsoDate('2026-12-31')), isNull);
  });

  test('طول بلوک پشت‌سرهم (نوبت دوروزه)', () {
    expect(book.blockLengthAt(parseIsoDate('2026-11-26')), 2);
    expect(book.blockLengthAt(parseIsoDate('2026-11-27')), 2);
    expect(book.blockLengthAt(parseIsoDate('2026-11-28')), 1);
    expect(book.blockLengthAt(parseIsoDate('2026-12-31')), 0);
  });

  test('نوبت‌های بعدی یک خانواده', () {
    final after = parseIsoDate('2026-11-28');
    expect(book.upcomingFor('B', after).map((x) => isoDate(x.date)),
        ['2026-11-30']);
    final earlier = parseIsoDate('2026-11-27');
    expect(book.upcomingFor('B', earlier).map((x) => isoDate(x.date)),
        ['2026-11-28', '2026-11-30']);
    expect(book.upcomingFor('C', parseIsoDate('2026-11-29')), isEmpty);
    expect(book.upcomingFor('B', earlier, limit: 1).length, 1);
  });

  test('برنامهٔ خالی', () {
    final empty = ScheduleBook(const []);
    expect(empty.isEmpty, isTrue);
    expect(empty.on(parseIsoDate('2026-11-28')), isNull);
  });
}
