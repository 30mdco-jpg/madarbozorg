import 'package:flutter/material.dart';

import '../models/models.dart';
import '../models/note.dart';
import '../services/notes_service.dart';
import 'common_widgets.dart';
import 'theme.dart';

String _fa(int n) {
  const digits = '۰۱۲۳۴۵۶۷۸۹';
  return n.toString().split('').map((c) {
    final d = int.tryParse(c);
    return d == null ? c : digits[d];
  }).join();
}

String _ago(DateTime time) {
  final diff = DateTime.now().toUtc().difference(time);
  if (diff.inMinutes < 1) return 'همین الان';
  if (diff.inMinutes < 60) return '${_fa(diff.inMinutes)} دقیقه پیش';
  if (diff.inHours < 24) return '${_fa(diff.inHours)} ساعت پیش';
  return '${_fa(diff.inDays)} روز پیش';
}

/// تب یادداشت‌ها: یادداشت همگانی برای همه، یا خصوصی برای یک خانواده.
class NotesTab extends StatefulWidget {
  const NotesTab({super.key, required this.profile, required this.families});

  final Profile profile;
  final Map<String, Family> families;

  @override
  State<NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends State<NotesTab> {
  final _service = NotesService();
  List<Note>? _notes;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _name(String familyId) => widget.families[familyId]?.name ?? '—';

  Future<void> _load() async {
    try {
      final notes = await _service.fetchNotes();
      if (!mounted) return;
      setState(() {
        _notes = notes;
        _error = null;
        _loading = false;
      });
      try {
        await NotesService.markSeen(
          userId: widget.profile.id,
          familyId: widget.profile.familyId,
          notes: notes,
        );
      } catch (_) {}
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'دریافت یادداشت‌ها انجام نشد. اینترنت را بررسی کنید.';
        _loading = false;
      });
    }
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _compose() async {
    final others = widget.families.values
        .where((f) => f.id != widget.profile.familyId)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final draft = await showModalBottomSheet<_Draft>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ComposeSheet(families: others),
    );
    if (draft == null || !mounted) return;
    try {
      await _service.sendNote(
        authorFamilyId: widget.profile.familyId,
        body: draft.body,
        toFamilyId: draft.toFamilyId,
      );
      if (!mounted) return;
      _snack('یادداشت ارسال شد.');
      await _load();
    } catch (_) {
      if (!mounted) return;
      _snack('ارسال یادداشت انجام نشد. اینترنت را بررسی و دوباره تلاش کنید.');
    }
  }

  Future<void> _delete(Note note) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف یادداشت'),
        content: const Text('این یادداشت برای همه پاک می‌شود. ادامه می‌دهید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await _service.deleteNote(note.id);
      if (!mounted) return;
      await _load();
    } catch (_) {
      if (!mounted) return;
      _snack('حذف انجام نشد. دوباره تلاش کنید.');
    }
  }

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
          FilledButton(
            onPressed: () {
              setState(() {
                _loading = true;
                _error = null;
              });
              _load();
            },
            child: const Text('تلاش دوباره'),
          ),
        ],
      );
    } else {
      final notes = _notes ?? const <Note>[];
      body = RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            Text(
              'یادداشت‌ها بعد از ۳۰ روز خودکار پاک می‌شوند.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            if (notes.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('هنوز یادداشتی نیست. با دکمهٔ «یادداشت جدید» اولین را بنویسید.'),
                ),
              )
            else
              for (final n in notes)
                _NoteCard(
                  note: n,
                  fromName: _name(n.authorFamilyId),
                  toName: n.toFamilyId == null ? null : _name(n.toFamilyId!),
                  forMe: n.toFamilyId == widget.profile.familyId,
                  mine: n.authorId == widget.profile.id,
                  onDelete: () => _delete(n),
                ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: body,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading || _error != null ? null : _compose,
        icon: const Icon(Icons.edit_note),
        label: const Text('یادداشت جدید'),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.note,
    required this.fromName,
    required this.toName,
    required this.forMe,
    required this.mine,
    required this.onDelete,
  });

  final Note note;
  final String fromName;
  final String? toName;
  final bool forMe;
  final bool mine;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = familyColor(fromName);
    final label = toName == null
        ? 'همگانی'
        : (forMe ? 'خصوصی برای شما' : 'خصوصی برای خانوادهٔ $toName');
    return Card(
      color: color.withAlpha(forMe ? 60 : 28),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withAlpha(forMe ? 200 : 90)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'از خانوادهٔ $fromName',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold, color: color),
                  ),
                ),
                if (mine)
                  IconButton(
                    tooltip: 'حذف یادداشت',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: onDelete,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(note.body),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  toName == null ? Icons.public : Icons.lock_outline,
                  size: 16,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(label, style: theme.textTheme.bodySmall),
                ),
                Text(_ago(note.createdAt), style: theme.textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Draft {
  const _Draft(this.body, this.toFamilyId);
  final String body;
  final String? toFamilyId;
}

class _ComposeSheet extends StatefulWidget {
  const _ComposeSheet({required this.families});

  final List<Family> families;

  @override
  State<_ComposeSheet> createState() => _ComposeSheetState();
}

class _ComposeSheetState extends State<_ComposeSheet> {
  static const String _allFamilies = '__all_families__';
  final _controller = TextEditingController();
  String _to = _allFamilies;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSend = _controller.text.trim().isNotEmpty;
    final isPublic = _to == _allFamilies;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            value: _to,
            decoration: const InputDecoration(
              labelText: 'برای',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<String>(
                value: _allFamilies,
                child: Text('همه (یادداشت همگانی)'),
              ),
              for (final f in widget.families)
                DropdownMenuItem<String>(
                  value: f.id,
                  child: Text('فقط خانوادهٔ ${f.name} (خصوصی)'),
                ),
            ],
            onChanged: (v) => setState(() => _to = v ?? _allFamilies),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            minLines: 3,
            maxLines: 6,
            maxLength: NotesService.maxLength,
            decoration: const InputDecoration(
              labelText: 'متن یادداشت',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: canSend
                ? () => Navigator.pop(
                      context,
                      _Draft(
                        _controller.text.trim(),
                        isPublic ? null : _to,
                      ),
                    )
                : null,
            icon: const Icon(Icons.send),
            label: Text(isPublic ? 'ارسال برای همه' : 'ارسال خصوصی'),
          ),
        ],
      ),
    );
  }
}
