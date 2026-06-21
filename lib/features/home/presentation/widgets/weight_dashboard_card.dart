// lib/features/home/presentation/widgets/weight_dashboard_card.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/befit_theme_extension.dart';
import '../../../../core/router/app_routes.dart';
import '../../../progress/presentation/providers/progress_provider.dart';
import '../../../progress/data/models/progress_photo.dart';

class WeightDashboardCard extends StatelessWidget {
  const WeightDashboardCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final custom = context.customColors;
    final isDark = theme.brightness == Brightness.dark;

    final progress = context.watch<ProgressProvider>();
    
    if (!progress.isInitialized || progress.isLoading) {
      return _buildLoadingState(context);
    }

    final currentWeight = progress.currentWeight;
    final unit = progress.weightUnit;
    
    // Sparkline spots
    // Take up to last 7 logs, sorted ASC for chart (oldest to newest)
    final logs = progress.allLogs.take(7).toList().reversed.toList();
    final spots = <FlSpot>[];
    for (int i = 0; i < logs.length; i++) {
      spots.add(FlSpot(i.toDouble(), progress.toDisplayWeight(logs[i].weightKg)));
    }

    final String lastLoggedText = progress.latestLog != null
        ? 'Logged ${DateFormat('MMM d').format(progress.latestLog!.loggedAt)}'
        : 'No entries';

    // Calculate weight change from the previous log
    double? lastChange;
    if (progress.allLogs.length >= 2) {
      lastChange = progress.toDisplayWeight(progress.allLogs[0].weightKg) - 
                   progress.toDisplayWeight(progress.allLogs[1].weightKg);
    }

    // Determine trend pill attributes
    Color? trendBgColor;
    Color? trendTextColor;
    String? trendLabel;
    IconData? trendIcon;

    if (lastChange != null && lastChange != 0.0) {
      final isLoss = lastChange < 0;
      trendBgColor = isLoss ? custom.success.withValues(alpha: 0.12) : custom.error.withValues(alpha: 0.12);
      trendTextColor = isLoss ? custom.success : custom.error;
      trendLabel = '${lastChange.abs().toStringAsFixed(1)} $unit';
      trendIcon = isLoss ? PhosphorIcons.arrowDownRight() : PhosphorIcons.arrowUpRight();
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Feedback.forTap(context);
          context.push(AppRoutes.progress);
        },
        borderRadius: BorderRadius.circular(26),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [custom.surfaceCard, custom.surfaceCard.withValues(alpha: 0.85)]
                  : [Colors.white, theme.colorScheme.primary.withValues(alpha: 0.03)],
            ),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: isDark ? custom.border : theme.colorScheme.outline.withValues(alpha: 0.12),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: PhosphorIcon(
                            PhosphorIcons.barbell(PhosphorIconsStyle.bold),
                            color: theme.colorScheme.primary,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            'BODY WEIGHT',
                            style: GoogleFonts.montserrat(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                              letterSpacing: 1.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Small active status pulsing indicator
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: custom.success.withValues(alpha: 0.8),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  PhosphorIcon(
                    PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Value & Chart Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Weight text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                currentWeight != null ? currentWeight.toStringAsFixed(1) : '--.-',
                                style: GoogleFonts.montserrat(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: theme.colorScheme.onSurface,
                                  letterSpacing: -0.8,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                unit,
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Footer: Trend badge + date
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (trendLabel != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: trendBgColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    PhosphorIcon(
                                      trendIcon!,
                                      size: 11,
                                      color: trendTextColor,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      trendLabel,
                                      style: GoogleFonts.montserrat(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: trendTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            Text(
                              lastLoggedText,
                              style: GoogleFonts.montserrat(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Sparkline chart
                  if (spots.length >= 2)
                    Flexible(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 90),
                        height: 44,
                        padding: const EdgeInsets.only(top: 10),
                        child: LineChart(
                          LineChartData(
                            gridData: const FlGridData(show: false),
                            titlesData: const FlTitlesData(
                              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(show: false),
                            lineTouchData: const LineTouchData(enabled: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: spots,
                                isCurved: true,
                                curveSmoothness: 0.35,
                                color: theme.colorScheme.primary,
                                barWidth: 3,
                                isStrokeCapRound: true,
                                // Show only the final spot as an anchor
                                dotData: FlDotData(
                                  show: true,
                                  checkToShowDot: (spot, barData) {
                                    return spot.x == barData.spots.last.x;
                                  },
                                  getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                                    radius: 4.5,
                                    color: theme.colorScheme.primary,
                                    strokeWidth: 2,
                                    strokeColor: Colors.white,
                                  ),
                                ),
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      theme.colorScheme.primary.withValues(alpha: 0.18),
                                      theme.colorScheme.primary.withValues(alpha: 0.0),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else if (spots.length == 1)
                    // Single dot indicator
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0, right: 12.0),
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(alpha: 0.4),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

              // Divider & Progress Photo Promo Section
              const SizedBox(height: 16),
              Divider(
                height: 1,
                thickness: 0.8,
                color: isDark ? custom.border : theme.colorScheme.outline.withValues(alpha: 0.1),
              ),
              const SizedBox(height: 14),
              
              if (progress.allPhotos.isNotEmpty) ...[
                // Photo Gallery Teaser
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          _buildMiniPhotoStack(progress.allPhotos.take(3).toList()),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${progress.allPhotos.length} progress photos',
                              style: GoogleFonts.montserrat(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'View Gallery',
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Add Photo Promo Call-to-Action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.camera_alt_rounded,
                              size: 12,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Add progress photos to track shape',
                              style: GoogleFonts.montserrat(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Log Photo',
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05);

    return Container(
      padding: const EdgeInsets.all(20),
      constraints: const BoxConstraints(minHeight: 200),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E222A) : Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : colorScheme.outline.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(width: 32, height: 32, decoration: BoxDecoration(color: baseColor, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Container(width: 80, height: 12, decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(4))),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 100, height: 32, decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(8))),
                    const SizedBox(height: 12),
                    Container(width: 130, height: 12, decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(4))),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(width: 80, height: 40, decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(8))),
            ],
          ),
          const SizedBox(height: 24),
          Container(height: 1, color: baseColor),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(width: 24, height: 24, decoration: BoxDecoration(color: baseColor, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Expanded(child: Container(height: 11, decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(4)))),
              const SizedBox(width: 40),
              Container(width: 60, height: 11, decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(4))),
            ],
          ),
        ],
      ).animate()
       .fadeIn(duration: 400.ms)
       .shimmer(duration: 1500.ms, color: colorScheme.primary.withValues(alpha: 0.1)),
    );
  }

  Widget _buildMiniPhotoStack(List<ProgressPhoto> photos) {
    return SizedBox(
      width: 48,
      height: 24,
      child: Stack(
        clipBehavior: Clip.none,
        children: List.generate(photos.length, (index) {
          final photo = photos[index];
          return Positioned(
            left: index * 12.0,
            child: FutureBuilder<String>(
              future: photo.resolveAbsolutePath(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                  );
                }
                return Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? const Color(0xFF1E222A) 
                          : Colors.white, 
                      width: 1.5,
                    ),
                    image: DecorationImage(
                      image: FileImage(File(snapshot.data!)),
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          );
        }),
      ),
    );
  }
}

