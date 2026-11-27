import 'package:flutter/material.dart';

ThemeData buildTheme() {
  const seed = Color(0xFF2E7D6B);
  return ThemeData(
    useMaterial3: true,
    colorSchemeSeed: seed,
    // اگر فونت وزیرمتن هنگام ساخت اضافه شده باشد استفاده می‌شود؛
    // در غیر این صورت اندروید از فونت فارسی سیستم استفاده می‌کند.
    fontFamily: 'Vazirmatn',
  );
}

const List<Color> _palette = [
  Color(0xFF1E88E5), // آبی
  Color(0xFFE53935), // قرمز
  Color(0xFF43A047), // سبز
  Color(0xFFFE8A7B), // طاهره (هلویی)
  Color(0xFFFB8C00), // نارنجی
  Color(0xFF00897B), // سبزآبی
];

const List<String> _knownOrder = ['حسن', 'سعید', 'محمد', 'طاهره', 'فاطمه'];

/// رنگ ثابت برای هر خانواده (بر اساس نام، تا در همهٔ گوشی‌ها یکسان باشد).
Color familyColor(String name) {
  final i = _knownOrder.indexOf(name);
  if (i >= 0) return _palette[i];
  return _palette[name.hashCode.abs() % _palette.length];
}

/// رنگ‌های کادر کارت‌های صفحهٔ خانه برای طاهره.
const Color taherehDarkColor = Color(0xFFB12411);
const Color taherehLightColor = Color(0xFFFE8A7B);

/// نسخهٔ تیره‌تر یک رنگ (برای پس‌زمینهٔ تیرهٔ چشمک‌زن).
Color darkerShade(Color c, [double lightness = 0.28]) {
  final hsl = HSLColor.fromColor(c);
  return hsl
      .withLightness(lightness)
      .withSaturation((hsl.saturation + 0.05).clamp(0.0, 1.0).toDouble())
      .toColor();
}

/// نسخهٔ بسیار روشن یک رنگ (برای پس‌زمینهٔ روشنِ چشمک‌زن).
Color lighterShade(Color c, [double lightness = 0.9]) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness(lightness).toColor();
}
