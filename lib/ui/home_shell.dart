import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/data_service.dart';
import 'calendar_tab.dart';
import 'common_widgets.dart';
import 'dashboard_tab.dart';

/// چارچوب اصلی پس از ورود: داده‌ها را یک‌بار می‌گیرد و بین «خانه» و «تقویم» پخش می‌کند.
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

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final families = await _data.fetchFamilies();
      final book = await _data.fetchSchedule();
      if (!mounted) return;
      setState(() {
        _families = {for (final f in families) f.id: f};
        _book = book;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'دریافت برنامه انجام نشد. اینترنت را بررسی و دوباره تلاش کنید.';
      });
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
    final titles = ['خانه', 'تقویم'];
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
    } else {
      body = CalendarTab(
        profile: widget.profile,
        families: _families,
        book: _book,
        onRefresh: _refreshSilently,
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
        ],
      ),
    );
  }
}
