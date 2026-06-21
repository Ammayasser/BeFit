

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../providers/onboarding_provider.dart';
import '../../domain/models/onboarding_page_model.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/responsive.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const _kAccent = Color(0xFF4ADE80);
const _kAccentDark = Color(0xFF22C55E);
const _kBase = Color(0xFF0A0C10);
const _kPanelBg = Color(0xFF0A0C10);

const _kPageAccents = [
  Color(0xFF4ADE80), // page 0 – green
  Color(0xFF38BDF8), // page 1 – sky-blue
  Color(0xFFA78BFA), // page 2 – violet
];

// ─── Root screen ──────────────────────────────────────────────────────────────
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OnboardingProvider>();
    final top = MediaQuery.of(context).padding.top;
    final s = Responsive.scale(context, 1);
    final totalH = MediaQuery.of(context).size.height;

    // Deep Fix: Use a Stack with Overlap. 
    // Image takes 58% height, Content takes 48%, creating a 6% overlap area.
    final imageH = totalH * 0.58;
    final panelH = totalH * 0.52;

    return Scaffold(
      backgroundColor: _kBase,
      body: Stack(
        children: [
          // ── 1. Image Area (58% of screen) ───────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: imageH,
            child: PageView.builder(
              controller: provider.pageController,
              onPageChanged: provider.onPageChanged,
              itemCount: provider.totalPages,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (ctx, i) => _ImagePage(
                index: i,
                pageData: OnboardingData.pages[i],
                pageController: provider.pageController,
              ),
            ),
          ),

          // ── 2. Content Panel (48% of screen, Overlapping) ────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: panelH,
            child: Container(
              decoration: BoxDecoration(
                color: _kPanelBg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32 * s)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 20,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: _ContentPanel(provider: provider),
            ),
          ),

          // ── 3. Top bar (Back + Skip) ──────────────────────────────────────
          Positioned(
            top: top + 16 * s,
            left: 20 * s,
            right: 20 * s,
            child: _TopBar(provider: provider),
          ),
        ],
      ),
    );
  }
}

// ─── Image page ──────────────────────────────────────────────────────────────
class _ImagePage extends StatelessWidget {
  final int index;
  final OnboardingPageModel pageData;
  final PageController pageController;

