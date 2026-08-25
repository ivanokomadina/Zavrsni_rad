import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit_log.dart';
import '../services/habit_service.dart';

/// FutureProvider.family - provider prima parametar (mjesec koji se prikazuje), pa Riverpod za svaki različiti
/// parametar drži zaseban cache rezultat
final monthLogsProvider = FutureProvider.family<List<HabitLog>, DateTime>((
  ref,
  month,
) async {
  final service = HabitService();
  final start = DateTime(month.year, month.month, 1);
  final end = DateTime(month.year, month.month + 1, 0);
  return service.getLogsInRange(start, end);
});
