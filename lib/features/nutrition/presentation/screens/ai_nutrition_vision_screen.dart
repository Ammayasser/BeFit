// lib/features/nutrition/presentation/screens/ai_nutrition_vision_screen.dart

import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:befit/core/services/ai_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../data/models/food_item.dart';
import '../../data/models/meal_log.dart';
import '../providers/nutrition_provider.dart';
import '../widgets/nutrition_colors.dart';
import '../widgets/food_portion_sheet.dart';

import '../widgets/nutrition_ui_utils.dart';

class AINutritionVisionScreen extends StatefulWidget {
  final MealType? preSelectedMeal;

  const AINutritionVisionScreen({super.key, this.preSelectedMeal});

  @override
  State<AINutritionVisionScreen> createState() =>
      _AINutritionVisionScreenState();
}

class _AINutritionVisionScreenState extends State<AINutritionVisionScreen> {
  final ImagePicker _picker = ImagePicker();
  final AIService _aiService = AIService();
  bool _isProcessing = false;
  File? _pickedImage;

  Future<void> _captureAndAnalyze(ImageSource source) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (photo == null) return;

      setState(() {
        _pickedImage = File(photo.path);
        _isProcessing = true;
      });

      final bytes = await photo.readAsBytes();
      final base64Image = base64Encode(bytes);

      final result = await _aiService.analyzeMealImage(base64Image);

      if (!mounted) return;

      if (result != null) {
        if (result['error'] == null) {
          final food = FoodItem(
            id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
            name: result['food_name'] ?? 'Analyzed Meal',
            caloriesPer100g:
                (result['calories_per_100g'] as num?)?.toDouble() ?? 0,
            proteinPer100g:
                (result['protein_per_100g'] as num?)?.toDouble() ?? 0,
            carbsPer100g: (result['carbs_per_100g'] as num?)?.toDouble() ?? 0,
            fatPer100g: (result['fat_per_100g'] as num?)?.toDouble() ?? 0,
            servingSize: '1 serving',
            servingGrams: (result['serving_grams'] as num?)?.toDouble() ?? 250,
          );

          setState(() => _isProcessing = false);

          // Show result in the portion sheet
          _showPortionSheet(food);
        } else {
          setState(() => _isProcessing = false);

          String message;
          Color bgColor = Colors.orange;
          final errType = result['error'];
          final errMsg = result['message'];

          switch (errType) {
            case 'safety_blocked':
            case 'prompt_blocked':
              message = 'Content filtered by AI safety rules.';
              break;
            case 'http_error':
              final status = result['status'];
              message = 'API Error ($status). ';
              if (status == 403 || status == 400) {
                message += 'Check API Key or request format.';
              } else if (status == 429) {
                message += 'Daily quota exceeded. Please try again tomorrow.';
              } else {
                message += errMsg ?? 'Server error.';
              }
              bgColor = Colors.redAccent;
              break;
            case 'parse_error':
              message = errMsg ?? 'Failed to parse AI response.';
              bgColor = Colors.redAccent;
              break;
            case 'exception':
              message = errMsg ?? 'Connection error. Check your internet.';
              bgColor = Colors.redAccent;
              break;
            case 'not_a_meal':
              message = 'Could not identify a meal in this photo.';
              break;
            default:
              message = errMsg ?? 'Analysis failed: $errType';
              bgColor = Colors.redAccent;
          }

          NutritionUi.showInfoSnackBar(
            context,
            message,
            color: bgColor,
            icon: bgColor == Colors.redAccent ? Iconsax.info_circle : Iconsax.warning_2,
          );
        }
      } else {
        setState(() {
          _isProcessing = false;
        });
        NutritionUi.showErrorSnackBar(
          context,
          'Technical error: AI Service returned no data. Check your connection.',
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      NutritionUi.showErrorSnackBar(context, 'Error: $e');
    }
  }

