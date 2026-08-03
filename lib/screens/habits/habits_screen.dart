import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/habit_provider.dart';
import '../../widgets/habit_card.dart';
import '../../widgets/app_bottom_nav.dart';

class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.watch ovdje znači: kad god se habitsProvider promijeni
    // (npr. korisnik doda naviku ili klikne checkbox), ovaj cijeli
    // build() se ponovno pozove i lista se osvježi na ekranu.
    final habits = ref.watch(habitsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Navike')),
      body: habits.isEmpty
          ? const Center(child: Text('Još nemaš nijednu naviku. Dodaj prvu!'))
          : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              itemCount: habits.length,
              itemBuilder: (context, index) {
                final habitDisplay = habits[index];
                return HabitCard(
                  habitDisplay: habitDisplay,
                  onToggle: () => ref
                      .read(habitsProvider.notifier)
                      .toggleToday(habitDisplay.habit.id!),
                  onTap: () => context.push(
                    '/habits/edit/${habitDisplay.habit.id}',
                    extra: habitDisplay.habit,
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/habits/add'),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }
}
