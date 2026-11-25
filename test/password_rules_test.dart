import 'package:flutter_test/flutter_test.dart';
import 'package:madarbozorg_family/config/app_config.dart';
import 'package:madarbozorg_family/core/password_rules.dart';

void main() {
  test('رمز کوتاه رد می‌شود', () {
    expect(validateNewPassword('1234567', '1234567'), isNotNull);
  });

  test('رمز اولیه یا رایج رد می‌شود', () {
    expect(validateNewPassword(AppConfig.initialPassword, AppConfig.initialPassword),
        isNotNull);
    expect(validateNewPassword('12345678', '12345678'), isNotNull);
    expect(validateNewPassword('aaaaaaaa', 'aaaaaaaa'), isNotNull);
  });

  test('تکرار نامطابق رد می‌شود', () {
    expect(validateNewPassword('Gol-e-yas1405', 'Gol-e-yas1406'), isNotNull);
  });

  test('رمز مناسب پذیرفته می‌شود', () {
    expect(validateNewPassword('Gol-e-yas1405', 'Gol-e-yas1405'), isNull);
  });
}
