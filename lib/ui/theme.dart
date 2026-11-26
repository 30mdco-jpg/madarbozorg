import 'package:flutter/material.dart';

const Color seedColor = Color(0xFF024473);
const Color headerColor = Color(0xFF024473);
const Color navBlue = Color(0xFF1E7FE0);

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: seedColor).copyWith(
    primary: seedColor,
    onPrimary: Colors.white,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: const Color(0xFFF2F4F8),
    // اگر فونت وزیرمتن هنگام ساخت اضافه شده باشد استفاده می‌شود؛
    // در غیر این صورت اندروید از فونت فارسی سیستم استفاده می‌کند.
    fontFamily: 'Vazirmatn',
    appBarTheme: const AppBarTheme(
      backgroundColor: seedColor,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFFF7941D),
      foregroundColor: Colors.white,
    ),
  );
}

/// دو رنگ هر خانواده: [dark] برای نوار بالای کادر و [light] برای بدنهٔ کادر.
class FamilyShade {
  const FamilyShade(this.dark, this.light);
  final Color dark;
  final Color light;
}

const Map<String, FamilyShade> _shades = {
  'حسن': FamilyShade(Color(0xFF0072BC), Color(0xFF6DCFF6)),
  'فاطمه': FamilyShade(Color(0xFF8B1FA6), Color(0xFFD592E5)),
  'سعید': FamilyShade(Color(0xFFBB6806), Color(0xFFF7941D)),
  'طاهره': FamilyShade(Color(0xFF630460), Color(0xFF630460)),
  'محمد': FamilyShade(Color(0xFF247040), Color(0xFF247040)),
};

const List<Color> familyPalette = [
  Color(0xFF2979FF),
  Color(0xFFFF3D57),
  Color(0xFF00C853),
  Color(0xFFAA00FF),
  Color(0xFFFF9100),
  Color(0xFF00BFA5),
];

const List<String> knownFamilyOrder = ['حسن', 'سعید', 'محمد', 'طاهره', 'فاطمه'];

FamilyShade familyShade(String name) {
  final known = _shades[name];
  if (known != null) return known;
  final c = familyPalette[name.hashCode.abs() % familyPalette.length];
  return FamilyShade(c, Color.lerp(c, Colors.white, 0.5)!);
}

/// رنگ پررنگ خانواده (نوار بالای کادر، نوبت خود کاربر در تقویم).
Color familyColor(String name) => familyShade(name).dark;

/// رنگ کم‌رنگ خانواده در تقویم: همان رنگ روشن با ۵۰٪ شفافیت.
Color familyPale(String name) {
  final s = familyShade(name);
  return s.light.withAlpha(128);
}

/// رنگ نوشته روی یک پس‌زمینه: روی رنگ روشن مشکی، روی رنگ تیره سفید.
Color textOn(Color background) =>
    background.computeLuminance() > 0.35 ? Colors.black : Colors.white;
