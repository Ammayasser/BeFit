import 'dart:io';

import 'dart:ui';

import 'package:befit/features/profile/presentation/providers/user_provider.dart';

import 'package:befit/features/profile/presentation/screens/profile_screen.dart';

import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import 'package:provider/provider.dart';

import 'package:go_router/go_router.dart';

import '../../achievements/engine/achievement_manager.dart';

import '../../achievements/ui/achievement_toast.dart';

import '../../widgets/responsive_layout.dart';

import '../../utils/haptics.dart';

import '../navigation_provider.dart';

import '../app_routes.dart';

import '../../../features/home/presentation/screens/home_screen.dart';

import '../../../features/workout/presentation/screens/workout_screen.dart';

import '../../../features/nutrition/presentation/screens/nutrition_screen.dart';

import '../../../features/community/presentation/screens/community_screen.dart';

class MainNavigationShell extends StatefulWidget {
  final Widget child;

  const MainNavigationShell({super.key, required this.child});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  @override
  void initState() {
    super.initState();

    // Listen for achievements

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final manager = context.read<AchievementManager>();

      manager.addListener(_onAchievementChanged);
    });
  }

  void _onAchievementChanged() {
    if (!mounted) return;

    final manager = context.read<AchievementManager>();

    final last = manager.lastUnlocked;

    if (last != null) {
      AchievementToast.show(context, last);

      manager.clearLastUnlocked();
    }
  }

  @override
  void dispose() {
    try {
      context.read<AchievementManager>().removeListener(_onAchievementChanged);
    } catch (_) {}

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<NavigationProvider>();

    return ResponsiveLayout(
      phone: _buildPhoneLayout(context, navProvider),

      tablet: _buildTabletLayout(context, navProvider),
    );
  }

  static String _shellLocationPath(BuildContext context) {
    var p = GoRouterState.of(context).uri.path;

    if (p.isEmpty || p == '/') return AppRoutes.home;

    if (p.length > 1 && p.endsWith('/')) {
      p = p.substring(0, p.length - 1);
    }

    return p;
  }

  static bool _isMainShellTab(String path) {
    if (path.startsWith('${AppRoutes.profile}/')) return false;

    const tabs = <String>{
      AppRoutes.home,

      AppRoutes.workout,

      AppRoutes.nutrition,

      AppRoutes.community,

      AppRoutes.profile,
    };

    return tabs.contains(path);
  }

  Widget _buildPhoneLayout(BuildContext context, NavigationProvider nav) {
    final path = _shellLocationPath(context);

    final showTabs = _isMainShellTab(path);

    return Scaffold(
      extendBody: true,

      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      body: showTabs
          ? IndexedStack(
              index: nav.currentIndex,

              children: const [
                HomeScreen(),

                WorkoutScreen(),

                NutritionScreen(),

                CommunityScreen(),

                ProfileScreen(),
              ],
            )
          : widget.child,

      bottomNavigationBar: showTabs
          ? ModernNavBar(
              currentIndex: nav.currentIndex,

              onTap: (i) {
                HapticService.lightImpact();

                nav.setIndex(i);
              },
            )
          : null,
    );
  }

  Widget _buildTabletLayout(BuildContext context, NavigationProvider nav) {
    int stackToRail(int i) => i;

    final path = _shellLocationPath(context);

    final showTabs = _isMainShellTab(path);

    if (!showTabs) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,

        body: widget.child,
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      body: Row(
        children: [
          ModernNavRail(
            selectedIndex: stackToRail(nav.currentIndex),

            onDestinationSelected: (i) {
              HapticService.lightImpact();

              nav.setIndex(i);
            },
          ),

          Expanded(
            child: IndexedStack(
              index: nav.currentIndex,

              children: const [
                HomeScreen(),

                WorkoutScreen(),

                NutritionScreen(),

                CommunityScreen(),

                ProfileScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ShellNavTokens {
  const ShellNavTokens({
    required this.dockOuterShadows,

    required this.dockFill,

    required this.dockBorder,

    required this.indicatorGradient,

    required this.indicatorBorder,

    required this.indicatorShadows,

    required this.iconMuted,

    required this.labelMuted,

    required this.inkSplash,

    required this.inkHighlight,

    required this.railBackground,

    required this.railDivider,

    required this.railOuterShadows,

    required this.railItemBorderIdle,

    required this.railSelectionGradient,

    required this.railSelectionBorder,
  });

  final List<BoxShadow> dockOuterShadows;

  final Color dockFill;

  final Color dockBorder;

  final Gradient indicatorGradient;

  final Color indicatorBorder;

  final List<BoxShadow> indicatorShadows;

  final Color iconMuted;

  final Color labelMuted;

  final Color inkSplash;

  final Color inkHighlight;

  final Color railBackground;

  final Color railDivider;

  final List<BoxShadow> railOuterShadows;

  final Color railItemBorderIdle;

  final Gradient railSelectionGradient;

  final Color railSelectionBorder;

  static ShellNavTokens of(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final light = Theme.of(context).brightness == Brightness.light;

    if (light) {
      return ShellNavTokens(
        dockOuterShadows: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),

            blurRadius: 28,

            offset: const Offset(0, 12),

            spreadRadius: -6,
          ),

          BoxShadow(
            color: colorScheme.primary.withOpacity(0.10),

            blurRadius: 20,

            offset: const Offset(0, 4),
          ),
        ],

        dockFill: colorScheme.surface.withOpacity(0.6),

        dockBorder: colorScheme.outlineVariant,

        indicatorGradient: LinearGradient(
          begin: Alignment.topLeft,

          end: Alignment.bottomRight,

          colors: [
            colorScheme.primary.withOpacity(0.20),

            colorScheme.primary.withOpacity(0.11),
          ],
        ),

        indicatorBorder: colorScheme.primary.withOpacity(0.42),

        indicatorShadows: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.12),

            blurRadius: 10,

            offset: const Offset(0, 2),
          ),
        ],

        iconMuted: colorScheme.onSurfaceVariant.withOpacity(0.7),

        labelMuted: colorScheme.onSurfaceVariant,

        inkSplash: colorScheme.primary.withOpacity(0.14),

        inkHighlight: colorScheme.primary.withOpacity(0.06),

        railBackground: colorScheme.surface,

        railDivider: colorScheme.outlineVariant,

        railOuterShadows: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),

            blurRadius: 14,

            offset: const Offset(3, 0),
          ),
        ],

        railItemBorderIdle: colorScheme.outline.withOpacity(0.1),

        railSelectionGradient: LinearGradient(
          begin: Alignment.centerLeft,

          end: Alignment.centerRight,

          colors: [
            colorScheme.primary.withOpacity(0.16),

            colorScheme.primary.withOpacity(0.07),
          ],
        ),

        railSelectionBorder: colorScheme.primary.withOpacity(0.38),
      );
    }

    return ShellNavTokens(
      dockOuterShadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.55),

          blurRadius: 32,

          offset: const Offset(0, 14),

          spreadRadius: -4,
        ),

        BoxShadow(
          color: colorScheme.primary.withOpacity(0.12),

          blurRadius: 24,

          offset: const Offset(0, 6),
        ),
      ],

      dockFill: colorScheme.surface.withOpacity(0.85),

      dockBorder: colorScheme.outline.withOpacity(0.2),

      indicatorGradient: LinearGradient(
        begin: Alignment.topLeft,

        end: Alignment.bottomRight,

        colors: [
          colorScheme.primary.withOpacity(0.22),

          colorScheme.primary.withOpacity(0.12),
        ],
      ),

      indicatorBorder: colorScheme.primary.withOpacity(0.35),

      indicatorShadows: [
        BoxShadow(
          color: colorScheme.primary.withOpacity(0.15),

          blurRadius: 12,

          offset: const Offset(0, 2),
        ),
      ],

      iconMuted: colorScheme.onSurfaceVariant,

      labelMuted: colorScheme.onSurfaceVariant.withOpacity(0.8),

      inkSplash: colorScheme.primary.withOpacity(0.08),

      inkHighlight: colorScheme.primary.withOpacity(0.04),

      railBackground: colorScheme.surface,

      railDivider: colorScheme.outline.withOpacity(0.1),

      railOuterShadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.35),

          blurRadius: 20,

          offset: const Offset(4, 0),
        ),
      ],

      railItemBorderIdle: colorScheme.outline.withOpacity(0.05),

      railSelectionGradient: LinearGradient(
        begin: Alignment.centerLeft,

        end: Alignment.centerRight,

        colors: [
          colorScheme.primary.withOpacity(0.2),

          colorScheme.primary.withOpacity(0.08),
        ],
      ),

      railSelectionBorder: colorScheme.primary.withOpacity(0.35),
    );
  }
}

