import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit_log.dart';
import '../services/habit_service.dart';

/// FutureProvider.family - "family" znači da provider prima PARAMETAR
/// (ovdje: koji mjesec prikazujemo), pa Riverpod za svaki različiti
/// parametar drži zaseban cache rezultata. Kad korisnik prijeđe na
/// drugi mjesec u kalendaru, automatski se pokreće novi upit SAMO
/// za taj mjesec - a ako se vrati na prethodni, rezultat je već
/// keširan (ne radi se ponovni upit prema bazi).
final monthLogsProvider = FutureProvider.family<List<HabitLog>, DateTime>((
  ref,
  month,
) async {
  final service = HabitService();
  final start = DateTime(month.year, month.month, 1);
  final end = DateTime(
    month.year,
    month.month + 1,
    0,
  ); // dan 0 sljedećeg mjeseca = zadnji dan ovog
  return service.getLogsInRange(start, end);
});
