import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/theme/befit_theme_extension.dart';
import '../../core/workout_user_resolver.dart';
import '../widgets/workout_screen/workout_hub_shared.dart';
import '../../data/models/custom_program_models.dart';
import '../providers/custom_program_provider.dart';

class CustomProgramsScreen extends StatefulWidget {
  const CustomProgramsScreen({super.key});

  @override
  State<CustomProgramsScreen> createState() => _CustomProgramsScreenState();
}

class _CustomProgramsScreenState extends State<CustomProgramsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final userId = WorkoutUserResolver.resolve(context);
    context.read<CustomProgramProvider>().loadPrograms(userId);
  }

  @override
  Widget build(BuildContext context) {
    final s = Responsive.scale(context, 1);
    final fs = Responsive.fontScale(context, 1);
    final colors = context.customColors;

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      body: Consumer<CustomProgramProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.programs.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return CustomScrollView(
            slivers: [
              _buildAppBar(context, s, fs),
              if (provider.programs.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(context, s, fs),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.symmetric(vertical: 20 * s),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final program = provider.programs[index];
                      return ProgramListCard(program: program);
                    }, childCount: provider.programs.length),
                  ),
                ),
              if (provider.programs.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20 * s, 0, 20 * s, 40 * s),
                    child: _buildCreateNewButton(context, s, fs),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, double s, double fs) {
    final colors = context.customColors;
    return SliverAppBar(
      pinned: true,
      expandedHeight: 130 * s,
      backgroundColor: colors.bgPrimary,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.setupTextPrimary),
        onPressed: () => context.pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: EdgeInsets.only(left: 20 * s, bottom: 16 * s),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Programs',
              style: GoogleFonts.montserrat(
                fontSize: 20 * fs,
                fontWeight: FontWeight.w800,
                color: colors.setupTextPrimary,
              ),
            ),
            Text(
              'Your training systems',
              style: GoogleFonts.inter(
                fontSize: 11 * fs,
                fontWeight: FontWeight.w500,
                color: colors.setupTextSecondary,
              ),
            ),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: 8 * s),
          child: IconButton(
            onPressed: () => _showCreateSheet(context),
            icon: Container(
              padding: EdgeInsets.all(6 * s),
              decoration: BoxDecoration(
                color: colors.setupPrimary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Iconsax.add, color: colors.setupPrimary, size: 22 * s),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, double s, double fs) {
    final colors = context.customColors;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 90 * s,
          height: 90 * s,
          decoration: BoxDecoration(
            color: colors.setupPrimary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Iconsax.calendar_1,
            color: colors.setupPrimary,
            size: 40 * s,
          ),
        ),
        SizedBox(height: 24 * s),
        Text(
          'No programs yet',
          style: GoogleFonts.montserrat(
            fontSize: 22 * fs,
            fontWeight: FontWeight.w800,
            color: colors.setupTextPrimary,
          ),
        ),
        SizedBox(height: 8 * s),
        Text(
          'Build your first multi-week training program',
          style: GoogleFonts.inter(
            fontSize: 14 * fs,
            color: colors.setupTextSecondary,
          ),
        ),
        SizedBox(height: 32 * s),
        ElevatedButton(
          onPressed: () => _showCreateSheet(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.setupPrimary,
            foregroundColor: colors.setupOnPrimary,
            padding: EdgeInsets.symmetric(horizontal: 24 * s, vertical: 12 * s),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Create Program',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildCreateNewButton(BuildContext context, double s, double fs) {
    final colors = context.customColors;
    return InkWell(
      onTap: () => _showCreateSheet(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16 * s),
        decoration: BoxDecoration(
          border: Border.all(
            color: colors.border,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.add_circle, color: colors.setupPrimary, size: 20 * s),
            SizedBox(width: 8 * s),
            Text(
              'Create New Program',
              style: GoogleFonts.montserrat(
                fontSize: 14 * fs,
                fontWeight: FontWeight.w700,
                color: colors.setupPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 550),
      builder: (context) => const CreateProgramSheet(),
    );
  }
}

class ProgramListCard extends StatelessWidget {
  final CustomProgram program;

  const ProgramListCard({super.key, required this.program});

  @override
  Widget build(BuildContext context) {
    final s = Responsive.scale(context, 1);
    final fs = Responsive.fontScale(context, 1);
    final colors = context.customColors;

    return Container(
      margin: EdgeInsets.fromLTRB(20 * s, 0, 20 * s, 16 * s),
      decoration: BoxDecoration(
        color: colors.bgSecondary,
        borderRadius: BorderRadius.circular(24 * s),
        border: Border.all(color: colors.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 15 * s,
            offset: Offset(0, 8 * s),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24 * s),
        onTap: () => context.push('${AppRoutes.customPrograms}/${program.id}'),
        child: Padding(
          padding: EdgeInsets.all(20 * s),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 56 * s,
                    height: 56 * s,
                    decoration: BoxDecoration(
                      color: colors.surfaceCard,
                      borderRadius: BorderRadius.circular(18 * s),
                      border: Border.all(color: colors.border.withValues(alpha: 0.5)),
                    ),
                    child: Center(
                      child: Text(
                        program.emoji ?? '💪',
                        style: TextStyle(fontSize: 28 * s),
                      ),
                    ),
                  ),
                  SizedBox(width: 16 * s),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          program.name,
                          style: GoogleFonts.montserrat(
                            fontSize: 17 * fs,
                            fontWeight: FontWeight.w800,
                            color: colors.setupTextPrimary,
                            height: 1.2,
                          ),
                        ),
                        SizedBox(height: 4 * s),
                        Text(
                          '${program.totalWeeks} Weeks • ${program.daysPerWeek} Days/Week',
                          style: GoogleFonts.inter(
                            fontSize: 12 * fs,
                            color: colors.setupTextSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (program.isActive)
                        const StatusBadge(text: 'ACTIVE', color: WorkoutHubTokens.lime)
                      else if (program.isCompleted)
                        const StatusBadge(text: 'DONE', color: Colors.green)
                      else
                        StatusBadge(text: 'DRAFT', color: colors.setupTextSecondary),
                      SizedBox(height: 10 * s),
                      Icon(
                        Iconsax.arrow_right_3,
                        color: colors.setupTextSecondary.withValues(alpha: 0.3),
                        size: 16 * s,
                      ),
                    ],
                  ),
                ],
              ),
              if (program.isActive) ...[
                SizedBox(height: 20 * s),
                Row(
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          Container(
                            height: 4 * s,
                            decoration: BoxDecoration(
                              color: colors.border.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          Container(
                            height: 4 * s,
                            width: (MediaQuery.of(context).size.width - 120 * s) * program.progressFraction,
                            decoration: BoxDecoration(
                              color: WorkoutHubTokens.lime,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: WorkoutHubTokens.lime.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12 * s),
                    Text(
                      '${(program.progressFraction * 100).toInt()}%',
                      style: GoogleFonts.montserrat(
                        fontSize: 11 * fs,
                        fontWeight: FontWeight.w800,
                        color: WorkoutHubTokens.lime,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 50.ms).slideY(begin: 0.05);
  }
}

class StatusBadge extends StatelessWidget {
  final String text;
  final Color color;

  const StatusBadge({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.montserrat(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

class CreateProgramSheet extends StatefulWidget {
  const CreateProgramSheet({super.key});

  @override
  State<CreateProgramSheet> createState() => _CreateProgramSheetState();
}

class _CreateProgramSheetState extends State<CreateProgramSheet> {
  final TextEditingController _nameController = TextEditingController();
  String _selectedEmoji = '💪';
  int _selectedWeeks = 8;
  int _selectedDays = 4;

  final List<String> _emojis = ['💪', '🔥', '⚡', '🏋️', '🏃', '🎯', '⚔️', '🦁'];
  final List<int> _weeksOptions = [2, 4, 6, 8, 10, 12];
  final List<int> _daysOptions = [2, 3, 4, 5, 6];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = Responsive.scale(context, 1);
    final fs = Responsive.fontScale(context, 1);
    final colors = context.customColors;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20 * s,
        12 * s,
        20 * s,
        (20 * s) + bottomInset,
      ),
      decoration: BoxDecoration(
        color: colors.bgSecondary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40 * s,
                height: 4 * s,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 24 * s),
            Text(
              'New Program',
              style: GoogleFonts.montserrat(
                fontSize: 22 * fs,
                fontWeight: FontWeight.w800,
                color: colors.setupTextPrimary,
              ),
            ),
            SizedBox(height: 24 * s),
            TextField(
              controller: _nameController,
              autofocus: true,
              style: GoogleFonts.inter(color: colors.setupTextPrimary, fontSize: 16 * fs),
              decoration: InputDecoration(
                hintText: 'e.g. My Push Pull Legs',
                hintStyle: GoogleFonts.inter(color: colors.setupTextSecondary),
                filled: true,
                fillColor: colors.surfaceCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.all(16 * s),
              ),
            ),
            SizedBox(height: 24 * s),
            Text(
              'Icon',
              style: GoogleFonts.montserrat(
                fontSize: 14 * fs,
                fontWeight: FontWeight.w700,
                color: colors.setupTextSecondary,
              ),
            ),
            SizedBox(height: 12 * s),
            Wrap(
              spacing: 10 * s,
              children: _emojis.map((e) => _buildEmojiChip(e, s)).toList(),
            ),
            SizedBox(height: 24 * s),
            _buildOptionRow(
              'Duration',
              _weeksOptions,
              _selectedWeeks,
              (val) {
                setState(() => _selectedWeeks = val);
              },
              'W',
              s,
              fs,
            ),
            SizedBox(height: 24 * s),
            _buildOptionRow(
              'Days/Week',
              _daysOptions,
              _selectedDays,
              (val) {
                setState(() => _selectedDays = val);
              },
              '',
              s,
              fs,
            ),
            SizedBox(height: 32 * s),
            _buildCreateButton(context, s, fs),
          ],
        ),
      ),
    );
  }

  Widget _buildEmojiChip(String emoji, double s) {
    final colors = context.customColors;
    final isSelected = _selectedEmoji == emoji;
    return GestureDetector(
      onTap: () => setState(() => _selectedEmoji = emoji),
      child: AnimatedContainer(
        duration: 200.ms,
        width: 44 * s,
        height: 44 * s,
        decoration: BoxDecoration(
          color: isSelected
              ? colors.setupPrimary.withValues(alpha: 0.15)
              : colors.surfaceCard,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? colors.setupPrimary : colors.border,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(emoji, style: TextStyle(fontSize: 20 * s)),
        ),
      ),
    );
  }

  Widget _buildOptionRow(
    String label,
    List<int> options,
    int selected,
    Function(int) onSelect,
    String suffix,
    double s,
    double fs,
  ) {
    final colors = context.customColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 14 * fs,
            fontWeight: FontWeight.w700,
            color: colors.setupTextSecondary,
          ),
        ),
        SizedBox(height: 12 * s),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: options.map((opt) {
              final isSelected = selected == opt;
              return GestureDetector(
                onTap: () => onSelect(opt),
                child: AnimatedContainer(
                  duration: 200.ms,
                  margin: EdgeInsets.only(right: 8 * s),
                  padding: EdgeInsets.symmetric(
                    horizontal: 16 * s,
                    vertical: 8 * s,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colors.setupPrimary
                        : colors.surfaceCard,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: isSelected
                          ? colors.setupPrimary
                          : colors.border,
                    ),
                  ),
                  child: Text(
                    '$opt$suffix',
                    style: GoogleFonts.montserrat(
                      fontSize: 12 * fs,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? colors.setupOnPrimary
                          : colors.setupTextSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateButton(BuildContext context, double s, double fs) {
    final colors = context.customColors;
    return GestureDetector(
      onTap: () async {
        if (_nameController.text.trim().isEmpty) return;

        final userId = WorkoutUserResolver.resolve(context);
        final program = await context
            .read<CustomProgramProvider>()
            .createProgram(
              userId: userId,
              name: _nameController.text.trim(),
              emoji: _selectedEmoji,
              totalWeeks: _selectedWeeks,
              daysPerWeek: _selectedDays,
            );

        if (context.mounted) {
          context.pop(); // close sheet
          context.push('${AppRoutes.customPrograms}/${program.id}/edit');
        }
      },
      child: Container(
        width: double.infinity,
        height: 54 * s,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colors.setupPrimary, colors.setupPrimary.withValues(alpha: 0.8)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'Create Program',
            style: GoogleFonts.montserrat(
              fontSize: 16 * fs,
              fontWeight: FontWeight.w800,
              color: colors.setupOnPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
