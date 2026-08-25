/// Model koji predstavlja odrađivanje navike za određeni dan
class HabitLog {
  final int? id;
  final int habitId; // strani ključ - povezuje log s konkretnom navikom
  final DateTime date;
  final bool completed;

  HabitLog({
    this.id,
    required this.habitId,
    required this.date,
    required this.completed,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'habitId': habitId,
      'date': date.toIso8601String(),
      'completed': completed ? 1 : 0,
    };
  }

  factory HabitLog.fromMap(Map<String, dynamic> map) {
    return HabitLog(
      id: map['id'] as int?,
      habitId: map['habitId'] as int,
      date: DateTime.parse(map['date'] as String),
      completed: (map['completed'] as int) == 1,
    );
  }
}
