import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/statistics.dart';
import '../services/statistics_service.dart';
import 'habit_provider.dart';
import 'obligation_provider.dart';

/// FutureProvider za tjedni pregled uspješnosti (postotak odrađenih navika po danu, zadnjih 7 dana)
final weeklyCompletionProvider = FutureProvider<List<DayCompletion>>((
  ref,
) async {
  ref.watch(habitsProvider);
  return StatisticsService().getLast7DaysCompletion();
});

/// FutureProvider za popis navika s njihovim trenutnim streakovima
final habitStreaksProvider = FutureProvider<List<HabitStreak>>((ref) async {
  ref.watch(habitsProvider);
  return StatisticsService().getAllStreaks();
});

/// FutureProvider za sažetak uspješnosti obveza (ukupno/završeno/postotak)
final obligationSummaryProvider = FutureProvider<Map<String, int>>((ref) async {
  ref.watch(obligationsProvider);
  return StatisticsService().getObligationSummary();
});
