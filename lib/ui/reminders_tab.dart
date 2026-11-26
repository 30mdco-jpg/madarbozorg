import 'package:flutter/material.dart';

import '../core/dates.dart';
import '../core/jalali.dart';
import '../models/models.dart';
import '../models/reminder.dart';
import '../services/reminder_service.dart';

/// تنظیم یادآوری‌ها: چند روز قبل از نوبت و چه ساعتی اعلان بیاید.
class RemindersTab extends StatefulWidget {
  const RemindersTab({
    super.key,
    required this.profile,
    required this.book,
    required this.prefs,
    required this.onChanged,
    required this.onReapply,
  });

  final Profile profile;
  final ScheduleBook book;
  final ReminderPrefs prefs;
  final Future<void> Function(ReminderPrefs) onChanged;
  final Future<void> Function() onReapply;

  @override
  State<RemindersTab> createState() => _RemindersTabState();
}

class _RemindersTabState extends State<RemindersTab> with WidgetsBindingObserver {
  bool? _allowed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // کاربر ممکن است از تنظیمات گوشی اعلان را روشن کرده باشد.
    if (state == AppLifecycleState.resumed) _checkPermission(reapply: true);
  }

  Future<void> _checkPermission({bool reapply = false}) async {
    final ok = await ReminderService.notificationsAllowed();
    if (!mounted) return;
    final changed = _allowed != ok;
    setState(() => _allowed = ok);
    if (reapply && ok && changed) await widget.onReapply();
  }

  Future<void> _requestPermission() async {
    final ok = await ReminderService.requestPermission();
    if (!mounted) return;
    setState(() => _allowed = ok);
    if (ok) {
      await widget.onReapply();
    } else {
      _snack('اجازه داده نشد. از تنظیمات گوشی ← برنامه‌ها ← نوبت بی بی ← اعلان‌ها، '
          'اعلان را روشن کنید.');
    }
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  List<ReminderRule> _sorted(List<ReminderRule> rules) {
    final list = [...rules];
    list.sort((a, b) {
      final byDays = b.daysBefore.compareTo(a.daysBefore);
      if (byDays != 0) return byDays;
      return (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute);
    });
    return list;
  }

  Future<void> _addRule() async {
    final rule = await showDialog<ReminderRule>(
      context: context,
      builder: (_) => const _RuleDialog(),
    );
    if (rule == null) return;
    final rules = [...widget.prefs.rules];
    if (!rules.contains(rule)) rules.add(rule);
    await widget.onChanged(widget.prefs.copyWith(rules: _sorted(rules)));
  }

  Future<void> _editRule(ReminderRule old) async {
    final rule = await showDialog<ReminderRule>(
      context: context,
      builder: (_) => _RuleDialog(initial: old),
    );
    if (rule == null) return;
    final rules = [...widget.prefs.rules]..remove(old);
    if (!rules.contains(rule)) rules.add(rule);
    await widget.onChanged(widget.prefs.copyWith(rules: _sorted(rules)));
  }

  Future<void> _removeRule(ReminderRule rule) async {
    final rules = [...widget.prefs.rules]..remove(rule);
    await widget.onChanged(widget.prefs.copyWith(rules: rules));
  }

  Future<void> _sendTest() async {
    final ok = await ReminderService.showTest();
    if (!mounted) return;
    _snack(ok
        ? 'اعلان آزمایشی ارسال شد.'
        : 'ارسال اعلان انجام نشد. مجوز اعلان را بررسی کنید.');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prefs = widget.prefs;
    final planned = planReminders(
      book: widget.book,
      familyId: widget.profile.familyId,
      nowTehran: tehranNow(),
      prefs: prefs,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_allowed == false)
          Card(
            color: theme.colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'اعلان‌های این برنامه روی گوشی شما خاموش است، پس یادآوری '
                    'نمایش داده نمی‌شود.',
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _requestPermission,
                    child: const Text('اجازهٔ ارسال اعلان'),
                  ),
                ],
              ),
            ),
          )
        else if (_allowed == true)
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.check_circle, color: Colors.green),
            title: Text('اجازهٔ اعلان روی این گوشی فعال است.'),
          ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('یادآوری نوبت‌ها'),
          subtitle: const Text('برای نوبت‌های خانوادهٔ شما، حتی وقتی برنامه بسته است'),
          value: prefs.enabled,
          onChanged: (v) => widget.onChanged(prefs.copyWith(enabled: v)),
        ),
        if (prefs.enabled) ...[
          const Divider(),
          Text('زمان یادآوری‌ها', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'برای نوبت دوروزه (مثل پنجشنبه و جمعه) فقط قبل از روز اول یادآوری می‌آید.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          if (prefs.rules.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('هیچ یادآوری‌ای تنظیم نشده است.'),
              ),
            ),
          for (final rule in prefs.rules)
            Card(
              child: ListTile(
                leading: const Icon(Icons.alarm),
                title: Text(rule.description),
                onTap: () => _editRule(rule),
                trailing: IconButton(
                  tooltip: 'حذف',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _removeRule(rule),
                ),
              ),
            ),
          if (prefs.rules.length < ReminderPrefs.maxRules)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: _addRule,
                icon: const Icon(Icons.add),
                label: const Text('افزودن یادآوری'),
              ),
            ),
          const Divider(),
          Text('اعلان‌های بعدی', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (planned.isEmpty)
            const Text('در ۹۰ روز آینده اعلانی برنامه‌ریزی نشده است.')
          else
            for (final p in planned.take(3))
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.notifications_active_outlined),
                title: Text(p.fireText),
                subtitle: Text(
                  'برای نوبت ${Jalali.fromDate(p.turnStart).formatWithWeekday()}',
                ),
              ),
        ],
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _sendTest,
          icon: const Icon(Icons.notifications_none),
          label: const Text('ارسال اعلان آزمایشی'),
        ),
        const SizedBox(height: 16),
        Text(
          'نکته: در بعضی گوشی‌ها (مثل شیائومی، هوآوی و سامسونگ) اگر برنامه از '
          '«بهینه‌سازی باتری» مستثنی نشود، ممکن است اعلان‌ها با تأخیر برسند. '
          'اعلان‌ها هر بار که برنامه را باز کنید برای ۹۰ روز آینده به‌روز می‌شوند.',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _RuleDialog extends StatefulWidget {
  const _RuleDialog({this.initial});

  final ReminderRule? initial;

  @override
  State<_RuleDialog> createState() => _RuleDialogState();
}

class _RuleDialogState extends State<_RuleDialog> {
  static const List<int> _baseOptions = [0, 1, 2, 3, 7];

  late int _days;
  late TimeOfDay _time;

  @override
  void initState() {
    super.initState();
    _days = widget.initial?.daysBefore ?? 1;
    _time = TimeOfDay(
      hour: widget.initial?.hour ?? 20,
      minute: widget.initial?.minute ?? 0,
    );
  }

  String _timeText() =>
      '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final options = {..._baseOptions, _days}.toList()..sort();
    return AlertDialog(
      title: Text(widget.initial == null ? 'افزودن یادآوری' : 'ویرایش یادآوری'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('چه زمانی یادآوری شود؟'),
          const SizedBox(height: 8),
          DropdownButton<int>(
            isExpanded: true,
            value: _days,
            items: [
              for (final d in options)
                DropdownMenuItem<int>(
                  value: d,
                  child: Text(
                    ReminderRule(daysBefore: d, hour: 0, minute: 0).daysLabel,
                  ),
                ),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _days = v);
            },
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.access_time),
            label: Text('ساعت ${toFa(_timeText())}'),
            onPressed: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: _time,
              );
              if (picked != null) setState(() => _time = picked);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('انصراف'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            ReminderRule(
              daysBefore: _days,
              hour: _time.hour,
              minute: _time.minute,
            ),
          ),
          child: const Text('تأیید'),
        ),
      ],
    );
  }
}
