import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/app_config.dart';
import 'services/reminder_service.dart';
import 'ui/auth_gate.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabasePublishableKey,
  );
  try {
    await ReminderService.init();
  } catch (_) {
    // اگر اعلان‌ها آماده نشد، بقیهٔ برنامه باید کار کند.
  }
  runApp(const MadarbozorgApp());
}

class MadarbozorgApp extends StatelessWidget {
  const MadarbozorgApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'دورهمی مادربزرگ',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      locale: const Locale('fa', 'IR'),
      supportedLocales: const [Locale('fa', 'IR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AuthGate(),
    );
  }
}
