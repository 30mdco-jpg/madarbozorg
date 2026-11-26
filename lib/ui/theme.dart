import 'package:flutter/material.dart';

/// رنگ اصلی برنامه: سبزآبی زنده.
const Color \_seed = Color(0xFF00A98F);

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: \_seed).copyWith(
    primary: \_seed,
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
      backgroundColor: \_seed,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: \_seed.withAlpha(70),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFFFF9100),
      foregroundColor: Colors.white,
    ),
  );
}

const List<Color> \_palette = \[
  Color(0xFF2979FF), // آبی
  Color(0xFFFF3D57), // قرمز
  Color(0xFF00C853), // سبز
  Color(0xFFAA00FF), // بنفش
  Color(0xFFFF9100), // نارنجی
  Color(0xFF00BFA5), // سبزآبی
\];

const List<String> \_knownOrder = \['حسن', 'سعید', 'محمد', 'طاهره', 'فاطمه'\];

/// رنگ ثابت برای هر خانواده (بر اساس نام، تا در همهٔ گوشی‌ها یکسان باشد).
Color familyColor(String name) {
  final i = \_knownOrder.indexOf(name);
  if (i &gt;= 0) return \_palette\[i\];
  return \_palette\[name.hashCode.abs() % \_palette.length\];
}