  const _ImagePage({
    required this.index,
    required this.pageData,
    required this.pageController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pageController,
      builder: (ctx, _) {
        double offset = 0.0;
        if (pageController.hasClients) {
          offset = (pageController.page ?? index.toDouble()) - index;
        }
        final opacity = (1.0 - offset.abs() * 1.2).clamp(0.0, 1.0);

        return Opacity(
          opacity: opacity,
          child: ClipRect(
            child: SizedBox.expand(
              child: Image.asset(
                pageData.imagePath,
                fit: BoxFit.cover,
                alignment: pageData.imageAlignment,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Content panel ────────────────────────────────────────────────────────────
class _ContentPanel extends StatelessWidget {
  final OnboardingProvider provider;
  const _ContentPanel({required this.provider});

  @override
  Widget build(BuildContext context) {
    final s = Responsive.scale(context, 1);
    final hp = Responsive.horizontalPadding(context);
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final isLast = provider.currentPage == provider.totalPages - 1;

    return Stack(
      children: [
        // Grid background pattern
        const Positioned.fill(child: _GridPattern()),

        // Content wrapper
        LayoutBuilder(
          builder: (context, constraints) {
            // Bug 3 Fix: Height-based gaps and paddings
            final availH = constraints.maxHeight;
            final topGap = (availH * 0.06).clamp(12.0, 32.0);
            final midGap = (availH * 0.04).clamp(6.0, 16.0);
            final botGap = (bottomPad + 8 * s).clamp(8.0, 36.0);

            // Bug 4 Fix: Height-aware title font size
            final rawTitleSize = Responsive.heroFontSize(context) * 0.70;
            final maxTitleByHeight = availH * 0.12;
            final titleSize = rawTitleSize.clamp(24.0, maxTitleByHeight.clamp(24.0, 48.0));

            // Final Fix: SingleChildScrollView + ConstrainedBox + MainAxisAlignment.spaceBetween
            // This is the ultimate layout pattern that guarantees perfect alignment on tall screens
            // and scrolls cleanly without any overflow errors/banners on short screens.
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(hp, topGap, hp, botGap),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TextBlock(
                        key: ValueKey(provider.currentPage),
                        pageData: OnboardingData.pages[provider.currentPage],
                        index: provider.currentPage,
                        titleSize: titleSize,
                      ),

                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _StepProgress(
                            total: provider.totalPages,
                            current: provider.currentPage,
                          ),

                          SizedBox(height: midGap),

                          // CTA button
                          _GradientButton(
                            label: isLast ? 'Get Started' : 'Continue',
                            onTap: () async {
                              if (isLast) {
                                await context.read<AuthProvider>().markOnboardingSeen();
                                if (context.mounted) context.go(AppRoutes.setup);
                              } else {
                                provider.next();
                              }
                            },
                          ),

                          if (isLast) ...[
                            SizedBox(height: 16 * s),
                            Center(
                              child: GestureDetector(
                                onTap: () async {
                                  await context.read<AuthProvider>().markOnboardingSeen();
                                  if (context.mounted) context.go(AppRoutes.login);
                                },
                                child: RichText(
                                  textAlign: TextAlign.center,
                                  text: TextSpan(
                                    text: 'Already have an account?  ',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.45),
                                      fontSize: 14 * s,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Log In',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.92),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14 * s,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ─── Grid Pattern ─────────────────────────────────────────────────────────────
class _GridPattern extends StatelessWidget {
  const _GridPattern();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GridPainter(
        color: Colors.white.withValues(alpha: 0.04),
        spacing: 30.0,
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color color;
  final double spacing;

  _GridPainter({required this.color, required this.spacing});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    for (double i = 0; i <= size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i <= size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Text block ───────────────────────────────────────────────────────────────
class _TextBlock extends StatelessWidget {
  final OnboardingPageModel pageData;
  final int index;
  final double titleSize;

  const _TextBlock({
    super.key,
    required this.pageData,
    required this.index,
    required this.titleSize,
  });

  @override
  Widget build(BuildContext context) {
    final s = Responsive.scale(context, 1);
    final accent = _kPageAccents[index.clamp(0, _kPageAccents.length - 1)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Tag pill
        _TagPill(label: pageData.tagLabel, color: accent)
            .animate()
            .fadeIn(delay: 0.ms, duration: 320.ms)
            .slideX(
              begin: -0.2,
              end: 0,
              duration: 320.ms,
              curve: Curves.easeOutCubic,
            ),

        SizedBox(height: 10 * s),

        // Title
        Text(
              pageData.title,
              style: TextStyle(
                color: Colors.white,
                fontSize: titleSize,
                fontWeight: FontWeight.w900,
                height: 1.08,
                letterSpacing: -1.5,
              ),
            )
            .animate()
            .fadeIn(delay: 70.ms, duration: 360.ms)
            .slideY(
              begin: 0.22,
              end: 0,
              duration: 360.ms,
              curve: Curves.easeOutCubic,
            ),

        SizedBox(height: 10 * s),

        // Description
        Text(
              pageData.description,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.74),
                fontSize: Responsive.bodyFontSize(context),
                height: 1.55,
              ),
            )
            .animate()
            .fadeIn(delay: 140.ms, duration: 360.ms)
            .slideY(
              begin: 0.18,
              end: 0,
              duration: 360.ms,
              curve: Curves.easeOutCubic,
            ),

        SizedBox(height: 14 * s),

        // Feature chips
        Wrap(
          spacing: 8 * s,
          runSpacing: 8 * s,
          children: pageData.features.asMap().entries.map((e) {
            return _FeatureChip(
              label: e.value,
              delay: Duration(milliseconds: 210 + e.key * 65),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─── Tag pill ─────────────────────────────────────────────────────────────────
class _TagPill extends StatelessWidget {
  final String label;
  final Color color;
  const _TagPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final s = Responsive.scale(context, 1);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 5 * s),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20 * s),
        border: Border.all(color: color.withValues(alpha: 0.38)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10.5 * s,
          fontWeight: FontWeight.w800,
          letterSpacing: 2.2,
        ),
      ),
    );
  }
}

// ─── Feature chip ─────────────────────────────────────────────────────────────
class _FeatureChip extends StatelessWidget {
  final String label;
  final Duration delay;
  const _FeatureChip({required this.label, required this.delay});

  @override
  Widget build(BuildContext context) {
    final s = Responsive.scale(context, 1);
    return Container(
          padding: EdgeInsets.symmetric(horizontal: 13 * s, vertical: 7 * s),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(20 * s),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.76),
              fontSize: 12 * s,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
        )
        .animate()
        .fadeIn(delay: delay, duration: 300.ms)
        .scale(
          begin: const Offset(0.80, 0.80),
          end: const Offset(1, 1),
          delay: delay,
          duration: 300.ms,
          curve: Curves.easeOutBack,
        );
  }
}

// ─── Step progress ────────────────────────────────────────────────────────────
class _StepProgress extends StatelessWidget {
  final int total;
  final int current;
  const _StepProgress({required this.total, required this.current});

  @override
  Widget build(BuildContext context) {
    final s = Responsive.scale(context, 1);
    return Row(
      children: List.generate(total, (i) {
        final isActive = i == current;
        final isDone = i < current;
        final lit = isActive || isDone;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
            margin: EdgeInsets.symmetric(horizontal: 3 * s),
            height: isActive ? 4 * s : 3 * s,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4 * s),
              color: lit ? _kAccent : Colors.white.withValues(alpha: 0.14),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: _kAccent.withValues(alpha: 0.6),
                        blurRadius: 8 * s,
                      ),
                    ]
                  : null,
            ),
          ),
        );
      }),
    );
  }
}

// ─── Gradient CTA button ──────────────────────────────────────────────────────
class _GradientButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _GradientButton({required this.label, required this.onTap});

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final s = Responsive.scale(context, 1);
    // Bug 6 Fix: Clamped button height
    final buttonHeight = (58 * s).clamp(52.0, 70.0);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Container(
          width: double.infinity,
          height: buttonHeight,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_kAccent, _kAccentDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16 * s),
            boxShadow: [
              BoxShadow(
                color: _kAccent.withValues(alpha: _pressed ? 0.18 : 0.40),
                blurRadius: _pressed ? 8 : 24,
                offset: Offset(0, _pressed ? 2 : 8) * s,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16 * s,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
              SizedBox(width: 8 * s),
              Icon(
                Icons.arrow_forward_rounded,
                color: Colors.black,
                size: 18 * s,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Top bar ──────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final OnboardingProvider provider;
  const _TopBar({required this.provider});

  @override
  Widget build(BuildContext context) {
    final s = Responsive.scale(context, 1);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Back button
        if (provider.currentPage > 0)
          _BlurredCircleButton(
            icon: Icons.arrow_back_rounded,
            onTap: provider.previous,
          )
        else
          const SizedBox.shrink(),

        // Skip button
        GestureDetector(
          onTap: () async {
            await context.read<AuthProvider>().markOnboardingSeen();
            if (context.mounted) context.go(AppRoutes.login);
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 18 * s,
              vertical: 8 * s,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10 * s),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Text(
              'SKIP',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 13 * s,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BlurredCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _BlurredCircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = Responsive.scale(context, 1);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44 * s,
        height: 44 * s,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10 * s),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 22 * s,
        ),
      ),
    );
  }
}
