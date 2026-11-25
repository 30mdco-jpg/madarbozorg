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
  Color(0xFF8E24AA), // بنفش
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
