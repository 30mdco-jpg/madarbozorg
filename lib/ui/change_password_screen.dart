import 'package:flutter/material.dart';

import '../core/password_rules.dart';
import '../services/auth_service.dart';

/// صفحهٔ تغییر اجباری رمز در اولین ورود.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({
    super.key,
    required this.onDone,
    required this.onLogout,
  });

  /// بعد از موفقیت کامل (هم Auth هم پرچم پروفایل) صدا زده می‌شود.
  final Future<void> Function() onDone;
  final Future<void> Function() onLogout;

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _auth = AuthService();
  final _password = TextEditingController();
  final _repeat = TextEditingController();
  bool _busy = false;
  bool _hide = true;
  bool _passwordAlreadyUpdated = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _repeat.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (!_passwordAlreadyUpdated) {
      final problem = validateNewPassword(_password.text, _repeat.text);
      if (problem != null) {
        setState(() => _error = problem);
        return;
      }
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (!_passwordAlreadyUpdated) {
        await _auth.updatePassword(_password.text);
        _passwordAlreadyUpdated = true;
      }
      await _auth.markPasswordChanged();
      await widget.onDone();
    } on UserFacingError catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('تعیین رمز جدید'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: _busy ? null : widget.onLogout,
            child: const Text('خروج'),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.lock_reset,
                      size: 64, color: theme.colorScheme.primary),
                  const SizedBox(height: 12),
                  const Text(
                    'برای امنیت بیشتر، لطفاً در اولین ورود یک رمز عبور تازه '
                    'برای خانوادهٔ خود تعیین کنید. این رمز بین اعضای همین '
                    'خانواده مشترک است.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _password,
                    enabled: !_passwordAlreadyUpdated,
                    obscureText: _hide,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.left,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                          labelText: 'رمز جدید (حداقل ۴ کاراکتر)',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_hide
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _hide = !_hide),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _repeat,
                    enabled: !_passwordAlreadyUpdated,
                    obscureText: _hide,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.left,
                    autocorrect: false,
                    enableSuggestions: false,
                    onSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(
                      border: const OutlineInputBorder(),
                          labelText: 'تکرار رمز جدید',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: _busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_passwordAlreadyUpdated
                              ? 'تلاش دوباره'
                              : 'ذخیرهٔ رمز جدید'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
