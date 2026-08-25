import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/obligation.dart';
import '../../providers/auth_provider.dart';
import '../../providers/habit_provider.dart';
import '../../providers/obligation_provider.dart';
import '../../widgets/habit_card.dart';
import '../../widgets/obligation_card.dart';
import '../../widgets/app_bottom_nav.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  /// Vraća pozdrav ovisan o dobu dana
  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Dobro jutro';
    if (hour < 18) return 'Dobar dan';
    return 'Dobra večer';
  }

  /// Vraća obveze koje su relevantne za dashboard
  List<Obligation> _relevantObligations(List<Obligation> all) {
    final sevenDaysFromNow = DateTime.now().add(const Duration(days: 7));

    final filtered = all.where((o) {
      if (o.status == 'done') return false;
      return o.dueDate.isBefore(sevenDaysFromNow);
    }).toList();

    filtered.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return filtered;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final habits = ref.watch(habitsProvider);
    final allObligations = ref.watch(obligationsProvider);

    final relevantObligations = _relevantObligations(allObligations);

    // Brza statistika za traku pri vrhu - koliko od ukupnih navika je već odrađeno
    final completedCount = habits.where((h) => h.completedToday).length;
    final totalCount = habits.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('${_greeting()}, ${authState.user?.name ?? ''}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: () => Future.wait([
          ref.read(habitsProvider.notifier).loadHabits(),
          ref.read(obligationsProvider.notifier).loadObligations(),
        ]),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 80),
          children: [
            if (totalCount > 0)
              _ProgressBanner(completed: completedCount, total: totalCount),

            _SectionHeader(
              title: 'Navike za danas',
              onSeeAll: () => context.go('/habits'),
            ),
            if (habits.isEmpty)
              const _EmptyHint(text: 'Nemaš još nijednu naviku.')
            else
              ...habits
                  .take(4)
                  .map(
                    (h) => HabitCard(
                      habitDisplay: h,
                      onToggle: () => ref
                          .read(habitsProvider.notifier)
                          .toggleToday(h.habit.id!),
                    ),
                  ),

            const SizedBox(height: 16),

            _SectionHeader(
              title: 'Obveze (sljedećih 7 dana)',
              onSeeAll: () => context.go('/obligations'),
            ),
            if (relevantObligations.isEmpty)
              const _EmptyHint(text: 'Nemaš nadolazećih obveza. 🎉')
            else
              ...relevantObligations
                  .take(4)
                  .map(
                    (o) => ObligationCard(
                      obligation: o,
                      onStatusTap: () =>
                          ref.read(obligationsProvider.notifier).cycleStatus(o),
                    ),
                  ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }
}

class _ProgressBanner extends StatelessWidget {
  final int completed;
  final int total;

  const _ProgressBanner({required this.completed, required this.total});

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : completed / total;

    return Card(
      margin: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Napredak danas',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),

            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(value: progress, minHeight: 8),
            ),
            const SizedBox(height: 8),
            Text('$completed / $total navika odrađeno'),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;

  const _SectionHeader({required this.title, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          TextButton(onPressed: onSeeAll, child: const Text('Prikaži sve')),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;

  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        text,
        style: TextStyle(color: Theme.of(context).colorScheme.outline),
      ),
    );
  }
}
