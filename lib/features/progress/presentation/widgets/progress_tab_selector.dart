// lib/features/progress/presentation/widgets/progress_tab_selector.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/befit_theme_extension.dart';

/// Segmented tab control for the Progress Dashboard.
///
/// Shows "Weight & Stats" and "Progress Photos" tabs.
class ProgressTabSelector extends StatelessWidget {
  final int currentTab;
  final ValueChanged<int> onTabChanged;

  const ProgressTabSelector({
    super.key,
    required this.currentTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final custom = context.customColors;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: isDark ? custom.surfaceCard : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? custom.border
              : theme.colorScheme.outline.withValues(alpha: 0.12),
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _TabItem(
            index: 0,
            currentTab: currentTab,
            icon: PhosphorIcons.barbell(),
            label: 'Weight & Stats',
            onTap: onTabChanged,
          ),
          _TabItem(
            index: 1,
            currentTab: currentTab,
            icon: PhosphorIcons.camera(),
            label: 'Progress Photos',
            onTap: onTabChanged,
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final int index;
  final int currentTab;
  final PhosphorIconData icon;
  final String label;
  final ValueChanged<int> onTap;

  const _TabItem({
    required this.index,
    required this.currentTab,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = currentTab == index;

    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap(index);
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PhosphorIcon(
                icon,
                color: isSelected
                    ? Colors.white
                    : theme.colorScheme.onSurfaceVariant,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? Colors.white
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
