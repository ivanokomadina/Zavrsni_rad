import '../models/habit.dart';
import '../models/habit_log.dart';
import 'database_service.dart';

/// Servis odgovoran za CRUD nad navikama i njihovim dnevnim logovima
class HabitService {
  final _db = DatabaseService.instance;

  /// Normalizira DateTime na samo datum
  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  // ---------- CRUD nad navikama ----------

  Future<List<Habit>> getAllHabits() async {
    final db = await _db.database;
    final result = await db.query('habits', orderBy: 'createdAt DESC');
    return result.map((row) => Habit.fromMap(row)).toList();
  }

  Future<int> insertHabit(Habit habit) async {
    final db = await _db.database;
    return await db.insert('habits', habit.toMap());
  }

  Future<void> updateHabit(Habit habit) async {
    final db = await _db.database;
    await db.update(
      'habits',
      habit.toMap(),
      where: 'id = ?',
      whereArgs: [habit.id],
    );
  }

  Future<void> deleteHabit(int habitId) async {
    final db = await _db.database;

    await db.delete('habits', where: 'id = ?', whereArgs: [habitId]);
  }

  // ---------- CRUD nad logovima navika ----------

  Future<List<HabitLog>> getLogsForDate(DateTime date) async {
    final db = await _db.database;
    final normalizedDate = _dateOnly(date).toIso8601String();

    final result = await db.query(
      'habit_logs',
      where: 'date = ?',
      whereArgs: [normalizedDate],
    );
    return result.map((row) => HabitLog.fromMap(row)).toList();
  }

  Future<List<HabitLog>> getLogsForHabit(int habitId) async {
    final db = await _db.database;
    final result = await db.query(
      'habit_logs',
      where: 'habitId = ?',
      whereArgs: [habitId],
      orderBy: 'date ASC',
    );
    return result.map((row) => HabitLog.fromMap(row)).toList();
  }

  Future<void> toggleCompletion({
    required int habitId,
    required DateTime date,
  }) async {
    final db = await _db.database;
    final normalizedDate = _dateOnly(date).toIso8601String();

    final existing = await db.query(
      'habit_logs',
      where: 'habitId = ? AND date = ?',
      whereArgs: [habitId, normalizedDate],
    );

    if (existing.isNotEmpty) {
      await db.delete(
        'habit_logs',
        where: 'habitId = ? AND date = ?',
        whereArgs: [habitId, normalizedDate],
      );
    } else {
      final log = HabitLog(
        habitId: habitId,
        date: _dateOnly(date),
        completed: true,
      );
      await db.insert('habit_logs', log.toMap());
    }
  }

  Future<List<HabitLog>> getLogsInRange(DateTime start, DateTime end) async {
    final db = await _db.database;
    final result = await db.query(
      'habit_logs',
      where: 'date >= ? AND date <= ?',
      whereArgs: [
        _dateOnly(start).toIso8601String(),
        _dateOnly(end).toIso8601String(),
      ],
    );
    return result.map((row) => HabitLog.fromMap(row)).toList();
  }
}
