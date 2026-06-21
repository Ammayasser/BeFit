import 'dart:io';

void main() {
  final dir = Directory('lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    String content = file.readAsStringSync();
    bool modified = false;

    // 1. Remove nutrition_colors.dart import if present
    if (content.contains('nutrition_colors.dart')) {
      content = content.replaceAll(RegExp(r"import\s+'[^']*nutrition_colors\.dart';"), "");
      modified = true;
    }

    // 2. Ensure AppColors and BeFitThemeExtension are imported if needed
    bool needsAppColors = content.contains('AppColors.');
    bool needsThemeExt = content.contains('BeFitThemeExtension') || content.contains('customColors');

    if (needsAppColors && !content.contains('app_colors.dart')) {
      content = "import 'package:befit/core/constants/app_colors.dart';\n$content";
      modified = true;
    }
    if (needsThemeExt && !content.contains('befit_theme_extension.dart')) {
      content = "import 'package:befit/core/theme/befit_theme_extension.dart';\n$content";
      modified = true;
    }

    // 3. Fix NColors remains
    if (content.contains('NColors.')) {
      content = content.replaceAll('NColors.bgPrimary(context)', 'Theme.of(context).colorScheme.background');
      content = content.replaceAll('NColors.bgSecondary(context)', 'Theme.of(context).colorScheme.surface');
      content = content.replaceAll('NColors.accentPrimary(context)', 'Theme.of(context).extension<BeFitThemeExtension>()!.calorieRing');
      content = content.replaceAll('NColors.accentSecondary(context)', 'Theme.of(context).extension<BeFitThemeExtension>()!.protein');
      content = content.replaceAll('NColors.warningAccent(context)', 'Theme.of(context).extension<BeFitThemeExtension>()!.carbs');
      content = content.replaceAll('NColors.dangerAccent(context)', 'Theme.of(context).extension<BeFitThemeExtension>()!.fat');
      content = content.replaceAll('NColors.hydration(context)', 'Theme.of(context).extension<BeFitThemeExtension>()!.hydration');
      content = content.replaceAll('NColors.textPrimary(context)', 'Theme.of(context).colorScheme.onSurface');
      content = content.replaceAll('NColors.textSecondary(context)', 'Theme.of(context).colorScheme.onSurfaceVariant');
      content = content.replaceAll('NColors.textTertiary(context)', 'Theme.of(context).disabledColor');
      content = content.replaceAll('NColors.divider(context)', 'Theme.of(context).colorScheme.outlineVariant');
      content = content.replaceAll('NColors.purple', 'AppColors.accentPurple');
      modified = true;
    }

    // 4. Fix AppColors.primary
    if (content.contains('AppColors.primary')) {
        content = content.replaceAll('AppColors.primary', 'Theme.of(context).colorScheme.primary');
        modified = true;
    }

    if (modified) {
      file.writeAsStringSync(content);
    }
  }
}
