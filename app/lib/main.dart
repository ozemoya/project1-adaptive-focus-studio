import 'package:flutter/material.dart';

import 'home_dashboard.dart';
import 'preset_store.dart';

void main() => runApp(const AdaptiveFocusApp());

class AdaptiveFocusApp extends StatelessWidget {
  const AdaptiveFocusApp({super.key, this.store});

  final PresetStore? store;

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
      home: AppShell(store: store),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.store});

  final PresetStore? store;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  bool _isDark = false;
  List<FocusPreset> _presets = [];
  FocusPreset? _editingPreset;
  PresetStore? _store;
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadPresets();
  }

  Future<void> _loadPresets() async {
    try {
      final store = widget.store ?? await PresetStore.openDevice();
      final presets = await store.all();
      if (!mounted) {
        if (widget.store == null) await store.close();
        return;
      }
      setState(() {
        _store = store;
        _presets = presets;
        _loading = false;
      });
    } catch (_) {
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

  Future<void> _deletePreset(FocusPreset preset) async {
    final id = preset.id;
    final store = _store;
    if (id == null || store == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this plan?'),
        content: Text('${preset.name} will be removed from this device.'),
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
      if (!mounted) return;
      setState(() => _presets = presets);
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
      heading: 'Choose a focus plan',
      description: 'Your saved presets and a quick summary will appear here.',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
    ),
    _Section(
      title: 'Editor',
      heading: 'Create a preset',
      description: 'Name, mood, and duration controls belong on this screen.',
      icon: Icons.edit_outlined,
      selectedIcon: Icons.edit,
    ),
    _Section(
      title: 'Focus',
      heading: 'Run a focus session',
      description:
          'The timer, pause control, and duration suggestion belong here.',
      icon: Icons.timer_outlined,
      selectedIcon: Icons.timer,
    ),
    _Section(
      title: 'History',
      heading: 'Review your sessions',
      description:
          'Saved sessions, filters, and insights belong on this screen.',
      icon: Icons.history_outlined,
      selectedIcon: Icons.history,
    ),
    _Section(
      title: 'Settings',
      heading: 'Choose local preferences',
      description: 'Default duration and reduced-motion controls belong here.',
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
                    onDelete: _deletePreset,
                    onToggleTheme: () => setState(() => _isDark = !_isDark),
                    isDark: _isDark,
                  ),
                  PresetEditor(
                    key: ValueKey(_editingPreset?.id ?? 'new'),
                    initialPreset: _editingPreset,
                    onSave: _savePreset,
                  ),
                  for (final section in _sections.skip(2))
                    _SectionPreview(section: section, isDark: _isDark),
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
  const PresetEditor({super.key, required this.onSave, this.initialPreset});

  final Future<bool> Function(FocusPreset) onSave;
  final FocusPreset? initialPreset;

  @override
  State<PresetEditor> createState() => _PresetEditorState();
}

class _PresetEditorState extends State<PresetEditor> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(
    text: widget.initialPreset?.name ?? '',
  );
  late final _durationController = TextEditingController(
    text: '${widget.initialPreset?.durationMinutes ?? 25}',
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
      ),
    );
    if (saved && mounted) {
      _nameController.clear();
      _durationController.text = '25';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = isDark ? Colors.white : ink;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(23, 31, 23, 30),
        children: [
          Text(
            widget.initialPreset == null ? 'Create a preset' : 'Edit a preset',
            style: TextStyle(
              color: foreground.withValues(alpha: 0.58),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'A plan that fits\nyour day.',
            style: TextStyle(
              color: foreground,
              fontSize: 38,
              height: 0.98,
              fontWeight: FontWeight.w900,
              letterSpacing: -2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Give your focus session a name and a length.',
            style: TextStyle(color: foreground.withValues(alpha: 0.65)),
          ),
          const SizedBox(height: 31),
          Form(
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
                    fillColor: isDark
                        ? const Color(0xFF222126)
                        : const Color(0xFFF1EAFD),
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
                TextFormField(
                  controller: _durationController,
                  style: TextStyle(color: foreground),
                  decoration: InputDecoration(
                    labelText: 'Duration (minutes)',
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF222126)
                        : const Color(0xFFF1EAFD),
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
                SizedBox(
                  height: 56,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: lavender,
                      foregroundColor: ink,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: _submit,
                    child: Text(
                      widget.initialPreset == null
                          ? 'Save preset'
                          : 'Save changes',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section {
  const _Section({
    required this.title,
    required this.heading,
    required this.description,
    required this.icon,
    required this.selectedIcon,
  });

  final String title;
  final String heading;
  final String description;
  final IconData icon;
  final IconData selectedIcon;
}

class _SectionPreview extends StatelessWidget {
  const _SectionPreview({required this.section, required this.isDark});

  final _Section section;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final foreground = isDark ? Colors.white : ink;
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(section.selectedIcon, size: 48, color: lavender),
                const SizedBox(height: 20),
                Text(
                  section.heading,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  section.description,
                  style: TextStyle(
                    color: foreground.withValues(alpha: 0.65),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: 90,
                  height: 8,
                  decoration: BoxDecoration(
                    color: lavender,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
