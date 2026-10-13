import 'package:adaptive_focus_studio/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('all five sections are reachable from the navigation bar', (
    tester,
  ) async {
    await tester.pumpWidget(const AdaptiveFocusApp());

    final sections = <String, String>{
      'Presets': 'Choose a focus plan',
      'Editor': 'Create or edit a preset',
      'Focus': 'Run a focus session',
      'History': 'Review your sessions',
      'Settings': 'Choose local preferences',
    };

    for (final entry in sections.entries) {
      await tester.tap(find.widgetWithText(NavigationDestination, entry.key));
      await tester.pumpAndSettle();
      expect(find.text(entry.value), findsOneWidget);
    }
  });
}
