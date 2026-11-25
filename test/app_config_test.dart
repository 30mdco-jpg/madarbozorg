import 'package:flutter_test/flutter_test.dart';
import 'package:madarbozorg_family/config/app_config.dart';

void main() {
  test('نگاشت نام کاربری به ایمیل فنی', () {
    expect(AppConfig.emailForUsername('hasan'), 'hasan@madarbozorg.app');
    expect(AppConfig.emailForUsername('  Saeed '), 'saeed@madarbozorg.app');
    expect(AppConfig.emailForUsername('unknown'), isNull);
    expect(AppConfig.accounts.length, 5);
  });
}
