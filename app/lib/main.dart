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
          for (final section in _sections) _SectionPreview(section: section),
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
