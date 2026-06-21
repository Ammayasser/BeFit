import 'dart:io';

void main() {
  final dir = Directory('lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    String content = file.readAsStringSync();
    bool modified = false;

    // Remove deleted nutrition_colors.dart import
    if (content.contains('nutrition_colors.dart')) {
        content = content.replaceAll(RegExp(r"import\s+'[^']*nutrition_colors\.dart';\s*"), "");
        modified = true;
    }

    // Fix Theme.of(context) in const contexts
    if (content.contains('const Theme.of(context)')) {
        content = content.replaceAll('const Theme.of(context)', 'Theme.of(context)');
        modified = true;
    }

    // Fix community_screen.dart specifically as it had a const CommunityTheme
    if (file.path.endsWith('community_screen.dart')) {
        content = content.replaceAll('const CommunityTheme(', 'CommunityTheme(');
        modified = true;
    }

    // Fix AppColors.primary (it was removed in favor of primaryGreen or theme)
    if (content.contains('AppColors.primary')) {
        content = content.replaceAll('AppColors.primary', 'Theme.of(context).colorScheme.primary');
        modified = true;
    }
    
    // Fix NColors still hanging around
    if (content.contains('NColors.')) {
        content = content.replaceAll('NColors.bgPrimary(context)', 'Theme.of(context).colorScheme.background');
        content = content.replaceAll('NColors.accentPrimary(context)', 'Theme.of(context).extension<BeFitThemeExtension>()!.calorieRing');
        content = content.replaceAll('NColors.textTertiary(context)', 'Theme.of(context).disabledColor');
        modified = true;
    }

    if (modified) {
      file.writeAsStringSync(content);
    }
  }
}
