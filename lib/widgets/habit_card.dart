import 'package:flutter/material.dart';
import '../models/habit_display.dart';

class HabitCard extends StatelessWidget {
  final HabitDisplay habitDisplay;
  final VoidCallback onToggle;
  final VoidCallback? onTap;

  const HabitCard({
    super.key,
    required this.habitDisplay,
    required this.onToggle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final habit = habitDisplay.habit;

    final color = Color(int.parse(habit.colorHex.replaceFirst('#', '0xFF')));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(Icons.repeat, color: color),
        ),
        title: Text(habit.name),
        subtitle: habit.description != null && habit.description!.isNotEmpty
            ? Text(habit.description!)
            : Text(_frequencyLabel(habit.frequency)),
        trailing: IconButton(
          icon: Icon(
            habitDisplay.completedToday
                ? Icons.check_circle
                : Icons.radio_button_unchecked,
            color: habitDisplay.completedToday ? color : Colors.grey,
            size: 28,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }

  String _frequencyLabel(String frequency) {
    switch (frequency) {
      case 'daily':
        return 'Svaki dan';
      case 'weekly':
        return 'Tjedno';
      default:
        return frequency;
    }
  }
}