class ModernNavBar extends StatelessWidget {
  final int currentIndex;

  final ValueChanged<int> onTap;

  static const double _dockHeight = 76;

  static const double _radius = 26;

  static const double _innerPadH = 8;

  static const double _indicatorInsetV = 8;

  const ModernNavBar({
    super.key,

    required this.currentIndex,

    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const items = [
      NavItem(label: 'Home', icon: NavIcons.home),

      NavItem(label: 'Workout', icon: NavIcons.workout),

      NavItem(label: 'Nutrition', icon: NavIcons.nutrition),

      NavItem(label: 'Chatbot', icon: NavIcons.community),

      NavItem(label: 'Profile', icon: NavIcons.profile),
    ];

    final style = ShellNavTokens.of(context);

    final bottomSafe = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomSafe + 12),

      child: SizedBox(
        height: _dockHeight,

        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_radius),

            boxShadow: style.dockOuterShadows,
          ),

          child: ClipRRect(
            borderRadius: BorderRadius.circular(_radius),

            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),

              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_radius),

                  color: style.dockFill,

                  border: Border.all(color: style.dockBorder, width: 1),
                ),

                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final n = items.length;

                    final trackW = constraints.maxWidth - _innerPadH * 2;

                    final slotW = trackW / n;

                    const indicatorHPad = 3.0;

                    return Stack(
                      alignment: Alignment.center,

                      children: [
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 360),

                          curve: Curves.easeOutCubic,

                          left:
                              _innerPadH + currentIndex * slotW + indicatorHPad,

                          width: slotW - indicatorHPad * 2,

                          top: _indicatorInsetV,

                          bottom: _indicatorInsetV,

                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),

                              gradient: style.indicatorGradient,

                              border: Border.all(color: style.indicatorBorder),

                              boxShadow: style.indicatorShadows,
                            ),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: _innerPadH,
                          ),

                          child: Row(
                            children: List.generate(n, (i) {
                              return Expanded(
                                child: NavDockItem(
                                  item: items[i],

                                  selected: currentIndex == i,

                                  onTap: () => onTap(i),
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NavDockItem extends StatelessWidget {
  final NavItem item;

  final bool selected;

  final VoidCallback onTap;

  const NavDockItem({
    super.key,

    required this.item,

    required this.selected,

    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final style = ShellNavTokens.of(context);

    final colorScheme = Theme.of(context).colorScheme;

    final iconColor = selected ? colorScheme.primary : style.iconMuted;

    final labelColor = selected ? colorScheme.primary : style.labelMuted;

    return Material(
      color: Colors.transparent,

      child: InkWell(
        onTap: onTap,

        splashColor: style.inkSplash,

        highlightColor: style.inkHighlight,

        borderRadius: BorderRadius.circular(20),

        child: Semantics(
          button: true,

          selected: selected,

          label: item.label,

          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),

            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,

              children: [
                SizedBox(
                  width: 24,

                  height: 24,

                  child: _buildDefaultProfileIcon(iconColor, selected),
                ),

                const SizedBox(height: 4),

                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 240),

                  curve: Curves.easeOutCubic,

                  style: GoogleFonts.montserrat(
                    fontSize: 10.5,

                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,

                    letterSpacing: 0.15,

                    height: 1.0,

                    color: labelColor,
                  ),

                  child: Text(
                    item.label,

                    maxLines: 1,

                    overflow: TextOverflow.ellipsis,

                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultProfileIcon(Color color, bool selected) {
    return CustomPaint(
      painter: IconPainter(
        icon: item.icon,

        color: color,

        fillProgress: selected ? 1.0 : 0.0,
      ),
    );
  }
}

enum NavIcons { home, workout, nutrition, community, profile }

class IconPainter extends CustomPainter {
  final NavIcons icon;

  final Color color;

  final double fillProgress;

  const IconPainter({
    required this.icon,

    required this.color,

    required this.fillProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;

    final h = size.height;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color.withOpacity(fillProgress)
      ..style = PaintingStyle.fill;

    switch (icon) {
      case NavIcons.home:
        _drawHome(canvas, w, h, strokePaint, fillPaint, fillProgress);

      case NavIcons.workout:
        _drawWorkout(canvas, w, h, strokePaint, fillPaint, fillProgress);

      case NavIcons.nutrition:
        _drawNutrition(canvas, w, h, strokePaint, fillPaint, fillProgress);

      case NavIcons.community:
        _drawCommunity(canvas, w, h, strokePaint, fillPaint, fillProgress);

      case NavIcons.profile:
        _drawProfile(canvas, w, h, strokePaint, fillPaint, fillProgress);
    }
  }

  void _drawHome(
    Canvas canvas,

    double w,

    double h,

    Paint stroke,

    Paint fill,

    double p,
  ) {
    final roofPath = Path()
      ..moveTo(w * 0.5, h * 0.05)
      ..lineTo(w * 0.95, h * 0.44)
      ..lineTo(w * 0.05, h * 0.44)
      ..close();

    final bodyPath = Path()
      ..moveTo(w * 0.15, h * 0.44)
      ..lineTo(w * 0.15, h * 0.94)
      ..lineTo(w * 0.85, h * 0.94)
      ..lineTo(w * 0.85, h * 0.44);

    final doorPath = Path()
      ..addRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(w * 0.37, h * 0.62, w * 0.26, h * 0.32),

          topLeft: const Radius.circular(3),

          topRight: const Radius.circular(3),
        ),
      );

    if (p > 0) {
      canvas.drawPath(
        roofPath,

        fill..color = stroke.color.withOpacity(p * 0.9),
      );

      canvas.drawPath(
        bodyPath..close(),

        fill..color = stroke.color.withOpacity(p * 0.25),
      );
    }

    canvas.drawPath(roofPath, stroke);

    canvas.drawPath(bodyPath, stroke);

    canvas.drawPath(doorPath, stroke);
  }

  void _drawWorkout(
    Canvas canvas,

    double w,

    double h,

    Paint stroke,

    Paint fill,

    double p,
  ) {
    final bar = Rect.fromLTWH(w * 0.12, h * 0.44, w * 0.76, h * 0.12);

    final leftPlate1 = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.04, h * 0.28, w * 0.14, h * 0.44),

      const Radius.circular(3),
    );

    final leftPlate2 = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.12, h * 0.22, w * 0.10, h * 0.56),

      const Radius.circular(3),
    );

    final rightPlate1 = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.82, h * 0.28, w * 0.14, h * 0.44),

      const Radius.circular(3),
    );

    final rightPlate2 = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.78, h * 0.22, w * 0.10, h * 0.56),

      const Radius.circular(3),
    );

    if (p > 0) {
      final fp = fill..color = stroke.color.withOpacity(p);

      canvas.drawRect(bar, fp);

      canvas.drawRRect(leftPlate1, fp);

      canvas.drawRRect(leftPlate2, fp);

      canvas.drawRRect(rightPlate1, fp);

      canvas.drawRRect(rightPlate2, fp);
    }

    canvas.drawRect(bar, stroke);

    canvas.drawRRect(leftPlate1, stroke);

    canvas.drawRRect(leftPlate2, stroke);

    canvas.drawRRect(rightPlate1, stroke);

    canvas.drawRRect(rightPlate2, stroke);
  }

  void _drawNutrition(
    Canvas canvas,

    double w,

    double h,

    Paint stroke,

    Paint fill,

    double p,
  ) {
    final bowlPath = Path()
      ..moveTo(w * 0.08, h * 0.42)
      ..quadraticBezierTo(w * 0.08, h * 0.90, w * 0.50, h * 0.94)
      ..quadraticBezierTo(w * 0.92, h * 0.90, w * 0.92, h * 0.42)
      ..close();

    final rimPath = Path()
      ..moveTo(w * 0.05, h * 0.42)
      ..lineTo(w * 0.95, h * 0.42);

    final leaf1 = Path()
      ..moveTo(w * 0.50, h * 0.18)
      ..quadraticBezierTo(w * 0.22, h * 0.10, w * 0.22, h * 0.38)
      ..quadraticBezierTo(w * 0.38, h * 0.22, w * 0.50, h * 0.18);

    final leaf2 = Path()
      ..moveTo(w * 0.50, h * 0.18)
      ..quadraticBezierTo(w * 0.78, h * 0.10, w * 0.78, h * 0.38)
      ..quadraticBezierTo(w * 0.62, h * 0.22, w * 0.50, h * 0.18);

    if (p > 0) {
      canvas.drawPath(
        bowlPath,

        fill..color = stroke.color.withOpacity(p * 0.2),
      );

      canvas.drawPath(leaf1, fill..color = stroke.color.withOpacity(p * 0.7));

      canvas.drawPath(leaf2, fill..color = stroke.color.withOpacity(p * 0.7));
    }

    canvas.drawPath(bowlPath, stroke);

    canvas.drawPath(rimPath, stroke);

    canvas.drawPath(leaf1, stroke);

    canvas.drawPath(leaf2, stroke);
  }

  void _drawCommunity(
    Canvas canvas,

    double w,

    double h,

    Paint stroke,

    Paint fill,

    double p,
  ) {
    final bubble1 = RRect.fromRectAndCorners(
      Rect.fromLTWH(w * 0.04, h * 0.06, w * 0.60, h * 0.50),

      topLeft: const Radius.circular(8),

      topRight: const Radius.circular(8),

      bottomRight: const Radius.circular(8),

      bottomLeft: const Radius.circular(2),
    );

    final bubble2 = RRect.fromRectAndCorners(
      Rect.fromLTWH(w * 0.36, h * 0.44, w * 0.60, h * 0.48),

      topLeft: const Radius.circular(8),

      topRight: const Radius.circular(8),

      bottomLeft: const Radius.circular(8),

      bottomRight: const Radius.circular(2),
    );

    final tail1 = Path()
      ..moveTo(w * 0.04, h * 0.52)
      ..lineTo(w * 0.04, h * 0.64)
      ..lineTo(w * 0.16, h * 0.56);

    final tail2 = Path()
      ..moveTo(w * 0.96, h * 0.88)
      ..lineTo(w * 0.96, h * 0.76)
      ..lineTo(w * 0.84, h * 0.82);

    if (p > 0) {
      canvas.drawRRect(
        bubble2,

        fill..color = stroke.color.withOpacity(p * 0.5),
      );

      canvas.drawRRect(
        bubble1,

        fill..color = stroke.color.withOpacity(p * 0.9),
      );
    }

    canvas.drawRRect(bubble2, stroke);

    canvas.drawPath(tail2, stroke);

    canvas.drawRRect(bubble1, stroke);

    canvas.drawPath(tail1, stroke);
  }

  void _drawProfile(
    Canvas canvas,

    double w,

    double h,

    Paint stroke,

    Paint fill,

    double p,
  ) {
    final headRect = Rect.fromCenter(
      center: Offset(w * 0.50, h * 0.28),

      width: w * 0.36,

      height: h * 0.36,
    );

    final shouldersPath = Path()
      ..moveTo(w * 0.04, h * 0.96)
      ..quadraticBezierTo(w * 0.04, h * 0.60, w * 0.50, h * 0.58)
      ..quadraticBezierTo(w * 0.96, h * 0.60, w * 0.96, h * 0.96)
      ..close();

    if (p > 0) {
      canvas.drawOval(headRect, fill..color = stroke.color.withOpacity(p));

      canvas.drawPath(
        shouldersPath,

        fill..color = stroke.color.withOpacity(p * 0.7),
      );
    }

    canvas.drawOval(headRect, stroke);

    canvas.drawPath(shouldersPath, stroke);
  }

  @override
  bool shouldRepaint(covariant IconPainter oldDelegate) =>
      oldDelegate.icon != icon ||
      oldDelegate.color != color ||
      oldDelegate.fillProgress != fillProgress;
}

class ModernNavRail extends StatelessWidget {
  final int selectedIndex;

  final ValueChanged<int> onDestinationSelected;

  const ModernNavRail({
    super.key,

    required this.selectedIndex,

    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();

    final avatarUrl = user.profile?.avatarUrl;

    const items = [
      NavItem(label: 'Home', icon: NavIcons.home),

      NavItem(label: 'Workout', icon: NavIcons.workout),

      NavItem(label: 'Nutrition', icon: NavIcons.nutrition),

      NavItem(label: 'Chatbot', icon: NavIcons.community),

      NavItem(label: 'Profile', icon: NavIcons.profile),
    ];

    final style = ShellNavTokens.of(context);

    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 88,

      decoration: BoxDecoration(
        color: style.railBackground,

        border: Border(right: BorderSide(color: style.railDivider)),

        boxShadow: style.railOuterShadows,
      ),

      child: Column(
        children: [
          const SizedBox(height: 28),

          GestureDetector(
            onTap: () => onDestinationSelected(4),

            child: Container(
              width: 44,

              height: 44,

              decoration: BoxDecoration(
                shape: BoxShape.circle,

                gradient: avatarUrl == null
                    ? LinearGradient(
                        begin: Alignment.topLeft,

                        end: Alignment.bottomRight,

                        colors: [
                          colorScheme.primary.withOpacity(0.28),

                          colorScheme.primary.withOpacity(0.12),
                        ],
                      )
                    : null,

                border: Border.all(
                  color: colorScheme.primary.withOpacity(0.45),

                  width: 1.5,
                ),

                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.2),

                    blurRadius: 12,

                    offset: const Offset(0, 3),
                  ),
                ],
              ),

              child: ClipOval(
                child: avatarUrl != null
                    ? (avatarUrl.startsWith('http')
                          ? Image.network(
                              avatarUrl,

                              fit: BoxFit.cover,

                              errorBuilder: (context, error, stackTrace) =>
                                  _buildFallback(context, user),
                            )
                          : Image.file(
                              File(avatarUrl),

                              fit: BoxFit.cover,

                              errorBuilder: (context, error, stackTrace) =>
                                  _buildFallback(context, user),
                            ))
                    : _buildFallback(context, user),
              ),
            ),
          ),

          const SizedBox(height: 28),

          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 10),

              itemCount: items.length,

              separatorBuilder: (context, index) => const SizedBox(height: 6),

              itemBuilder: (context, i) {
                final selected = selectedIndex == i;

                return Material(
                  color: Colors.transparent,

                  child: InkWell(
                    onTap: () => onDestinationSelected(i),

                    borderRadius: BorderRadius.circular(18),

                    splashColor: style.inkSplash,

                    highlightColor: style.inkHighlight,

                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 280),

                      curve: Curves.easeOutCubic,

                      padding: const EdgeInsets.symmetric(
                        vertical: 12,

                        horizontal: 8,
                      ),

                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),

                        gradient: selected ? style.railSelectionGradient : null,

                        border: Border.all(
                          color: selected
                              ? style.railSelectionBorder
                              : style.railItemBorderIdle,
                        ),
                      ),

                      child: Column(
                        mainAxisSize: MainAxisSize.min,

                        children: [
                          SizedBox(
                            width: 24,

                            height: 24,

                            child: CustomPaint(
                              painter: IconPainter(
                                icon: items[i].icon,

                                color: selected
                                    ? colorScheme.primary
                                    : style.iconMuted,

                                fillProgress: selected ? 1.0 : 0.0,
                              ),
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            items[i].label,

                            maxLines: 1,

                            overflow: TextOverflow.ellipsis,

                            style: GoogleFonts.montserrat(
                              color: selected
                                  ? colorScheme.primary
                                  : style.labelMuted,

                              fontSize: 10,

                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w500,

                              letterSpacing: 0.12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFallback(BuildContext context, UserProvider user) {
    final colorScheme = Theme.of(context).colorScheme;

    final initials = user.displayName.isNotEmpty
        ? user.displayName[0].toUpperCase()
        : 'A';

    return Center(
      child: Text(
        initials,

        style: GoogleFonts.montserrat(
          fontSize: 18,

          fontWeight: FontWeight.w800,

          color: colorScheme.primary,
        ),
      ),
    );
  }
}

class NavItem {
  final String label;

  final NavIcons icon;

  const NavItem({required this.label, required this.icon});
}
