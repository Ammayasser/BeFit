import 'dart:io';

void main() {
  final dir = Directory('lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    String content = file.readAsStringSync();
    bool modified = false;

    // Remove 'const' before Theme.of(context)
    if (content.contains('const Theme.of(context)')) {
      content = content.replaceAll('const Theme.of(context)', 'Theme.of(context)');
      modified = true;
    }

    // Fix lists that were const but now contain Theme.of
    // This is harder to do with regex perfectly, but let's try common patterns
    if (content.contains('const [') && content.contains('Theme.of(context)')) {
       // Find lists containing Theme.of(context) and remove const
       content = content.replaceAllMapped(RegExp(r'const\s+\[([^\]]*Theme\.of\(context\)[^\]]*)\]'), (match) {
         return '[${match.group(1)}]';
       });
       modified = true;
    }
    
    // Fix constructors that were const but now contain Theme.of
    if (content.contains('const ') && content.contains('Theme.of(context)')) {
       content = content.replaceAllMapped(RegExp(r'const\s+([A-Z][a-zA-Z0-9_]*\s*\([^)]*Theme\.of\(context\)[^)]*\))'), (match) {
         return match.group(1)!;
       });
       modified = true;
    }

    // Fix AppColors.primary
    if (content.contains('AppColors.primary')) {
      content = content.replaceAll('AppColors.primary', 'Theme.of(context).colorScheme.primary');
      modified = true;
    }

    // Ensure imports
    if (content.contains('BeFitThemeExtension') || content.contains('customColors')) {
      if (!content.contains('befit_theme_extension.dart')) {
        content = "import 'package:befit/core/theme/befit_theme_extension.dart';\n$content";
        modified = true;
      }
    }
    
    if (content.contains('AppColors') && !content.contains('app_colors.dart')) {
        content = "import 'package:befit/core/constants/app_colors.dart';\n$content";
        modified = true;
    }

    if (modified) {
      file.writeAsStringSync(content);
    }
  }
}
