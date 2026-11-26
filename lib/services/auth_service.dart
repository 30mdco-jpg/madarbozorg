import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../core/password_rules.dart';

/// خطایی که پیام آن مستقیماً برای کاربر قابل نمایش است.
class UserFacingError implements Exception {
  const UserFacingError(this.message);
  final String message;

  @override
  String toString() => message;
}

const String kNetworkMessage =
    'اتصال به اینترنت یا سرور برقرار نشد. لطفاً اتصال را بررسی و دوباره تلاش کنید.';
const String kBadCredentialsMessage = 'نام کاربری یا رمز عبور اشتباه است.';

class AuthService {
  SupabaseClient get _client => Supabase.instance.client;

  Future<void> signIn(String username, String password) async {
    final email = AppConfig.emailForUsername(username);
    if (email == null || password.isEmpty) {
      throw const UserFacingError(kBadCredentialsMessage);
    }
    try {
      await _client.auth
          .signInWithPassword(email: email, password: serverPassword(password));
    } on AuthRetryableFetchException {
      throw const UserFacingError(kNetworkMessage);
    } on AuthException {
      // عمداً پیام یکسان برای هر خطای هویتی تا جزئیات حساب‌ها فاش نشود.
      throw const UserFacingError(kBadCredentialsMessage);
    } catch (_) {
      throw const UserFacingError(kNetworkMessage);
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (_) {
      // حتی اگر اینترنت قطع باشد، نشست محلی پاک می‌شود.
      await _client.auth.signOut(scope: SignOutScope.local);
    }
  }

  /// مرحلهٔ ۱: تغییر رمز در Supabase Auth.
  Future<void> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: serverPassword(newPassword)));
    } on AuthRetryableFetchException {
      throw const UserFacingError(kNetworkMessage);
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('different')) {
        throw const UserFacingError('رمز جدید باید با رمز فعلی متفاوت باشد.');
      }
      if (msg.contains('weak') || msg.contains('short') || msg.contains('least')) {
        throw const UserFacingError('رمز انتخابی به‌اندازهٔ کافی قوی نیست.');
      }
      throw const UserFacingError('تغییر رمز انجام نشد. لطفاً دوباره تلاش کنید.');
    } catch (_) {
      throw const UserFacingError(kNetworkMessage);
    }
  }

  /// مرحلهٔ ۲: خاموش کردن پرچم «تغییر اجباری رمز» با تابع امن سمت سرور.
  Future<void> markPasswordChanged() async {
    try {
      await _client.rpc('complete_password_change');
    } catch (_) {
      throw const UserFacingError(
        'رمز شما تغییر کرد، اما ثبت نهایی انجام نشد. دکمهٔ «تلاش دوباره» را بزنید.',
      );
    }
  }
}
