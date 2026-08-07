/// Predstavlja postotak odrađenih navika za JEDAN dan - jedna "stupac"
/// u tjednom bar chartu.
class DayCompletion {
  final DateTime date;
  final double percentage; // 0.0 - 1.0 (0% - 100%)

  DayCompletion({required this.date, required this.percentage});
}

/// Predstavlja trenutni streak (niz uzastopnih odrađenih dana) za
/// jednu naviku - koristi se za prikaz liste streakova.
class HabitStreak {
  final String habitName;
  final String habitColorHex;
  final int currentStreak;

  HabitStreak({
    required this.habitName,
    required this.habitColorHex,
    required this.currentStreak,
  });
}
