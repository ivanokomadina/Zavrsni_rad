import '../models/habit.dart';
import '../models/habit_log.dart';
import 'database_service.dart';

/// Servis odgovoran za CRUD nad navikama (habits) i njihovim
/// dnevnim logovima (habit_logs).
class HabitService {
  final _db = DatabaseService.instance;

  /// Normalizira DateTime na "samo datum" (bez vremena) - sat/minuta/
  /// sekunda uvijek postavljeni na 0. Ovo je bitno jer želimo da
  /// "danas u 14:32" i "danas u 09:10" broje kao ISTI dan pri
  /// spremanju/pretraživanju logova.
  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  // ---------- CRUD nad habits ----------

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
    // Zahvaljujući "ON DELETE CASCADE" na habit_logs (postavljenom u koraku 2),
    // brisanjem navike SQLite sam briše i sve njene logove - ne moramo
    // ovdje ručno brisati iz habit_logs.
    await db.delete('habits', where: 'id = ?', whereArgs: [habitId]);
  }

  // ---------- Logovi (habit_logs) ----------

  /// Dohvaća sve logove za zadani datum (za SVE navike odjednom) -
  /// koristi se za izračun "koje su navike odrađene danas".
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

  /// Dohvaća SVE logove za jednu naviku (kroz cijelu povijest) -
  /// trebat ćemo ovo kasnije za statistiku/streak izračun.
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

  /// "Prebacuje" (toggle) status navike za zadani datum:
  /// - ako log za taj dan već postoji -> briše ga (označava kao neodrađeno)
  /// - ako ne postoji -> kreira novi log s completed=true
  ///
  /// Ovo je namjerno JEDNA metoda koja radi oba smjera - UI ne treba
  /// znati trenutno stanje da bi je pozvao, samo kaže "toggle za ovu naviku".
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
      // Log postoji -> brišemo ga (undo)
      await db.delete(
        'habit_logs',
        where: 'habitId = ? AND date = ?',
        whereArgs: [habitId, normalizedDate],
      );
    } else {
      // Log ne postoji -> kreiramo ga
      final log = HabitLog(
        habitId: habitId,
        date: _dateOnly(date),
        completed: true,
      );
      await db.insert('habit_logs', log.toMap());
    }
  }
}
