/// تنظیمات عمومی اپ.
///
/// توجه: «کلید عمومی (publishable key)» عمداً برای قرار گرفتن داخل اپ ساخته شده
/// و محرمانه نیست؛ امنیت واقعی را قواعد RLS در دیتابیس تأمین می‌کند.
/// کلید `service_role` هرگز نباید در این پروژه قرار بگیرد.
class AppConfig {
  AppConfig._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://dgvhpsuhoysaxhrqsoah.supabase.co',
  );

  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_eZJmRG8QUbp2ekeH-y122A_xNqHENG_',
  );

  /// نگاشت نام کاربری به ایمیل فنی (صندوق پستی واقعی نیستند).
  static const Map<String, String> accounts = {
    'hasan': 'hasan@madarbozorg.app',
    'saeed': 'saeed@madarbozorg.app',
    'mohammad': 'mohammad@madarbozorg.app',
    'tahereh': 'tahereh@madarbozorg.app',
    'fatemeh': 'fatemeh@madarbozorg.app',
  };

  static String? emailForUsername(String input) =>
      accounts[input.trim().toLowerCase()];

  /// رمز اولیه‌ای که نباید به‌عنوان رمز جدید پذیرفته شود.
  static const String initialPassword = '123456';
}
