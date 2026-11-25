import '../config/app_config.dart';

const int minPasswordLength = 8;

const Set<String> _commonPasswords = {
  '12345678',
  '123456789',
  '1234567890',
  '87654321',
  '11111111',
  '00000000',
  'password',
  'qwertyui',
  'abcd1234',
};

/// اعتبارسنجی رمز جدید. اگر مشکلی نبود `null` برمی‌گرداند.
String? validateNewPassword(String password, String repeat) {
  if (password.length < minPasswordLength) {
    return 'رمز عبور باید حداقل ۸ کاراکتر باشد.';
  }
  if (password == AppConfig.initialPassword) {
    return 'رمز جدید نباید همان رمز اولیه باشد.';
  }
  if (password.split('').toSet().length == 1) {
    return 'رمز عبور نباید فقط یک کاراکتر تکراری باشد.';
  }
  if (_commonPasswords.contains(password.toLowerCase())) {
    return 'این رمز بسیار رایج است؛ رمز دیگری انتخاب کنید.';
  }
  if (password != repeat) {
    return 'تکرار رمز با رمز جدید یکسان نیست.';
  }
  return null;
}
