import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/statistics.dart';
import '../services/statistics_service.dart';
import 'habit_provider.dart';
import 'obligation_provider.dart';

final weeklyCompletionProvider = FutureProvider<List<DayCompletion>>((
  ref,
) async {
  // ref.watch ovdje NE koristimo rezultat habitsProvidera direktno -
  // koristimo ga samo kao "okidač". Svaki put kad se habitsProvider
  // promijeni (npr. nakon toggleToday()), Riverpod zna da MORA
  // ponovno pokrenuti CIJELU ovu funkciju - jer smo deklarirali
  // ovisnost pozivom ref.watch().
  ref.watch(habitsProvider);
  return StatisticsService().getLast7DaysCompletion();
});

final habitStreaksProvider = FutureProvider<List<HabitStreak>>((ref) async {
  ref.watch(habitsProvider);
  return StatisticsService().getAllStreaks();
});

final obligationSummaryProvider = FutureProvider<Map<String, int>>((ref) async {
  ref.watch(obligationsProvider);
  return StatisticsService().getObligationSummary();
});
