import 'package:flutter/material.dart';
import '../../core/workout_colors.dart';
import 'package:go_router/go_router.dart';
import '../widgets/workout_ui.dart';

class WorkoutFiltersScreen extends StatefulWidget {
  const WorkoutFiltersScreen({super.key});

  @override
  State<WorkoutFiltersScreen> createState() => _WorkoutFiltersScreenState();
}

class _WorkoutFiltersScreenState extends State<WorkoutFiltersScreen> {
  String? _duration;
  final Set<String> _difficulties = {};
  final Set<String> _equipment = {};

  int get _activeCount =>
      (_duration != null ? 1 : 0) + _difficulties.length + _equipment.length;

  void _clearAll() {
    setState(() {
      _duration = null;
      _difficulties.clear();
      _equipment.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return WorkoutLightScaffold(
      appBar: AppBar(
        backgroundColor: WorkoutColors.scaffold(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: WorkoutColors.onSurface(context)),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Filters',
          style: workoutTextStyle(context, size: 18, weight: FontWeight.w700),
        ),
        actions: [
          TextButton(
            onPressed: _clearAll,
            child: Text(
              'Clear All',
              style: workoutTextStyle(
                context,
                size: 14,
                weight: FontWeight.w600,
                color: WorkoutColors.onSurfaceMuted(context),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _sectionTitle(context, 'Duration'),
          ...['15 min', '30 min', '45 min', '60+ min'].map(
            (d) => _radioTile(
              context,
              d,
              _duration == d,
              () => setState(() => _duration = d),
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle(context, 'Difficulty'),
          ...['Beginner', 'Intermediate', 'Advanced'].map(
            (d) => _checkTile(context, d, _difficulties.contains(d), () {
              setState(() {
                if (_difficulties.contains(d)) {
                  _difficulties.remove(d);
                } else {
                  _difficulties.add(d);
                }
              });
            }),
          ),
          const SizedBox(height: 24),
          _sectionTitle(context, 'Equipment'),
          ...['Dumbbell', 'Barbell', 'Bench', 'Mat', 'None'].map(
            (e) => _checkTile(context, e, _equipment.contains(e), () {
              setState(() {
                if (_equipment.contains(e)) {
                  _equipment.remove(e);
                } else {
                  _equipment.add(e);
                }
              });
            }),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: WorkoutPrimaryButton(
            label: _activeCount > 0
                ? 'Apply Filters ($_activeCount)'
                : 'Apply Filters',
            onPressed: () => context.pop({
              'duration': _duration,
              'difficulties': _difficulties.toList(),
              'equipment': _equipment.toList(),
            }),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String t) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      t,
      style: workoutTextStyle(context, size: 16, weight: FontWeight.w700),
    ),
  );

  Widget _radioTile(
    BuildContext context,
    String label,
    bool selected,
    VoidCallback onTap,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: workoutTextStyle(context, size: 15)),
      trailing: Radio<String>(
        value: label,
        groupValue: selected ? label : null,
        activeColor: WorkoutColors.lime(context),
        onChanged: (_) => onTap(),
      ),
      onTap: onTap,
    );
  }

  Widget _checkTile(
    BuildContext context,
    String label,
    bool selected,
    VoidCallback onTap,
  ) {
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: workoutTextStyle(context, size: 15)),
      value: selected,
      activeColor: WorkoutColors.lime(context),
      checkColor: Colors.black,
      onChanged: (_) => onTap(),
      controlAffinity: ListTileControlAffinity.trailing,
    );
  }
}
