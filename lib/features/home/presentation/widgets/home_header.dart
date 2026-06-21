// lib/features/home/presentation/widgets/home_header.dart

import 'dart:io';
import 'dart:ui';

import 'package:befit/core/router/app_routes.dart';
import 'package:befit/core/router/navigation_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:befit/features/home/presentation/widgets/home_theme.dart';
import 'package:befit/features/profile/presentation/providers/user_provider.dart';

class HomeHeaderSliver extends StatelessWidget {
  const HomeHeaderSliver({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final displayName = firstName(userProvider.displayName);
    final avatarUrl = userProvider.profile?.avatarUrl;
    final greeting = greetingForTimeOfDay();
    final topPadding = MediaQuery.paddingOf(context).top;

    return SliverPersistentHeader(
      pinned: true,
      delegate: _HomeHeaderDelegate(
        topPadding: topPadding,
        greeting: greeting,
        displayName: displayName,
        avatarUrl: avatarUrl,
        onBellTap: () => _navigateToNotifications(context),
        onAvatarTap: () => _navigateToProfile(context),
      ),
    );
  }

  void _navigateToNotifications(BuildContext context) {
    HapticFeedback.lightImpact();
    context.push(AppRoutes.notifications);
  }

  void _navigateToProfile(BuildContext context) {
    HapticFeedback.lightImpact();
    context.read<NavigationProvider>().setIndex(4);
    context.go(AppRoutes.profile);
  }
}

class _HomeHeaderDelegate extends SliverPersistentHeaderDelegate {
  _HomeHeaderDelegate({
    required this.topPadding,
    required this.greeting,
    required this.displayName,
    required this.avatarUrl,
    required this.onBellTap,
    required this.onAvatarTap,
  });

  final double topPadding;
  final String greeting;
  final String displayName;
  final String? avatarUrl;
  final VoidCallback onBellTap;
  final VoidCallback onAvatarTap;

  @override
  double get minExtent => 90 + topPadding;

  @override
  double get maxExtent => 148 + topPadding;

  @override
  bool shouldRebuild(covariant _HomeHeaderDelegate oldDelegate) =>
      topPadding != oldDelegate.topPadding ||
      greeting != oldDelegate.greeting ||
      displayName != oldDelegate.displayName ||
      avatarUrl != oldDelegate.avatarUrl;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final t = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final overlapsColor = isDark
        ? const Color(0xDC111318)
        : const Color(0xECF6F8F7);
    final transparentColor = isDark
        ? const Color(0x60111318)
        : const Color(0x70F6F8F7);
    final base = Color.lerp(
      transparentColor,
      overlapsColor,
      overlapsContent ? 1.0 : t,
    );

    final avatarSize = lerpDouble(54, 40, t)!;
    final actionSize = lerpDouble(48, 40, t)!;
    final nameSize = lerpDouble(30, 20, t)!;

    final greetingOpacity = (1.0 - t * 2.0).clamp(0.0, 1.0);
    final dateOpacity = (1.0 - t * 2.5).clamp(0.0, 1.0);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: base,
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: overlapsContent ? 0.08 : 0.0)
                    : Colors.black.withValues(alpha: overlapsContent ? 0.05 : 0.0),
                width: 0.8,
              ),
            ),
            boxShadow: overlapsContent
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          padding: EdgeInsets.fromLTRB(
            kHorizontalPadding,
            topPadding + lerpDouble(12, 6, t)!,
            kHorizontalPadding,
            lerpDouble(18, 12, t)!,
          ),
          child: Row(
            children: [
              _Avatar(
                avatarUrl: avatarUrl,
                displayName: displayName,
                onTap: onAvatarTap,
                size: avatarSize,
              ),
              SizedBox(width: lerpDouble(14, 12, t)!),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (greetingOpacity > 0.0)
                      Opacity(
                        opacity: greetingOpacity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              greeting.toUpperCase(),
                              style: GoogleFonts.montserrat(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.8,
                                color: HomeUi.accent(context),
                              ),
                            ),
                            const SizedBox(height: 3),
                          ],
                        ),
                      ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(
                            fontSize: nameSize,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.0,
                            color: colorScheme.onSurface,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          '.',
                          style: GoogleFonts.montserrat(
                            fontSize: nameSize,
                            fontWeight: FontWeight.w900,
                            color: HomeUi.accent(context),
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                    if (dateOpacity > 0.0)
                      Opacity(
                        opacity: dateOpacity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: HomeUi.accent(context).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                DateFormat(
                                  'EEEE, MMM d',
                                ).format(DateTime.now()).toUpperCase(),
                                style: GoogleFonts.montserrat(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                  color: HomeUi.accent(context),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _NotificationButton(
                icon: Iconsax.notification_bing,
                onTap: onBellTap,
                size: actionSize,
                showDot: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.avatarUrl,
    required this.displayName,
    required this.onTap,
    required this.size,
  });

  final String? avatarUrl;
  final String displayName;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(displayName);

    Widget? imageChild;
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      if (avatarUrl!.startsWith('http') || avatarUrl!.startsWith('https')) {
        imageChild = Image.network(
          avatarUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _initialsWidget(context, initials),
        );
      } else {
        final file = File(avatarUrl!);
        if (file.existsSync()) {
          imageChild = Image.file(
            file,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _initialsWidget(context, initials),
          );
        }
      }
    }

    final child = imageChild != null
        ? ClipOval(child: imageChild)
        : _initialsWidget(context, initials);

    final double ringSize = size + 6;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: ringSize,
        height: ringSize,
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [HomeUi.accent(context), HomeUi.accentSecondary(context)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: HomeUi.accent(context).withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.surface,
          ),
          padding: const EdgeInsets.all(1.5),
          child: ClipOval(child: child),
        ),
      ),
    );
  }

  Widget _initialsWidget(BuildContext context, String initials) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            HomeUi.accent(context).withValues(alpha: 0.12),
            HomeUi.accentSecondary(context).withValues(alpha: 0.08),
          ],
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.montserrat(
            fontSize: size * 0.36,
            fontWeight: FontWeight.w800,
            color: HomeUi.accent(context),
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

class _NotificationButton extends StatefulWidget {
  const _NotificationButton({
    required this.icon,
    required this.onTap,
    required this.size,
    this.showDot = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final bool showDot;

  @override
  State<_NotificationButton> createState() => _NotificationButtonState();
}

class _NotificationButtonState extends State<_NotificationButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.03),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05),
            width: 1.0,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              widget.icon,
              size: widget.size * 0.44,
              color: colorScheme.onSurface,
            ),
            if (widget.showDot)
              Positioned(
                top: widget.size * 0.22,
                right: widget.size * 0.22,
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final scale = 1.0 + _pulseController.value * 1.2;
                    final opacity = 1.0 - _pulseController.value;

                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Pulsing outer ring
                        Transform.scale(
                          scale: scale,
                          child: Opacity(
                            opacity: opacity,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: HomeUi.accentWarm(context),
                              ),
                            ),
                          ),
                        ),
                        // Inner solid dot
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: HomeUi.accentWarm(context),
                            boxShadow: [
                              BoxShadow(
                                color: HomeUi.accentWarm(
                                  context,
                                ).withValues(alpha: 0.5),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

