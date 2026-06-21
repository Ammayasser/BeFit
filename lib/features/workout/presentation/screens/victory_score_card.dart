import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'victory_colors.dart';
import 'victory_rank_badge.dart';
import 'victory_mood_selector.dart';

class VictoryScoreCard extends StatefulWidget {
  final double totalVolume;
  final int totalSets;
  final int totalReps;
  final List<String> trainedMuscles;
  final WorkoutRank rank;
  final String rankLabel;
  final int initialMood;
  final Function(int mood, String note) onSave;
  final bool isSaving;

  const VictoryScoreCard({
    super.key,
    required this.totalVolume,
    required this.totalSets,
    required this.totalReps,
    required this.trainedMuscles,
    required this.rank,
    required this.rankLabel,
    this.initialMood = 3,
    required this.onSave,
    this.isSaving = false,
  });

  @override
  State<VictoryScoreCard> createState() => _VictoryScoreCardState();
}

class _VictoryScoreCardState extends State<VictoryScoreCard> {
  late int _selectedMood;
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedMood = widget.initialMood;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
      decoration: BoxDecoration(
        color: VictoryColors.background.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: VictoryColors.border.withValues(alpha: 0.5), width: 1),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('VOLUME', '${widget.totalVolume.toInt()}kg'),
                _buildDivider(),
                _buildStat('SETS', '${widget.totalSets}'),
                _buildDivider(),
                _buildStat('REPS', '${widget.totalReps}'),
              ],
            ).animate().fadeIn(duration: 800.ms),

            const SizedBox(height: 24),
            const Divider(color: VictoryColors.border, thickness: 1),
            const SizedBox(height: 24),

            // Muscles Section
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${widget.trainedMuscles.length} MUSCLES TRAINED',
                style: GoogleFonts.montserrat(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: VictoryColors.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.trainedMuscles.map((m) => _buildMuscleChip(m)).toList(),
            ),

            const SizedBox(height: 32),

            // Rank Badge
            VictoryRankBadge(rank: widget.rank, label: widget.rankLabel),

            const SizedBox(height: 32),

            // Mood Selector
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'HOW DID IT FEEL?',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: VictoryColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            VictoryMoodSelector(
              selectedMood: _selectedMood,
              onMoodSelected: (m) => setState(() => _selectedMood = m),
            ),

            const SizedBox(height: 24),

            // Notes Field
            TextField(
              controller: _noteController,
              maxLines: null,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Add a note about this workout...',
                hintStyle: GoogleFonts.inter(color: VictoryColors.textMuted),
                filled: true,
                fillColor: VictoryColors.backgroundCard,
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: VictoryColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: VictoryColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: VictoryColors.accent),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: widget.isSaving ? null : () => widget.onSave(_selectedMood, _noteController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: VictoryColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: widget.isSaving
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        'SAVE & CONTINUE',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ).animate().custom(
          duration: VictoryColors.countingDuration,
          builder: (context, val, child) => Text(
            value, // In a real app we'd animate the number here
            style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: VictoryColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 30, color: VictoryColors.border);
  }

  Widget _buildMuscleChip(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: VictoryColors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: VictoryColors.accent.withValues(alpha: 0.3)),
      ),
      child: Text(
        name.toUpperCase(),
        style: GoogleFonts.montserrat(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: VictoryColors.accent,
        ),
      ),
    );
  }
}
