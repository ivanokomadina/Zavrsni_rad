import '../models/statistics.dart';
import 'database_service.dart';
import 'habit_service.dart';

class StatisticsService {
  final _db = DatabaseService.instance;
  final _habitService = HabitService();

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  /// Računa postotak odrađenih navika za svaki od zadnjih 7 dana
  Future<List<DayCompletion>> getLast7DaysCompletion() async {
    final habits = await _habitService.getAllHabits();
    final today = _dateOnly(DateTime.now());

    final sevenDaysAgo = today.subtract(const Duration(days: 6));
    final logs = await _habitService.getLogsInRange(sevenDaysAgo, today);

    final results = <DayCompletion>[];

    for (int i = 6; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));

      final completedThatDay = logs
          .where((log) => log.completed && _isSameDay(log.date, day))
          .length;

      final total = habits.isEmpty ? 1 : habits.length;
      final percentage = habits.isEmpty ? 0.0 : completedThatDay / total;

      results.add(DayCompletion(date: day, percentage: percentage));
    }

    return results;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Računa trenutni streak (broj uzastopnih odrađenih dana za jednu naviku)
  Future<int> _calculateStreakForHabit(int habitId) async {
    final logs = await _habitService.getLogsForHabit(habitId);

    final completedDates = logs
        .where((log) => log.completed)
        .map((log) => _dateOnly(log.date))
        .toSet();

    int streak = 0;
    DateTime day = _dateOnly(DateTime.now());

    while (completedDates.contains(day)) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }

    return streak;
  }

  /// Računa streakove za sve navike odjednom
  Future<List<HabitStreak>> getAllStreaks() async {
    final habits = await _habitService.getAllHabits();

    final streaks = <HabitStreak>[];
    for (final habit in habits) {
      final streak = await _calculateStreakForHabit(habit.id!);
      streaks.add(
        HabitStreak(
          habitName: habit.name,
          habitColorHex: habit.colorHex,
          currentStreak: streak,
        ),
      );
    }

    streaks.sort((a, b) => b.currentStreak.compareTo(a.currentStreak));
    return streaks;
  }

  /// Dodatna statistika - ukupan broj odrađenih i ukupan broj obveza kroz cijelu povijest
  Future<Map<String, int>> getObligationSummary() async {
    final db = await _db.database;

    final doneResult = await db.rawQuery(
      "SELECT COUNT(*) as count FROM obligations WHERE status = 'done'",
    );
    final totalResult = await db.rawQuery(
      "SELECT COUNT(*) as count FROM obligations",
    );

    return {
      'done': doneResult.first['count'] as int,
      'total': totalResult.first['count'] as int,
    };
  }
}
