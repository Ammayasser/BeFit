// lib/features/nutrition/presentation/widgets/water_tracker_card.dart

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/befit_theme_extension.dart';

import 'nutrition_colors.dart';
import 'custom_water_amount_sheet.dart';
import 'water_daily_view.dart';
import 'water_weekly_view.dart';

class WaterTrackerCard extends StatefulWidget {
  final int waterLoggedMl;
  final int waterGoalMl;
  final List<int> hourlyWaterMl;
  final bool isTodayView;
  final List<int> weekWaterTotalsMl;
  final Future<void> Function() onLoadWeekTotals;
  final ValueChanged<int> onAddWater;

  const WaterTrackerCard({
    super.key,
    required this.waterLoggedMl,
    required this.waterGoalMl,
    required this.hourlyWaterMl,
    required this.isTodayView,
    required this.weekWaterTotalsMl,
    required this.onLoadWeekTotals,
    required this.onAddWater,
  });

  @override
  State<WaterTrackerCard> createState() => _WaterTrackerCardState();
}

class _WaterTrackerCardState extends State<WaterTrackerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveCtrl;
  int _hydrationTab = 0;

  static Color _hydrationAccent(BuildContext context) => context.customColors.hydration;
  static Color _panelBg(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF0B0F14)
        : const Color(0xFFECFEFF);
  }
  static Color _panelBg2(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF111827)
        : const Color(0xFFCFFAFE);
  }
  static Color _glassBorder(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.white.withValues(alpha: 0.12)
          : Colors.black.withValues(alpha: 0.08);
  static Color _muted(BuildContext context) => Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7);

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onLoadWeekTotals();
    });
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goal = widget.waterGoalMl.clamp(1, 20000);
    final logged = widget.waterLoggedMl.clamp(0, 20000);
    final fill = (logged / goal).clamp(0.0, 1.0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: NColors.spaceMd,
        vertical: NColors.spaceSm,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_panelBg(context), _panelBg2(context)],
              ),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: _glassBorder(context), width: 1),
              boxShadow: [
                BoxShadow(
                  color: _hydrationAccent(context).withValues(alpha: 0.12),
                  blurRadius: 32,
                  spreadRadius: 0,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -40,
                  top: -60,
                  child: IgnorePointer(
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            _hydrationAccent(context).withValues(alpha: 0.18),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Hydration',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.orbitron(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _SegChip(
                                label: 'Daily',
                                selected: _hydrationTab == 0,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _hydrationTab = 0);
                                },
                              ),
                            ),
                            Expanded(
                              child: _SegChip(
                                label: 'Weekly',
                                selected: _hydrationTab == 1,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _hydrationTab = 1);
                                  widget.onLoadWeekTotals();
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 320),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: _hydrationTab == 0
                            ? WaterDailyView(
                                fill: fill,
                                logged: logged,
                                goal: goal,
                                hourly: widget.hourlyWaterMl,
                                waveListenable: _waveCtrl,
                                onAddWater: widget.onAddWater,
                                isTodayView: widget.isTodayView,
                                onCustomAmount: () => _showCustomAmountSheet(context),
                              )
                            : WaterWeeklyView(
                                fill: fill,
                                logged: logged,
                                goal: goal,
                                weekTotals: widget.weekWaterTotalsMl,
                                goalMl: goal,
                                onAddWater: widget.onAddWater,
                                onCustomAmount: () => _showCustomAmountSheet(context),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.04, end: 0);
  }

  void _showCustomAmountSheet(BuildContext context) async {
    final ml = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CustomWaterAmountSheet(
        glassBorder: _glassBorder(context),
        muted: _muted(context),
        accent: _hydrationAccent(context),
      ),
    );
    if (ml != null && ml > 0 && context.mounted) {
      HapticFeedback.mediumImpact();
      widget.onAddWater(ml);
    }
  }
}

class _SegChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = context.customColors.hydration;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: selected
                ? LinearGradient(
                    colors: [accent, accent.withValues(alpha: 0.7)],
                  )
                : null,
            color: selected ? null : Colors.transparent,
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.35),
                      blurRadius: 16,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: selected
                    ? const Color(0xFF0B1220)
                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
