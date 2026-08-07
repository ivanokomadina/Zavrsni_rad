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

  /// Vraća pozdrav ovisan o dobu dana - mala UX sitnica koja čini
  /// dashboard "živim", umjesto statičnog naslova.
  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Dobro jutro';
    if (hour < 18) return 'Dobar dan';
    return 'Dobra večer';
  }

  /// Vraća obveze koje su relevantne za dashboard: već gotove
  /// izostavljamo (nema smisla prikazivati ih na "danas" pregledu),
  /// a od preostalih uzimamo samo one s rokom u sljedećih 7 dana
  /// (uključujući i one koje kasne - "isBefore(sevenDaysFromNow)"
  /// hvata i prošle datume).
  ///
  /// Ova metoda je čista funkcija (ne ovisi o stanju izvan parametara,
  /// ne mijenja ništa) - lako ju je testirati zasebno, kad bismo
  /// dodali unit testove.
  List<Obligation> _relevantObligations(List<Obligation> all) {
    final sevenDaysFromNow = DateTime.now().add(const Duration(days: 7));

    final filtered = all.where((o) {
      if (o.status == 'done') return false;
      return o.dueDate.isBefore(sevenDaysFromNow);
    }).toList();

    // Sortiramo tako da zakašnjele i hitne obveze budu na vrhu -
    // obligationsProvider ih već vraća sortirane po dueDate, ali
    // eksplicitni sort ovdje čini kod čitljivijim bez oslanjanja
    // na to "kako slučajno dolaze" iz providera.
    filtered.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return filtered;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Tri providera se prate odjednom - svaki put kad se BILO KOJI
    // od njih promijeni, ovaj build() se ponovno pokreće i cijeli
    // dashboard se osvježi.
    final authState = ref.watch(authProvider);
    final habits = ref.watch(habitsProvider);
    final allObligations = ref.watch(obligationsProvider);

    final relevantObligations = _relevantObligations(allObligations);

    // Brza statistika za "napredak danas" traku pri vrhu -
    // koliko od ukupnih navika je već odrađeno.
    final completedCount = habits.where((h) => h.completedToday).length;
    final totalCount = habits.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('${_greeting()}, ${authState.user?.name ?? ''}'),
      ),
      // RefreshIndicator omogućuje "povuci prema dolje da osvježiš" gestu -
      // uobičajen obrazac u mobilnim aplikacijama. Poziva oba loadX()
      // odjednom preko Future.wait, pa se korisniku ne čeka dvostruko dulje.
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
              // Na dashboardu prikazujemo samo prvih nekoliko navika
              // (ne cijelu listu) - detaljan pregled je na /habits ekranu.
              // take(4) uzima najviše 4 elementa liste.
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

/// Privatni (ispod donje crte "_") widget - vidljiv samo unutar ove
/// datoteke. Koristimo ovo za manje komponente koje nema smisla
/// izdvajati u zaseban dijeljeni widgets/ fajl jer se koriste SAMO
/// na dashboardu.
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
            // ClipRRect + LinearProgressIndicator - traka napretka
            // sa zaobljenim rubovima, standardan moderan izgled.
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
