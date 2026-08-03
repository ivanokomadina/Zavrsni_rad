import 'habit.dart';

/// Pomoćni (display) model koji kombinira Habit s informacijom
/// je li ta navika odrađena DANAS. Ovo NIJE tablica u bazi -
/// to je model koji postoji samo u memoriji, kreiran u provideru,
/// specifično radi lakšeg prikaza u UI-u (npr. dashboard i habits ekran
/// mogu odmah iscrtati checkbox bez da sami rade upit nad habit_logs).
class HabitDisplay {
  final Habit habit;
  final bool completedToday;

  HabitDisplay({required this.habit, required this.completedToday});

  /// copyWith je koristan jer često mijenjamo SAMO completedToday
  /// (npr. kad korisnik klikne checkbox), a habit ostaje isti.
  HabitDisplay copyWith({bool? completedToday}) {
    return HabitDisplay(
      habit: habit,
      completedToday: completedToday ?? this.completedToday,
    );
  }
}
