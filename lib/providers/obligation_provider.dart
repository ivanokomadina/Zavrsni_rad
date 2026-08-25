import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/obligation.dart';
import '../services/obligation_service.dart';
import '../services/notification_service.dart';
import 'notification_settings_provider.dart';

// Redoslijed statusa kroz koji obveza "kruži" kad korisnik klikne na nju
const _statusCycle = ['pending', 'in_progress', 'done'];

/// StateNotifier koji upravlja popisom obveza te povezuje CRUD operacije
/// nad obvezama sa zakazivanjem/otkazivanjem pripadajućih obavijesti
class ObligationsNotifier extends StateNotifier<List<Obligation>> {
  final ObligationService _service;
  final Ref _ref; // omogućuje čitanje drugih providera iz ovog notifiera

  ObligationsNotifier(this._service, this._ref) : super([]) {
    loadObligations();
  }

  /// Provjerava jesu li notifikacije trenutno dopuštene
  bool get _notificationsAllowed => _ref.read(notificationsEnabledProvider);

  Future<void> loadObligations() async {
    state = await _service.getAllObligations();
  }

  Future<void> addObligation(Obligation obligation) async {
    final id = await _service.insertObligation(obligation);

    if (_notificationsAllowed) {
      final saved = Obligation(
        id: id,
        name: obligation.name,
        description: obligation.description,
        dueDate: obligation.dueDate,
        priority: obligation.priority,
        categoryId: obligation.categoryId,
        status: obligation.status,
      );
      await NotificationService.instance.scheduleObligationReminder(saved);
    }

    await loadObligations();
  }

  Future<void> updateObligation(Obligation obligation) async {
    await _service.updateObligation(obligation);

    if (_notificationsAllowed) {
      await NotificationService.instance.scheduleObligationReminder(obligation);
    }

    await loadObligations();
  }

  Future<void> deleteObligation(int id) async {
    await _service.deleteObligation(id);
    // Brisanjem obveze otkazuje se i njena eventualno zakazana notifikacija
    await NotificationService.instance.cancelObligationReminder(id);
    await loadObligations();
  }

  /// Pomiče status obveze na sljedeći u ciklusu
  Future<void> cycleStatus(Obligation obligation) async {
    final currentIndex = _statusCycle.indexOf(obligation.status);
    final nextIndex = (currentIndex + 1) % _statusCycle.length;
    final newStatus = _statusCycle[nextIndex];

    await _service.updateStatus(id: obligation.id!, newStatus: newStatus);

    if (newStatus == 'done') {
      await NotificationService.instance.cancelObligationReminder(
        obligation.id!,
      );
    }

    await loadObligations();
  }
}

/// Provider koji izlaže ObligationsNotifier ostatku aplikacije
final obligationsProvider =
    StateNotifierProvider<ObligationsNotifier, List<Obligation>>((ref) {
      return ObligationsNotifier(ObligationService(), ref);
    });