  void _showPortionSheet(FoodItem food) {
    showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<NutritionProvider>(),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: FoodPortionSheet(
            food: food,
            preSelectedMeal: widget.preSelectedMeal,
          ),
        ),
      ),
    ).then((result) {
      if (result is Map && result?['success'] == true && mounted) {
        // Wait for the sheet animation to finish fully
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NColors.bgPrimary(context),
      extendBodyBehindAppBar: _isProcessing,
      appBar: AppBar(
        title: Text(
          'AI Vision',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w800,
            color: _isProcessing ? Colors.white : NColors.textPrimary(context),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _isProcessing ? Colors.white : NColors.textPrimary(context),
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isProcessing && _pickedImage != null
          ? _ModernAiScanner(imageFile: _pickedImage!)
          : _buildCaptureUI(),
    );
  }

  Widget _buildCaptureUI() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: NColors.accentPrimary(context).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.camera,
                size: 64,
                color: NColors.accentPrimary(context),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Snapshot your meal',
              style: GoogleFonts.montserrat(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: NColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Our AI will estimate the calories and macros automatically from your photo.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: NColors.textSecondary(context),
              ),
            ),
            const SizedBox(height: 48),
            _ActionButton(
              icon: Iconsax.camera,
              label: 'Take Photo',
              color: NColors.accentPrimary(context),
              onTap: () => _captureAndAnalyze(ImageSource.camera),
            ),
            const SizedBox(height: 16),
            _ActionButton(
              icon: Iconsax.image,
              label: 'Choose from Gallery',
              color: NColors.textPrimary(context),
              isOutlined: true,
              onTap: () => _captureAndAnalyze(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModernAiScanner extends StatefulWidget {
  final File imageFile;
  const _ModernAiScanner({required this.imageFile});

  @override
  State<_ModernAiScanner> createState() => _ModernAiScannerState();
}

class _ModernAiScannerState extends State<_ModernAiScanner> {
  final List<String> _statuses = [
    'Initializing AI Vision...',
    'Analyzing Plate Geometry...',
    'Extracting Food Features...',
    'Identifying Ingredients...',
    'Estimating Portion Volume...',
    'Calculating Macros...',
  ];

  late final Stream<int> _timer;

  @override
  void initState() {
    super.initState();
    _timer = Stream.periodic(
      const Duration(milliseconds: 2000),
      (i) => (i + 1) % _statuses.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background Image with subtle blur
        Image.file(widget.imageFile, fit: BoxFit.cover),

        // Sophisticated Vignette & Blur
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.8,
                  colors: [
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Central "AI Focal Point"
        Center(child: _AIFocalPoint(color: NColors.accentPrimary(context))),

        // Animated Scanning Line (More subtle)
        const _SubtleScannerLine(),

        // Bottom Glassmorphic Status Card
        Positioned(
          left: 20,
          right: 20,
          bottom: 40,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [_GlassStatusCard(statuses: _statuses, timer: _timer)],
          ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.2, end: 0),
        ),
      ],
    );
  }
}

class _AIFocalPoint extends StatelessWidget {
  final Color color;
  const _AIFocalPoint({required this.color});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulsing outer ring
        Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
              ),
            )
            .animate(onPlay: (c) => c.repeat())
            .scale(
              duration: 2.seconds,
              begin: const Offset(1, 1),
              end: const Offset(1.5, 1.5),
            )
            .fadeOut(),

        // Scanning brackets
        SizedBox(
          width: 200,
          height: 200,
          child: CustomPaint(painter: _BracketsPainter(color: color)),
        ).animate(onPlay: (c) => c.repeat()).rotate(duration: 10.seconds),

        // Core dot
        Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
            )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(
              duration: 1.seconds,
              begin: const Offset(0.8, 0.8),
              end: const Offset(1.2, 1.2),
            ),
      ],
    );
  }
}

class _BracketsPainter extends CustomPainter {
  final Color color;
  _BracketsPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const len = 20.0;
    // Top Left
    canvas.drawLine(const Offset(0, 0), const Offset(len, 0), p);
    canvas.drawLine(const Offset(0, 0), const Offset(0, len), p);

    // Top Right
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - len, 0), p);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, len), p);

    // Bottom Left
    canvas.drawLine(Offset(0, size.height), Offset(len, size.height), p);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - len), p);

    // Bottom Right
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width - len, size.height),
      p,
    );
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width, size.height - len),
      p,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SubtleScannerLine extends StatefulWidget {
  const _SubtleScannerLine();

  @override
  State<_SubtleScannerLine> createState() => _SubtleScannerLineState();
}

class _SubtleScannerLineState extends State<_SubtleScannerLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: 4.seconds)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Positioned(
          top: MediaQuery.of(context).size.height * _ctrl.value,
          left: 0,
          right: 0,
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  NColors.accentPrimary(context).withValues(alpha: 0),
                  NColors.accentPrimary(context).withValues(alpha: 0.5),
                  NColors.accentPrimary(context),
                  NColors.accentPrimary(context).withValues(alpha: 0.5),
                  NColors.accentPrimary(context).withValues(alpha: 0),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: NColors.accentPrimary(context).withValues(alpha: 0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GlassStatusCard extends StatelessWidget {
  final List<String> statuses;
  final Stream<int> timer;

  const _GlassStatusCard({required this.statuses, required this.timer});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'AI VISION PROCESSING',
                    style: GoogleFonts.montserrat(
                      color: NColors.accentPrimary(context),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const _LoadingDots(),
                ],
              ),
              const SizedBox(height: 20),
              StreamBuilder<int>(
                stream: timer,
                initialData: 0,
                builder: (context, snapshot) {
                  final idx = snapshot.data ?? 0;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedSwitcher(
                        duration: 400.ms,
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: animation.drive(
                                Tween<Offset>(
                                  begin: const Offset(0, 0.2),
                                  end: Offset.zero,
                                ),
                              ),
                              child: child,
                            ),
                          );
                        },
                        child: Text(
                          statuses[idx],
                          key: ValueKey(idx),
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Modern Progress Bar
                      Stack(
                        children: [
                          Container(
                            height: 6,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          AnimatedContainer(
                            duration: 2000.ms,
                            height: 6,
                            width:
                                MediaQuery.of(context).size.width *
                                ((idx + 1) / statuses.length),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  NColors.accentPrimary(context),
                                  NColors.accentPrimary(
                                    context,
                                  ).withValues(alpha: 0.7),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(3),
                              boxShadow: [
                                BoxShadow(
                                  color: NColors.accentPrimary(
                                    context,
                                  ).withValues(alpha: 0.4),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingDots extends StatefulWidget {
  const _LoadingDots();

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Container(
              width: 4,
              height: 4,
              margin: const EdgeInsets.only(left: 3),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            )
            .animate(onPlay: (c) => c.repeat())
            .fadeIn(delay: (index * 200).ms, duration: 600.ms)
            .then()
            .fadeOut(duration: 600.ms);
      }),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isOutlined;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: isOutlined ? Colors.transparent : color,
          foregroundColor: isOutlined ? color : Colors.white,
          elevation: isOutlined ? 0 : 4,
          side: isOutlined ? BorderSide(color: color, width: 2) : null,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
