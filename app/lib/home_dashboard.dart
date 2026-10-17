import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'preset_store.dart';

const ink = Color(0xFF111015);
const lavender = Color(0xFFC7A4F8);
const orange = Color(0xFFFFBF60);
const periwinkle = Color(0xFF91A3FA);
const pink = Color(0xFFF76AC6);

class HomeDashboard extends StatelessWidget {
  const HomeDashboard({
    super.key,
    required this.presets,
    required this.onCreate,
    required this.onEdit,
    required this.onStart,
    required this.onDelete,
    required this.onToggleTheme,
    required this.isDark,
  });

  final List<FocusPreset> presets;
  final VoidCallback onCreate;
  final ValueChanged<FocusPreset> onEdit;
  final ValueChanged<FocusPreset> onStart;
  final ValueChanged<FocusPreset> onDelete;
  final VoidCallback onToggleTheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final foreground = isDark ? Colors.white : ink;
    final today = DateTime.now();
    final dateLabel =
        '${_weekday(today.weekday)}, ${today.day} ${_month(today.month)}';
    final featured = presets.isNotEmpty ? presets.first : null;
    final second = presets.length > 1 ? presets[1] : null;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 26),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: lavender,
                child: Text(
                  'M',
                  style: TextStyle(
                    color: ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, Myles',
                      style: TextStyle(
                        color: foreground,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.9,
                      ),
                    ),
                    Text(
                      dateLabel,
                      style: TextStyle(
                        color: foreground.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: isDark
                    ? 'Switch to light mode'
                    : 'Switch to dark mode',
                onPressed: onToggleTheme,
                icon: Icon(
                  isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  color: foreground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          Container(
            height: 172,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: lavender,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -10,
                  top: 12,
                  child: Transform.rotate(
                    angle: -0.15,
                    child: const CustomPaint(
                      size: Size(150, 150),
                      painter: _FlowerPainter(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(19),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Daily\nFocus',
                        style: TextStyle(
                          color: ink,
                          height: 0.91,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -2.0,
                        ),
                      ),
                      const SizedBox(height: 9),
                      const Text(
                        'Plan your next focus session.',
                        style: TextStyle(
                          color: ink,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          for (final color in [orange, periwinkle, pink])
                            Container(
                              margin: const EdgeInsets.only(right: 3),
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(color: lavender, width: 2),
                              ),
                            ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${presets.length} saved ${presets.length == 1 ? 'plan' : 'plans'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: ink,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              for (var offset = -3; offset <= 3; offset++)
                Expanded(
                  child: _DayPill(
                    day: today.add(Duration(days: offset)),
                    selected: offset == 0,
                    isDark: isDark,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 29),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Your Plan',
                  style: TextStyle(
                    color: foreground,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.2,
                  ),
                ),
              ),
              TextButton(
                onPressed: onCreate,
                child: Text(
                  'Add new  +',
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 238,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 11,
                  child: _PlanCard(
                    color: orange,
                    label: featured == null ? 'START HERE' : 'SAVED PRESET',
                    title: featured?.name ?? 'Deep Focus',
                    minutes: featured?.durationMinutes ?? 25,
                    icon: Icons.notifications_active_rounded,
                    onTap: featured == null
                        ? onCreate
                        : () => onStart(featured),
                    preset: featured,
                    onEdit: onEdit,
                    onDelete: onDelete,
                    footer: featured == null
                        ? 'Build your first plan'
                        : 'Saved on this device',
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  flex: 9,
                  child: Column(
                    children: [
                      Expanded(
                        child: _PlanCard(
                          color: periwinkle,
                          label: second == null ? 'A LITTLE RESET' : 'SAVED',
                          title: second?.name ?? 'Quick Reset',
                          minutes: second?.durationMinutes ?? 10,
                          icon: Icons.cloud_rounded,
                          onTap: second == null
                              ? onCreate
                              : () => onStart(second),
                          preset: second,
                          onEdit: onEdit,
                          onDelete: onDelete,
                          compact: true,
                        ),
                      ),
                      const SizedBox(height: 9),
                      InkWell(
                        onTap: onCreate,
                        borderRadius: BorderRadius.circular(17),
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: pink,
                            borderRadius: BorderRadius.circular(17),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_circle,
                                color: Colors.white,
                                size: 23,
                              ),
                              SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Make a plan',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: ink,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (presets.isEmpty) ...[
            const SizedBox(height: 18),
            Text(
              'Your saved plans will appear here once you create one.',
              style: TextStyle(
                color: foreground.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ] else if (presets.length > 2) ...[
            const SizedBox(height: 23),
            Text(
              'More plans',
              style: TextStyle(
                color: foreground,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            for (final preset in presets.skip(2))
              ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: () => onStart(preset),
                title: Text(preset.name, style: TextStyle(color: foreground)),
                subtitle: Text(
                  '${preset.durationMinutes} min',
                  style: TextStyle(color: foreground.withValues(alpha: 0.6)),
                ),
                trailing: _PresetMenu(
                  preset: preset,
                  onEdit: onEdit,
                  onDelete: onDelete,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _DayPill extends StatelessWidget {
  const _DayPill({
    required this.day,
    required this.selected,
    required this.isDark,
  });
  final DateTime day;
  final bool selected;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final foreground = selected
        ? (isDark ? ink : Colors.white)
        : (isDark ? Colors.white : ink);
    return Container(
      height: 64,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: selected ? (isDark ? Colors.white : ink) : Colors.transparent,
        border: Border.all(color: isDark ? Colors.white70 : ink, width: 1.2),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (selected) Icon(Icons.star, size: 12, color: foreground),
          Text(
            _weekday(day.weekday).substring(0, 3),
            style: TextStyle(
              color: foreground,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '${day.day}',
            style: TextStyle(
              color: foreground,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.color,
    required this.label,
    required this.title,
    required this.minutes,
    required this.icon,
    required this.onTap,
    this.preset,
    this.onEdit,
    this.onDelete,
    this.compact = false,
    this.footer,
  });
  final Color color;
  final String label;
  final String title;
  final int minutes;
  final IconData icon;
  final VoidCallback onTap;
  final FocusPreset? preset;
  final ValueChanged<FocusPreset>? onEdit;
  final ValueChanged<FocusPreset>? onDelete;
  final bool compact;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Stack(
          children: [
            Positioned(
              right: compact ? -14 : -8,
              bottom: compact ? -16 : 16,
              child: Transform.rotate(
                angle: -0.35,
                child: Icon(
                  icon,
                  color: compact
                      ? const Color(0xFFDCE6FF)
                      : const Color(0xFFA48AEA),
                  size: compact ? 84 : 98,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(compact ? 14 : 17),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: ink,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: ink,
                      fontSize: compact ? 19 : 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1.2,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '$minutes min',
                    style: const TextStyle(
                      color: ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (!compact) ...[
                    const Spacer(),
                    Text(
                      footer ?? '',
                      style: const TextStyle(
                        color: ink,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (preset != null && onEdit != null && onDelete != null)
              Positioned(
                top: 3,
                right: 2,
                child: _PresetMenu(
                  preset: preset!,
                  onEdit: onEdit!,
                  onDelete: onDelete!,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PresetMenu extends StatelessWidget {
  const _PresetMenu({
    required this.preset,
    required this.onEdit,
    required this.onDelete,
  });

  final FocusPreset preset;
  final ValueChanged<FocusPreset> onEdit;
  final ValueChanged<FocusPreset> onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      key: Key('plan-menu-${preset.id}'),
      tooltip: 'More options for ${preset.name}',
      icon: const Icon(Icons.more_horiz, color: ink, size: 21),
      onSelected: (action) =>
          action == 'edit' ? onEdit(preset) : onDelete(preset),
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'edit', child: Text('Edit plan')),
        PopupMenuItem(value: 'delete', child: Text('Delete plan')),
      ],
    );
  }
}

class _FlowerPainter extends CustomPainter {
  const _FlowerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final petal = Rect.fromCenter(
      center: Offset(0, -39),
      width: 43,
      height: 87,
    );
    canvas.save();
    canvas.translate(center.dx, center.dy);
    for (var i = 0; i < 7; i++) {
      canvas.save();
      canvas.rotate(i * math.pi * 2 / 7);
      canvas.drawOval(
        petal,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFDC66), Color(0xFFFFA721)],
          ).createShader(petal),
      );
      canvas.restore();
    }
    canvas.drawCircle(
      Offset.zero,
      15,
      Paint()..color = const Color(0xFFFFCA42),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

String _weekday(int day) => const [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
][day - 1];
String _month(int month) => const [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
][month - 1];
