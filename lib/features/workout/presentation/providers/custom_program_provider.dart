import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/custom_program_models.dart';
import '../../data/repositories/custom_program_repository.dart';

class CustomProgramProvider extends ChangeNotifier {
  final CustomProgramRepository _repo = CustomProgramRepository();
  final _uuid = const Uuid();

  List<CustomProgram> _programs = [];
  CustomProgram? _activeProgram;
  bool _isLoading = false;

  List<CustomProgram> get programs => _programs;
  CustomProgram? get activeProgram => _activeProgram;
  bool get isLoading => _isLoading;
  bool get hasActiveProgram => _activeProgram != null;

  // ── Load ──────────────────────────────────────────────────────

  Future<void> loadPrograms(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _programs = await _repo.getPrograms(userId);
      _activeProgram = _programs.where((p) => p.isActive && !p.isCompleted).firstOrNull;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<CustomProgram?> loadProgramFull(String programId) async {
    return _repo.getProgramFull(programId);
  }

  // ── Create ────────────────────────────────────────────────────

  /// Creates an empty program shell + scaffolds the week/day structure
  Future<CustomProgram> createProgram({
    required String userId,
    required String name,
    String? emoji,
    required int totalWeeks,
    required int daysPerWeek,
  }) async {
    final now = DateTime.now();
    final programId = _uuid.v4();

    final program = CustomProgram(
      id: programId,
      userId: userId,
      name: name,
      emoji: emoji ?? '💪',
      totalWeeks: totalWeeks,
      daysPerWeek: daysPerWeek,
      createdAt: now,
      updatedAt: now,
    );
    await _repo.saveProgram(program);

    // Scaffold weeks + days (all empty, user fills them in)
    for (int w = 1; w <= totalWeeks; w++) {
      final weekId = _uuid.v4();
      final week = ProgramWeek(id: weekId, programId: programId, weekNumber: w);
      await _repo.saveWeek(week);

      for (int d = 1; d <= daysPerWeek; d++) {
        final day = ProgramDay(
          id: _uuid.v4(),
          programWeekId: weekId,
          programId: programId,
          dayNumber: d,
          name: 'Day $d',   // user renames later
        );
        await _repo.saveDay(day);
      }
    }

    await loadPrograms(userId);
    return program;
  }

  // ── Update ────────────────────────────────────────────────────

  Future<void> updateProgramMeta(CustomProgram program) async {
    await _repo.updateProgram(program.copyWith(updatedAt: DateTime.now()));
    await loadPrograms(program.userId);
  }

  Future<void> saveDayExercises(
    String dayId,
    List<ProgramDayExercise> exercises,
    String userId,
  ) async {
    await _repo.saveDayExercises(dayId, exercises);
    // no full reload needed — exercises are edited in-screen
    notifyListeners();
  }

  Future<void> updateDayName(ProgramDay day, String newName) async {
    await _repo.updateDay(day.copyWith(name: newName));
    notifyListeners();
  }

  Future<void> updateDayRestStatus(ProgramDay day, bool isRestDay) async {
    await _repo.updateDay(day.copyWith(isRestDay: isRestDay));
    notifyListeners();
  }

  // ── Activate / Delete ─────────────────────────────────────────

  Future<void> activateProgram(String programId, String userId) async {
    // Deactivate all others
    for (final p in _programs.where((p) => p.isActive)) {
      await _repo.updateProgram(p.copyWith(isActive: false));
    }
    final targetIndex = _programs.indexWhere((p) => p.id == programId);
    if (targetIndex != -1) {
      final target = _programs[targetIndex];
      await _repo.updateProgram(target.copyWith(
        isActive: true,
        startedAt: DateTime.now(),
      ));
    }
    await loadPrograms(userId);
  }

  Future<void> deleteProgram(String programId, String userId) async {
    await _repo.deleteProgram(programId);
    await loadPrograms(userId);
  }

  // ── Complete a day ────────────────────────────────────────────

  Future<void> completeDay(String dayId, CustomProgram program) async {
    await _repo.markDayCompleted(dayId);
    await _repo.advanceCurrentDay(program);
    await loadPrograms(program.userId);
  }
}
