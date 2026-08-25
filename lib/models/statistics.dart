/// Predstavlja postotak odrađenih navika za jedan dan u tjednom bar chartu
class DayCompletion {
  final DateTime date;
  final double percentage;

  DayCompletion({required this.date, required this.percentage});
}

/// Predstavlja trenutni streak (niz uzastopnih odrađenih dana) za jednu naviku
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
