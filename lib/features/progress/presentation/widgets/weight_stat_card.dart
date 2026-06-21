// lib/features/progress/presentation/widgets/weight_stat_card.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/befit_theme_extension.dart';

class WeightStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? changeText;
  final bool?
  isPositiveChange; // true = good (e.g. green/down for weight loss), false = warning/up, null = neutral
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final VoidCallback? onTap;

  const WeightStatCard({
    super.key,
    required this.title,
    required this.value,
    this.changeText,
    this.isPositiveChange,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final custom = context.customColors;
    final isDark = theme.brightness == Brightness.dark;

    // Determine colors for the trend pill
    Color trendBgColor;
    Color trendTextColor;
    if (isPositiveChange == null) {
      trendBgColor = isDark
          ? Colors.white.withValues(alpha: 0.06)
          : theme.colorScheme.onSurface.withValues(alpha: 0.05);
      trendTextColor = theme.colorScheme.onSurfaceVariant;
    } else if (isPositiveChange!) {
      trendBgColor = custom.success.withValues(alpha: 0.12);
      trendTextColor = custom.success;
    } else {
      trendBgColor = custom.error.withValues(alpha: 0.12);
      trendTextColor = custom.error;
    }

    final card = Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? custom.surfaceCard : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? custom.border
              : theme.colorScheme.outline.withValues(alpha: 0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Icon Badge (Circular)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: PhosphorIcon(icon, color: iconColor, size: 20),
              ),
              // Trend indicator mini icon
              if (isPositiveChange != null)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: trendBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: PhosphorIcon(
                    isPositiveChange!
                        ? PhosphorIcons.arrowDownRight()
                        : PhosphorIcons.arrowUpRight(),
                    size: 14,
                    color: trendTextColor,
                  ),
                )
              else if (onTap != null)
                PhosphorIcon(
                  PhosphorIcons.pencilSimple(),
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Title
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 6),
          // Value
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.montserrat(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          if (changeText != null) ...[
            const SizedBox(height: 12),
            // Trend/Goal Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: trendBgColor,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      changeText!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: trendTextColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: card,
      );
    }
    return card;
  }
}
