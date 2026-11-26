import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../services/reminder_service.dart';
import 'change_password_screen.dart';
import 'common_widgets.dart';
import 'home_shell.dart';
import 'login_screen.dart';

/// تصمیم می‌گیرد کاربر کدام صفحه را ببیند: ورود، تغییر رمز اجباری یا خانه.
///
/// نکته‌ها:
/// - خطای دریافت پروفایل (مثلاً قطعی اینترنت) کاربر را از حساب بیرون نمی‌اندازد؛
///   فقط صفحهٔ «تلاش دوباره» نشان داده می‌شود.
/// - با شمارندهٔ `_token` از اثر گرفتن پاسخ‌های قدیمی (race condition) جلوگیری می‌شود.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _data = DataService();
  final _auth = AuthService();
  StreamSubscription<AuthState>? _sub;

  Session? _session;
  Profile? _profile;
  String? _error;
  bool _loading = false;
  int _token = 0;

  @override
  void initState() {
    super.initState();
    final client = Supabase.instance.client;
    _session = client.auth.currentSession;
    _sub = client.auth.onAuthStateChange.listen(_onAuthChange);
    if (_session != null) {
      _loading = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _onAuthChange(AuthState state) {
    final newSession = state.session;
    final userChanged = newSession?.user.id != _session?.user.id;
    _session = newSession;
    if (newSession == null) {
      // با پایان نشست، اعلان‌های این حساب هم باید پاک شوند.
      ReminderService.cancelAll();
      _token++;
      setState(() {
        _profile = null;
        _error = null;
        _loading = false;
      });
    } else if (userChanged || (_profile == null && !_loading)) {
      _loadProfile();
    } else {
      // فقط تمدید توکن؛ نیازی به دریافت دوبارهٔ پروفایل نیست.
      setState(() {});
    }
  }

  Future<void> _loadProfile() async {
    final myToken = ++_token;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await _data.fetchMyProfile();
      if (!mounted || myToken != _token) return;
      setState(() {
        _profile = profile;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || myToken != _token) return;
      setState(() {
        _error = 'دریافت اطلاعات حساب انجام نشد. اینترنت را بررسی و دوباره تلاش کنید.';
        _loading = false;
      });
    }
  }

  Future<void> _logout() async {
    await _auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    if (_session == null) return const LoginScreen();

    if (_error != null) {
      return Scaffold(
        body: CenteredMessage(
          message: _error!,
          icon: Icons.wifi_off,
          actions: [
            FilledButton(onPressed: _loadProfile, child: const Text('تلاش دوباره')),
            TextButton(onPressed: _logout, child: const Text('خروج از حساب')),
          ],
        ),
      );
    }

    final profile = _profile;
    if (profile == null || _loading) {
      return const Scaffold(body: LoadingView());
    }

    if (profile.mustChangePassword) {
      return ChangePasswordScreen(onDone: _loadProfile, onLogout: _logout);
    }

    return HomeShell(profile: profile, onLogout: _logout);
  }
}
