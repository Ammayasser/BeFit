// lib/features/progress/presentation/widgets/measurement_section.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/befit_theme_extension.dart';
import '../../../../core/utils/responsive.dart';
import '../providers/progress_provider.dart';
import 'weight_log_sheet.dart';

/// Displays the Body Measurements section with a responsive card grid.
///
/// Shows an empty state with a CTA if no measurements have been logged yet.
class MeasurementsSection extends StatelessWidget {
  final ProgressProvider progress;

  const MeasurementsSection({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final custom = context.customColors;
    final isDark = theme.brightness == Brightness.dark;

    final latest = progress.latestLog;
    final changes = progress.bodyMeasurementChange;
    final hasMeasurements =
        latest != null &&
        (latest.waistCm != null ||
            latest.chestCm != null ||
            latest.hipsCm != null ||
            latest.neckCm != null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Body Measurements',
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        if (!hasMeasurements)
          _EmptyMeasurementsState(isDark: isDark, theme: theme, custom: custom)
        else
          _MeasurementsGrid(
            latest: latest,
            changes: changes,
            isDark: isDark,
            theme: theme,
            custom: custom,
          ),
      ],
    );
  }
}

class _EmptyMeasurementsState extends StatelessWidget {
  final bool isDark;
  final ThemeData theme;
  final BeFitThemeExtension custom;

  const _EmptyMeasurementsState({
    required this.isDark,
    required this.theme,
    required this.custom,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? custom.surfaceCard : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? custom.border
              : theme.colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          PhosphorIcon(
            PhosphorIcons.ruler(),
            size: 36,
            color: theme.colorScheme.primary.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 12),
          Text(
            'No body measurements logged yet.',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              WeightLogSheet.show(context);
            },
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Add Measurements',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _MeasurementsGrid extends StatelessWidget {
  final dynamic latest; // WeightLog
  final Map<String, double> changes;
  final bool isDark;
  final ThemeData theme;
  final BeFitThemeExtension custom;

  const _MeasurementsGrid({
    required this.latest,
    required this.changes,
    required this.isDark,
    required this.theme,
    required this.custom,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = Responsive.isTablet(context);
        final crossCount = isTablet ? 4 : 2;
        const spacing = 10.0;
        final itemWidth =
            (constraints.maxWidth - (crossCount - 1) * spacing) / crossCount;

        final items = <({String label, double value, double change})>[];
        if (latest.waistCm != null) {
          items.add((
            label: 'Waist',
            value: latest.waistCm!,
            change: changes['waist'] ?? 0.0,
          ));
        }
        if (latest.chestCm != null) {
          items.add((
            label: 'Chest',
            value: latest.chestCm!,
            change: changes['chest'] ?? 0.0,
          ));
        }
        if (latest.hipsCm != null) {
          items.add((
            label: 'Hips',
            value: latest.hipsCm!,
            change: changes['hips'] ?? 0.0,
          ));
        }
        if (latest.neckCm != null) {
          items.add((
            label: 'Neck',
            value: latest.neckCm!,
            change: changes['neck'] ?? 0.0,
          ));
        }

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items
              .map(
                (item) => SizedBox(
                  width: itemWidth,
                  child: MeasurementCard(
                    label: item.label,
                    value: '${item.value.toStringAsFixed(1)} cm',
                    change: item.change,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

/// A single body measurement card showing label, value, and change delta.
class MeasurementCard extends StatelessWidget {
  final String label;
  final String value;
  final double change;

  const MeasurementCard({
    super.key,
    required this.label,
    required this.value,
    required this.change,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final custom = context.customColors;
    final isDark = theme.brightness == Brightness.dark;
    final isDecrease = change < 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? custom.surfaceCard : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? custom.border
              : theme.colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
          if (change != 0.0) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                PhosphorIcon(
                  isDecrease
                      ? PhosphorIcons.arrowDownRight()
                      : PhosphorIcons.arrowUpRight(),
                  size: 12,
                  color: isDecrease ? custom.success : custom.error,
                ),
                const SizedBox(width: 2),
                Text(
                  '${change > 0 ? '+' : ''}${change.toStringAsFixed(1)} cm',
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isDecrease ? custom.success : custom.error,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
