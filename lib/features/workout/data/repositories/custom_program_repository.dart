import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../models/custom_program_models.dart';

class CustomProgramRepository {
  static const _p  = 'custom_programs';
  static const _w  = 'custom_program_weeks';
  static const _d  = 'custom_program_days';
  static const _e  = 'custom_program_exercises';

  // ── Programs ────────────────────────────────────────────────

  Future<void> saveProgram(CustomProgram program) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(_p, program.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<CustomProgram>> getPrograms(String userId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(_p, where: 'user_id = ?', whereArgs: [userId], orderBy: 'updated_at DESC');
    return rows.map((r) => CustomProgram.fromMap(r)).toList();
  }

  Future<CustomProgram?> getProgramById(String id) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(_p, where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return CustomProgram.fromMap(rows.first);
  }

  /// Loads program WITH all weeks + days + exercises (full tree)
  Future<CustomProgram?> getProgramFull(String programId) async {
    final db = await DatabaseHelper.instance.database;
    final progRows = await db.query(_p, where: 'id = ?', whereArgs: [programId], limit: 1);
    if (progRows.isEmpty) return null;

    final weekRows = await db.query(_w,
      where: 'program_id = ?', whereArgs: [programId], orderBy: 'week_number ASC');

    final List<ProgramWeek> weeks = [];
    for (final weekRow in weekRows) {
      final weekId = weekRow['id'] as String;
      final dayRows = await db.query(_d,
        where: 'program_week_id = ?', whereArgs: [weekId], orderBy: 'day_number ASC');

      final List<ProgramDay> days = [];
      for (final dayRow in dayRows) {
        final dayId = dayRow['id'] as String;
        final exRows = await db.query(_e,
          where: 'program_day_id = ?', whereArgs: [dayId], orderBy: 'sort_order ASC');
        final exercises = exRows.map((e) => ProgramDayExercise.fromMap(e)).toList();
        days.add(ProgramDay.fromMap(dayRow, exercises: exercises));
      }
      weeks.add(ProgramWeek.fromMap(weekRow, days: days));
    }

    return CustomProgram.fromMap(progRows.first, weeks: weeks);
  }

  Future<void> updateProgram(CustomProgram program) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(_p, program.toMap(), where: 'id = ?', whereArgs: [program.id]);
  }

  Future<void> deleteProgram(String programId) async {
    final db = await DatabaseHelper.instance.database;
    // Cascade deletes weeks → days → exercises via FK ON DELETE CASCADE
    await db.delete(_p, where: 'id = ?', whereArgs: [programId]);
  }

  // ── Weeks ───────────────────────────────────────────────────

  Future<void> saveWeek(ProgramWeek week) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(_w, week.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ProgramWeek>> getWeeks(String programId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(_w,
      where: 'program_id = ?', whereArgs: [programId], orderBy: 'week_number ASC');
    return rows.map((r) => ProgramWeek.fromMap(r)).toList();
  }

  // ── Days ─────────────────────────────────────────────────────

  Future<void> saveDay(ProgramDay day) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(_d, day.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<ProgramDay?> getDayFull(String dayId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(_d, where: 'id = ?', whereArgs: [dayId], limit: 1);
    if (rows.isEmpty) return null;
    final exRows = await db.query(_e,
      where: 'program_day_id = ?', whereArgs: [dayId], orderBy: 'sort_order ASC');
    return ProgramDay.fromMap(rows.first,
      exercises: exRows.map((e) => ProgramDayExercise.fromMap(e)).toList());
  }

  Future<void> updateDay(ProgramDay day) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(_d, day.toMap(), where: 'id = ?', whereArgs: [day.id]);
  }

  Future<void> markDayCompleted(String dayId) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(_d, {
      'is_completed': 1,
      'completed_at': DateTime.now().toIso8601String(),
    }, where: 'id = ?', whereArgs: [dayId]);
  }

  // ── Exercises ────────────────────────────────────────────────

  /// Replaces all exercises for a day (delete + re-insert pattern, same as routine_repository)
  Future<void> saveDayExercises(String dayId, List<ProgramDayExercise> exercises) async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      await txn.delete(_e, where: 'program_day_id = ?', whereArgs: [dayId]);
      for (int i = 0; i < exercises.length; i++) {
        final map = exercises[i].toMap();
        map['sort_order'] = i;
        await txn.insert(_e, map, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  // ── Advance after completing a workout ──────────────────────

  Future<void> advanceCurrentDay(CustomProgram program) async {
    int nextDay = program.currentDayIndex + 1;
    int nextWeek = program.currentWeekIndex;

    if (nextDay >= program.daysPerWeek) {
      nextDay = 0;
      nextWeek += 1;
    }

    final isNowCompleted = nextWeek >= program.totalWeeks;

    await updateProgram(CustomProgram.fromMap({
      ...program.toMap(),
      'current_day_index': isNowCompleted ? 0 : nextDay,
      'current_week_index': isNowCompleted ? program.totalWeeks - 1 : nextWeek,
      'is_completed': isNowCompleted ? 1 : 0,
      'is_active': isNowCompleted ? 0 : 1,
      'updated_at': DateTime.now().toIso8601String(),
    }));
  }
}
