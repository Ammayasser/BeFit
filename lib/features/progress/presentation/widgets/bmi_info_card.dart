// lib/features/progress/presentation/widgets/bmi_info_card.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/befit_theme_extension.dart';
import '../../../../core/utils/responsive.dart';

class BmiInfoCard extends StatelessWidget {
  final double bmi;
  final String category;

  const BmiInfoCard({super.key, required this.bmi, required this.category});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final custom = context.customColors;
    final isDark = theme.brightness == Brightness.dark;
    final isTablet = Responsive.isTablet(context);
    final isLandscape = Responsive.isLandscape(context);
    final useSplitLayout = isTablet || isLandscape;

    // Standard BMI ranges mapping (15 to 35 range clamp)
    final clampedBmi = bmi.clamp(15.0, 35.0);
    final double pointerPosition = (clampedBmi - 15.0) / (35.0 - 15.0);

    final leftSideWidth = useSplitLayout
        ? (Responsive.screenWidth(context) < 600 ? 180.0 : 220.0)
        : 220.0;

    Widget buildScaleBar(double width) {
      final double pointerX = pointerPosition * width;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pointer arrow
          Stack(
            children: [
              SizedBox(height: 12, width: width),
              Positioned(
                left: (pointerX - 6).clamp(0, width - 12),
                child: Icon(
                  Icons.arrow_drop_down_rounded,
                  color: theme.colorScheme.onSurface,
                  size: 16,
                ),
              ),
            ],
          ),
          // Colored Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  // Underweight
                  Expanded(flex: 175, child: Container(color: custom.protein)),
                  const SizedBox(width: 2),
                  // Normal
                  Expanded(flex: 325, child: Container(color: custom.success)),
                  const SizedBox(width: 2),
                  // Overweight
                  Expanded(flex: 250, child: Container(color: custom.warning)),
                  const SizedBox(width: 2),
                  // Obese
                  Expanded(flex: 250, child: Container(color: custom.failure)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Scale labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '15.0',
                style: GoogleFonts.montserrat(
                  fontSize: Responsive.fontScale(context, 10),
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '18.5',
                style: GoogleFonts.montserrat(
                  fontSize: Responsive.fontScale(context, 10),
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '25.0',
                style: GoogleFonts.montserrat(
                  fontSize: Responsive.fontScale(context, 10),
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '30.0',
                style: GoogleFonts.montserrat(
                  fontSize: Responsive.fontScale(context, 10),
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '35.0+',
                style: GoogleFonts.montserrat(
                  fontSize: Responsive.fontScale(context, 10),
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      );
    }

    Widget cardContent;

    if (useSplitLayout) {
      // Split layout for wider screens
      cardContent = Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left Side Info Column
          SizedBox(
            width: leftSideWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'BMI (Body Mass Index)',
                  style: GoogleFonts.montserrat(
                    fontSize: Responsive.fontScale(context, 14),
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      bmi.toStringAsFixed(1),
                      style: GoogleFonts.montserrat(
                        fontSize: Responsive.fontScale(context, 34),
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.onSurface,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'kg/m²',
                      style: GoogleFonts.montserrat(
                        fontSize: Responsive.fontScale(context, 12),
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(custom).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    category,
                    style: GoogleFonts.montserrat(
                      fontSize: Responsive.fontScale(context, 11),
                      fontWeight: FontWeight.w700,
                      color: _getCategoryColor(custom),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 32),
          // Right Side Slider Bar
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) =>
                  buildScaleBar(constraints.maxWidth),
            ),
          ),
        ],
      );
    } else {
      // Original vertical card stack for phones
      cardContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'BMI (Body Mass Index)',
                style: GoogleFonts.montserrat(
                  fontSize: Responsive.fontScale(context, 16),
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getCategoryColor(custom).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  category,
                  style: GoogleFonts.montserrat(
                    fontSize: Responsive.fontScale(context, 12),
                    fontWeight: FontWeight.w700,
                    color: _getCategoryColor(custom),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                bmi.toStringAsFixed(1),
                style: GoogleFonts.montserrat(
                  fontSize: Responsive.fontScale(context, 34),
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'kg/m²',
                style: GoogleFonts.montserrat(
                  fontSize: Responsive.fontScale(context, 14),
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) =>
                buildScaleBar(constraints.maxWidth),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? custom.surfaceCard : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? custom.border
              : theme.colorScheme.outline.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: cardContent,
    );
  }

  Color _getCategoryColor(BeFitThemeExtension custom) {
    switch (category.toLowerCase()) {
      case 'underweight':
        return custom.protein;
      case 'normal':
        return custom.success;
      case 'overweight':
        return custom.warning;
      case 'obese':
      default:
        return custom.failure;
    }
  }
}
