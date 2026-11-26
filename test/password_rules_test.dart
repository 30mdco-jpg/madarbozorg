import 'package:flutter_test/flutter_test.dart';
import 'package:madarbozorg_family/config/app_config.dart';
import 'package:madarbozorg_family/core/password_rules.dart';

void main() {
  test('رمز کمتر از ۴ کاراکتر رد می‌شود', () {
    expect(validateNewPassword('123', '123'), isNotNull);
  });

  test('رمز ۴ کاراکتری پذیرفته می‌شود', () {
    expect(validateNewPassword('1234', '1234'), isNull);
    expect(validateNewPassword('گل۱۴', 'گل۱۴'), isNull);
  });

  test('رمز اولیه به‌عنوان رمز جدید رد می‌شود', () {
    expect(
      validateNewPassword(AppConfig.initialPassword, AppConfig.initialPassword),
      isNotNull,
    );
  });

  test('تکرار نامطابق رد می‌شود', () {
    expect(validateNewPassword('abcd', 'abce'), isNotNull);
  });

  group('serverPassword', () {
    test('رمزهای کوتاه‌تر از ۶ کاراکتر برای سرور بلندتر می‌شوند', () {
      for (final p in ['1234', '12345', 'ab']) {
        final sent = serverPassword(p);
        expect(sent.length >= serverMinPasswordLength, isTrue);
        expect(sent.startsWith(p), isTrue);
      }
    });

    test('رمزهای ۶ کاراکتری و بیشتر بدون تغییر می‌مانند', () {
      expect(serverPassword('123456'), '123456');
      expect(serverPassword('Gol-e-yas1405'), 'Gol-e-yas1405');
    });

    test('تبدیل قطعی است (ورود با همان رمز ذخیره‌شده کار می‌کند)', () {
      expect(serverPassword('1234'), serverPassword('1234'));
      expect(serverPassword('1234') == serverPassword('1235'), isFalse);
    });
  });
}
