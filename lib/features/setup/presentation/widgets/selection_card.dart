import 'package:flutter/material.dart';
import '../../../../core/theme/befit_theme_extension.dart';

/// A selectable card used in setup flows.
///
/// Supports optional icon, image asset, subtitle, and selection animation.
class SelectionCard extends StatefulWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final String? imageAsset;
  final String value;
  final String? groupValue;
  final ValueChanged<String?> onChanged;
  final bool isSelected;
  final double? height;
  final bool showIcon;

  const SelectionCard({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.imageAsset,
    required this.value,
    this.groupValue,
    required this.onChanged,
    this.isSelected = false,
    this.height,
    this.showIcon = true,
  });

  @override
  State<SelectionCard> createState() => _SelectionCardState();
}

class _SelectionCardState extends State<SelectionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _borderAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _borderAnimation = Tween<double>(begin: 1.0, end: 2.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.customColors;

    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      onTap: () => widget.onChanged(widget.value),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: widget.height ?? 80,
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? theme.setupPrimary.withValues(alpha: 0.1)
                    : theme.setupCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.isSelected ? theme.setupPrimary : theme.border,
                  width: widget.isSelected ? _borderAnimation.value : 1.5,
                ),
                boxShadow: [
                  if (widget.isSelected)
                    BoxShadow(
                      color: theme.setupPrimary.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    if (widget.showIcon) ...[
                      _IconContainer(
                        isSelected: widget.isSelected,
                        icon: widget.icon,
                        imageAsset: widget.imageAsset,
                        theme: theme,
                      ),
                      const SizedBox(width: 16),
                    ],
                    Expanded(
                      child: _CardText(
                        title: widget.title,
                        subtitle: widget.subtitle,
                        isSelected: widget.isSelected,
                        theme: theme,
                      ),
                    ),
                    _SelectionIndicator(
                      isSelected: widget.isSelected,
                      theme: theme,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Private Sub-Widgets ────────────────────────────────────────────────────

class _IconContainer extends StatelessWidget {
  final bool isSelected;
  final IconData? icon;
  final String? imageAsset;
  final BeFitThemeExtension theme;

  const _IconContainer({
    required this.isSelected,
    required this.theme,
    this.icon,
    this.imageAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isSelected
            ? theme.setupPrimary.withValues(alpha: 0.2)
            : theme.border.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: imageAsset != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(imageAsset!, fit: BoxFit.cover),
            )
          : Icon(
              icon ?? Icons.fitness_center,
              color: isSelected ? theme.setupPrimary : theme.setupTextSecondary,
              size: 24,
            ),
    );
  }
}

class _CardText extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool isSelected;
  final BeFitThemeExtension theme;

  const _CardText({
    required this.title,
    required this.isSelected,
    required this.theme,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: isSelected ? theme.setupPrimary : theme.setupTextPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: theme.setupTextSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

class _SelectionIndicator extends StatelessWidget {
  final bool isSelected;
  final BeFitThemeExtension theme;

  const _SelectionIndicator({required this.isSelected, required this.theme});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? theme.setupPrimary : Colors.transparent,
        border: Border.all(
          color: isSelected ? theme.setupPrimary : theme.border,
          width: 2,
        ),
      ),
      child: isSelected
          ? const Icon(Icons.check, color: Colors.white, size: 16)
          : null,
    );
  }
}
