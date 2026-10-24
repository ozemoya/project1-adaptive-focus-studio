import 'dart:async';

import 'package:flutter/material.dart';

import 'home_dashboard.dart';
import 'preset_store.dart';
import 'session_scout.dart';
import 'studio_components.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({
    super.key,
    required this.preset,
    required this.sessions,
    required this.onFinish,
    required this.onChoosePlan,
    this.now,
  });

  final FocusPreset? preset;
  final List<FocusSession> sessions;
  final Future<bool> Function(FocusSession) onFinish;
  final VoidCallback onChoosePlan;
  final DateTime Function()? now;

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  Timer? _timer;
  int _elapsedSeconds = 0;
  int _elapsedAtStart = 0;
  DateTime? _runStartedAt;
  bool _running = false;
  bool _started = false;
  bool _completed = false;
  bool _saving = false;
  int? _overrideMinutes;
  bool _showSuggestion = true;

  DateTime get _now => widget.now?.call() ?? DateTime.now();

  @override
  void didUpdateWidget(covariant FocusScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.preset?.id != widget.preset?.id) _reset();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    if (widget.preset == null || _running || _completed) return;
    _timer?.cancel();
    _elapsedAtStart = _elapsedSeconds;
    _runStartedAt = _now;
    setState(() {
      _started = true;
      _running = true;
    });
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _refreshElapsed(),
    );
  }

  void _refreshElapsed() {
    if (!mounted || !_running || _runStartedAt == null) return;
    final total = (_overrideMinutes ?? widget.preset!.durationMinutes) * 60;
    final seconds = _now.difference(_runStartedAt!).inSeconds;
    final elapsed = (_elapsedAtStart + seconds).clamp(0, total);
    setState(() {
      _elapsedSeconds = elapsed;
      if (elapsed == total) {
        _running = false;
        _completed = true;
        _timer?.cancel();
      }
    });
  }

  void _pause() {
    _refreshElapsed();
    _timer?.cancel();
    if (mounted) setState(() => _running = false);
  }

  void _reset() {
    _timer?.cancel();
    _elapsedSeconds = 0;
    _elapsedAtStart = 0;
    _runStartedAt = null;
    _running = false;
    _started = false;
    _completed = false;
    _overrideMinutes = null;
    _showSuggestion = true;
  }

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset this session?'),
        content: const Text('The current timer progress will be cleared.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep going'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) setState(_reset);
  }

  Future<void> _finish() async {
    final preset = widget.preset;
    if (preset == null || !_started || _saving) return;
    _refreshElapsed();
    _timer?.cancel();
    setState(() {
      _running = false;
      _saving = true;
    });
    final saved = await widget.onFinish(
      FocusSession(
        presetId: preset.id,
        presetName: preset.name,
        mood: preset.mood,
        plannedMinutes: _overrideMinutes ?? preset.durationMinutes,
        completedMinutes: (_elapsedSeconds / 60).ceil(),
        finishedAt: _now,
      ),
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (saved) _reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final preset = widget.preset;
    if (preset == null) {
      return StudioPage(
        eyebrow: 'Session activity',
        title: 'Time to focus',
        subtitle: '',
        children: [
          StudioCard(
            color: lavender,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.timer_outlined, size: 52, color: ink),
                const SizedBox(height: 48),
                const Text(
                  'Ready when you are.',
                  style: TextStyle(
                    color: ink,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 20),
                StudioButton(
                  label: 'Choose a plan',
                  onPressed: widget.onChoosePlan,
                ),
              ],
            ),
          ),
        ],
      );
    }
    final plannedMinutes = _overrideMinutes ?? preset.durationMinutes;
    final total = plannedMinutes * 60;
    final remaining = (total - _elapsedSeconds).clamp(0, total);
    final display =
        '${(remaining ~/ 60).toString().padLeft(2, '0')}:${(remaining % 60).toString().padLeft(2, '0')}';
    final status = _completed
        ? 'Complete'
        : !_started
        ? 'Ready'
        : _running
        ? 'Running'
        : 'Paused';
    final suggestion = suggestDuration(widget.sessions, preset.mood);
    return StudioPage(
      eyebrow: 'Session activity',
      title: 'Time to focus',
      subtitle: '',
      children: [
        StudioCard(
          color: lavender,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                preset.name,
                style: const TextStyle(
                  color: ink,
                  fontSize: 31,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.4,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${preset.mood} / Planned $plannedMinutes minutes',
                style: const TextStyle(color: ink, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        StudioCard(
          color: orange,
          child: Column(
            children: [
              const Text(
                'READY TO BEGIN',
                style: TextStyle(
                  color: ink,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 22),
              Semantics(
                label:
                    'Time remaining: ${remaining ~/ 60} minutes and ${remaining % 60} seconds',
                value: status,
                child: ExcludeSemantics(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      display,
                      key: const Key('focus-timer'),
                      style: const TextStyle(
                        color: ink,
                        fontSize: 66,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -3,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              LinearProgressIndicator(
                value: _elapsedSeconds / total,
                color: ink,
                backgroundColor: Colors.white54,
                minHeight: 7,
              ),
              const SizedBox(height: 13),
              Text(
                '$status · Elapsed ${(_elapsedSeconds ~/ 60).toString().padLeft(2, '0')}:${(_elapsedSeconds % 60).toString().padLeft(2, '0')}',
                style: const TextStyle(color: ink, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 13),
        Row(
          children: [
            Expanded(
              child: StudioButton(
                color: ink,
                label: 'Start session',
                onPressed: _started ? null : _start,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StudioButton(
                color: periwinkle,
                label: _running ? 'Pause' : 'Resume',
                onPressed: _started && !_completed
                    ? (_running ? _pause : _start)
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _started && !_saving ? _finish : null,
                child: const Text('Finish'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                onPressed: _started ? _confirmReset : null,
                child: const Text('Reset'),
              ),
            ),
          ],
        ),
        if (suggestion != null && _showSuggestion && !_started) ...[
          const SizedBox(height: 13),
          StudioCard(
            color: const Color(0xFFF2ECFA),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SESSION SCOUT',
                  style: TextStyle(
                    color: ink,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  'Try ${suggestion.minutes} minutes',
                  style: const TextStyle(
                    color: ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Median of ${suggestion.samples.join(', ')} min from 3 recent ${preset.mood.toLowerCase()} sessions. Fixed baseline: ${ScoutSuggestion.baselineMinutes} min.',
                  style: const TextStyle(color: ink),
                ),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 8,
                  children: [
                    TextButton(
                      onPressed: () => setState(() {
                        _overrideMinutes = suggestion.minutes;
                        _showSuggestion = false;
                      }),
                      child: const Text('Apply suggestion'),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _showSuggestion = false),
                      child: const Text('Not now'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
