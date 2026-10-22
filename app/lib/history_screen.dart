import 'package:flutter/material.dart';

import 'home_dashboard.dart';
import 'preset_store.dart';
import 'studio_components.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    super.key,
    required this.sessions,
    required this.onDelete,
    required this.onSave,
  });

  final List<FocusSession> sessions;
  final ValueChanged<FocusSession> onDelete;
  final Future<bool> Function(FocusSession) onSave;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _mood = 'All';

  Future<void> _editSession([FocusSession? session]) => showDialog<void>(
    context: context,
    builder: (_) =>
        _SessionEditorDialog(session: session, onSave: widget.onSave),
  );

  @override
  Widget build(BuildContext context) {
    final shown = _mood == 'All'
        ? widget.sessions
        : widget.sessions.where((session) => session.mood == _mood).toList();
    final total = shown.fold<int>(
      0,
      (sum, session) => sum + session.completedMinutes,
    );
    final average = shown.isEmpty ? 0 : (total / shown.length).round();
    final dark = Theme.of(context).brightness == Brightness.dark;
    final foreground = dark ? Colors.white : ink;
    return StudioPage(
      eyebrow: 'History and insights',
      title: 'Your progress',
      subtitle: '',
      children: [
        StudioCard(
          color: lavender,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SMALL STEPS ADD UP',
                style: TextStyle(
                  color: ink,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '$average min',
                style: const TextStyle(
                  color: ink,
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -2,
                ),
              ),
              Text(
                'Average completed / ${shown.length} finished ${shown.length == 1 ? 'session' : 'sessions'}',
                style: const TextStyle(color: ink, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: Text(
                'Session history',
                style: TextStyle(
                  color: foreground,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
            ),
            DropdownButton<String>(
              value: _mood,
              onChanged: (value) => setState(() => _mood = value ?? 'All'),
              items: const ['All', 'Calm', 'Energized', 'Tired']
                  .map(
                    (mood) => DropdownMenuItem(value: mood, child: Text(mood)),
                  )
                  .toList(),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (shown.isEmpty)
          StudioCard(
            color: periwinkle,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.history_rounded, color: ink, size: 34),
                SizedBox(height: 18),
                Text(
                  'No finished sessions to show.',
                  style: TextStyle(
                    color: ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Finish a focus session and it will appear here.',
                  style: TextStyle(color: ink),
                ),
              ],
            ),
          )
        else
          for (var index = 0; index < shown.length; index++) ...[
            StudioCard(
              color: index.isEven ? orange : periwinkle,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              shown[index].presetName,
                              style: const TextStyle(
                                color: ink,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '${shown[index].completedMinutes} min / ${shown[index].mood} / ${_date(shown[index].finishedAt)}',
                              style: const TextStyle(color: ink),
                            ),
                            if (shown[index].isManual)
                              const Text(
                                'Manual entry',
                                style: TextStyle(color: ink, fontSize: 11),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => _editSession(shown[index]),
                        child: const Text('Edit log'),
                      ),
                      const Spacer(),
                      IconButton(
                        key: Key('delete-session-${shown[index].id}'),
                        tooltip: 'Delete ${shown[index].presetName} session',
                        onPressed: () => widget.onDelete(shown[index]),
                        icon: const Icon(Icons.delete_outline, color: ink),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        const SizedBox(height: 8),
        StudioButton(
          label: '+ Add manual log',
          onPressed: () => _editSession(),
        ),
      ],
    );
  }

  String _date(DateTime date) => '${date.month}/${date.day}/${date.year}';
}

class _SessionEditorDialog extends StatefulWidget {
  const _SessionEditorDialog({required this.session, required this.onSave});

  final FocusSession? session;
  final Future<bool> Function(FocusSession) onSave;

  @override
  State<_SessionEditorDialog> createState() => _SessionEditorDialogState();
}

class _SessionEditorDialogState extends State<_SessionEditorDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(
    text: widget.session?.presetName ?? '',
  );
  late final _minutes = TextEditingController(
    text: '${widget.session?.completedMinutes ?? 25}',
  );
  late String _mood = widget.session?.mood ?? 'Calm';
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _minutes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final session = widget.session;
    final completed = int.parse(_minutes.text.trim());
    try {
      final saved = await widget.onSave(
        FocusSession(
          id: session?.id,
          presetName: _name.text.trim(),
          mood: _mood,
          plannedMinutes: session?.plannedMinutes ?? completed,
          completedMinutes: completed,
          finishedAt: session?.finishedAt ?? DateTime.now(),
          isManual: session?.isManual ?? true,
        ),
      );
      if (saved && mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save this session. Try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.session == null ? 'Add manual log' : 'Edit session'),
    content: Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Plan name'),
            validator: (value) =>
                value == null || value.trim().isEmpty ? 'Enter a name' : null,
          ),
          DropdownButtonFormField<String>(
            initialValue: _mood,
            decoration: const InputDecoration(labelText: 'Mood'),
            items: const ['Calm', 'Energized', 'Tired']
                .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)),
                )
                .toList(),
            onChanged: _saving
                ? null
                : (value) => setState(() => _mood = value ?? 'Calm'),
          ),
          TextFormField(
            controller: _minutes,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Completed minutes'),
            validator: (value) {
              final parsed = int.tryParse(value?.trim() ?? '');
              return parsed == null || parsed < 1 || parsed > 180
                  ? 'Enter 1 to 180 minutes'
                  : null;
            },
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _saving ? null : _save,
        child: Text(_saving ? 'Saving...' : 'Save log'),
      ),
    ],
  );
}
