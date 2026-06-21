import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../data/models/meal_log.dart';
import '../providers/nutrition_provider.dart';
import '../widgets/nutrition_colors.dart';
import '../widgets/food_portion_sheet.dart';

class BarcodeScannerScreen extends StatefulWidget {
  final MealType? preSelectedMeal;

  const BarcodeScannerScreen({super.key, this.preSelectedMeal});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: [BarcodeFormat.all],
  );

  bool _isProcessing = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty || barcodes.first.rawValue == null) return;

    final String code = barcodes.first.rawValue!;
    
    // Defer processing to avoid setState during the active build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isProcessing) {
        _processBarcode(code);
      }
    });
  }

  Future<void> _processBarcode(String code) async {
    setState(() {
      _isProcessing = true;
    });

    // Provide haptic feedback for successful scan
    HapticFeedback.vibrate();
    
    // Pause scanner while looking up
    _scannerController.stop();

    try {
      final provider = context.read<NutritionProvider>();
      final food = await provider.lookupBarcode(code);

      if (!mounted) return;

      if (food != null) {
        // Show the portion sheet
        final result = await showModalBottomSheet<Map<String, dynamic>>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => ChangeNotifierProvider.value(
            value: provider,
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
        );

        if (!mounted) return;

        if (result != null) {
          // Close scanner if logged
          Navigator.of(context).pop();
          // Update the state outside of the scanner's active tree
          provider.addFoodLog(
            result['meal'] as MealType, 
            food, 
            result['grams'] as double,
          );
        } else {
          // Restart scanner if cancelled
          setState(() {
            _isProcessing = false;
          });
          _scannerController.start();
        }
      } else {
        // Show not found dialog
        _showNotFoundDialog();
      }
    } catch (e) {
      if (mounted) {
        _showNotFoundDialog();
      }
    }
  }

  void _showNotFoundDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: NColors.bgSecondary(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: NColors.dangerAccent(context).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.close_circle,
                color: NColors.dangerAccent(context),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Food Not Found',
              style: GoogleFonts.inter(
                color: NColors.textPrimary(context),
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We couldn\'t find this barcode in our database. Try searching for the food manually.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: NColors.textSecondary(context),
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  setState(() {
                    _isProcessing = false;
                  });
                  _scannerController.start(); // Resume scanning
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: NColors.bgElevated(context),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Scan Another Item',
                  style: GoogleFonts.inter(
                    color: NColors.textPrimary(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close scanner
                },
                child: Text(
                  'Back to Search',
                  style: GoogleFonts.inter(
                    color: NColors.accentPrimary(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showManualEntryDialog() {
    _scannerController.stop();
    final TextEditingController controller = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: NColors.bgSecondary(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter Barcode Manually',
                style: GoogleFonts.montserrat(
                  color: NColors.textPrimary(context),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Type the numbers found under the barcode.',
                style: GoogleFonts.inter(
                  color: NColors.textSecondary(context),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: GoogleFonts.inter(color: NColors.textPrimary(context)),
                decoration: InputDecoration(
                  hintText: 'e.g. 04963406',
                  hintStyle: GoogleFonts.inter(color: NColors.textTertiary(context)),
                  filled: true,
                  fillColor: NColors.bgPrimary(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(Iconsax.barcode, color: NColors.textSecondary(context)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final text = controller.text.trim();
                    Navigator.pop(context);
                    if (text.isNotEmpty) {
                      _processBarcode(text);
                    } else {
                      _scannerController.start();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NColors.accentPrimary(context),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Search Product',
                    style: GoogleFonts.inter(
                      color: NColors.bgPrimary(context),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      color: NColors.textSecondary(context),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      if (!_isProcessing) {
        _scannerController.start();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera View
          MobileScanner(
            controller: _scannerController,
            onDetect: _handleBarcode,
          ),
          
          // Overlay
          CustomPaint(
            painter: _ScannerOverlayPainter(),
            child: const SizedBox.expand(),
          ),

          // Animated Scanning Line
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              final height = MediaQuery.of(context).size.height;
              // Scanner box is typically centered and ~300px tall
              final boxTop = (height - 250) / 2;
              return Positioned(
                top: boxTop + (_animationController.value * 250),
                left: 40,
                right: 40,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: NColors.accentPrimary(context),
                    boxShadow: [
                      BoxShadow(
                        color: NColors.accentPrimary(context).withValues(alpha: 0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                ),
              );
            },
          ),

          // Header / Controls
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close, color: Colors.white, size: 24),
                    ),
                  ),
                  // Flash Toggle
                  ValueListenableBuilder<MobileScannerState>(
                    valueListenable: _scannerController,
                    builder: (context, state, child) {
                      final isFlashOn = state.torchState == TorchState.on;
                      return GestureDetector(
                        onTap: () => _scannerController.toggleTorch(),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isFlashOn 
                                ? NColors.accentPrimary(context) 
                                : Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFlashOn ? Icons.flash_on : Icons.flash_off,
                            color: isFlashOn ? Colors.black : Colors.white,
                            size: 24,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Bottom Info Text
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Icon(
                  Iconsax.scan_barcode,
                  color: Colors.white70,
                  size: 32,
                ),
                const SizedBox(height: 16),
                Text(
                  'Align barcode within the frame to scan',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
                TextButton.icon(
                  onPressed: _showManualEntryDialog,
                  icon: Icon(Iconsax.edit, color: NColors.accentPrimary(context), size: 20),
                  label: Text(
                    'Enter Barcode Manually',
                    style: GoogleFonts.inter(
                      color: NColors.accentPrimary(context),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: NColors.accentPrimary(context).withValues(alpha: 0.1),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Loading Overlay
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: NColors.accentPrimary(context)),
                    const SizedBox(height: 24),
                    Text(
                      'Looking up food...',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;

    final double boxWidth = size.width - 80;
    const double boxHeight = 250;
    final double left = (size.width - boxWidth) / 2;
    final double top = (size.height - boxHeight) / 2;
    
    final RRect scanBox = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, boxWidth, boxHeight),
      const Radius.circular(16),
    );

    // Draw dark background with transparent cutout
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRRect(scanBox),
      ),
      backgroundPaint,
    );

    // Draw white corner brackets
    final bracketPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const double cornerLength = 30;

    // Top-Left
    canvas.drawPath(
      Path()
        ..moveTo(left, top + cornerLength)
        ..lineTo(left, top)
        ..lineTo(left + cornerLength, top),
      bracketPaint,
    );

    // Top-Right
    canvas.drawPath(
      Path()
        ..moveTo(left + boxWidth - cornerLength, top)
        ..lineTo(left + boxWidth, top)
        ..lineTo(left + boxWidth, top + cornerLength),
      bracketPaint,
    );

    // Bottom-Left
    canvas.drawPath(
      Path()
        ..moveTo(left, top + boxHeight - cornerLength)
        ..lineTo(left, top + boxHeight)
        ..lineTo(left + cornerLength, top + boxHeight),
      bracketPaint,
    );

    // Bottom-Right
    canvas.drawPath(
      Path()
        ..moveTo(left + boxWidth - cornerLength, top + boxHeight)
        ..lineTo(left + boxWidth, top + boxHeight)
        ..lineTo(left + boxWidth, top + boxHeight - cornerLength),
      bracketPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
