import 'habit.dart';

/// Pomoćni model koji kombinira naviku s informacijom je li ta navika odrađena danas
class HabitDisplay {
  final Habit habit;
  final bool completedToday;

  HabitDisplay({required this.habit, required this.completedToday});

  HabitDisplay copyWith({bool? completedToday}) {
    return HabitDisplay(
      habit: habit,
      completedToday: completedToday ?? this.completedToday,
    );
  }
}
