// lib/features/nutrition/presentation/screens/hydration_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import '../providers/nutrition_provider.dart';
import '../widgets/nutrition_colors.dart';
import '../widgets/water_tracker_card.dart';

/// Full-screen hydration hub (opened from [HydrationEntryCard] on nutrition).
class HydrationScreen extends StatelessWidget {
  const HydrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NColors.bgPrimary(context),
      body: Consumer<NutritionProvider>(
        builder: (context, provider, _) {
          final nutrition = provider.dailyNutrition;
          return RefreshIndicator(
            onRefresh: () async => provider.refresh(),
            color: NColors.accentPrimary(context),
            backgroundColor: NColors.bgSecondary(context),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverAppBar(
                  pinned: true,
                  backgroundColor: NColors.bgSecondary(context),
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  scrolledUnderElevation: 1,
                  shadowColor: NColors.divider(context),
                  leading: IconButton(
                    icon: Icon(Iconsax.arrow_left_2, color: NColors.textPrimary(context)),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      Navigator.of(context).pop();
                    },
                  ),
                  title: Text(
                    'Hydration',
                    style: GoogleFonts.montserrat(
                      color: NColors.textPrimary(context),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  centerTitle: true,
                ),
                SliverToBoxAdapter(
                  child: WaterTrackerCard(
                    waterLoggedMl: nutrition.waterLoggedMl,
                    waterGoalMl: nutrition.waterGoalMl,
                    hourlyWaterMl: nutrition.hourlyWaterMl,
                    isTodayView: provider.isToday,
                    weekWaterTotalsMl: provider.weekWaterTotalsMl,
                    onLoadWeekTotals: provider.loadWeekWaterTotals,
                    onAddWater: provider.addWater,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          );
        },
      ),
    );
  }
}
