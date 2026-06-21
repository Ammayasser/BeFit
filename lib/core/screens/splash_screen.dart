import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../router/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _startTransition = false;
  bool _showContent = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // 1. Brief wait to ensure Flutter has painted the first frame
    await Future.delayed(const Duration(milliseconds: 500));
    
    // 2. Remove the native splash screen - Dart takes over now
    FlutterNativeSplash.remove();
    
    if (mounted) {
      setState(() => _showContent = true);
    }

    // 3. Cinematic Pause
    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (mounted) {
      setState(() => _startTransition = true);
    }

    // 4. Final Navigation
    await Future.delayed(const Duration(milliseconds: 1200));
    _navigate();
  }

  void _navigate() {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    
    if (auth.status == AuthStatus.authenticated) {
      context.go(AppRoutes.home);
    } else {
      context.go(
        auth.hasSeenOnboarding ? AppRoutes.login : AppRoutes.onboarding,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // In Light mode: Native splash is WHITE. We start WHITE and transition to app background.
    // In Dark mode: Native splash is DARK. We start DARK and transition to app background.
    final Color initialBg = isDark ? const Color(0xFF111318) : Colors.white;
    
    // Final color always matches app theme
    final Color targetBg = isDark ? const Color(0xFF111318) : const Color(0xFFF8FAFB);
    final Color textColor = isDark ? Colors.white : const Color(0xFF1A1D1C);
    final Color accentColor = const Color(0xFF4ADE80);

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeInOutExpo,
        color: _startTransition ? targetBg : initialBg,
        child: Stack(
          children: [
            // ─── Cinematic Background Elements ───────────────────────────────
            if (_startTransition)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.5,
                      colors: [
                        accentColor.withOpacity(isDark ? 0.05 : 0.03),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 800.ms),
              ),

            // ─── Main Content ────────────────────────────────────────────────
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo with Smooth Cinematic Scale
                  if (_showContent)
                    Hero(
                      tag: 'app_logo',
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(_startTransition ? (isDark ? 0.4 : 0.15) : 0.1),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: Image.asset(
                            'assets/images/app-logo/befit-logo.jpg',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    )
                    .animate()
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1.0, 1.0),
                      duration: 1000.ms,
                      curve: Curves.easeOutBack,
                    )
                    .then()
                    .animate(target: _startTransition ? 1 : 0)
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.1, 1.1),
                      duration: 800.ms,
                    ),

                  const SizedBox(height: 48),

                  // App Name with Elegant Reveal
                  if (_showContent)
                    Opacity(
                      opacity: _startTransition ? 1.0 : 0.0,
                      child: Text(
                        'BEFIT',
                        style: GoogleFonts.montserrat(
                          color: textColor,
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 12.0,
                        ),
                      ),
                    )
                    .animate(target: _startTransition ? 1 : 0)
                    .fadeIn(duration: 800.ms, delay: 200.ms)
                    .slideY(begin: 0.2, end: 0)
                    .shimmer(delay: 1000.ms, duration: 1500.ms, color: accentColor.withOpacity(0.4)),

                  const SizedBox(height: 12),

                  // Tagline
                  if (_showContent)
                    Opacity(
                      opacity: _startTransition ? 1.0 : 0.0,
                      child: Text(
                        'ELITE PERSONAL TRAINING',
                        style: GoogleFonts.inter(
                          color: textColor.withOpacity(0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 3.0,
                        ),
                      ),
                    )
                    .animate(target: _startTransition ? 1 : 0)
                    .fadeIn(duration: 800.ms, delay: 400.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
