import 'package:flutter/material.dart';
import '../../core/workout_colors.dart';
import 'package:google_fonts/google_fonts.dart';

TextStyle workoutTextStyle(
  BuildContext context, {
  double size = 14,
  FontWeight weight = FontWeight.w500,
  Color? color,
}) =>
    GoogleFonts.montserrat(
      fontSize: size,
      fontWeight: weight,
      color: color ?? WorkoutColors.onSurface(context),
    );

class WorkoutPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool fullWidth;

  const WorkoutPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: Colors.black),
          const SizedBox(width: 8),
        ],
        Text(
          label.toUpperCase(),
          style: workoutTextStyle(context,
              size: 14, weight: FontWeight.w800, color: Colors.black),
        ),
      ],
    );

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: WorkoutColors.lime(context),
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: child,
      ),
    );
  }
}

class WorkoutSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const WorkoutSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: workoutTextStyle(context, size: 18, weight: FontWeight.w700)),
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionLabel!,
                style: workoutTextStyle(context,
                    size: 13, weight: FontWeight.w600, color: WorkoutColors.limeDark(context)),
              ),
            ),
        ],
      ),
    );
  }
}

class WorkoutFilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const WorkoutFilterPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.black : WorkoutColors.surfaceMuted(context),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: workoutTextStyle(
            context,
            size: 13,
            weight: FontWeight.w600,
            color: selected ? WorkoutColors.lime(context) : WorkoutColors.onSurfaceMuted(context),
          ),
        ),
      ),
    );
  }
}

class WorkoutStatMiniCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subValue;
  final IconData icon;
  final Color? iconColor;

  const WorkoutStatMiniCard({
    super.key,
    required this.label,
    required this.value,
    this.subValue,
    required this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: WorkoutColors.cardDecoration(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon,
                size: 18,
                color: iconColor ?? WorkoutColors.onSurfaceMuted(context)),
            const SizedBox(height: 10),
            Text(value,
                style: workoutTextStyle(context, size: 16, weight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label,
                style: workoutTextStyle(context,
                    size: 11, color: WorkoutColors.onSurfaceMuted(context))),
            if (subValue != null)
              Text(subValue!,
                  style:
                      workoutTextStyle(context, size: 10, color: WorkoutColors.limeDark(context))),
          ],
        ),
      ),
    );
  }
}

class WorkoutMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String? badge;

  const WorkoutMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: WorkoutColors.scaffold(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: WorkoutColors.border(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: workoutTextStyle(context,
                    size: 11, color: WorkoutColors.onSurfaceMuted(context))),
            const SizedBox(height: 6),
            Text(value,
                style: workoutTextStyle(context, size: 15, weight: FontWeight.w800)),
            if (badge != null) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: WorkoutColors.limeMuted(context),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge!,
                  style: workoutTextStyle(context,
                      size: 10, weight: FontWeight.w600, color: WorkoutColors.limeDark(context)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class WorkoutLightScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final bool extendBodyBehindAppBar;

  const WorkoutLightScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.extendBodyBehindAppBar = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WorkoutColors.scaffold(context),
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      appBar: appBar,
      body: body,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

class WorkoutBackAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? actions;
  final bool transparent;

  const WorkoutBackAppBar({
    super.key,
    this.title,
    this.actions,
    this.transparent = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final foregroundColor = transparent ? Colors.white : WorkoutColors.onSurface(context);
    
    return AppBar(
      backgroundColor: transparent ? Colors.transparent : WorkoutColors.scaffold(context),
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new,
            size: 20, color: foregroundColor),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: title != null
          ? Text(title!,
              style: workoutTextStyle(context,
                  size: 17,
                  weight: FontWeight.w700,
                  color: foregroundColor))
          : null,
      actions: actions,
      iconTheme: IconThemeData(color: foregroundColor),
    );
  }
}
