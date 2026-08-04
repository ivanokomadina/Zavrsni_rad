import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/obligation.dart';
import '../services/obligation_service.dart';

/// Redoslijed statusa kroz koji obveza "kruži" kad korisnik klikne na nju.
/// Definiran kao top-level konstanta da je logika ciklusa na jednom mjestu.
const _statusCycle = ['pending', 'in_progress', 'done'];

class ObligationsNotifier extends StateNotifier<List<Obligation>> {
  final ObligationService _service;

  ObligationsNotifier(this._service) : super([]) {
    loadObligations();
  }

  Future<void> loadObligations() async {
    state = await _service.getAllObligations();
  }

  Future<void> addObligation(Obligation obligation) async {
    await _service.insertObligation(obligation);
    await loadObligations();
  }

  Future<void> updateObligation(Obligation obligation) async {
    await _service.updateObligation(obligation);
    await loadObligations();
  }

  Future<void> deleteObligation(int id) async {
    await _service.deleteObligation(id);
    await loadObligations();
  }

  /// Pomiče status obveze na sljedeći u ciklusu (pending -> in_progress
  /// -> done -> natrag na pending). Ovo omogućuje brzu promjenu statusa
  /// jednim tapom, bez otvaranja forme.
  Future<void> cycleStatus(Obligation obligation) async {
    final currentIndex = _statusCycle.indexOf(obligation.status);
    // Ako trenutni status nije prepoznat (ne bi se smjelo dogoditi),
    // vrati se na prvi u ciklusu kao sigurnosnu mjeru.
    final nextIndex = (currentIndex + 1) % _statusCycle.length;
    await _service.updateStatus(
      id: obligation.id!,
      newStatus: _statusCycle[nextIndex],
    );
    await loadObligations();
  }
}

final obligationsProvider =
    StateNotifierProvider<ObligationsNotifier, List<Obligation>>((ref) {
      return ObligationsNotifier(ObligationService());
    });
