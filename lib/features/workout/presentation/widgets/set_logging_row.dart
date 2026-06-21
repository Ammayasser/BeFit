import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import '../../core/workout_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/primary_button.dart';

class SetLoggingRow extends StatefulWidget {
  final double initialWeight;
  final int initialReps;
  final bool useKg;
  final Function(double weight, int reps) onLog;

  const SetLoggingRow({
    super.key,
    required this.initialWeight,
    required this.initialReps,
    required this.useKg,
    required this.onLog,
  });

  @override
  State<SetLoggingRow> createState() => _SetLoggingRowState();
}

class _SetLoggingRowState extends State<SetLoggingRow> {
  late double _weight;
  late int _reps;

  @override
  void initState() {
    super.initState();
    _weight = widget.initialWeight;
    _reps = widget.initialReps;
  }

  void _adjustWeight(double delta) {
    setState(() {
      _weight = (_weight + delta).clamp(0, 500);
    });
  }

  void _adjustReps(int delta) {
    setState(() {
      _reps = (_reps + delta).clamp(0, 100);
    });
  }

  void _showNumericKeypad(bool isWeight) {
    final controller = TextEditingController(
      text: isWeight ? _weight.toStringAsFixed(1) : _reps.toString(),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: WorkoutColors.surfaceMuted(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isWeight ? "Enter Weight (${widget.useKg ? 'kg' : 'lbs'})" : "Enter Repetitions",
                style: GoogleFonts.montserrat(
                  color: WorkoutColors.onSurface(context),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: GoogleFonts.jetBrainsMono(color: WorkoutColors.onSurface(context), fontSize: 24),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: WorkoutColors.card(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                text: "Save",
                onPressed: () {
                  final val = double.tryParse(controller.text);
                  if (val != null) {
                    setState(() {
                      if (isWeight) {
                        _weight = val;
                      } else {
                        _reps = val.toInt();
                      }
                    });
                  }
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md.toDouble(),
        vertical: AppSpacing.md.toDouble(),
      ),
      decoration: BoxDecoration(
        color: WorkoutColors.card(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: WorkoutColors.border(context)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Weight Control
              Expanded(
                child: Column(
                  children: [
                    Text(
                      "WEIGHT",
                      style: GoogleFonts.montserrat(
                        color: WorkoutColors.onSurfaceMuted(context),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildAdjustButton(
                          icon: Icons.remove,
                          onPressed: () => _adjustWeight(widget.useKg ? -2.5 : -5.0),
                        ),
                        Flexible(
                          child: GestureDetector(
                            onTap: () => _showNumericKeypad(true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              alignment: Alignment.center,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  textBaseline: TextBaseline.alphabetic,
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  children: [
                                    Text(
                                      _weight.toStringAsFixed(1),
                                      style: GoogleFonts.jetBrainsMono(
                                        color: WorkoutColors.onSurface(context),
                                        fontSize: 28, // Slightly smaller base size
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      widget.useKg ? "kg" : "lbs",
                                      style: GoogleFonts.montserrat(
                                        color: WorkoutColors.onSurfaceMuted(context),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        _buildAdjustButton(
                          icon: Icons.add,
                          onPressed: () => _adjustWeight(widget.useKg ? 2.5 : 5.0),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Separator
              Container(
                width: 1,
                height: 50,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: WorkoutColors.border(context),
              ),
              // Reps Control
              Expanded(
                child: Column(
                  children: [
                    Text(
                      "REPS",
                      style: GoogleFonts.montserrat(
                        color: WorkoutColors.onSurfaceMuted(context),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildAdjustButton(
                          icon: Icons.remove,
                          onPressed: () => _adjustReps(-1),
                        ),
                        Flexible(
                          child: GestureDetector(
                            onTap: () => _showNumericKeypad(false),
                            child: Container(
                              alignment: Alignment.center,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  "$_reps",
                                  style: GoogleFonts.jetBrainsMono(
                                    color: WorkoutColors.onSurface(context),
                                    fontSize: 28, // Slightly smaller base size
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        _buildAdjustButton(
                          icon: Icons.add,
                          onPressed: () => _adjustReps(1),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Log Set Button
          PrimaryButton(
            text: "Log Set",
            onPressed: () => widget.onLog(_weight, _reps),
            isFullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAdjustButton({required IconData icon, required VoidCallback onPressed}) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Material(
        color: WorkoutColors.surfaceMuted(context),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Icon(
            icon,
            color: WorkoutColors.onSurface(context),
            size: 20,
          ),
        ),
      ),
    );
  }
}
