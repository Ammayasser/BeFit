import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import '../../core/workout_colors.dart';
import 'package:provider/provider.dart';
import '../providers/fitbod_workout_provider.dart';
import '../providers/exercise_library_provider.dart';
import '../../data/models/fitbod_workout_model.dart';
import 'fitbod_workout_detail_screen.dart';
import '../widgets/workout_ui.dart';

class WorkoutDiscoverScreen extends StatefulWidget {
  final String? initialCategory;
  final String? initialMuscle;
  final String? initialDifficulty;

  const WorkoutDiscoverScreen({
    super.key,
    this.initialCategory,
    this.initialMuscle,
    this.initialDifficulty,
  });

  @override
  State<WorkoutDiscoverScreen> createState() => _WorkoutDiscoverScreenState();
}

class _WorkoutDiscoverScreenState extends State<WorkoutDiscoverScreen> {
  String _selectedCategory = 'All';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<FitbodWorkoutProvider>();
      provider.loadCategories();

      if (widget.initialCategory != null) {
        setState(() {
          _selectedCategory = widget.initialCategory!;
        });
        provider.loadByCategory(widget.initialCategory!);
      } else if (widget.initialMuscle != null) {
        setState(() {
          _selectedCategory = 'All';
        });
        provider.applyFilters(muscle: widget.initialMuscle);
      } else if (widget.initialDifficulty != null) {
        setState(() {
          _selectedCategory = 'All';
        });
        provider.applyFilters(difficulty: widget.initialDifficulty);
      } else {
        provider.loadFeatured();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onCategoryTapped(String cat) {
    setState(() {
      _selectedCategory = cat;
    });
    final provider = context.read<FitbodWorkoutProvider>();
    if (cat == 'All') {
      provider.loadFeatured();
    } else {
      provider.loadByCategory(cat);
    }
  }

  void _onSearchChanged(String query) {
    final provider = context.read<FitbodWorkoutProvider>();
    if (query.trim().isEmpty) {
      if (_selectedCategory == 'All') {
        provider.loadFeatured();
      } else {
        provider.loadByCategory(_selectedCategory);
      }
    } else {
      provider.search(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FitbodWorkoutProvider>();
    final libraryProvider = context.watch<ExerciseLibraryProvider>();

    if (!libraryProvider.isSyncing &&
        provider.featuredWorkouts.isEmpty &&
        !provider.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          provider.loadCategories();
          provider.loadFeatured();
        }
      });
    }

    final workoutsList =
        _selectedCategory == 'All' && _searchController.text.isEmpty
        ? provider.featuredWorkouts
        : provider.workouts;

    return WorkoutLightScaffold(
      appBar: const WorkoutBackAppBar(title: 'Discover Workouts'),
      body: SafeArea(
        child: provider.isLoading && provider.categories.isEmpty
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildSearch(context)),
                  SliverToBoxAdapter(
                    child: _buildCategories(provider.categories),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  SliverToBoxAdapter(
                    child: WorkoutSectionHeader(
                      title: _searchController.text.isNotEmpty
                          ? 'Search Results'
                          : (_selectedCategory == 'All'
                                ? 'Featured Routines'
                                : 'Category: $_selectedCategory'),
                    ),
                  ),
                  _buildWorkoutsList(context, workoutsList, provider.isLoading),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
      ),
    );
  }

  Widget _buildSearch(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search 1,700+ workouts...',
          hintStyle: workoutTextStyle(
            context,
            size: 14,
            color: WorkoutColors.onSurfaceSubtle(context),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: WorkoutColors.onSurfaceMuted(context),
          ),
          filled: true,
          fillColor: WorkoutColors.card(context),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildCategories(List<String> list) {
    final allCats = ['All', ...list];
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: allCats.length,
        itemBuilder: (context, index) {
          final cat = allCats[index];
          return WorkoutFilterPill(
            label: cat,
            selected: _selectedCategory == cat,
            onTap: () => _onCategoryTapped(cat),
          );
        },
      ),
    );
  }

  Widget _buildWorkoutsList(
    BuildContext context,
    List<FitbodWorkout> list,
    bool loading,
  ) {
    if (loading) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (list.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Center(
            child: Text(
              'No workouts found.',
              style: workoutTextStyle(
                context,
                color: WorkoutColors.onSurfaceMuted(context),
              ),
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, i) {
          final w = list[i];
          final coverUrl = w.imageUrls.isNotEmpty ? w.imageUrls.first : null;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FitbodWorkoutDetailScreen(workout: w),
                  ),
                );
              },
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: WorkoutColors.card(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: WorkoutColors.border(context)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Row(
                    children: [
                      if (coverUrl != null)
                        Image.network(
                          coverUrl,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        )
                      else
                        Container(
                          width: 120,
                          color: const Color(0xFF1E3A5F),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.fitness_center,
                            color: Colors.white24,
                            size: 36,
                          ),
                        ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                w.name,
                                style: GoogleFonts.montserrat(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: WorkoutColors.onSurface(context),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(
                                    w.difficulty.toUpperCase(),
                                    style: GoogleFonts.montserrat(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: WorkoutColors.primary(context),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${w.exercises.length} EXERCISES',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: WorkoutColors.onSurfaceMuted(
                                        context,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }, childCount: list.length),
      ),
    );
  }
}
