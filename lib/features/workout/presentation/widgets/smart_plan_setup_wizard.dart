// lib/features/workout/presentation/widgets/smart_plan_setup_wizard.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../core/workout_colors.dart';
import '../../../profile/presentation/providers/user_provider.dart';

class SmartPlanSetupWizard extends StatefulWidget {
  final Function(Map<String, dynamic> data) onComplete;

  const SmartPlanSetupWizard({super.key, required this.onComplete});

  @override
  State<SmartPlanSetupWizard> createState() => _SmartPlanSetupWizardState();
}

class _SmartPlanSetupWizardState extends State<SmartPlanSetupWizard> {
  int _currentStep = 0;
  
  // Data collected
  late String _goal;
  late String _experience;
  late String _location;
  int _daysPerWeek = 3;
  int _sessionDuration = 60;

  @override
  void initState() {
    super.initState();
    final user = context.read<UserProvider>();
    _goal = user.fitnessGoal.isNotEmpty ? user.fitnessGoal : 'StayFit';
    _experience = user.experienceLevel.isNotEmpty ? user.experienceLevel : 'Beginner';
    _location = user.workoutLocation.isNotEmpty ? user.workoutLocation : 'Gym';
    _daysPerWeek = user.workoutDays > 0 ? user.workoutDays : 3;
  }

  void _next() {
    if (_currentStep < 4) {
      setState(() => _currentStep++);
    } else {
      widget.onComplete({
        'goal': _goal,
        'experience': _experience,
        'location': _location,
        'daysPerWeek': _daysPerWeek,
        'duration': _sessionDuration,
      });
    }
  }

  void _back() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: WorkoutColors.scaffold(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Progress Indicator ────────────────────────────────────────────
          Row(
            children: List.generate(5, (index) => Expanded(
              child: Container(
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: index <= _currentStep ? WorkoutColors.lime(context) : WorkoutColors.border(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            )),
          ),
          const SizedBox(height: 32),
          
          // ─── Step Content ──────────────────────────────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildStepContent(),
          ),
          
          const SizedBox(height: 40),
          
          // ─── Navigation ────────────────────────────────────────────────────
          Row(
            children: [
              if (_currentStep > 0)
                IconButton(
                  onPressed: _back,
                  icon: Icon(Icons.arrow_back_ios_new_rounded),
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: WorkoutColors.card(context),
                  ),
                ),
              if (_currentStep > 0) const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WorkoutColors.lime(context),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    _currentStep == 4 ? 'Generate My Plan' : 'Continue',
                    style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _StepSelector(
          key: const ValueKey(0),
          title: 'What is your main goal?',
          options: const [
            {'value': 'LoseWeight', 'label': 'Lose Weight', 'icon': Iconsax.weight},
            {'value': 'BuildMuscle', 'label': 'Build Muscle', 'icon': Iconsax.strongbox},
            {'value': 'StayFit', 'label': 'Get Fit & Toned', 'icon': Iconsax.heart},
          ],
          selectedValue: _goal,
          onSelect: (v) => setState(() => _goal = v),
        );
      case 1:
        return _StepSelector(
          key: const ValueKey(1),
          title: 'Your experience level?',
          options: const [
            {'value': 'Beginner', 'label': 'Beginner', 'icon': Iconsax.flash_1},
            {'value': 'Intermediate', 'label': 'Intermediate', 'icon': Iconsax.flash_circle},
            {'value': 'Advanced', 'label': 'Advanced', 'icon': Iconsax.flash},
          ],
          selectedValue: _experience,
          onSelect: (v) => setState(() => _experience = v),
        );
      case 2:
        return _StepSelector(
          key: const ValueKey(2),
          title: 'Where will you workout?',
          options: const [
            {'value': 'Gym', 'label': 'Commercial Gym', 'icon': Iconsax.building},
            {'value': 'Home', 'label': 'Home (No Equipment)', 'icon': Iconsax.home},
            {'value': 'HomeDumbbells', 'label': 'Home (Dumbbells)', 'icon': Iconsax.weight},
          ],
          selectedValue: _location,
          onSelect: (v) => setState(() => _location = v),
        );
      case 3:
        return Column(
          key: const ValueKey(3),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How many days per week?', style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(5, (index) {
                final d = index + 2; // 2 to 6 days
                final isSelected = _daysPerWeek == d;
                return GestureDetector(
                  onTap: () => setState(() => _daysPerWeek = d),
                  child: Container(
                    width: 55,
                    height: 55,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? WorkoutColors.lime(context) : WorkoutColors.card(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isSelected ? WorkoutColors.lime(context) : WorkoutColors.border(context)),
                    ),
                    child: Text('$d', style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w900, color: isSelected ? Colors.black : WorkoutColors.onSurface(context))),
                  ),
                );
              }),
            ),
          ],
        );
      case 4:
        return Column(
          key: const ValueKey(4),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Session duration?', style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 24),
            _DurationOption(label: 'Quick (30 min)', value: 30, selectedValue: _sessionDuration, onSelect: (v) => setState(() => _sessionDuration = v)),
            const SizedBox(height: 12),
            _DurationOption(label: 'Standard (60 min)', value: 60, selectedValue: _sessionDuration, onSelect: (v) => setState(() => _sessionDuration = v)),
            const SizedBox(height: 12),
            _DurationOption(label: 'Intense (90 min)', value: 90, selectedValue: _sessionDuration, onSelect: (v) => setState(() => _sessionDuration = v)),
          ],
        );
      default:
        return const SizedBox();
    }
  }
}

class _StepSelector extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> options;
  final String selectedValue;
  final Function(String) onSelect;

  const _StepSelector({required this.title, required this.options, required this.selectedValue, required this.onSelect, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 24),
        ...options.map((opt) {
          final isSelected = selectedValue == opt['value'];
          return GestureDetector(
            onTap: () => onSelect(opt['value']),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isSelected ? WorkoutColors.lime(context).withValues(alpha: 0.1) : WorkoutColors.card(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? WorkoutColors.lime(context) : WorkoutColors.border(context)),
              ),
              child: Row(
                children: [
                  Icon(opt['icon'], color: isSelected ? WorkoutColors.lime(context) : WorkoutColors.onSurfaceMuted(context)),
                  const SizedBox(width: 16),
                  Text(opt['label'], style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w700, color: isSelected ? WorkoutColors.lime(context) : WorkoutColors.onSurface(context))),
                  const Spacer(),
                  if (isSelected) Icon(Icons.check_circle_rounded, color: WorkoutColors.lime(context)),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _DurationOption extends StatelessWidget {
  final String label;
  final int value;
  final int selectedValue;
  final Function(int) onSelect;

  const _DurationOption({required this.label, required this.value, required this.selectedValue, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selectedValue;
    return GestureDetector(
      onTap: () => onSelect(value),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? WorkoutColors.lime(context).withValues(alpha: 0.1) : WorkoutColors.card(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? WorkoutColors.lime(context) : WorkoutColors.border(context)),
        ),
        child: Row(
          children: [
            Text(label, style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w700, color: isSelected ? WorkoutColors.lime(context) : WorkoutColors.onSurface(context))),
            const Spacer(),
            if (isSelected) Icon(Icons.check_circle_rounded, color: WorkoutColors.lime(context)),
          ],
        ),
      ),
    );
  }
}
