import 'package:flutter/material.dart';

void main() => runApp(const AdaptiveFocusApp());

class AdaptiveFocusApp extends StatelessWidget {
  const AdaptiveFocusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Adaptive Focus Studio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B5E69)),
        useMaterial3: true,
      ),
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  final List<FocusPreset> _presets = [];

  void _savePreset(FocusPreset preset) {
    setState(() {
      _presets.add(preset);
      _selectedIndex = 0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${preset.name} saved for this session')),
    );
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
      heading: 'Create or edit a preset',
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
    return Scaffold(
      appBar: AppBar(title: const Text('Adaptive Focus Studio')),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _PresetList(
            presets: _presets,
            onCreate: () => setState(() => _selectedIndex = 1),
          ),
          PresetEditor(onSave: _savePreset),
          for (final section in _sections.skip(2))
            _SectionPreview(section: section),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          for (final section in _sections)
            NavigationDestination(
              icon: Icon(section.icon),
              selectedIcon: Icon(section.selectedIcon),
              label: section.title,
            ),
        ],
      ),
    );
  }
}

class FocusPreset {
  const FocusPreset({required this.name, required this.durationMinutes});

  final String name;
  final int durationMinutes;
}

class _PresetList extends StatelessWidget {
  const _PresetList({required this.presets, required this.onCreate});

  final List<FocusPreset> presets;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Choose a focus plan',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Build a reusable plan for your next study session.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text('Create preset'),
          ),
          const SizedBox(height: 20),
          if (presets.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('No presets yet. Create one to get started.'),
              ),
            )
          else
            for (final preset in presets)
              Card(
                child: ListTile(
                  title: Text(preset.name),
                  subtitle: Text('${preset.durationMinutes} minutes'),
                  leading: const Icon(Icons.timer_outlined),
                ),
              ),
        ],
      ),
    );
  }
}

class PresetEditor extends StatefulWidget {
  const PresetEditor({super.key, required this.onSave});

  final ValueChanged<FocusPreset> onSave;

  @override
  State<PresetEditor> createState() => _PresetEditorState();
}

class _PresetEditorState extends State<PresetEditor> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _durationController = TextEditingController(text: '25');

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSave(
      FocusPreset(
        name: _nameController.text.trim(),
        durationMinutes: int.parse(_durationController.text.trim()),
      ),
    );
    _nameController.clear();
    _durationController.text = '25';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Create or edit a preset',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose a name and a focus duration. You can change these before starting a session.',
          ),
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Preset name',
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                  maxLength: 40,
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Enter a preset name'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _durationController,
                  decoration: const InputDecoration(
                    labelText: 'Duration (minutes)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final minutes = int.tryParse(value?.trim() ?? '');
                    return minutes == null || minutes < 1 || minutes > 180
                        ? 'Enter a whole number from 1 to 180'
                        : null;
                  },
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _submit,
                  child: const Text('Save preset'),
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
  const _SectionPreview({required this.section});

  final _Section section;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
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
                Icon(section.selectedIcon, size: 48, color: colors.primary),
                const SizedBox(height: 20),
                Text(
                  section.heading,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  section.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                const Chip(label: Text('Navigation prototype')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
