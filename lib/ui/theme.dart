import 'package:flutter/material.dart';

const Color seedColor = Color(0xFF00A98F);

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: seedColor).copyWith(
    primary: seedColor,
    onPrimary: Colors.white,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: const Color(0xFFF1FBF8),
    // اگر فونت وزیرمتن هنگام ساخت اضافه شده باشد استفاده می‌شود؛
    // در غیر این صورت اندروید از فونت فارسی سیستم استفاده می‌کند.
    fontFamily: 'Vazirmatn',
    appBarTheme: const AppBarTheme(
      backgroundColor: seedColor,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: seedColor.withAlpha(70),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFFFF9100),
      foregroundColor: Colors.white,
    ),
  );
}

const List<Color> familyPalette = [
  Color(0xFF2979FF), // آبی
  Color(0xFFFF3D57), // قرمز
  Color(0xFF00C853), // سبز
  Color(0xFFAA00FF), // بنفش
  Color(0xFFFF9100), // نارنجی
  Color(0xFF00BFA5), // سبزآبی
];

const List<String> knownFamilyOrder = ['حسن', 'سعید', 'محمد', 'طاهره', 'فاطمه'];

/// رنگ ثابت برای هر خانواده (بر اساس نام، تا در همهٔ گوشی‌ها یکسان باشد).
Color familyColor(String name) {
  final index = knownFamilyOrder.indexOf(name);
  if (index == -1) {
    final familyIndex = name.hashCode.abs() % familyPalette.length;
    return familyPalette[familyIndex];
  }
  return familyPalette[index];
}
