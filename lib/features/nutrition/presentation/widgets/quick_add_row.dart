// lib/features/nutrition/presentation/widgets/quick_add_row.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/theme/befit_theme_extension.dart';

class QuickAddRow extends StatelessWidget {
  final ValueChanged<int> onAddWater;
  final VoidCallback onCustom;

  const QuickAddRow({
    super.key,
    required this.onAddWater,
    required this.onCustom,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GlassCircleButton(
            icon: Iconsax.cup,
            label: '250ml',
            onTap: () {
              HapticFeedback.lightImpact();
              onAddWater(250);
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GlassCircleButton(
            icon: Iconsax.drop,
            label: '500ml',
            onTap: () {
              HapticFeedback.lightImpact();
              onAddWater(500);
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GlassCircleButton(
            icon: Iconsax.setting_4,
            label: 'Custom',
            onTap: onCustom,
          ),
        ),
      ],
    );
  }
}

class GlassCircleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const GlassCircleButton({
    super.key,
    required this.icon,
    required this.label,
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
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: isDark ? 0.12 : 0.05),
                blurRadius: 12,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: accent, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
