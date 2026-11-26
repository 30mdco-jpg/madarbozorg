import 'package:flutter/material.dart';

import '../core/dates.dart';
import '../models/models.dart';
import '../models/reminder.dart';
import '../services/data_service.dart';
import '../services/reminder_service.dart';
import 'calendar_tab.dart';
import 'common_widgets.dart';
import 'dashboard_tab.dart';
import 'reminders_tab.dart';

/// چارچوب اصلی پس از ورود: داده‌ها را یک‌بار می‌گیرد و بین «خانه»، «تقویم»
/// و «یادآوری» پخش می‌کند.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.profile, required this.onLogout});

  final Profile profile;
  final Future<void> Function() onLogout;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final _data = DataService();
  int _tab = 0;
  bool _loading = true;
  String? _error;
  Map<String, Family> _families = {};
  ScheduleBook _book = ScheduleBook(const []);
  ReminderPrefs _prefs = ReminderPrefs.defaults;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final families = await _data.fetchFamilies();
      final book = await _data.fetchSchedule();
      var prefs = _prefs;
      try {
        prefs = await _data.fetchReminderPrefs(widget.profile.id);
      } catch (_) {
        // اگر تنظیمات دریافت نشد، همان مقدار قبلی/پیش‌فرض می‌ماند.
      }
      if (!mounted) return;
      setState(() {
        _families = {for (final f in families) f.id: f};
        _book = book;
        _prefs = prefs;
        _loading = false;
        _error = null;
      });
      await _applyReminders();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'دریافت برنامه انجام نشد. اینترنت را بررسی و دوباره تلاش کنید.';
      });
    }
  }

  /// اعلان‌های دستگاه را بر اساس برنامه و تنظیمات فعلی از نو می‌سازد.
  Future<void> _applyReminders() async {
    try {
      if (!_prefs.enabled) {
        await ReminderService.cancelAll();
        return;
      }
      if (!await ReminderService.notificationsAllowed()) return;
      final plan = planReminders(
        book: _book,
        familyId: widget.profile.familyId,
        nowTehran: tehranNow(),
        prefs: _prefs,
      );
      await ReminderService.replaceAll(plan);
    } catch (_) {
      // خطای اعلان نباید کار اصلی برنامه را مختل کند.
    }
  }

  Future<void> _onPrefsChanged(ReminderPrefs prefs) async {
    setState(() => _prefs = prefs);
    var saved = true;
    try {
      await _data.saveReminderPrefs(widget.profile.id, prefs);
    } catch (_) {
      saved = false;
    }
    await _applyReminders();
    if (!mounted) return;
    if (!saved) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text(
            'تنظیمات روی این گوشی اعمال شد، اما ذخیره روی سرور انجام نشد.',
          ),
        ));
    }
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    await _fetch();
  }

  Future<void> _refreshSilently() => _fetch();

  @override
  Widget build(BuildContext context) {
    const titles = ['خانه', 'تقویم', 'یادآوری'];
    Widget body;
    if (_loading) {
      body = const LoadingView();
    } else if (_error != null) {
      body = CenteredMessage(
        message: _error!,
        icon: Icons.wifi_off,
        actions: [
          FilledButton(onPressed: _reload, child: const Text('تلاش دوباره')),
        ],
      );
    } else if (_tab == 0) {
      body = DashboardTab(
        profile: widget.profile,
        families: _families,
        book: _book,
        onRefresh: _refreshSilently,
      );
    } else if (_tab == 1) {
      body = CalendarTab(
        profile: widget.profile,
        families: _families,
        book: _book,
        onRefresh: _refreshSilently,
      );
    } else {
      body = RemindersTab(
        profile: widget.profile,
        book: _book,
        prefs: _prefs,
        onChanged: _onPrefsChanged,
        onReapply: _applyReminders,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_tab]),
        actions: [
          IconButton(
            tooltip: 'به‌روزرسانی',
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _reload,
          ),
          PopupMenuButton<String>(
            tooltip: 'منو',
            onSelected: (v) {
              if (v == 'logout') widget.onLogout();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'logout', child: Text('خروج از حساب')),
            ],
          ),
        ],
      ),
      body: SafeArea(child: body),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'خانه'),
          NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined), label: 'تقویم'),
          NavigationDestination(
              icon: Icon(Icons.notifications_outlined), label: 'یادآوری'),
        ],
      ),
    );
  }
}
