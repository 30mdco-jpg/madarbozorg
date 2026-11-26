import '../config/app_config.dart';

/// حداقل طول رمز (انتخاب خود خانواده: برنامهٔ ساده، بدون اطلاعات حساس).
const int minPasswordLength = 4;

/// سرور Supabase هرگز رمز کوتاه‌تر از ۶ کاراکتر نمی‌پذیرد و این حداقل قابل
/// کم‌کردن نیست. برای رمزهای کوتاه‌تر، اپ یک پسوند ثابت اضافه می‌کند تا سرور
/// بپذیرد. کاربر همیشه فقط رمز خودش را تایپ می‌کند.
const int serverMinPasswordLength = 6;
const String _shortPasswordPad = '#nobat-bibi';

/// رمزی که واقعاً به سرور فرستاده می‌شود (هم هنگام ورود، هم هنگام تغییر رمز).
String serverPassword(String typed) =>
    typed.length < serverMinPasswordLength ? '$typed$_shortPasswordPad' : typed;

/// اعتبارسنجی رمز جدید. اگر مشکلی نبود `null` برمی‌گرداند.
String? validateNewPassword(String password, String repeat) {
  if (password.length < minPasswordLength) {
    return 'رمز عبور باید حداقل ۴ کاراکتر باشد.';
  }
  if (password == AppConfig.initialPassword) {
    return 'رمز جدید نباید همان رمز اولیه باشد.';
  }
  if (password != repeat) {
    return 'تکرار رمز با رمز جدید یکسان نیست.';
  }
  return null;
}
