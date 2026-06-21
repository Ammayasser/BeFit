import 'dart:io';

void main() {
  final dir = Directory('lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    String content = file.readAsStringSync();
    bool modified = false;

    if (content.contains('0xFFC0FF00')) {
      content = content.replaceAll('Color(0xFFC0FF00)', 'Theme.of(context).extension<BeFitThemeExtension>()!.calorieRing');
      content = content.replaceAll('const Color(0xFFC0FF00)', 'Theme.of(context).extension<BeFitThemeExtension>()!.calorieRing');
      modified = true;
    }
    
    if (content.contains('0xFF0F172A')) {
      content = content.replaceAll('Color(0xFF0F172A)', 'Theme.of(context).colorScheme.background');
      content = content.replaceAll('const Color(0xFF0F172A)', 'Theme.of(context).colorScheme.background');
      content = content.replaceAll('0xFF0F172A', '0xFF111318'); // Fallback for raw hex
      modified = true;
    }

    if (content.contains('0xFF1E293B')) {
      content = content.replaceAll('Color(0xFF1E293B)', 'Theme.of(context).colorScheme.surface');
      content = content.replaceAll('const Color(0xFF1E293B)', 'Theme.of(context).colorScheme.surface');
      modified = true;
    }

    if (content.contains('0xFF3B82F6')) {
      content = content.replaceAll('Color(0xFF3B82F6)', 'Theme.of(context).extension<BeFitThemeExtension>()!.protein');
      content = content.replaceAll('const Color(0xFF3B82F6)', 'Theme.of(context).extension<BeFitThemeExtension>()!.protein');
      modified = true;
    }

    if (content.contains('0xFF8B5CF6')) {
      content = content.replaceAll('Color(0xFF8B5CF6)', 'Theme.of(context).colorScheme.secondary');
      content = content.replaceAll('const Color(0xFF8B5CF6)', 'Theme.of(context).colorScheme.secondary');
      modified = true;
    }

    if (content.contains('0xFF14B8A6')) {
      content = content.replaceAll('Color(0xFF14B8A6)', 'Theme.of(context).extension<BeFitThemeExtension>()!.hydration');
      content = content.replaceAll('const Color(0xFF14B8A6)', 'Theme.of(context).extension<BeFitThemeExtension>()!.hydration');
      modified = true;
    }

    if (modified) {
      file.writeAsStringSync(content);
    }
  }
}
