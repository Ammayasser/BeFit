// lib/features/nutrition/presentation/widgets/custom_water_amount_sheet.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomWaterAmountSheet extends StatefulWidget {
  final Color glassBorder;
  final Color muted;
  final Color accent;

  const CustomWaterAmountSheet({
    super.key,
    required this.glassBorder,
    required this.muted,
    required this.accent,
  });

  @override
  State<CustomWaterAmountSheet> createState() => _CustomWaterAmountSheetState();
}

class _CustomWaterAmountSheetState extends State<CustomWaterAmountSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
          decoration: BoxDecoration(
            color: const Color(0xFF151B24),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: widget.glassBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Custom amount',
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Enter milliliters (50–2000)',
                style: GoogleFonts.inter(
                  color: widget.muted,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                maxLines: 1,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
                cursorColor: widget.accent,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  hintText: 'e.g. 350',
                  hintStyle: GoogleFonts.inter(color: widget.muted),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: widget.accent, width: 1.5),
                  ),
                  suffixText: 'ml',
                  suffixStyle: GoogleFonts.inter(color: widget.muted),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: widget.muted,
                        side: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        final v = int.tryParse(_controller.text.trim());
                        if (v == null || v < 50 || v > 2000) return;
                        Navigator.pop(context, v);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: widget.accent,
                        foregroundColor: const Color(0xFF0B1220),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Add',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
