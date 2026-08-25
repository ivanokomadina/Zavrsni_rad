import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit.dart';
import '../models/habit_display.dart';
import '../services/habit_service.dart';

/// StateNotifier koji drži popis navika zajedno s njihovim statusom za danas
class HabitsNotifier extends StateNotifier<List<HabitDisplay>> {
  final HabitService _service;

  HabitsNotifier(this._service) : super([]) {
    loadHabits();
  }

  /// Učitava navike iz baze i spaja ih s današnjim logovima
  Future<void> loadHabits() async {
    final habits = await _service.getAllHabits();
    final todayLogs = await _service.getLogsForDate(DateTime.now());

    final completedHabitIds = todayLogs.map((log) => log.habitId).toSet();

    state = habits.map((habit) {
      return HabitDisplay(
        habit: habit,
        completedToday: completedHabitIds.contains(habit.id),
      );
    }).toList();
  }

  Future<void> addHabit({
    required String name,
    String? description,
    required String colorHex,
    required String frequency,
  }) async {
    final habit = Habit(
      name: name,
      description: description,
      colorHex: colorHex,
      frequency: frequency,
      createdAt: DateTime.now(),
    );
    await _service.insertHabit(habit);
    await loadHabits();
  }

  Future<void> updateHabit(Habit updatedHabit) async {
    await _service.updateHabit(updatedHabit);
    await loadHabits();
  }

  Future<void> deleteHabit(int habitId) async {
    await _service.deleteHabit(habitId);
    await loadHabits();
  }

  /// Poziva se kad korisnik klikne checkbox pored navike na dashboardu/habits ekranu
  Future<void> toggleToday(int habitId) async {
    await _service.toggleCompletion(habitId: habitId, date: DateTime.now());
    await loadHabits();
  }
}

final habitsProvider =
    StateNotifierProvider<HabitsNotifier, List<HabitDisplay>>((ref) {
      return HabitsNotifier(HabitService());
    });
