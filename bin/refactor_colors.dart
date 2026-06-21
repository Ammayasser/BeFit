import 'dart:io';

void main() {
  final dir = Directory('lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    String content = file.readAsStringSync();
    if (content.contains('NColors')) {
      content = content.replaceAll('NColors.bgPrimary(context)', 'Theme.of(context).colorScheme.background');
      content = content.replaceAll('NColors.bgPrimary(ctx)', 'Theme.of(context).colorScheme.background');
      
      content = content.replaceAll('NColors.bgSecondary(context)', 'Theme.of(context).colorScheme.surface');
      content = content.replaceAll('NColors.bgSecondary(ctx)', 'Theme.of(context).colorScheme.surface');

      content = content.replaceAll('NColors.bgElevated(context)', 'Theme.of(context).colorScheme.surfaceContainerHighest');

      content = content.replaceAll('NColors.accentPrimary(context)', 'Theme.of(context).extension<BeFitThemeExtension>()!.calorieRing');
      content = content.replaceAll('NColors.accentSecondary(context)', 'Theme.of(context).extension<BeFitThemeExtension>()!.protein');
      content = content.replaceAll('NColors.warningAccent(context)', 'Theme.of(context).extension<BeFitThemeExtension>()!.carbs');
      content = content.replaceAll('NColors.dangerAccent(context)', 'Theme.of(context).extension<BeFitThemeExtension>()!.fat');
      content = content.replaceAll('NColors.hydration(context)', 'Theme.of(context).extension<BeFitThemeExtension>()!.hydration');

      content = content.replaceAll('NColors.textPrimary(context)', 'Theme.of(context).colorScheme.onSurface');
      content = content.replaceAll('NColors.textPrimary(ctx)', 'Theme.of(context).colorScheme.onSurface');
      
      content = content.replaceAll('NColors.textSecondary(context)', 'Theme.of(context).colorScheme.onSurfaceVariant');
      content = content.replaceAll('NColors.textSecondary(ctx)', 'Theme.of(context).colorScheme.onSurfaceVariant');

      content = content.replaceAll('NColors.textTertiary(context)', 'Theme.of(context).disabledColor');
      content = content.replaceAll('NColors.textTertiary(ctx)', 'Theme.of(context).disabledColor');

      content = content.replaceAll('NColors.divider(context)', 'Theme.of(context).colorScheme.outlineVariant');

      content = content.replaceAll('NColors.radiusCard', '20.0');
      content = content.replaceAll('NColors.radiusChip', '12.0');
      content = content.replaceAll('NColors.radiusButton', '14.0');
      content = content.replaceAll('NColors.radiusInput', '16.0');
      content = content.replaceAll('NColors.radiusModal', '28.0');

      content = content.replaceAll('NColors.spaceSm', '8.0');
      content = content.replaceAll('NColors.spaceMd', '16.0');
      content = content.replaceAll('NColors.spaceLg', '24.0');

      content = content.replaceAll('NColors.mealColor(context,', 'AppColors.primaryGreen /* TODO meal color */');
      content = content.replaceAll('NColors.mealColor(ctx,', 'AppColors.primaryGreen /* TODO meal color */');
      
      content = content.replaceAll('NColors.nutriScoreColor(context,', 'AppColors.primaryGreen /* TODO nutriscore */');

      content = content.replaceAll('NColors.cardGlow(context)', '[BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, spreadRadius: 0, offset: const Offset(0, 4))]');
      content = content.replaceAll('NColors.activeCardGlow(context)', '[BoxShadow(color: Theme.of(context).extension<BeFitThemeExtension>()!.calorieRing.withOpacity(0.12), blurRadius: 24, spreadRadius: 2, offset: const Offset(0, 8))]');

      content = content.replaceAll("import '../../../../core/theme/befit_theme_extension.dart';", "import 'package:befit/core/theme/befit_theme_extension.dart';");
      content = content.replaceAll("import 'package:befit/features/nutrition/presentation/widgets/nutrition_colors.dart';", "");
      content = content.replaceAll("import 'nutrition_colors.dart';", "");
      
      file.writeAsStringSync(content);
    }
  }
}
