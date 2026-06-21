import 'package:befit/features/workout/core/workout_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../data/models/workout_models.dart';
import '../providers/exercise_library_provider.dart';
import '../widgets/exercise_detail_sheet.dart';
import '../widgets/alphabet_scrubber.dart';
import '../widgets/exercise_list_tile.dart';
import '../../../profile/presentation/providers/user_provider.dart';

class ExerciseLibraryScreen extends StatefulWidget {
  final bool selectionMode;
  final void Function(List<ExerciseLibraryItem>)? onSelectionConfirmed;

  const ExerciseLibraryScreen({
    super.key,
    this.selectionMode = false,
    this.onSelectionConfirmed,
  });

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _filterBodyPart = 'All';
  String _filterEquipment = 'All';
  String _filterDifficulty = 'All';
  final Set<String> _selectedIds = {};
  final Map<String, double> _letterOffsets = {};

  @override
  void initState() {
    super.initState();
    final provider = context.read<ExerciseLibraryProvider>();
    _filterBodyPart = provider.filterBodyPart ?? 'All';
    _filterEquipment = provider.filterEquipment ?? 'All';
    _filterDifficulty = provider.filterDifficulty ?? 'All';
    _searchController.text = provider.searchQuery;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider.initialize();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    // Reset filters when leaving the screen to ensure a clean state next time
    Future.microtask(() {
      if (mounted) {
        context.read<ExerciseLibraryProvider>().resetFilters();
      }
    });
    super.dispose();
  }

  List<_ListItem> _buildGroupedItems(List<ExerciseLibraryItem> exercises) {
    if (exercises.isEmpty) return [];
    final sorted = List<ExerciseLibraryItem>.from(exercises)
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final items = <_ListItem>[];
    _letterOffsets.clear();

    String? currentLetter;
    double currentOffset = 0;

    for (final ex in sorted) {
      final letter = ex.name.isEmpty ? '#' : ex.name[0].toUpperCase();
      if (letter != currentLetter) {
        currentLetter = letter;
        _letterOffsets[letter] = currentOffset;
        items.add(_ListItem.header(letter));
        currentOffset += 60.0; // Estimated height of header
      }
      items.add(_ListItem.exercise(ex));
      currentOffset +=
          108.0; // Fixed height of ExerciseListTile (96 + 12 margin)
    }
    return items;
  }

