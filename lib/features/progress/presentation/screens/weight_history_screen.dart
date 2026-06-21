// lib/features/progress/presentation/screens/weight_history_screen.dart

import 'package:befit/features/progress/data/models/weight_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/befit_theme_extension.dart';
import '../../../../core/widgets/content_wrapper.dart';
import '../providers/progress_provider.dart';
import '../widgets/weight_log_sheet.dart';

class WeightHistoryScreen extends StatelessWidget {
  const WeightHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final custom = context.customColors;
    final isDark = theme.brightness == Brightness.dark;

    final progress = context.watch<ProgressProvider>();
    final logs = progress.allLogs; // sorted DESC
    final unit = progress.weightUnit;

    // Group logs by month
    final groupedLogs = _groupLogsByMonth(logs);

    return Scaffold(
      backgroundColor: custom.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          onPressed: () {
            HapticFeedback.selectionClick();
            context.pop();
          },
          icon: PhosphorIcon(
            PhosphorIcons.caretLeft(),
            color: theme.colorScheme.onSurface,
          ),
        ),
        title: Text(
          'Weight History',
          style: GoogleFonts.montserrat(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
      body: logs.isEmpty
          ? Center(
              child: Text(
                'No logs registered.',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          : ContentWrapper(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: groupedLogs.keys.length,
                itemBuilder: (context, index) {
                  final monthKey = groupedLogs.keys.elementAt(index);
                  final monthLogs = groupedLogs[monthKey]!;

                  // Parse date for header
                  final parsedDate = DateTime.parse('$monthKey-01');
                  final monthHeader = DateFormat(
                    'MMMM yyyy',
                  ).format(parsedDate);

                  // Calculate month average weight
                  final totalWeight = monthLogs.fold(
                    0.0,
                    (sum, l) => sum + l.weightKg,
                  );
                  final avgWeightKg = totalWeight / monthLogs.length;
                  final avgWeight = progress.toDisplayWeight(avgWeightKg);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Month Header with average
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              monthHeader,
                              style: GoogleFonts.montserrat(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            Text(
                              'Avg: ${avgWeight.toStringAsFixed(1)} $unit',
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Log list inside this month
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: monthLogs.length,
                        itemBuilder: (context, logIdx) {
                          final log = monthLogs[logIdx];

                          // Find index in main logs list to calculate change from previous chronological entry
                          final mainIdx = logs.indexWhere(
                            (l) => l.id == log.id,
                          );
                          double? change;
                          if (mainIdx != -1 && mainIdx + 1 < logs.length) {
                            // mainIdx + 1 is chronologically older log
                            final olderLog = logs[mainIdx + 1];
                            change =
                                progress.toDisplayWeight(log.weightKg) -
                                progress.toDisplayWeight(olderLog.weightKg);
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: Dismissible(
                              key: Key(log.id),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (direction) =>
                                  _showDeleteConfirmation(context, log),
                              onDismissed: (direction) {
                                progress.deleteWeightLog(log.id);
                              },
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20.0),
                                decoration: BoxDecoration(
                                  color: custom.error.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: PhosphorIcon(
                                  PhosphorIcons.trash(),
                                  color: custom.error,
                                  size: 24,
                                ),
                              ),
                              child: InkWell(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  WeightLogSheet.show(
                                    context,
                                    existingLog: log,
                                  );
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? custom.surfaceCard
                                        : theme.colorScheme.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isDark
                                          ? custom.border
                                          : theme.colorScheme.outline
                                                .withValues(alpha: 0.15),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      // Day indicator
                                      Container(
                                        width: 42,
                                        height: 42,
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary
                                              .withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            DateFormat(
                                              'd',
                                            ).format(log.loggedAt),
                                            style: GoogleFonts.montserrat(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: theme.colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),

                                      // Weight & measurements summary
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              DateFormat(
                                                'EEEE, MMM d',
                                              ).format(log.loggedAt),
                                              style: GoogleFonts.montserrat(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color:
                                                    theme.colorScheme.onSurface,
                                              ),
                                            ),
                                            if (_hasMeasurementsSummary(
                                              log,
                                            )) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                _buildMeasurementsText(log),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.montserrat(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                  color: theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),

                                      // Displayed weight & delta indicator
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${progress.toDisplayWeight(log.weightKg).toStringAsFixed(1)} $unit',
                                            style: GoogleFonts.montserrat(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                              color:
                                                  theme.colorScheme.onSurface,
                                            ),
                                          ),
                                          if (change != null &&
                                              change != 0.0) ...[
                                            const SizedBox(height: 2),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                PhosphorIcon(
                                                  change < 0
                                                      ? PhosphorIcons.arrowDownRight()
                                                      : PhosphorIcons.arrowUpRight(),
                                                  size: 12,
                                                  color: change < 0
                                                      ? custom.success
                                                      : custom.error,
                                                ),
                                                const SizedBox(width: 2),
                                                Text(
                                                  '${change > 0 ? '+' : ''}${change.toStringAsFixed(1)} $unit',
                                                  style: GoogleFonts.montserrat(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    color: change < 0
                                                        ? custom.success
                                                        : custom.error,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
    );
  }

  Map<String, List<WeightLog>> _groupLogsByMonth(List<WeightLog> logs) {
    final Map<String, List<WeightLog>> groups = {};
    for (var log in logs) {
      final monthKey = DateFormat('yyyy-MM').format(log.loggedAt);
      if (!groups.containsKey(monthKey)) {
        groups[monthKey] = [];
      }
      groups[monthKey]!.add(log);
    }
    return groups;
  }

  bool _hasMeasurementsSummary(WeightLog log) {
    return log.bodyFatPercentage != null ||
        log.waistCm != null ||
        log.chestCm != null ||
        log.hipsCm != null ||
        log.neckCm != null;
  }

  String _buildMeasurementsText(WeightLog log) {
    final parts = <String>[];
    if (log.bodyFatPercentage != null) {
      parts.add('Fat: ${log.bodyFatPercentage!.toStringAsFixed(0)}%');
    }
    if (log.waistCm != null) {
      parts.add('Waist: ${log.waistCm!.toStringAsFixed(0)}cm');
    }
    if (log.chestCm != null) {
      parts.add('Chest: ${log.chestCm!.toStringAsFixed(0)}cm');
    }
    if (log.hipsCm != null) {
      parts.add('Hips: ${log.hipsCm!.toStringAsFixed(0)}cm');
    }
    return parts.join(' • ');
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context, WeightLog log) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Entry',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Are you sure you want to delete this weight log from ${DateFormat('MMMM d, y').format(log.loggedAt)}?',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.customColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
