import 'package:flutter/material.dart';

import '../core/dates.dart';
import '../models/models.dart';
import '../models/reminder.dart';
import '../services/data_service.dart';
import '../services/reminder_service.dart';
import 'calendar_tab.dart';
import 'common_widgets.dart';
import 'dashboard_tab.dart';
import 'notes_tab.dart';
import 'reminders_tab.dart';
import 'theme.dart';
import 'wave_header.dart';

/// چارچوب اصلی پس از ورود: داده‌ها را یک‌بار می‌گیرد و بین «خانه»، «تقویم»،
/// «یادداشت‌ها» و «یادآوری» پخش می‌کند.
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
    } else if (_tab == 2) {
      body = NotesTab(
        profile: widget.profile,
        families: _families,
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

    final familyName = _families[widget.profile.familyId]?.name;

    return Scaffold(
      body: Column(
        children: [
          _Header(
            familyName: familyName,
            loading: _loading,
            onRefresh: _reload,
            onLogout: widget.onLogout,
          ),
          Expanded(child: body),
        ],
      ),
      bottomNavigationBar: _FloatingNav(
        index: _tab,
        onChanged: (i) => setState(() => _tab = i),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.familyName,
    required this.loading,
    required this.onRefresh,
    required this.onLogout,
  });

  final String? familyName;
  final bool loading;
  final VoidCallback onRefresh;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final pageColor = Theme.of(context).scaffoldBackgroundColor;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [headerColor, Color(0xFF0B67A8)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 56,
            child: WaveBackground(waveColor: pageColor),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(12, top + 8, 12, 44),
            child: SizedBox(
              height: 80,
              child: Stack(
                children: [
                  Center(
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/app_icon.png',
                          fit: BoxFit.cover,
                          cacheWidth: 200,
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(30),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            familyName == null
                                ? 'خانواده'
                                : 'خانواده $familyName',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: 'به‌روزرسانی',
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          onPressed: loading ? null : onRefresh,
                        ),
                        PopupMenuButton<String>(
                          tooltip: 'منو',
                          icon:
                              const Icon(Icons.more_vert, color: Colors.white),
                          onSelected: (v) {
                            if (v == 'logout') onLogout();
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                                value: 'logout', child: Text('خروج از حساب')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingNav extends StatelessWidget {
  const _FloatingNav({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  static const _items = [
    (Icons.home_outlined, Icons.home_rounded, 'خانه'),
    (Icons.calendar_month_outlined, Icons.calendar_month, 'تقویم'),
    (Icons.sticky_note_2_outlined, Icons.sticky_note_2, 'یادداشت‌ها'),
    (Icons.notifications_outlined, Icons.notifications, 'یادآوری'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 14,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            for (var i = 0; i < _items.length; i++)
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () => onChanged(i),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        width: i == index ? 72 : 44,
                        height: 40,
                        decoration: BoxDecoration(
                          color: i == index ? navBlue : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          i == index ? _items[i].$2 : _items[i].$1,
                          color: i == index ? Colors.white : Colors.black54,
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _items[i].$3,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              i == index ? FontWeight.bold : FontWeight.normal,
                          color: i == index ? navBlue : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