  void _jumpToLetter(String letter) {
    final offset = _letterOffsets[letter];
    if (offset != null) {
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExerciseLibraryProvider>();
    // ignore: unused_local_variable
    final user = context.watch<UserProvider>();

    final exercises = provider.exercises;
    final isSearching = _searchController.text.isNotEmpty;
    final grouped = isSearching ? null : _buildGroupedItems(exercises);
    final letters = grouped != null
        ? grouped.where((i) => i.isHeader).map((i) => i.letter!).toList()
        : <String>[];

    return Scaffold(
      backgroundColor: WorkoutColors.scaffold(context),
      appBar: AppBar(
        backgroundColor: WorkoutColors.scaffold(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            widget.selectionMode
                ? Icons.close_rounded
                : Icons.arrow_back_ios_new_rounded,
            color: WorkoutColors.onSurface(context),
            size: 22,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.selectionMode ? 'Select Exercises' : 'Library',
          style: Theme.of(context).textTheme.headlineSmall!.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: false,
        actions: [
          if (!widget.selectionMode) ...[
            // Actions removed per user request
          ],
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(provider),
          if (provider.isSyncing) _buildSyncBanner(provider),
          Expanded(
            child: provider.isLoading
                ? _buildSkeleton()
                : exercises.isEmpty
                ? _buildEmptyState()
                : Stack(
                    children: [
                      isSearching
                          ? _buildFlatList(exercises, provider)
                          : _buildGroupedList(grouped!, provider),
                      if (!isSearching && letters.isNotEmpty)
                        Positioned(
                          right: 8,
                          top: 0,
                          bottom: 0,
                          child: AlphabetScrubber(
                            letters: letters,
                            onLetterSelected: _jumpToLetter,
                          ),
                        ),
                    ],
                  ),
          ),
          if (widget.selectionMode && _selectedIds.isNotEmpty)
            _buildSelectionBar(exercises),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(ExerciseLibraryProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      decoration: BoxDecoration(color: WorkoutColors.scaffold(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            onChanged: (v) {
              provider.search(v);
              setState(() {});
            },
            style: GoogleFonts.montserrat(
              color: WorkoutColors.onSurface(context),
            ),
            decoration: InputDecoration(
              hintText: 'Search 1500+ exercises...',
              prefixIcon: Icon(
                Icons.search,
                size: 20,
                color: WorkoutColors.onSurfaceMuted(context),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        provider.search('');
                        setState(() {});
                      },
                    )
                  : null,
              filled: true,
              fillColor: WorkoutColors.card(context),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: WorkoutColors.border(context)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'FILTERS',
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: WorkoutColors.onSurfaceMuted(context),
                  letterSpacing: 1.2,
                ),
              ),
              if (_filterBodyPart != 'All' ||
                  _filterEquipment != 'All' ||
                  _filterDifficulty != 'All' ||
                  _searchController.text.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() {
                      _filterBodyPart = 'All';
                      _filterEquipment = 'All';
                      _filterDifficulty = 'All';
                    });
                    provider.resetFilters();
                  },
                  child: Text(
                    'Reset All',
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: WorkoutColors.primary(context),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              children: [
                _FilterCard(
                  title: 'BODY PART',
                  value: _filterBodyPart,
                  icon: Icons.accessibility_new_rounded,
                  onTap: () => _showFilterPicker(
                    'Body Part',
                    {
                      'All': Icons.all_inclusive_rounded,
                      'Chest': Icons.layers_rounded,
                      'Back': Icons.reorder_rounded,
                      'Shoulders': Icons.accessibility_rounded,
                      'Upper Arms': Icons.fitness_center_rounded,
                      'Upper Legs': Icons.directions_run_rounded,
                      'Lower Legs': Icons.height_rounded,
                      'Waist': Icons.center_focus_strong_rounded,
                      'Cardio': Icons.bolt_rounded,
                    },
                    _filterBodyPart,
                    (v) {
                      setState(() => _filterBodyPart = v);
                      provider.applyFilter(bodyPart: v);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                _FilterCard(
                  title: 'EQUIPMENT',
                  value: _filterEquipment,
                  icon: Icons.fitness_center_rounded,
                  onTap: () => _showFilterPicker(
                    'Equipment',
                    {
                      'All': Icons.all_inclusive_rounded,
                      'Barbell': Icons.linear_scale_rounded,
                      'Dumbbell': Icons.fitness_center_rounded,
                      'Cable': Icons.settings_input_component_rounded,
                      'Body Weight': Icons.person_pin_rounded,
                      'Kettlebell': Icons.sports_kabaddi_rounded,
                      'Machine': Icons.settings_rounded,
                      'Bands': Icons.linear_scale_rounded,
                      'Bench': Icons.chair_rounded,
                      'TRX': Icons.sports_gymnastics_rounded,
                      'Medicine Ball': Icons.sports_baseball_rounded,
                      'Other': Icons.more_horiz_rounded,
                    },
                    _filterEquipment,
                    (v) {
                      setState(() => _filterEquipment = v);
                      provider.applyFilter(equipment: v);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                _FilterCard(
                  title: 'DIFFICULTY',
                  value: _filterDifficulty,
                  icon: Icons.bolt_rounded,
                  onTap: () => _showFilterPicker(
                    'Difficulty',
                    {
                      'All': Icons.all_inclusive_rounded,
                      'Beginner': Icons.signal_cellular_alt_1_bar_rounded,
                      'Intermediate': Icons.signal_cellular_alt_2_bar_rounded,
                      'Advanced': Icons.signal_cellular_alt_rounded,
                    },
                    _filterDifficulty,
                    (v) {
                      setState(() => _filterDifficulty = v);
                      provider.applyFilter(difficulty: v);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncBanner(ExerciseLibraryProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: WorkoutColors.primary(context).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: WorkoutColors.primary(context),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Syncing Library...',
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: WorkoutColors.primary(context),
                ),
              ),
              const Spacer(),
              Text(
                '${(provider.syncProgress * 100).toInt()}%',
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: WorkoutColors.primary(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: provider.syncProgress,
              backgroundColor: WorkoutColors.border(context),
              color: WorkoutColors.primary(context),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedList(
    List<_ListItem> items,
    ExerciseLibraryProvider provider,
  ) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item.isHeader) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(4, 24, 0, 12),
            child: Text(
              item.letter!,
              style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: WorkoutColors.onSurfaceMuted(context),
              ),
            ),
          );
        }
        return _buildExerciseTile(item.exercise!, provider);
      },
    );
  }

  Widget _buildFlatList(
    List<ExerciseLibraryItem> exercises,
    ExerciseLibraryProvider provider,
  ) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: exercises.length,
      itemBuilder: (context, index) =>
          _buildExerciseTile(exercises[index], provider),
    );
  }

  Widget _buildExerciseTile(
    ExerciseLibraryItem ex,
    ExerciseLibraryProvider provider,
  ) {
    final isSelected = _selectedIds.contains(ex.id);
    return ExerciseListTile(
      exercise: ex,
      onTap: () {
        if (widget.selectionMode) {
          setState(
            () => isSelected
                ? _selectedIds.remove(ex.id)
                : _selectedIds.add(ex.id),
          );
        } else {
          ExerciseDetailSheet.show(context, ex);
        }
      },
      trailing: widget.selectionMode
          ? Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected
                    ? WorkoutColors.primary(context)
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : WorkoutColors.border(context),
                  width: 2,
                ),
                shape: BoxShape.circle,
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      size: 14,
                      color: Theme.of(context).colorScheme.onPrimary,
                    )
                  : null,
            )
          : null,
    );
  }

  Widget _buildSelectionBar(List<ExerciseLibraryItem> all) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: WorkoutColors.card(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () => widget.onSelectionConfirmed?.call(
          all.where((e) => _selectedIds.contains(e.id)).toList(),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: WorkoutColors.onSurface(context),
          foregroundColor: WorkoutColors.scaffold(context),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 0,
        ),
        child: Text(
          'Add ${_selectedIds.length} Exercises',
          style: Theme.of(context).textTheme.titleSmall!.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: WorkoutColors.scaffold(context),
          ),
        ),
      ),
    );
  }

  void _showFilterPicker(
    String title,
    Map<String, IconData> options,
    String current,
    Function(String) onPick,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: WorkoutColors.card(context),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: WorkoutColors.border(ctx),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    onPick('All');
                    Navigator.pop(ctx);
                  },
                  child: Text(
                    'Clear',
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: WorkoutColors.primary(ctx),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemCount: options.length,
              itemBuilder: (c, i) {
                final key = options.keys.elementAt(i);
                final icon = options.values.elementAt(i);
                final isSelected = current == key;

                return GestureDetector(
                  onTap: () {
                    onPick(key);
                    Navigator.pop(ctx);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? WorkoutColors.primary(ctx)
                          : WorkoutColors.scaffold(ctx),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : WorkoutColors.border(ctx),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icon,
                          color: isSelected
                              ? Theme.of(ctx).colorScheme.onPrimary
                              : WorkoutColors.onSurfaceMuted(ctx),
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          key,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall!
                              .copyWith(
                                fontSize: 11,
                                color: isSelected
                                    ? Theme.of(ctx).colorScheme.onPrimary
                                    : WorkoutColors.onSurfaceMuted(ctx),
                              ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton() => Skeletonizer(
    child: ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 10,
      itemBuilder: (c, i) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Container(height: 90),
      ),
    ),
  );
  Widget _buildEmptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.search_off_rounded,
          color: WorkoutColors.border(context),
          size: 64,
        ),
        const SizedBox(height: 20),
        Text(
          'No results found',
          style: Theme.of(context).textTheme.titleSmall!.copyWith(
            fontSize: 16,
            color: WorkoutColors.onSurfaceMuted(context),
          ),
        ),
      ],
    ),
  );
}

class _FilterCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _FilterCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = value != 'All';
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 130,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: active
              ? WorkoutColors.primary(context)
              : WorkoutColors.card(context),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: active
                  ? WorkoutColors.primary(context).withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: active ? Colors.transparent : WorkoutColors.border(context),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: active
                    ? Colors.white24
                    : WorkoutColors.scaffold(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: active ? Colors.white : WorkoutColors.primary(context),
                size: 16,
              ),
            ),
            const Spacer(),
            Text(
              title,
              style: GoogleFonts.montserrat(
                color: active
                    ? Colors.white70
                    : WorkoutColors.onSurfaceMuted(context),
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: GoogleFonts.montserrat(
                      color: active
                          ? Colors.white
                          : WorkoutColors.onSurface(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: active
                      ? Colors.white70
                      : WorkoutColors.onSurfaceMuted(context),
                  size: 14,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ListItem {
  final String? letter;
  final ExerciseLibraryItem? exercise;
  _ListItem.header(this.letter) : exercise = null;
  _ListItem.exercise(this.exercise) : letter = null;
  bool get isHeader => letter != null;
}
