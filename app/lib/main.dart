import 'package:flutter/material.dart';

import 'app_preferences.dart';
import 'focus_screen.dart';
import 'history_screen.dart';
import 'home_dashboard.dart';
import 'preset_store.dart';
import 'studio_components.dart';

void main() => runApp(const AdaptiveFocusApp());

class AdaptiveFocusApp extends StatelessWidget {
  const AdaptiveFocusApp({super.key, this.store, this.preferences});

  final PresetStore? store;
  final AppPreferences? preferences;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Adaptive Focus Studio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: lavender),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: AppShell(store: store, preferences: preferences),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.store, this.preferences});

  final PresetStore? store;
  final AppPreferences? preferences;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  bool _isDark = false;
  bool _reducedMotion = false;
  int _defaultMinutes = 25;
  List<FocusPreset> _presets = [];
  List<FocusSession> _sessions = [];
  FocusPreset? _editingPreset;
  FocusPreset? _activePreset;
  PresetStore? _store;
  late final AppPreferences _preferences =
      widget.preferences ?? DeviceAppPreferences();
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadPresets();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final values = await Future.wait<Object>([
        _preferences.darkMode(),
        _preferences.defaultMinutes(),
        _preferences.reducedMotion(),
      ]);
      if (!mounted) return;
      setState(() {
        _isDark = values[0] as bool;
        _defaultMinutes = values[1] as int;
        _reducedMotion = values[2] as bool;
      });
    } catch (_) {
      if (mounted) _showPreferenceError();
    }
  }

  void _showPreferenceError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not save preferences. Try again.')),
    );
  }

  Future<void> _setDarkMode(bool value) async {
    final previous = _isDark;
    setState(() => _isDark = value);
    try {
      await _preferences.setDarkMode(value);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isDark = previous);
      _showPreferenceError();
    }
  }

  Future<void> _setDefaultMinutes(int value) async {
    final previous = _defaultMinutes;
    setState(() => _defaultMinutes = value);
    try {
      await _preferences.setDefaultMinutes(value);
    } catch (_) {
      if (!mounted) return;
      setState(() => _defaultMinutes = previous);
      _showPreferenceError();
    }
  }

  Future<void> _setReducedMotion(bool value) async {
    final previous = _reducedMotion;
    setState(() => _reducedMotion = value);
    try {
      await _preferences.setReducedMotion(value);
    } catch (_) {
      if (!mounted) return;
      setState(() => _reducedMotion = previous);
      _showPreferenceError();
    }
  }

  Future<void> _loadPresets() async {
    try {
      final store = widget.store ?? await PresetStore.openDevice();
      final presets = await store.all();
      final sessions = await store.sessions();
      if (!mounted) {
        if (widget.store == null) await store.close();
        return;
      }
      setState(() {
        _store = store;
        _presets = presets;
        _sessions = sessions;
        _loading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Failed to load local data: $error\n$stackTrace');
      if (mounted) {
        setState(() {
          _loadError = 'Unable to load presets. Restart the app and try again.';
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    if (widget.store == null) _store?.close();
    super.dispose();
  }

  Future<bool> _savePreset(FocusPreset preset) async {
    final store = _store;
    if (store == null) return false;
    try {
      if (preset.id == null) {
        await store.create(preset);
      } else {
        await store.update(preset);
      }
      final presets = await store.all();
      if (!mounted) return false;
      setState(() {
        _presets = presets;
        _editingPreset = null;
        _selectedIndex = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${preset.name} saved on this device')),
      );
      return true;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save the preset. Try again.'),
          ),
        );
      }
      return false;
    }
  }

  void _openEditor([FocusPreset? preset]) {
    setState(() {
      _editingPreset = preset;
      _selectedIndex = 1;
    });
  }

  void _openFocus(FocusPreset preset) {
    setState(() {
      _activePreset = preset;
      _selectedIndex = 2;
    });
  }

  Future<bool> _saveSession(FocusSession session) async {
    try {
      if (session.id == null) {
        await _store!.createSession(session);
      } else {
        await _store!.updateSession(session);
      }
      final sessions = await _store!.sessions();
      if (!mounted) return false;
      setState(() => _sessions = sessions);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Session saved to history')));
      return true;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save this session. Try again.'),
          ),
        );
      }
      return false;
    }
  }

  Future<void> _deleteSession(FocusSession session) async {
    if (session.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this session?'),
        content: Text('${session.presetName} will be removed from history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep session'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _store!.deleteSession(session.id!);
      final sessions = await _store!.sessions();
      if (mounted) setState(() => _sessions = sessions);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not delete this session. Try again.'),
          ),
        );
      }
    }
  }

  Future<void> _deletePreset(FocusPreset preset) async {
    final id = preset.id;
    final store = _store;
    if (id == null || store == null) return;
    late final int linkedCount;
    try {
      linkedCount = await store.linkedSessionCount(id);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not check linked sessions. Try again.'),
          ),
        );
      }
      return;
    }
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this plan?'),
        content: Text(
          linkedCount == 0
              ? '${preset.name} will be removed from this device.'
              : '${preset.name} and $linkedCount linked ${linkedCount == 1 ? 'session' : 'sessions'} will be removed from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep plan'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await store.delete(id);
      final presets = await store.all();
      final sessions = await store.sessions();
      if (!mounted) return;
      setState(() {
        _presets = presets;
        _sessions = sessions;
        if (_editingPreset?.id == id) {
          _editingPreset = null;
          _selectedIndex = 0;
        }
        if (_activePreset?.id == id) _activePreset = null;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('${preset.name} deleted')));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not delete the plan. Try again.'),
          ),
        );
      }
    }
  }

  static const _sections = <_Section>[
    _Section(
      title: 'Presets',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
    ),
    _Section(
      title: 'Editor',
      icon: Icons.edit_outlined,
      selectedIcon: Icons.edit,
    ),
    _Section(
      title: 'Focus',
      icon: Icons.timer_outlined,
      selectedIcon: Icons.timer,
    ),
    _Section(
      title: 'History',
      icon: Icons.history_outlined,
      selectedIcon: Icons.history,
    ),
    _Section(
      title: 'Settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final foreground = _isDark ? Colors.white : ink;
    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: _isDark ? Colors.black : Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: lavender,
          brightness: _isDark ? Brightness.dark : Brightness.light,
        ),
      ),
      child: Scaffold(
        backgroundColor: _isDark ? Colors.black : Colors.white,
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
            ? Center(child: Text(_loadError!))
            : IndexedStack(
                index: _selectedIndex,
                children: [
                  HomeDashboard(
                    presets: _presets,
                    onCreate: () => _openEditor(),
                    onEdit: _openEditor,
                    onStart: _openFocus,
                    onDelete: _deletePreset,
                    onToggleTheme: () => _setDarkMode(!_isDark),
                    isDark: _isDark,
                  ),
                  PresetEditor(
                    key: ValueKey(_editingPreset?.id ?? 'new-$_defaultMinutes'),
                    initialPreset: _editingPreset,
                    defaultMinutes: _defaultMinutes,
                    onSave: _savePreset,
                    onCancel: () => setState(() => _selectedIndex = 0),
                    onDelete: _deletePreset,
                  ),
                  FocusScreen(
                    preset: _activePreset,
                    sessions: _sessions,
                    onFinish: _saveSession,
                    onChoosePlan: () => setState(() => _selectedIndex = 0),
                  ),
                  HistoryScreen(
                    sessions: _sessions,
                    onDelete: _deleteSession,
                    onSave: _saveSession,
                  ),
                  _SettingsScreen(
                    isDark: _isDark,
                    defaultMinutes: _defaultMinutes,
                    reducedMotion: _reducedMotion,
                    onDarkModeChanged: _setDarkMode,
                    onDefaultMinutesChanged: _setDefaultMinutes,
                    onReducedMotionChanged: _setReducedMotion,
                  ),
                ],
              ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Container(
                height: 66,
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: _isDark ? Colors.white : ink,
                  borderRadius: BorderRadius.circular(38),
                ),
                child: Row(
                  children: [
                    for (var index = 0; index < _sections.length; index++)
                      Expanded(
                        child: Tooltip(
                          message: _sections[index].title,
                          child: Semantics(
                            label: _sections[index].title,
                            button: true,
                            selected: _selectedIndex == index,
                            child: InkWell(
                              key: Key('nav-${_sections[index].title}'),
                              onTap: () {
                                if (index == 1) {
                                  _openEditor();
                                } else {
                                  setState(() => _selectedIndex = index);
                                }
                              },
                              borderRadius: BorderRadius.circular(36),
                              child: Container(
                                height: 55,
                                decoration: BoxDecoration(
                                  color: _selectedIndex == index
                                      ? (_isDark ? Colors.black : Colors.white)
                                      : Colors.transparent,
                                  shape: BoxShape.circle,
                                  border: _selectedIndex == index
                                      ? Border.all(
                                          color: _isDark
                                              ? Colors.black
                                              : Colors.white,
                                          width: 2,
                                        )
                                      : null,
                                ),
                                child: Icon(
                                  _selectedIndex == index
                                      ? _sections[index].selectedIcon
                                      : _sections[index].icon,
                                  color: _selectedIndex == index
                                      ? foreground
                                      : (_isDark ? ink : Colors.white),
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PresetEditor extends StatefulWidget {
  const PresetEditor({
    super.key,
    required this.onSave,
    required this.onCancel,
    required this.onDelete,
    required this.defaultMinutes,
    this.initialPreset,
  });

  final Future<bool> Function(FocusPreset) onSave;
  final VoidCallback onCancel;
  final ValueChanged<FocusPreset> onDelete;
  final int defaultMinutes;
  final FocusPreset? initialPreset;

  @override
  State<PresetEditor> createState() => _PresetEditorState();
}

class _PresetEditorState extends State<PresetEditor> {
  final _formKey = GlobalKey<FormState>();
  late String _mood = widget.initialPreset?.mood ?? 'Calm';
  late final _nameController = TextEditingController(
    text: widget.initialPreset?.name ?? '',
  );
  late final _durationController = TextEditingController(
    text: '${widget.initialPreset?.durationMinutes ?? widget.defaultMinutes}',
  );

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final saved = await widget.onSave(
      FocusPreset(
        id: widget.initialPreset?.id,
        name: _nameController.text.trim(),
        durationMinutes: int.parse(_durationController.text.trim()),
        mood: _mood,
      ),
    );
    if (saved && mounted) {
      _nameController.clear();
      _durationController.text = '${widget.defaultMinutes}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = isDark ? Colors.white : ink;
    return StudioPage(
      eyebrow: widget.initialPreset == null ? 'Preset editor' : 'Edit preset',
      title: 'Make a plan',
      subtitle: '',
      children: [
        const StudioCard(
          color: lavender,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your next\nsmall step.',
                style: TextStyle(
                  color: ink,
                  fontSize: 33,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.7,
                ),
              ),
              SizedBox(height: 13),
              Text(
                'Create or edit a reusable focus preset.',
                style: TextStyle(color: ink, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        StudioCard(
          color: isDark ? const Color(0xFF2B2534) : Colors.white,
          borderColor: isDark ? Colors.white24 : const Color(0xFFE7E1ED),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  style: TextStyle(color: foreground),
                  decoration: InputDecoration(
                    labelText: 'Preset name',
                    hintText: 'e.g. Study sprint',
                    filled: true,
                    fillColor: isDark ? const Color(0xFF222126) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(17),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  textInputAction: TextInputAction.next,
                  maxLength: 40,
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Enter a preset name'
                      : null,
                ),
                const SizedBox(height: 13),
                DropdownButtonFormField<String>(
                  initialValue: _mood,
                  decoration: InputDecoration(
                    labelText: 'Mood',
                    filled: true,
                    fillColor: isDark ? const Color(0xFF222126) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(17),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: const ['Calm', 'Energized', 'Tired']
                      .map(
                        (mood) =>
                            DropdownMenuItem(value: mood, child: Text(mood)),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _mood = value ?? 'Calm'),
                ),
                const SizedBox(height: 13),
                TextFormField(
                  controller: _durationController,
                  style: TextStyle(color: foreground),
                  decoration: InputDecoration(
                    labelText: 'Duration (minutes)',
                    filled: true,
                    fillColor: isDark ? const Color(0xFF222126) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(17),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final minutes = int.tryParse(value?.trim() ?? '');
                    return minutes == null || minutes < 1 || minutes > 180
                        ? 'Enter a whole number from 1 to 180'
                        : null;
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: StudioButton(
                        color: ink,
                        label: widget.initialPreset == null
                            ? 'Save plan'
                            : 'Save changes',
                        onPressed: _submit,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 52,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFF2ECFA),
                            foregroundColor: ink,
                          ),
                          onPressed: widget.onCancel,
                          child: const Text(
                            'Cancel',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (widget.initialPreset != null)
                  TextButton.icon(
                    onPressed: () => widget.onDelete(widget.initialPreset!),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete preset'),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Section {
  const _Section({
    required this.title,
    required this.icon,
    required this.selectedIcon,
  });

  final String title;
  final IconData icon;
  final IconData selectedIcon;
}

class _SettingsScreen extends StatelessWidget {
  const _SettingsScreen({
    required this.isDark,
    required this.defaultMinutes,
    required this.reducedMotion,
    required this.onDarkModeChanged,
    required this.onDefaultMinutesChanged,
    required this.onReducedMotionChanged,
  });

  final bool isDark;
  final int defaultMinutes;
  final bool reducedMotion;
  final ValueChanged<bool> onDarkModeChanged;
  final ValueChanged<int> onDefaultMinutesChanged;
  final ValueChanged<bool> onReducedMotionChanged;

  @override
  Widget build(BuildContext context) {
    return StudioPage(
      eyebrow: 'Settings',
      title: 'Make it yours',
      subtitle: '',
      children: [
        const StudioCard(
          color: lavender,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your focus.\nYour pace.',
                style: TextStyle(
                  color: ink,
                  fontSize: 33,
                  fontWeight: FontWeight.w900,
                  height: 1,
                  letterSpacing: -1.5,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Preferences stay on this device.',
                style: TextStyle(color: ink),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        StudioCard(
          color: isDark ? const Color(0xFF242128) : Colors.white,
          borderColor: isDark ? Colors.white24 : const Color(0xFFE7E1ED),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Default duration',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                trailing: DropdownButton<int>(
                  value: defaultMinutes,
                  onChanged: (value) {
                    if (value != null) onDefaultMinutesChanged(value);
                  },
                  items: const [15, 25, 30, 45, 60]
                      .map(
                        (minutes) => DropdownMenuItem(
                          value: minutes,
                          child: Text('$minutes min'),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 8),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('10 minutes', style: TextStyle(fontSize: 11)),
                  Text('60 minutes', style: TextStyle(fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        StudioCard(
          color: isDark ? const Color(0xFF242128) : Colors.white,
          borderColor: isDark ? Colors.white24 : const Color(0xFFE7E1ED),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Reduce motion',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: const Text('Limit optional interface animation.'),
                value: reducedMotion,
                onChanged: onReducedMotionChanged,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        StudioCard(
          color: isDark ? const Color(0xFF242128) : Colors.white,
          borderColor: isDark ? Colors.white24 : const Color(0xFFE7E1ED),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Offline storage',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text('SQLite records and device preferences.'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        StudioCard(
          color: isDark ? const Color(0xFF242128) : Colors.white,
          borderColor: isDark ? Colors.white24 : const Color(0xFFE7E1ED),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Dark mode',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: const Text('Use a darker screen palette'),
                value: isDark,
                onChanged: onDarkModeChanged,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const StudioCard(
          color: Color(0xFFF2ECFA),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Saved automatically',
                style: TextStyle(
                  color: ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 7),
              Text(
                'Your choices remain after restarting.',
                style: TextStyle(color: ink),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
