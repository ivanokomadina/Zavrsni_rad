import '../models/statistics.dart';
import 'database_service.dart';
import 'habit_service.dart';

class StatisticsService {
  final _db = DatabaseService.instance;
  final _habitService = HabitService();

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  /// Računa postotak odrađenih navika za svaki od zadnjih 7 dana
  /// (uključujući danas). Rezultat je uređen kronološki - od najstarijeg
  /// prema najnovijem danu - pogodno za direktno iscrtavanje u bar chartu
  /// s lijeva na desno.
  Future<List<DayCompletion>> getLast7DaysCompletion() async {
    final habits = await _habitService.getAllHabits();
    final today = _dateOnly(DateTime.now());

    // Dohvaćamo SVE logove za zadnjih 7 dana JEDNIM upitom (raspon),
    // umjesto 7 zasebnih upita po danu - isti princip kao kod kalendara
    // u koraku 8.
    final sevenDaysAgo = today.subtract(const Duration(days: 6));
    final logs = await _habitService.getLogsInRange(sevenDaysAgo, today);

    final results = <DayCompletion>[];

    // Iteriramo kroz zadnjih 7 dana, od najstarijeg (i=6) prema danas (i=0).
    for (int i = 6; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));

      // Koliko navika je te navike koje postoje DANAS bilo odrađeno
      // baš na taj dan. Napomena: koristimo trenutni broj navika kao
      // nazivnik za sve dane radi jednostavnosti - realno bi broj
      // navika mogao biti drugačiji prije nekoliko dana (npr. ako je
      // korisnik tek jučer dodao naviku), ali za potrebe ovog pregleda
      // (opći "osjećaj napretka" kroz tjedan) ovo pojednostavljenje
      // je prihvatljivo i puno jednostavnije za objasniti i implementirati.
      final completedThatDay = logs
          .where((log) => log.completed && _isSameDay(log.date, day))
          .length;

      final total = habits.isEmpty
          ? 1
          : habits.length; // izbjegavamo dijeljenje s 0
      final percentage = habits.isEmpty ? 0.0 : completedThatDay / total;

      results.add(DayCompletion(date: day, percentage: percentage));
    }

    return results;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Računa trenutni streak (broj uzastopnih odrađenih dana, brojeći
  /// unatrag od danas) za JEDNU naviku.
  Future<int> _calculateStreakForHabit(int habitId) async {
    final logs = await _habitService.getLogsForHabit(habitId);

    // Pretvaramo listu logova u Set datuma (samo onih koji su completed)
    // radi brze O(1) provjere "je li ovaj dan odrađen" u petlji ispod,
    // umjesto O(n) pretraživanja liste za svaki dan.
    final completedDates = logs
        .where((log) => log.completed)
        .map((log) => _dateOnly(log.date))
        .toSet();

    int streak = 0;
    DateTime day = _dateOnly(DateTime.now());

    // Krećemo od danas i idemo unatrag dan po dan, sve dok nailazimo
    // na odrađene dane. Čim naiđemo na dan koji NIJE odrađen, streak
    // prekida i vraćamo dosad izbrojano.
    while (completedDates.contains(day)) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }

    return streak;
  }

  /// Računa streakove za SVE navike odjednom - koristi se za prikaz
  /// liste na statistics ekranu.
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

    // Sortiramo od najduljeg streaka prema najkraćem - najzanimljivije
    // (najduži streak) korisnik vidi prvo.
    streaks.sort((a, b) => b.currentStreak.compareTo(a.currentStreak));
    return streaks;
  }

  /// Jednostavna dodatna statistika - ukupan broj odrađenih vs. ukupan
  /// broj obveza kroz cijelu povijest. Koristi se za "kartice" sa sažetkom.
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
