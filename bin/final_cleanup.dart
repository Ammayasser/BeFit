import 'dart:io';

void main() {
  final dir = Directory('lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    String content = file.readAsStringSync();
    bool modified = false;

    // Fix broken meal color syntax
    if (content.contains('/* TODO meal color */')) {
      content = content.replaceAllMapped(
        RegExp(r'Theme\.of\(context\)\.colorScheme\.primaryGreen\s*/\* TODO meal color \*/\s*[^),]+'),
        (match) => 'Theme.of(context).colorScheme.primary'
      );
      modified = true;
    }

    // Fix NColors still hanging around
    if (content.contains('NColors.')) {
        content = content.replaceAll('NColors.bgPrimary(context)', 'Theme.of(context).colorScheme.background');
        content = content.replaceAll('NColors.bgPrimary(\n                          context,\n                        )', 'Theme.of(context).colorScheme.background');
        content = content.replaceAll('NColors.accentPrimary(context)', 'Theme.of(context).extension<BeFitThemeExtension>()!.calorieRing');
        content = content.replaceAll('NColors.accentPrimary(\n                                    context,\n                                  )', 'Theme.of(context).extension<BeFitThemeExtension>()!.calorieRing');
        content = content.replaceAll('NColors.purple', 'AppColors.accentPurple');
        content = content.replaceAll('NColors.textTertiary(context)', 'Theme.of(context).disabledColor');
        modified = true;
    }

    // Revert curated_workouts gradient
    if (file.path.endsWith('curated_workouts.dart')) {
      content = content.replaceAll(
        'this.gradient = [Theme.of(context).colorScheme.surface, Theme.of(context).colorScheme.background],',
        'this.gradient = const [Color(0xFF1E293B), Color(0xFF0F172A)],'
      );
      modified = true;
    }

    // Fix illegal const
    if (content.contains('const ')) {
        // Remove const from ColorFilter.mode
        content = content.replaceAll('const ColorFilter.mode(', 'ColorFilter.mode(');
        // Remove const from BoxDecoration
        content = content.replaceAll('const BoxDecoration(', 'BoxDecoration(');
        // Remove const from _LivePulse
        content = content.replaceAll('const _LivePulse(', '_LivePulse(');
        modified = true;
    }

    // Fix missing context in private classes in professional_workout_sections.dart
    if (file.path.endsWith('professional_workout_sections.dart')) {
        if (content.contains('_difficultyColor()')) {
             content = content.replaceAll('_difficultyColor()', '_difficultyColor(context)');
             modified = true;
        }
    }

    if (modified) {
      file.writeAsStringSync(content);
    }
  }
}
